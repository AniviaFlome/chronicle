# Changelog

## [Unreleased]

## [1.3.0] - 2026-09-24

### Added
- Classes screen menu: "Delete all classes" bulk-deletes every class
  (with schedules and absence records) after confirmation.
- Settings → Data → "Import schedule": parses a supported course-table
  PDF (Hacettepe Bilsis Ders Programı) with pure-Dart text extraction
  (Android + Linux) and creates one class per course with weekly slots
  after a tick-to-select preview. Back-to-back rows of one course merge
  into a single block (08:40–10:30, not two one-hour slots).

### Changed
- Absences opens in the weeks-grid view by default (switch back anytime).
- Auto-sync now merges before exporting, watches the data folder, and
  imports on app resume — manual Export/Import remain as override.

### Fixed
- Absences grid no longer slides on every entry when the current week is
  already visible, and the auto-jump clamps to the scroll range so the
  latest weeks land on-screen instead of overshooting.
- Import skips single unparsable rows (e.g. from a newer app version)
  instead of aborting the whole import; the count shows in the
  import confirmation.
- Auto-sync no longer drops changes that arrive while a sync is running;
  queued work runs right after instead of waiting for the next edit.
- Auto-export no longer prunes blobs (a peer's new attachment can't be
  deleted before import); manual Export still prunes.
- Auto-import no longer uses cross-device wall-clock ordering, so clock
  skew can't permanently skip a peer export; late Syncthing files retry.
- Concurrent edits on both devices preserve the losing version under
  `conflicts/` instead of silently discarding it.
- Settings → Data now shows the last sync error and preserved-conflict
  count instead of logging to console only.
- Settings → Data: the Android file-access row sits with the folder
  picker again, so Export/Import stay adjacent instead of split apart.

## [1.2.3] - 2026-09-24

### Added
- Settings → Data shows a File access row on Android with one-tap
  "All files access" grant (the folder picker grant alone does not
  enable raw file reads on Android 11+).

### Fixed
- Import reports the underlying read error for an unreadable
  `manifest.json` (e.g. permission denied vs truncated sync) instead
  of a bare "couldn't read it".

## [1.2.2] - 2026-09-24

### Fixed
- Import distinguishes an unreadable `manifest.json` (e.g. missing
  Android file access) from a folder with no export yet, instead of
  reporting both as "no export".
- Android declares external-storage permissions so a Syncthing data
  folder is readable (broad access still needs the system "All files
  access" grant for Chronicle).
- Auto-sync no longer re-exports forever: the change watcher only
  listens to synced data tables, so export/import bookkeeping writes
  don't schedule another export. Previously every export rewrote the
  manifest within seconds, so Syncthing peers never converged on one
  manifest.

## [1.2.1] - 2026-09-23

### Fixed
- Import errors say what's wrong (folder gone vs no export yet vs
  foreign folder) instead of one blanket message.

## [1.2.0] - 2026-09-23

### Added
- Automatic data-folder sync while the app runs: changes export a few
  seconds after edits, folder updates import within ~30s and at startup.
  Toggle in Settings → Data; manual Export/Import remain as override.

### Fixed
- Attachment references are relative paths, so files survive reinstalls
  and user changes (legacy absolute rows still resolve). Sync blobs use
  readable `stem_shortid.ext` names; exports carry no absolute device
  paths. Old `uuid.ext` blobs still import.

## [1.1.0] - 2026-09-23

### Added
- File attachments for classes and academic years (PDFs, slides, program
  files). Picked via the platform picker, opened in the default app,
  synced through the data folder.
- Absence records carry an optional theory/practical tag, picked in the
  mark-absent dialog and shown in absence lists.

### Fixed
- Focus timer: dropped the "working on" picker; countdown stays inside
  the progress ring with large fonts.
- Menu: date no longer claims every day is today; Beytepe/Sıhhiye switch
  fits narrow phones; allergen chips and legend highlight match their
  shapes; day chevrons labeled correctly.
- Phone bottom bar: all 7 labels visible, single-line, no shifting; on
  Android the Absences view switch sits in the title row.
- Class file errors show a plain message; Linux release bundles sqlite.

### Changed
- Launcher icon is now a 7-day strip (was a calendar page).

## [1.0.0] - 2026-09-21

### Added
- Class schedules with weekly, A/B-week, custom-cycle and day-rotation slots.
- Calendar list and time-grid views with absence marking.
- Absence tracking with per-class quotas and a weeks-grid overview.
- Tasks with subtasks, reminders, repeats and exams with grades.
- Focus timer with custom work/break durations and streak statistics.
- Dining-hall menus (Hacettepe) with offline cache.
- Local data folder export/import for moving data between devices.
- Linux desktop bundle and Android APK builds.
