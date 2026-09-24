# Changelog

## [Unreleased]

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
