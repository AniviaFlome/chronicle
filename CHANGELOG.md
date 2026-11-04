# Changelog

## [Unreleased]

## [1.14.1] - 2026-11-04

### Fixed
- Widget menu push keeps full servings: the per-meal dish cap is 12, not 8 (live Hacettepe breakfast serves 9 items — the old cap silently dropped Ekmek from every widget), and blank dish names are dropped instead of rendering empty bullets.
- Hub menu/agenda/tasks tabs are copies of the standalone widgets, not second designs: new `SharedMenuList`/`SharedAgendaList`/`SharedTasksList` render the tall dish/class/task rows in both places (same row components, gaps, scrolling contract as `SharedClassTab` does for classes); short/narrow tiers keep their fitting-take variants as the documented space adjustment. The standalone tasks widget's tall tiers now scroll the full list instead of capping at 4/8.
- Hub widgets are copies of the standalone widgets: narrow menu tabs reuse the standalone `MealSwitcher` row in the header slot (icon + title + steppers crush to zero there), and the short menu tab scrolls the full dish list like the standalone Compact tier instead of capping at 2–3 behind a `+N` pill — the host reports a short slot and then draws it tall, so a capped take orphans dishes behind a void.
- Dining menu widget meal pick is day-scoped (same reset-to-today contract as the agenda's `selectedDay`): arrow picks stick for the day, then lunch wins again when servable — previously a single tap pinned that meal forever, and every pre-update pick read as fresh, so Breakfast-stuck widgets never flipped back. After updating, existing widgets show Lunch immediately (no fresh push needed).
- Dining menu: Hacettepe garnish sides (`.garnitur-inline`, e.g. "(Haşlama Sebze Garnitür · 35 kcal)") are parsed into the dish name instead of being dropped, so lunch/dinner mains show their full serving; the menu page always offers Breakfast/Lunch/Dinner switching (plus Vegan when the day carries it) with lunch preferred, including ITU days that publish lunch + dinner only (breakfast shows the empty state); the widget push defaults to lunch when servable and the native resolver prefers lunch when servable, so existing widgets showing Breakfast flip to Lunch without waiting for a fresh push.
- Hub short strips always show the per-tab header (icon + title, including the menu meal steppers with the title kept alongside); previously multi-tab shorts dropped the header under the dots bar. On 1-column narrow strips the meal steppers yield to the title (icon + title only — two 40dp arrows plus title physically overflow ~75dp and crush the title to zero); meal switching stays on wider placements, the standalone menu widget, and the app.
- Hub class tab and standalone Next-class widget always carry the class location: short-bar hero meta is now `status · range · room` (was status only), quiet bar then-lines append `room · building` when known, and the standalone lookahead rows push `teacher/room/building/range` like the hub (were time/name/color only).
- Lunch widget meal switching is arrows-only: the standalone `MealSwitcher` row no longer carries a whole-row +1 tap that swallowed arrow hits (same contract as the hub tab bar); hub menu header keeps its title next to the steppers instead of blanking it.
- Tasks page tiles are back to the roomier size (6dp stripe, default checkbox, two-line details) with the expandable notes/subtasks/progress section kept; the checkbox now centers against the collapsed title block by construction instead of top-pinning (it rendered high on short tiles).
- Exam tasks show their location: the linked class's room rides the exam tile meta (`Exam · … · Mathematics · B4`) and the exam countdown card shows the room under the class name (plus due time when set); the quiz `?` icons are gone from the exam tiles and countdown cards.
- Tasks *widget* rows are dense checklist blocks with a details line: 14sp single-line title (was 16sp two-line), 16dp checkbox (was 20dp), plus an 11sp `class · steps` meta line under the title (new `class`/`steps` wire fields, localized `stepsCount`), so rows show which class a task belongs to and its subtask progress; standalone Due-tasks and hub tasks tabs share the row, and the static picker preview mirrors it.
- iCal UTC timestamps (`Z`) now convert to local wall time (built as UTC then `toLocal`); previously the conversion was a no-op and external feeds rendered hours off.
- Folder sync blob lifecycle: import resolves relative stored paths, skips stale rows before copying (no orphan `name (1).ext` bloat), export resolves relative blobs + atomic tmp+rename copies, export lock carries an owner UUID (no cross-device delete race), manual Export merges before pruning, mtime gate uses `>=` for coarse filesystems, losing bytes preserved alongside JSON conflicts, corrupt/foreign folders surface `dataSyncError`.
- Database integrity: absence marks dedup per class+date, task reminders dedup per offset, `MenuCache.storeDay` runs in a transaction, class/year/slot/task deletes explicitly remove tombstoned children (no FK-pragma dependence), empty-uuid tombstones logged, pomodoro sessions gain a tombstoned delete.
- Settings sync: `week_start_day`, `week_ab_anchor`, `absences_view` now have keys and ride the portable snapshot; `FolderSyncController.scheduleExport()` added for settings-only changes.
- Widgets: hub/menu push normalizes location ids and enforces `isCacheValid` (stale-format rows refetch); calendar first-paint gate includes `weekStartDay`.
- Release: unsigned fallback genuinely unsets `CHRONICLE_KEYSTORE` and Gradle falls back on missing file; R8 keeps all `ActionCallback` implementations.
- Audit sweep (10 fixes, `test/audit_fixes_test.dart` +351 green): dashboard stats window is exactly 7 days (`-6`, was 8 with `-7`); iCal parser rejects out-of-range dates (month 13, Feb 30, hour 25) instead of rolling over; empty `classIds` filter yields an empty engine instead of all slots; class/task deletes await the row delete before bumping FK-nulled victims (was a concurrent race); attachment `resolveStoredPath` rejects `../` escapes outside the support dir; legacy DB rescue deletes stale target `-wal/-shm/-journal` before replacing; widget menu self-heal skips caching all-empty days (mirrors the menu page guard); dashboard task toggle refreshes home widgets and both toggles surface errors via snackbar; bottom-nav/rail highlights nothing on editor/grades/focus routes instead of lying on Today; forever-daily Xtra series from old anchors fast-forward arithmetically to the query window instead of vanishing past the step guard.
- Audit sweep round 2 (9 fixes, `test/audit_sweep_test.dart` +357 green): iCal `FREQ=DAILY;BYDAY=...` now filters to the listed weekdays instead of expanding every day; malformed `COUNT`/`UNTIL` fails closed to a single instance instead of widening to the 500/horizon cap; all-day events with an explicit midnight `DTEND` keep the `VALUE=DATE` form on export (was degrading to timed midnight on re-export); `shortWeekdayName`/`fullWeekdayName` match `tr-TR`/`TR` like `hhmmLocale` does (were English for any non-exact `tr`); Linux class-reminder dedup compares the stored fire instant instead of mere existence so lead-time/schedule edits re-fire (matches the task-reminder gate); `teachingDays` doc corrected to excluding holidays (code already excluded them); folder-sync export only deletes its own lock (a failed lock write no longer deletes a concurrent exporter's lock); Flatpak gains `--share=network` so menu/catalog HTTPS works sandboxed; release Linux tarball step fails fast with a clear error when `ldconfig` yields no sqlite path.

## [1.14.0] - 2026-11-01

### Changed
- Today page no longer shows absence warnings; quota urgency moved to the Absences page as per-class highlights (red only when strictly over the limit, a middle tone exactly at the limit, amber when one remains; no highlight otherwise and never for classes without a limit).
- Absences list view shows every active class: quota cards for classes with a limit plus a neutral card for classes without one (previously limit-less classes were invisible there).
- Task and class editors pin the save button in a bottom bar above the system navigation instead of at the end of the scroll list, so it stays tappable on long forms.
- Absences week grid freezes the class-name column: names (and quota highlights) stay pinned on the left while only the weeks scroll.
- Mouse, stylus and trackpad drags now scroll everywhere (e.g. the absence week grid in Waydroid), matching touch-drag behavior.

## [1.13.0] - 2026-10-30

### Added
- Widget option "Show full class names" (Settings → Widgets): the Next-class timeline (hero, Then-line, lookahead, in the standalone widget and the hub class tab) shows plain class names without the course-code prefix. Agenda day rows already use plain names and are unchanged.

### Changed
- Hub paging is dots/arrows-only: every other tap (tab body, header, shell padding, tiny strips) opens the app. Previously narrow shells and the wide tab body advanced on any tap, so misses on the small dots target read as "can't switch pages" (and there was no app-open target on 1-column widgets). Short 1-column widgets keep a slim dots-only bar (no header while it shows: bar + header leaves one squeezed row at ~110dp) with trimmed single-row bodies — name + live status for the class tab, plain then-line for quiet days; tall widgets are unchanged. Tiny strips have no dots bar, so their taps open the app; single-tab shorts skip the empty bar.
- Tall single-tab hub hides the tab bar (chevrons wrapping to the same tab were a no-op wasting ~48dp); short single-tab behavior unchanged.

### Fixed
- Monthly repeats clamp to the last day of the month (Jan 31 → Feb 28/29, not Mar 2/3) in task repeats and Xtra event expansion.
- Week-start prefs clamp to 1..7; all week math shares `weekStartOf` so garbage prefs can't silently shift weeks.
- DST-safe date math: class/task reminder fire times, iCal multi-day durations and UNTIL comparisons use wall-clock calendar arithmetic, not exact `Duration` blocks.
- iCal export stamps `DTSTAMP` with trailing `Z` (UTC); malformed VEVENTs log instead of vanishing silently; `_unescape` scans left-to-right so introduced backslashes aren't re-processed.
- Schedule loading tolerates corrupt rows: `decodeIntList` falls back to `[]`, date parses use `tryParse` instead of throwing the whole calendar.
- Day-rotation slots no longer fire on non-school days (Saturday sharing Friday's index); rotation/cycle indexes memoize per day; `loadEngine` filters slots by `classIds` when present.
- Attachment inserts stamp `uuid`/`updatedAt` at creation (were backfilled only at export); folder import sanitizes peer-supplied filenames so `../../evil` can't escape the scope dir.
- Class/task deletes bump FK-nulled victims (`tasks.classId`, `pomodoro_sessions.taskId`, `tasks.linkedExamId`) so the nulling wins on peers; linked-exam fixup skips no-op writes to stop perpetual export churn.
- Migrations guard `createTable` with existence checks (killed-migration safe); legacy DB rescue logs unreadable files; new v14 migration normalizes en/em-dash rooms (`–`, `—`) to null with `updatedAt` bump.
- Reminders scope to the active year (hidden-year classes no longer schedule); Linux due check batches reminders in one query; `activeYearId()` one-shot read added.
- Calendar `warmCalendarWeek` docstring fixed (post-frame, not pre-`runApp`); `calendarWeekRange` and all week starts share `weekStartOf`; stats window documented as trailing-7-day.
- Settings day-range and grid-markers pickers hold layout with `Visibility(maintainSize)` instead of collapsing to zero height; app shell hoists `MediaQuery` to one read; error route keeps navigation chrome; accent-dot check uses luminance contrast; matrix absence tick uses the class slot time when known.
- Widgets: removed dead `fmtEnds` wire key (never read natively) and dead `MENU_DISH_IDX` / Next-class expand scaffolding; `isoDate` delegates to `isoFromDateTime` (single canonical helper).

## [1.12.1] - 2026-10-20

### Changed
- Code cleanup: removed dead widget code (`SegmentedTabs` + `HubTabSelectCallback`, `DatePillar`, `CountdownHero`, `MetaRow`, hub dead Compact/hairline paths); shared header model for hub tall/short layouts; dropped unused `riverpod_generator`; renamed the 360px probe suite to `narrow_smoke_test`; extracted `_computeGridGeometry`, `_collectIcsEvents`, `_loadValue`, `_dayAt`, `_rowDeleter`, `tombstoneAndDeleteRow`, `deleteAttachmentRow`, `_getBool/_setBool`, `_readDecoded`, partition helpers; DB-side year filters, concurrent merge prefetch, atomic delete-all.

### Fixed
- Data-folder auto-import skips its round while a fresh export lock is present (an exporter is mid-generation, here or mid-upload from a peer); stale locks are ignored and manual imports always proceed. Deleting an academic year now stamps the member classes' year-nulling so sync propagates it even where FK cascades are disabled.
- Small robustness fixes: calendar import reports the actually-imported count; background import failures are logged instead of escaping as unhandled async errors; clearing the data folder has the standard busy guard and error handling; corrupt week-anchor rows fall back instead of throwing on every calendar build; the linked-exam fixup bumps `updatedAt` (sync propagation) and tolerates corrupt ids; manifest/export share one timestamp; the slot editor can't save a sub-15-minute span after snap-to-5, and can't throw on corrupt starts.
- 1-column hub: any tap on the widget body advances to the next tab (was: opening the app except on a tiny dots target); the track keeps the small pill look (the earlier full-width bubble is gone). Tab content fills the card — the hero, the then-card and its location meta all fit without clipping (compact rows: name + "time · room", height-aware row budget).
- Hub paging no longer depends on the matched size slot: tiny strips (which have no dots bar at all — every tap opened the app and the one visible line was a dead end) now switch tabs on tap, and the tab body advances on every size (wide keeps app-open on the header only). A short hub showing a single dish is a one-line strip by physics — resize it taller for the scrollable full dish list.
- Hub menu header icon sits level with every other tab's icon: the 40dp meal steppers stretched the shared centered header to 40dp and floated the 16dp icon ~10dp low (measured 33px), and the icon jumped whenever meal data arrived and the steppers popped in. Menu headers (tall + short) now use a top-pinned row; other widgets keep the shared header untouched.
- Tiny hub lines carry a meta suffix (hero "name · in 7 h", quiet state plus tomorrow's class, tasks "title · date", menu "first dish · +N"): the host can report a far smaller size than it draws (seen: slot 110x40 drawn at ~150x115), leaving one centered line over a void, so the line itself says more. Same single-line height, ellipsis-safe on true strips.
- 1-column hub strips (~110-150dp tall) get a slim layout instead of the stock Compact: header + fitting rows, no dots bar (a stock Compact leaves ~10dp for content at 110dp and squeezes rows to textless slivers — seen-on-device). New 140x110/150x110 slots match real 1-column shorts (previously fell back to Tiny). Hero-short shows name + status/range/room (no teacher line/then-row — neither fits); multi-meal short headers yield the title to the steppers. Taller shorts take one more row via a 135dp gate.
- Room placeholders ("--", "-") are normalized to empty everywhere: the ITU catalog mapping, class editor / quick-edit / slot dialog saves, plus a v13 migration cleaning existing rows (and bumping `updatedAt` so folder sync propagates the cleanup). Widgets and tiles already hide empty rooms.
- Agenda and Due-tasks widgets can shrink to 1 column again (`minResizeWidth/Height` 180x110 → 40dp like the other widgets).
- Next-class detail is always visible instead of hidden behind a tap: the hero shows status · time range · room plus teacher · building, and every row shows its own "time · room" meta. The tap-to-expand machinery is gone (its expansion marker, per-row toggles and grow rule all deleted).

## [1.12.0] - 2026-10-18

### Fixed
- Release builds no longer break every widget tap: R8 strips the Glance `ActionCallback` no-arg constructors it can't see used (debug builds never minify), crashing taps with `NoSuchMethodException` — `proguard-rules.pro` now keeps every `*Callback` in the widget package.
- Hub tab switches are faster: own slim 8-slot set (was 13 — every update composes/translates one view per slot) + per-tab lazy parsing with a raw-string cache (was: all four JSON blobs re-parsed on every slot).
- Standalone menu widget always lists every dish (scrollable): the old Compact branch capped at 2 dishes + "+N more", and hosts can display that small-slot composition inside a much taller widget — orphaning dishes behind a dead indicator with a huge void below.
- Hub menu tab likewise always lists every dish (was a one-line summary with "+N" in Compact); the now-dead dish-rotate tap callback is removed.
- Hub dots no longer flash white/grey on tap: the dots sit on an opaque tonal track and tapping anywhere on it advances to the next tab, as before. Two stacked bugs fed the flash: Glance 1.2.0 `NoRippleOverride` is just int 0, which the translator maps to the DEFAULT ripple (verified from dex), and the first replacement was a `const` — the compile-time R class stubs every id as 0, so it baked in 0 and silently re-enabled the default ripple. `NoPressFeedback` (transparent drawable id via a runtime `val`) is now used on all 9 tap targets.

### Changed
- All widgets default to 2x2 (menu was 2x3, others already 2x2; compact rendering covers it: scrolling full lists, capped rows + indicators).
- Release APKs are split per ABI (~28MB each) instead of one ~80MB universal APK.

## [1.11.0] - 2026-10-13

### Added
- Course code on classes: saved from the class editor (auto-filled by the catalog lookup), synced via folder sync, and shown in the Next-class / hub class-tab timeline ("MAT 103E · Müzik Teorisi I").
- Class hero expands on tap: tapping the class title toggles a teacher detail line (native-owned expand marker per widget, Hub + standalone Next-class; quiet "tomorrow" rows expand too).
- Agenda day rail: weekday label over numeral in every cell, today highlighted accent, 5 cells on wide widgets (3 when narrow).

### Fixed
- Widget pushes no longer stall/ANR the app: dropped the per-push gallery-preview renders (six main-thread Glance compositions on every startup/save left the method channel wedged and broadcasts unsent).
- Next-class / hub class tab no longer render a lone "No classes today" line over a tall blank void: quiet entries now show the pushed Then-line plus lookahead rows.
- Widget empty-state fit: `EmptyState` top spacer 16dp → 8dp for short strips; due-tasks header hides the count pill when the count is 0.
- Updaters no longer open an empty database: pre-v1.10 files lived in the documents directory, now in app-data — startup one-time-copies the legacy file when the new location holds no classes (never overwrites real data, never throws).
- Widget pushes skip identical payloads (fingerprint per widget): re-applying unchanged RemoteViews read as flicker on every app resume; freshness is covered natively plus scheduled ticks. Agenda still refreshes every push (reset-to-today contract).
- Widget pushes are skipped under `flutter_test` (FakeAsync + real async I/O wedged `pumpAndSettle` forever in menu widget tests).
- Hub / Next-class lookahead no longer repeats the next class twice: the Then-line class is filtered out of the lookahead list (was showing e.g. Viyolonsel I at 13:30 two times in a row).
- Widgets can be shrunk again and survive being enlarged: resize floors lowered to 40x40 (1-cell strips, which the Tiny bucket renders as a one-liner) on the four portrait widgets and wide responsive slots (320/470dp) added, so an enlarged widget matches a real slot instead of stretching the nearest portrait one.
- Hub tab arrows use synchronous commits and a composition-tracked bump read, so ‹ › taps switch tabs instead of replaying the previous tab.
- Shrunken tall widgets render the narrow stacked layout instead of squeezed horizontal rows: tall-narrow responsive slots (120x320, 120x450, 260x320) added; hosts apply first-fit, so narrow slots sort first.
- 1-column Hub keeps a usable tab bar: dots-only next-tab target (fixed 72x40dp box — wrap-content clickables never received taps on-device) instead of chevrons that don't fit.
- Hub menu tab renders dishes again: meal steppers moved into the header trailing slot; short buckets show a tappable one-line summary (tap rotates the dish), tall buckets list every dish. Hub dish lists also respect the small-bucket take.
- Menu food rows are bubble-free plain text with bullets (no tonal blocks), everywhere they appear.
- NextClass location: room-less classes no longer show a "--" placeholder (null/blank/"--" rooms render time range only).
- Lookahead time chips are fixed-width so class names start aligned in wide rows.
- Running classes show plain "Currently" (the time range already carries start/end — no repeated end time).

### Changed
- Debug builds install side-by-side with release (`applicationIdSuffix ".debug"`, "Chronicle Dev" label) for on-device widget testing without touching real data.
- Widget pushes use fully-qualified receiver names (bare `androidName` resolves against the applicationId and throws on the `.debug` flavor, failing pushes silently).

## [1.10.0] - 2026-10-11

### Added
- Cafeteria menu widget (meal title + dishes with ‹ › meal stepping) and Weekly classes widget (day-by-day sections), sharing the vertical-flow foundation (24dp outer / 16dp inner radii) with the other widgets.
- Chronicle Hub widget: next class, today's agenda, due tasks and today's dining menu in one card with a bottom ‹ dots › tab bar; configurable at placement (tab picker) and from Settings → Widgets; sealed Loading/Empty/Success/Error states like the other widgets.
- Scrollable widget lists: hub/agenda/tasks menus, agenda rows and class lookahead scroll in tall buckets (weight-bounded `LazyColumn`) instead of capping; short buckets render whole rows only (static take + "+N more"), so a small widget never shows a row that cannot be fully seen.
- Sliding 3-day agenda rail window with big readable numerals (tapping a side cell steps the selection); shortest strips lead with a one-line day summary. New Tiny bucket: 1×1/2×1 strips collapse to a single quiet line instead of clipping.
- Countdown pills ("in N min", "Currently · ends …") computed at render time; cross-day lookahead chips carry weekday hints ("Sat 17:11").
- Android widgets follow Material You (wallpaper + system dark mode) or the app theme via the Settings → Widgets style toggle.

### Fixed
- Widget taps reliable, verified on-device with screenshots: process locks + synchronous commits stop rapid taps collapsing into one; forgiving full-row tap targets stop fall-through app launches; snapshot bump counters stop live-session stale replays (Glance reuses compositions ~45s, so pure prefs reads replayed old tabs).
- Hub class tab and standalone Next-class render one shared component (identical hero, meta, lookahead with gaps); multi-root compositions must live inside a vertical `Column` or siblings paint over each other.
- Layout polish: bottom-pinned tab bar (flush shell slot); 6dp header gap; 12dp content corners; 6dp row gaps and gap above "+N more"; compact meal switcher (12sp title, 40dp arrows); narrow-width graceful degradation (smaller type, short "+N" counts, number rail cells) with wide layouts untouched.
- Resize floors so widgets can't shrink into useless sizes (hub 200×150 … tasks 180×110).
- Menu widgets self-heal an empty cache with a capped provider fetch; widget push also runs after data-folder import (manual + auto).
- Empty states no longer swallow the hub bottom bar (`EmptyState` wraps content height instead of `fillMaxSize`).

### Changed
- Database moves from `~/Documents/chronicle.sqlite` to the app-data dir (`~/.local/share/com.chronicleapp.chronicle/` on Linux, with attachments); no auto-migration, the old file is left alone.

## [1.9.0] - 2026-10-06

### Added
- Selectable agenda days: tapping a day in the Today's-classes week rail
  switches the widget to that day's classes (accent marks the selected
  day); opening the app resets it to today. Next class shows
  "Currently · ends …" while a class is in session.

### Changed
- Widgets resized to fit: Next class defaults to 3×2, Today's classes
  to 2×1 (both still resizable). The agenda rail shows weekday names
  (Mon, Tue…) rolling from today instead of date numbers, with no
  header — the wide card adds the divider and rows.
- Widgets refresh right after a class, task or event is added, edited
  or deleted, not just on app start.
- Task reminders are rescheduled at startup like class reminders, so
  they survive a device reboot.

## [1.8.0] - 2026-10-06

### Added
- Android home-screen widgets (three providers): Next class (2×2, the
  upcoming class with a live countdown and a "Then …" lookahead, swaps
  automatically), Today's agenda (default 2×2, grows to a wide card when
  resized: 7-day rail with circled today, divider, today's rows plus
  dimmed upcoming classes as filler), Due tasks (2×2, top open tasks
  with due dates, overdue first). They refresh when the app starts and
  follow the app theme and accent live (change it in Settings and the
  widgets re-render); the picker shows proper preview cards. Next class
  says "Currently" while a class is running; tapping a day in the
  agenda rail switches the rows to that day. All three share
  one look: small accent header, bold title, gray details.
- Settings sync opt-in (Settings → Data, "Sync settings", default off):
  the data folder gains a settings.json snapshot with the portable
  app settings (appearance, calendar, reminders, menu/catalog source…
  — never device paths, sync markers or toggles), applied on import
  only when the folder copy is newer.
- Events can repeat: the event editor has a Repeats row (daily, weekly
  or monthly) with an optional repeat-until date, so birthdays and
  weekly meetings show up on the calendar without re-creating them.
- Day layout (Settings → Calendar) is a mobile-only option now: desktop
  builds always use the horizontal strip.

### Fixed
- Tapping a home-screen widget no longer lands on a "Page Not Found"
  screen — it opens the app dashboard.
- The Next-class widget looks ahead up to a week when today has no more
  classes left, instead of showing an empty state.
- The widget picker shows a proper preview card for each home-screen
  widget instead of a blank box.
- Event tiles created from the calendar page no longer show a redundant
  calendar icon.
- Course-catalog source setting (Settings → Course catalog, default
  None): the class editor's "Fetch details" button only appears once a
  source is picked, so only ITU students who opt in hit the ITU catalog.
  No source is selected by default; existing users pick ITU once.

## [1.7.0] - 2026-10-05

### Added
- Calendar setting "Start on today" (Settings → Calendar, on by
  default): turn it off to open the week at its first day instead of
  scrolling to today.

### Fixed
- Calendar (phones): the week now actually opens on today. The
  today-jump landed while the week was still hidden and the reveal
  remounted the scrollable, resetting it to the week start — today (and
  its highlight) stayed off screen in both horizontal and vertical
  layouts. The reveal now flips the hidden flag instead of swapping the
  subtree, so the jump offset survives.

## [1.6.0] - 2026-10-03

### Added
- Calendar time grid is a slot grid in fixed-rhythm mode: each lesson is
  one uniform row labeled with its own time range (08:40–09:30), breaks
  take no space, and classes span whole rows — like a school timetable.
  Class blocks are softly rounded with hairline borders and small gaps.
  Off-rhythm classes are absorbed into the rows they touch. Class-times
  mode keeps the exact-time layout.
  Grid times follow the app locale: Turkish shows 08.40, English 08:40.
- Calendar day layout setting (Settings → Day layout): stack the 7 days
  vertically instead of the horizontal strip, in both list and time-grid
  views. The vertical layout scrolls as one column with full-width days.
- Calendar time-grid gutter follows the markers mode (Settings → Markers):
  with class times it labels the week's actual lesson start/end minutes
  (e.g. 08:40, 09:30) instead of whole hours; with a fixed rhythm it
  labels the configured slot boundaries, preferring lesson starts when
  two marks sit too close together (e.g. 08:40 wins over 08:30). Whole
  hours stay the fallback when there is nothing to mark, and close
  labels collapse so they never overlap.
- ITU dining menu: separate vegan menu alongside the standard one, via
  the Genel/Vegan switch on the menu page. Weekend lunch hours are
  12:00 - 14:00 per the official SKS dining-hours table (dinner
  unchanged); stale cached rows with weekday hours refetch.
- Course catalog lookup: enter a course code in the class editor and
  fetch its details. ITU (public OBS data) fills name, instructor,
  room/building and notes (credits, ECTS, language), then lets you pick
  a section to create the weekly slots. Section end times follow ITU's
  display convention (11:29 prints as 11:30), buildings resolve to full
  names, and the picked section appends its method, quota and
  prerequisites to notes. Typing a CRN explains that CRN lookup isn't
  supported instead of reporting "not found".

### Fixed
- Calendar (Android): swipe vertically past the top/bottom edge of the
  week to flip to the previous/next week. The day strip also fills the
  viewport on light weeks so the gesture works over empty areas too.
  The pull is a bit calmer now (160px past the edge instead of 120px),
  and the time-grid hour gutter is narrower (38px). The grid now
  stretches exactly to out-of-range classes instead of adding a
  30-minute padding past a custom day start/end.
- Dining menu reliability (ITU + Hacettepe): unpublished days now show
  "no menu published" instead of a load error; stale-format cache keeps
  showing while the refetch runs; Hacettepe retries transient failures
  and no longer mixes other days' weekly cards into the day; ITU detail
  links resolve against the serving host and fetch with browser headers,
  charset sniffing, tighter timeouts and smaller enrichment batches.
- Dining menu page: removed the extra Today button (it shifted the
  layout); the date button itself jumps back to today. Empty meal tabs
  fall back to the first meal with dishes, and unpublished days are
  never cached so a later publish is picked up.
- Settings: the default-absence-limit and Hacettepe program fields no
  longer visibly fill in after the page opens — the absence limit is
  preloaded before startup so its row renders with the saved value on
  the first frame, and the program row stays hidden until its saved
  values finish loading. No mid-screen label animation or layout shift.

## [1.5.0] - 2026-10-02

### Added
- Dining menu source: ITU (Istanbul Technical University) — single
  "Genel" menu with lunch (11:30 - 14:00) and dinner (17:00 - 19:30),
  per-dish kcal and allergens. Pick it in Settings → Dining menu.
- Class quick-edit: long-press any class tile (calendar list,
  dashboard, classes page) to change its color, room, teacher,
  reminder or notes without opening the full editor. In the
  calendar time-grid, long-press still adjusts times, with a
  Quick edit button into the same sheet.
- Classes accept a generic "Notes" line (class code, section,
  anything) in the full editor and quick-edit; it shows on the
  class cards and in the occurrence details.
- Full-app e2e suite (`test/e2e_*_test.dart`, plain widget tests run in CI
  with the rest of `flutter test`): class surfacing on dashboard/calendar/classes,
  sheet mark-absent flow, absence quota tracking, exam-to-grades
  flow, menu cache fallback, settings and calendar-view restart
  persistence, and folder export/import round-trip.
- Linux releases now ship in three formats from the same bundle: the
  plain tarball, an AppImage, and a Flatpak bundle.
- Schedule slot editor offers customizable start-time preset chips
  (defaults: hourly 08:00-18:00). Edit them in Settings → Schedule →
  Slot start presets; tapping a chip fills the start time (auto-end
  still applies) while the fields stay for any other time.
- README install section carries the official "Get it on Obtainium"
  badge with a one-tap import link for the app.

### Changed
- Snappier data-folder sync: export scans tables and writes files
  concurrently, reuses already-loaded rows for attachments, and skips
  recopying unchanged blobs; conflict backups older than 30 days are
  pruned automatically. ITU menu dish details fetch with bounded
  concurrency instead of 40+ simultaneous connections.

### Fixed
- Calendar time-grid no longer loads classes in visible steps: the
  grid's day-range/marker/fixed-grid settings join the first-run
  gate (and the startup prewarm), so the first paint already uses
  final geometry instead of repositioning every block as each
  setting resolves.
- Focus custom-minutes field is now a chip like the presets: tapping
  it opens a minutes dialog (same 1..max validation, inline errors)
  instead of embedding a mismatched text box in the chip row.
- Xtra event tiles no longer wear an unearned football icon; they
  show a neutral event glyph (Xtra events have no type to depict).
- Grid event-block titles and time chips use regular weight; the
  semibold from the block restyle rendered badly.
- The ITU dining-menu source is named "İtü" under the Turkish locale
  ("Itu" in English).
- Focus timer ring is larger with a thicker stroke and now actually
  fills its box, so the countdown never overlaps it — including at
  200% system font sizes.
- Calendar week strip and absences grid no longer flash the
  week-start before jumping to today: they stay hidden until the
  jump lands, and only jump when today is in the shown week.
- Marked-absent classes no longer squeeze their name into a
  letter-per-line stack on narrow columns: the name stays on one
  line and the Absent marker sits below (list tiles) or leads the
  details line (grid blocks).
- Itu (formerly "ITU") menu dishes are title-cased
  ("Tutmaç Çorbası", not "TUTMAÇ ÇORBASI"), and the pointless
  single-option "Campus: Genel" picker is hidden. Days cached
  before the normalization are detected and refetched instead of
  showing ALL-CAPS until the cache expires.
- Hacettepe lunch and vegan show the real weekend window
  (12:00 - 13:30) on Saturdays and Sundays — the site publishes
  weekday hours there. Also fixed meal tabs shifting onto the
  wrong kinds when a tab is missing from the page.
- Calendar-day math (dashboard tomorrow, notification window,
  calendar export range, iCal recurrence stepping) uses
  wall-clock day shifts, so DST transitions can't skip or
  duplicate a day.
- The calendar no longer flashes a loading spinner on its first
  open after startup: the current week's providers are warmed
  post-frame so the first paint already holds data.
- Slow calendar loads show a shimmer skeleton (real headers plus
  placeholder bars in both list and grid geometry) instead of an
  empty week: content still appears all at once, independent warm
  inputs resolve concurrently to shorten the wait, and startup is
  never blocked waiting for week data.
- Custom school days on an academic year now survive a round-trip:
  saving e.g. weekend-inclusive days no longer resets to Mon–Fri.

### Removed
- Day streak displays on the Focus and Dashboard screens (and the
  now-unused streak helper, its tests and strings). Focus sessions
  are still recorded for the weekly statistics.
- The chronicle.sh launcher wrapper is gone from the Linux tarball;
  run the chronicle binary directly (it finds its bundled libraries
  itself).

## [1.4.0] - 2026-09-25

### Changed
- Absences list view shows only the per-class quota cards; the
  per-record history list (and its "No absences recorded" empty text)
  is gone — use the weeks grid or the class editor to manage records.
- The mark-absence dialog no longer asks for a theory/practical
  session kind; quotas are total-based, so new records default to it.

### Fixed
- Bilsis import no longer drops one of two overlapping classes sharing a
  grid cell: side-by-side lines are matched to their own course code, so
  both courses are imported with their own slots and details.

## [1.3.1] - 2026-09-24

### Fixed
- Absences list view shows the excused-state chips and class picker on
  top again (above the quota cards), matching the weeks-grid view.

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
