# AGENTS.md — Chronicle

Flutter student planner. NixOS-first repo; `flutter`/`dart` only exist inside `nix develop`.

## Shell / build
- Always run via `nix develop --command bash -c "..."` from repo root.
- Linux bundle: `nix develop --command bash -c "flutter build linux --release"`. devShell sets `SQLITE_LIB` + `LD_LIBRARY_PATH` for drift. Release tarball bundles `libsqlite3.so` under `bundle/lib` (found via `$ORIGIN/lib` RUNPATH — no launcher script, no system sqlite needed).

## Release
- Version lives in `pubspec.yaml` (`versionName/versionCode`). Push tag `vX.Y.Z` to publish.
- Android signing reads `CHRONICLE_KEYSTORE` (+`_PASSWORD`, `_ALIAS`, `_KEY_PASSWORD`) from env; without them builds fall back to debug keys. Upload keystore lives in `android/keystore/` (gitignored) — never commit it; CI restores it from `ANDROID_KEYSTORE_BASE64`.
- `ci.yml` runs analyze + tests on push/PR. `release.yml` runs on tags: verify, signed universal APK + Linux tarball + AppImage + Flatpak, GitHub Release with `CHANGELOG.md` `[Unreleased]` notes.
- Linux Flatpak (`packaging/flatpak/*.yml`): `type: dir` sources merge their *contents* into the module build dir — the `dest: stage` on the source is what makes the `stage/...` paths in `build-commands` exist.
- Keep `CHANGELOG.md` `[Unreleased]` current; move entries under the version heading when tagging.

## Verify
- `nix develop --command bash -c "flutter analyze --no-pub"`
- `nix develop --command bash -c "flutter test --no-pub"` (all of `test/`, incl. `e2e_*` full-app suites)
- Single test: `--plain-name 'Exact test name'` — one flag only; multiple AND-match to zero.
- Keep full-app suites as plain `flutter_test` widget tests under `test/` (never an `integration_test/` dir: the flutter tool treats that path as on-device tests and tries to build + launch the Linux app, which needs GTK and a display that CI verify jobs don't have).
- Ignore drift "multiple databases" warnings in tests (each test makes its own `NativeDatabase.memory()`).

## Codegen — do not edit generated files
- `lib/data/database.g.dart` from `database.dart` + `tables.dart` via `dart run build_runner build --delete-conflicting-outputs`. Bump `schemaVersion` + idempotent `_addColumnIfMissing` steps (killed migrates must re-run safely).
- l10n source is `lib/l10n/app_en.arb` / `app_tr.arb` (`l10n.yaml`); generated `app_localizations*.dart` via `flutter generate`. Add strings to ARBs only.

## Architecture
- Entry `lib/main.dart`: opens `AppDatabase`, reads `calendarView`/`absencesView` prefs, overrides `*ViewSeedProvider` before `runApp` (avoids list→grid flash), applies portrait lock. `StartupRunner` does post-frame reminder sync + `warmCalendarWeek` + folder-sync start only — never read providers synchronously during mount.
- `lib/app.dart`: `go_router` `ShellRoute` (`/`, `/calendar`, `/classes`, `/tasks`, `/absences`, `/menu`, `/settings`). `NavigationRail` at width ≥600 (extended ≥900); custom `_PhoneNavBar` below 600 (stock `NavigationBar` can't fit 7 labels).
- State: hand-written Riverpod in `lib/providers.dart` — `riverpod_annotation`/`riverpod_generator` are deps but no `@riverpod` codegen is in use. Settings (`SettingsRepository`) is source of truth → `dayRangeProvider`/`fixedGridProvider`/`weekStartDayProvider`/etc. Calendar first paint is gated on warmed week inputs (`warmCalendarWeek`); add new geometry-affecting settings there.
- Schedule: `ScheduleRepository.loadEngine` → `domain/schedule_occurrence_engine.dart`.
- Themes (`lib/theme.dart`, 6 families: default/catppuccin/nord/dracula/gruvbox/tokyo-night): class fills must use `classBlockColor`, side-bars `classAccentColor`, text `classOnBlockColor` — never raw `Color(colorValue)`.
- Dining menu (`lib/services/menu/`, `/menu`): `MenuProvider` + `menuSources` registry (`hacettepe`, `itu`). Page is empty until a source is picked in Settings (`menu_provider` key, default ''). 6h cache in `MenuCache` table, excluded from sync/backup.
- Local data folder (`lib/services/data_folder.dart` + `folder_sync.dart`, started post-frame in `main.dart`): one JSON per table (`manifest.json`, `<table>.json`, `tombstones.json`) + `files/<stem>_<shortid>.<ext>` blobs for class/year attachments (blob bytes copied locally on import, incoming absolute paths never trusted). Merge is newer-`updatedAt`-wins keyed on `uuid`, deletes via `SyncTombstones`; conflicts preserved under `conflicts/`. Auto-sync (default on, `auto_sync` key): 5s-debounced merge-before-export on drift `tableUpdates()` (synced tables only), equality-gated import (manifest `exportedAt` + file mtimes — never wall-clock ordering) every 30s + at startup + on folder FS events + on app resume. Auto-export never prunes blobs; manual Export does.

## Hard rules (past bugs)
- Dates: never `Duration(days: n)` for calendar days (DST drift). Use `shiftDays(d, n)` / `DateTime(y, m, d + n)` (`lib/utils/time_format.dart`). Same for absence weeks and `TaskRepository.nextRepeatDate`.
- Day range is minutes (`day_start_minutes`/`day_end_minutes`, `dayRangeProvider`). Legacy `day_start_hour` keys remain as fallback; setters write both.
- Absence matrix weeks respect `weekStartDayProvider`; W1 = week containing `year.startDate`.
- Every insert stamps `uuid: newUuid()` + `updatedAt: syncNow()`; every update bumps `updatedAt`; every delete `recordTombstone`s the row plus cascade children *before* deleting (FK cascades won't tombstone). New tables need both columns + migration entries or sync silently duplicates rows.
- Tests: pump async-init screens with `pumpForAsync(tester)` helper (`test/widget_test.dart`); set `tester.view.physicalSize` for form/phone screens. `testWidgets` runs in FakeAsync: wrap ALL real async I/O (drift queries, `Directory`/`File` ops, folder export/import) in `tester.runAsync` — outside it they hang until the 10-min timeout (plain `test()` is unaffected).
- Linux window (`linux/runner/my_application.cc`): keep resizable + 800×600 minimum.
