# AGENTS.md — Chronicle

Flutter student planner. NixOS-first repo; `flutter`/`dart` only exist inside `nix develop`.

## Shell / build
- Always run via `nix develop --command bash -c "..."` from repo root.
- Linux bundle: `nix develop --command bash -c "flutter build linux --release"`. `flake.nix` devShell sets `SQLITE_LIB` + `LD_LIBRARY_PATH` for drift. The GitHub release tarball additionally bundles `libsqlite3.so` with a `chronicle.sh` launcher (sets `LD_LIBRARY_PATH` to `bundle/lib`), so end-user systems need no global sqlite install.

## Release
- Version lives in `pubspec.yaml` (`1.0.0+1` → versionName/versionCode). Push tag `vX.Y.Z` to publish.
- Android release signing reads `CHRONICLE_KEYSTORE` (+`_PASSWORD`, `_ALIAS`, `_KEY_PASSWORD`) from env; without them local builds fall back to debug keys. Upload keystore lives in `android/keystore/` (gitignored) — never commit it; CI restores it from the `ANDROID_KEYSTORE_BASE64` secret.
- `.github/workflows/ci.yml` runs analyze + tests on push/PR. `release.yml` runs on tags: verify, signed universal APK + Linux bundle tarball, GitHub Release with `CHANGELOG.md` notes.
- Keep `CHANGELOG.md` `[Unreleased]` section current; move entries under the version heading when tagging.

## Verify
- `nix develop --command bash -c "flutter analyze --no-pub"`
- Full widget suite: `nix develop --command bash -c "flutter test test/widget_test.dart --no-pub"` (~16s, 52 tests).
- Single test: `flutter test test/widget_test.dart --no-pub --plain-name 'Exact test name'` — one `--plain-name` only; multiple names AND-match to zero.
- Ignore drift "multiple databases" warnings in tests (each test makes its own `NativeDatabase.memory()`).

## Codegen — do not edit generated files
- `lib/data/database.g.dart` from `lib/data/database.dart` + `lib/data/tables.dart` via `dart run build_runner build --delete-conflicting-outputs`. Bump `schemaVersion` + idempotent `_addColumnIfMissing` steps (killed migrates must re-run safely).
- l10n: source is `lib/l10n/app_en.arb` / `app_tr.arb` (`l10n.yaml`); generated `app_localizations*.dart` via `flutter generate`. Never edit generated files; add strings to ARBs.

## Architecture
- Entry: `lib/main.dart` opens `AppDatabase`, reads `calendarView`/`absencesView` prefs, overrides `*ViewSeedProvider` before `runApp` (avoids list→grid flash). `StartupRunner` does post-frame reminder sync only.
- `lib/app.dart`: `go_router` `ShellRoute` (`/`, `/calendar`, `/classes`, `/tasks`, `/absences`, `/settings`) + `NavigationRail`/`NavigationBar` switch at 600/900px.
- State: hand-written Riverpod in `lib/providers.dart` (no riverpod codegen in use). Settings are the source of truth: `SettingsRepository` (`lib/data/repositories.dart`) → `dayRangeProvider`/`fixedGridProvider`/`weekStartDayProvider`/etc.
- Schedule: `ScheduleRepository.loadEngine` → `domain/schedule_occurrence_engine.dart`; date math lives in `lib/utils/time_format.dart`.
- Themes: `lib/theme.dart` `buildAppTheme` + `classBlockColor`/`classAccentColor`/`classOnBlockColor`. Class side-bars/blocks must use `classAccentColor`, backgrounds `classBlockColor`, text `classOnBlockColor` — never raw `Color(colorValue)` for fills.
- Dining menu (`lib/services/menu/`, `/menu` route): `MenuProvider` abstraction + `menuSources` registry (only `hacettepe` ships). Page is empty until a source is picked in Settings → Dining menu (`menu_provider` key, default ''). Display-only scraping with 6h cache (`MenuCache` table, excluded from sync/backup).
- Local data folder (`lib/services/data_folder.dart`): user-picked folder holding one JSON file per table (`manifest.json`, `<table>.json`, `tombstones.json`) plus `files/<uuid>[.ext]` content blobs for class/year attachments (referenced by `class_files.json`/`year_files.json`; blob bytes copied locally on import, incoming absolute paths never trusted). Manual Export overwrites the files and prunes unreferenced blobs; manual Import merges newer rows by `updatedAt` keyed on `uuid`, with `SyncTombstones` for deletes. No network, no background watchers, no external-service integration — whatever syncs the folder is outside the app. One device at a time: export, let the folder sync elsewhere, import on the other side.

## Hard rules (past bugs)
- Dates: never `Duration(days: n)` add/subtract for calendar days (DST drift, e.g. Europe/Berlin Mar 29). Use `shiftDays(d, n)` and `DateTime(y, m, d + n)` construction. Same for absence-matrix weeks and `TaskRepository.nextRepeatDate`.
- Day range is minutes (`day_start_minutes`/`day_end_minutes`, `dayRangeProvider` = minutes). Legacy `day_start_hour` keys remain as fallback; `setDayStartHour` writes both. Calendar grid takes `rangeStart/rangeEnd` minutes, draws faint `hourly` base + stronger `markers` + labeled break bands. Day columns shrink to fit all 7 across (min 110 list / 100 grid) before scrolling; Android phones keep the scroll strip with jump-to-today.
- Absence matrix weeks respect `weekStartDayProvider`; W1 = week containing `year.startDate`. `_MatrixCell` tap toggles: empty→create on `weekStart` (540–600), single→delete, multi→dialog.
- Settings keys to know: `calendar_view`/`absences_view`, `grid_markers_mode`, `grid_fixed_lesson/break`, `locale_override` (`system/en/tr`), `active_year_id`, `data_folder_path`, `data_last_export_at`, `data_last_import_at`.
- Every repository insert must stamp `uuid: newUuid()` + `updatedAt: syncNow()`; every update must bump `updatedAt`; every delete must `recordTombstone` the row plus cascade children *before* deleting (FK cascades won't tombstone). New tables need the same two columns + v+1 migration entries, otherwise sync silently duplicates rows.
- Tests: pump `SettingsScreen`/async-init screens with `pumpForAsync(tester)` helper; set `tester.view.physicalSize` for form screens; class-picker dot count = palette + current-theme accents + custom picker.
- Linux window: `linux/runner/my_application.cc` forces resizable + 800×600 min; keep it.
