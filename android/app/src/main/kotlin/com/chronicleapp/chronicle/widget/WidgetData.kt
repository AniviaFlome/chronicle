// Hand-written widget data layer: prefs keys, JSON shapes, stale gating,
// timeline resolution. NOT generated — edit freely. The wire contract is
// mirrored by lib/services/widget_push.dart; keep both sides in lockstep.
package com.chronicleapp.chronicle.widget

import android.content.SharedPreferences
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

/** Prefs key prefixes — must match widget_push.dart's `WidgetKeys`. */
object Keys {
    const val NEXT_CLASS = "home_widget.NextClass"
    const val TODAY_AGENDA = "home_widget.TodayAgenda"
    const val DUE_TASKS = "home_widget.DueTasksCompact"
    const val HUB = "home_widget.ChronicleHub"
    const val CAFETERIA_MENU = "home_widget.CafeteriaMenu"
    const val WEEKLY_CALENDAR = "home_widget.WeeklyCalendar"

    // Common scalars (all four widgets).
    const val THEME_BG = "themeBg"
    const val USE_YOU = "useYou"
    /** 0 = solid, 1 = translucent, 2 = transparent (see widget_bg helpers). */
    const val OPACITY = "widgetOpacity"
    const val TODAY_ISO = "todayIso"
    const val STALE_NAME = "staleClassName"
    const val EMPTY_TEXT = "emptyText"

    // NextClass.
    const val TIMED_DATA = "timedData"
    // Native-owned hub menu dish cursor (index into the shown meal's
    // dishes, rotated by tapping the summary); never pushed.
    const val MENU_DISH_IDX = "menuDishIdx"

    // TodayAgenda.
    const val SELECTED_DAY = "selectedDay"
    const val WEEK = "week"
    // day0..day6 built as "day$index".

    // DueTasksCompact.
    const val HEADER_TITLE = "headerTitle"
    const val TASKS_COUNT = "tasksCount"
    const val TASKS = "tasks"

    // ChronicleHub.
    const val TAB_CLASS = "tabClass"
    const val TAB_AGENDA = "tabAgenda"
    const val TAB_TASKS = "tabTasks"
    const val TAB_MENU = "tabMenu"
    const val SELECTED_TAB = "selectedTab" // native-owned, never pushed
    const val AGENDA_ROWS = "agendaRows"
    const val TASKS_ROWS = "tasksRows"
    const val TASKS_TITLE = "tasksTitle"
    const val MENU_TITLE = "menuTitle"
    const val MENU_ROWS = "menuRows"
    // All servable meals: [{kind, title, dishes[]}] in day order.
    const val MENU_MEALS = "menuMeals"
    // Pushed default index (menu-page rule: first with dishes).
    const val MENU_MEAL_DEFAULT = "menuMealDefault"
    // Native-owned kind override from the meal arrows; never pushed.
    const val MENU_MEAL_KIND = "menuMealKind"
    const val TITLE_CLASS = "titleClass"
    const val TITLE_AGENDA = "titleAgenda"

    // Hub per-tab empty-state copy (pushed l10n; additive to the original
    // wire contract).
    const val EMPTY_TASKS = "emptyTasks"
    const val EMPTY_MENU = "emptyMenu"

    // Render-time countdown templates (pushed l10n with a "{n}" slot the
    // native side fills in: statusLine goes stale between pushes, but a
    // class start/end instant never does).
    const val FMT_IN_MIN = "fmtInMin"
    const val FMT_IN_HOURS = "fmtInHours"
    const val FMT_CURRENTLY = "fmtCurrently"
}

/** One timeline entry of the Next-class hero (and the hub class tab). */
data class TimedEntry(
    val at: Long,
    val className: String,
    val detailLine: String,
    val statusLine: String,
    val startLabel: String,
    val thenLine: String,
    /** Structured then-parts (plain class name + when); empty on old
     *  pushes, which fall back to parsing [thenLine]. */
    val thenName: String = "",
    val thenWhen: String = "",
    val colorHex: String,
    val thenColorHex: String,
    /** Hub class-tab lookahead rows (the classes after this one), time-sliced
     *  per entry so they stay correct at render time. */
    val looks: List<TimeRow> = emptyList(),
    /** Class start/end instants (epoch ms) for the render-time countdown.
     *  Zero on synthetic entries (no-classes/sentinel), which keep the
     *  pushed statusLine instead. */
    val startMs: Long = 0,
    val endMs: Long = 0,
    /** Teacher name for the expandable hero detail; empty when unset. */
    val teacher: String = "",
    /** Room for the expandable detail ("C-K2-09[102]"); empty when unset. */
    val room: String = "",
    /** Building for the expandable detail ("C Blok"); empty when unset. */
    val building: String = "",
    /** Time range for the expandable detail ("08:40–10:30"); empty on
     *  synthetic entries. */
    val range: String = "",
)


/** Generic time+name row (agenda days, hub agenda/looks). */
data class TimeRow(
    val time: String,
    val name: String,
    val colorHex: String,
    /** Expand key for class rows (negated class start epoch so it can never
     *  collide with a timeline entry key); 0 = not expandable (agenda rows,
     *  old pushes). */
    val at: Long = 0,
    val teacher: String = "",
    val room: String = "",
    val building: String = "",
    val range: String = "",
)

/** Task row (due-tasks widget, hub tasks tab). */
data class TaskRow(
    val title: String,
    val date: String,
    val urgent: Boolean,
)

/** Week-rail cell (agenda widget). */
data class WeekCell(
    val label: String,
    val num: String,
    val isToday: Boolean,
)

/** Fully resolved widget state — one snapshot per render. */
data class WidgetSnapshot(
    val useYou: Boolean,
    val themeCode: Int,
    /** 0 = solid, 1 = translucent, 2 = transparent background. */
    val opacity: Int,
    val stale: Boolean,
    val staleName: String,
    val emptyText: String,
    /** Countdown templates (see Keys.FMT_*): pushed l10n with "{n}" slots. */
    val fmtInMin: String,
    val fmtInHours: String,
    val fmtCurrently: String,
)

// ---------------------------------------------------------------------------
// Prefs accessors (ClassCastException-safe: the push side may write ints as
// Long through the plugin's generic channel).
// ---------------------------------------------------------------------------

fun SharedPreferences.str(key: String, def: String = ""): String =
    try {
        getString(key, def) ?: def
    } catch (_: ClassCastException) {
        def
    }

fun SharedPreferences.int(key: String, def: Int = 0): Int =
    try {
        getInt(key, def)
    } catch (_: ClassCastException) {
        try {
            getLong(key, def.toLong()).toInt()
        } catch (_: ClassCastException) {
            def
        }
    }

fun SharedPreferences.bool(key: String, def: Boolean = false): Boolean =
    try {
        getBoolean(key, def)
    } catch (_: ClassCastException) {
        def
    }

fun SharedPreferences.long(key: String, def: Long = -1L): Long =
    try {
        getLong(key, def)
    } catch (_: ClassCastException) {
        try {
            getInt(key, def.toInt()).toLong()
        } catch (_: ClassCastException) {
            def
        }
    }

fun SharedPreferences.snapshot(prefix: String): WidgetSnapshot {
    val todayIso = str("$prefix.${Keys.TODAY_ISO}")
    val deviceToday = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    return WidgetSnapshot(
        useYou = bool("$prefix.${Keys.USE_YOU}"),
        themeCode = int("$prefix.${Keys.THEME_BG}"),
        opacity = int("$prefix.${Keys.OPACITY}").coerceIn(0, 2),
        stale = todayIso.isNotEmpty() && todayIso != deviceToday,
        staleName = str("$prefix.${Keys.STALE_NAME}"),
        emptyText = str("$prefix.${Keys.EMPTY_TEXT}"),
        fmtInMin = str("$prefix.${Keys.FMT_IN_MIN}"),
        fmtInHours = str("$prefix.${Keys.FMT_IN_HOURS}"),
        fmtCurrently = str("$prefix.${Keys.FMT_CURRENTLY}"),
    )
}

// ---------------------------------------------------------------------------
// JSON parsing. Lists are JSON arrays of objects; the timeline is a JSON
// object keyed by epoch-millis strings. Both are pushed as plain strings.
// ---------------------------------------------------------------------------

private fun JSONObject.s(key: String): String =
    try {
        optString(key, "")
    } catch (_: Exception) {
        ""
    }

fun parseTimeRows(json: String): List<TimeRow> {
    if (json.isBlank()) return emptyList()
    return try {
        val arr = JSONArray(json)
        buildList {
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                add(TimeRow(o.s("time"), o.s("name"), o.s("colorHex")))
            }
        }
    } catch (_: Exception) {
        emptyList()
    }
}

fun parseTaskRows(json: String): List<TaskRow> {
    if (json.isBlank()) return emptyList()
    return try {
        val arr = JSONArray(json)
        buildList {
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                add(
                    TaskRow(
                        title = o.s("title"),
                        date = o.s("date"),
                        urgent = o.optBoolean("urgent", false) || o.s("urgent") == "1",
                    ),
                )
            }
        }
    } catch (_: Exception) {
        emptyList()
    }
}

fun parseWeek(json: String): List<WeekCell> {
    if (json.isBlank()) return emptyList()
    return try {
        val arr = JSONArray(json)
        buildList {
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                add(
                    WeekCell(
                        label = o.s("label"),
                        num = o.s("num"),
                        isToday = o.optBoolean("isToday", false),
                    ),
                )
            }
        }
    } catch (_: Exception) {
        emptyList()
    }
}

fun parseStrings(json: String): List<String> {
    if (json.isBlank()) return emptyList()
    return try {
        val arr = JSONArray(json)
        buildList {
            for (i in 0 until arr.length()) {
                add(arr.optString(i, ""))
            }
        }
    } catch (_: Exception) {
        emptyList()
    }
}

/** One servable meal: kind id (sabah/ogle/...), localized title, dishes. */
data class MenuMeal(
    val kind: String,
    val title: String,
    val dishes: List<String>,
)

/**
 * Parses `menuMeals` (`[{kind, title, dishes[]}]`). Entries with blank
 * kinds or no dishes are skipped — mirrors the menu page, which only
 * ever points at a meal that has dishes.
 */
fun parseMenuMeals(json: String): List<MenuMeal> {
    if (json.isBlank()) return emptyList()
    return try {
        val arr = JSONArray(json)
        buildList {
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val kind = o.s("kind")
                val dishes = parseStrings(
                    o.optJSONArray("dishes")?.toString().orEmpty(),
                ).map { it.trim() }.filter { it.isNotEmpty() }
                if (kind.isEmpty() || dishes.isEmpty()) continue
                add(MenuMeal(kind, o.s("title"), dishes))
            }
        }
    } catch (_: Exception) {
        emptyList()
    }
}

/**
 * Picks the meal to show: the native-owned kind override wins when it is
 * still servable, otherwise the pushed default (clamped). Mirrors the
 * menu page's `_syncMealToDay`.
 */
fun resolveMenuMeal(
    meals: List<MenuMeal>,
    defaultIdx: Int,
    overrideKind: String,
): MenuMeal? {
    if (meals.isEmpty()) return null
    if (overrideKind.isNotEmpty()) {
        meals.firstOrNull { it.kind == overrideKind }?.let { return it }
    }
    return meals[defaultIdx.coerceIn(meals.indices)]
}

/** Per-entry "looks" lookahead rows (nested inside a timeline entry). */
private fun parseLooksArr(arr: JSONArray?): List<TimeRow> {
    if (arr == null) return emptyList()
    return buildList {
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            add(
                TimeRow(
                    o.s("time"),
                    o.s("name"),
                    o.s("colorHex"),
                    at = o.optLong("at", 0),
                    teacher = o.s("teacher"),
                    room = o.s("room"),
                    building = o.s("building"),
                    range = o.s("range"),
                ),
            )
        }
    }
}

/**
 * Parses the timeline object `{"<epochMs>": {...}}` into a list sorted by
 * key time. Malformed entries are skipped, never crash the render.
 */
fun parseTimed(json: String, withThen: Boolean): List<TimedEntry> {
    if (json.isBlank()) return emptyList()
    return try {
        val obj = JSONObject(json)
        buildList {
            for (key in obj.keys()) {
                val at = key.toLongOrNull() ?: continue
                val o = obj.optJSONObject(key) ?: continue
                add(
                    TimedEntry(
                        at = at,
                        className = o.s("className"),
                        detailLine = o.s("detailLine"),
                        statusLine = o.s("statusLine"),
                        startLabel = o.s("startLabel"),
                        thenLine = if (withThen) o.s("thenLine") else "",
                        thenName = if (withThen) o.s("thenName") else "",
                        thenWhen = if (withThen) o.s("thenWhen") else "",
                        colorHex = o.s("colorHex"),
                        thenColorHex = if (withThen) o.s("thenColorHex") else "",
                        looks = parseLooksArr(o.optJSONArray("looks")),
                        startMs = o.optLong("startMs", 0),
                        endMs = o.optLong("endMs", 0),
                        teacher = o.s("teacher"),
                        room = o.s("room"),
                        building = o.s("building"),
                        range = o.s("range"),
                    ),
                )
            }
        }.sortedBy { it.at }
    } catch (_: Exception) {
        emptyList()
    }
}

/**
 * Greatest key at or before [nowMs] — the contract the Dart push keys the
 * timeline by display-from times (start-of-today / previous class end) plus
 * a closing sentinel keyed at the last class end. A sentinel className of
 * "—" (or empty) means "done for now": callers show the stale copy.
 */
fun resolveTimed(entries: List<TimedEntry>, nowMs: Long): TimedEntry? =
    entries.lastOrNull { it.at <= nowMs }

// ---------------------------------------------------------------------------
// Parse cache: hub resolveState runs once per size slot (10x per update)
// with identical raw strings — cache hits skip re-parsing. All parse
// functions are pure; synchronized on a private lock. Raw strings are the
// cache keys: a push writes new strings, which naturally miss and re-parse.
// Single-entry per shape: entries hold one widget's strings at a time,
// which is exactly the within-update sharing pattern (10 slot
// compositions, one parse); cross-widget updates re-parse once each,
// never more than uncached code would.
// ---------------------------------------------------------------------------

private val hubParseLock = Any()
private var cachedTimedRaw: String? = null
private var cachedTimedThen: Boolean = true
private var cachedTimedRows: List<TimedEntry> = emptyList()
private var cachedTimeRowsRaw: String? = null
private var cachedTimeRows: List<TimeRow> = emptyList()
private var cachedTaskRowsRaw: String? = null
private var cachedTaskRows: List<TaskRow> = emptyList()
private var cachedMenuMealsRaw: String? = null
private var cachedMenuMeals: List<MenuMeal> = emptyList()
private var cachedStringsRaw: String? = null
private var cachedStrings: List<String> = emptyList()

fun cachedParseTimed(json: String, withThen: Boolean): List<TimedEntry> =
    synchronized(hubParseLock) {
        if (json == cachedTimedRaw && withThen == cachedTimedThen) return cachedTimedRows
        val parsed = parseTimed(json, withThen)
        cachedTimedRaw = json
        cachedTimedThen = withThen
        cachedTimedRows = parsed
        parsed
    }

fun cachedParseTimeRows(json: String): List<TimeRow> =
    synchronized(hubParseLock) {
        if (json == cachedTimeRowsRaw) return cachedTimeRows
        val parsed = parseTimeRows(json)
        cachedTimeRowsRaw = json
        cachedTimeRows = parsed
        parsed
    }

fun cachedParseTaskRows(json: String): List<TaskRow> =
    synchronized(hubParseLock) {
        if (json == cachedTaskRowsRaw) return cachedTaskRows
        val parsed = parseTaskRows(json)
        cachedTaskRowsRaw = json
        cachedTaskRows = parsed
        parsed
    }

fun cachedParseMenuMeals(json: String): List<MenuMeal> =
    synchronized(hubParseLock) {
        if (json == cachedMenuMealsRaw) return cachedMenuMeals
        val parsed = parseMenuMeals(json)
        cachedMenuMealsRaw = json
        cachedMenuMeals = parsed
        parsed
    }

fun cachedParseStrings(json: String): List<String> =
    synchronized(hubParseLock) {
        if (json == cachedStringsRaw) return cachedStrings
        val parsed = parseStrings(json)
        cachedStringsRaw = json
        cachedStrings = parsed
        parsed
    }

/** The sentinel marks the end of the listed classes. */
val TimedEntry.isSentinel: Boolean
    get() = className == "—" || className.isEmpty()

/**
 * Hero name after contract resolution: sentinel/stale both fall back to
 * the pushed stale copy ("No classes today"), per the stale contract.
 */
fun TimedEntry.heroName(snap: WidgetSnapshot): String =
    if (isSentinel || snap.stale) snap.staleName.ifEmpty { snap.emptyText } else className

/**
 * Render-time countdown for the status pill. The pushed statusLine is baked
 * at push time ("in 17 h" at 01:09 is still "in 17 h" at noon); the class
 * start/end instants never go stale, so recompute here on every compose.
 * Today-only (like the push-side statusFor): future-day entries keep the
 * pushed statusLine. Falls back to statusLine when instants are missing
 * (synthetic entries) or the templates were never pushed.
 */
/**
 * Hero numeral parts (prefix, number, unit suffix) parsed off the pushed
 * countdown templates by splitting on "{n}" — fully localized with zero new
 * wire keys. Null when the entry isn't countdown-able (running, sentinel,
 * synthetic, or future-day): callers show the [liveStatus] pill instead.
 * Mirrors [liveStatus]'s thresholds exactly (today-only, <120 min rule).
 */
fun countdownParts(
    e: TimedEntry,
    snap: WidgetSnapshot,
    nowMs: Long,
): Triple<String, String, String>? {
    if (e.startMs <= 0L || snap.stale || e.isSentinel) return null
    val dayFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    if (dayFmt.format(Date(e.startMs)) != dayFmt.format(Date(nowMs))) return null
    val minsToStart = ((e.startMs - nowMs) / 60000).toInt()
    if (minsToStart <= 0) return null
    fun split(t: String): Pair<String, String> {
        val i = t.indexOf("{n}")
        return if (i < 0) Pair(t, "") else Pair(t.substring(0, i), t.substring(i + 3))
    }
    return if (minsToStart < 120) {
        if (snap.fmtInMin.isEmpty()) return null
        val (pre, suf) = split(snap.fmtInMin)
        Triple(pre, "$minsToStart", suf)
    } else {
        if (snap.fmtInHours.isEmpty()) return null
        val (pre, suf) = split(snap.fmtInHours)
        Triple(pre, "${minsToStart / 60}", suf)
    }
}

fun liveStatus(e: TimedEntry, snap: WidgetSnapshot, nowMs: Long): String {
    if (e.startMs > 0 && e.endMs > 0) {
        val dayFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val today = dayFmt.format(Date(nowMs))
        if (dayFmt.format(Date(e.startMs)) == today) {
            val minsToStart = ((e.startMs - nowMs) / 60000).toInt()
            if (minsToStart > 0) {
                if (snap.fmtInMin.isNotEmpty() && snap.fmtInHours.isNotEmpty()) {
                    return if (minsToStart < 120) {
                        snap.fmtInMin.replace("{n}", "$minsToStart")
                    } else {
                        snap.fmtInHours.replace("{n}", "${minsToStart / 60}")
                    }
                }
            } else if (nowMs < e.endMs && snap.fmtCurrently.isNotEmpty()) {
                // Running: plain "Currently" — the detail line already
                // carries the time range, so no end-time suffix.
                return snap.fmtCurrently
            }
        }
    }
    return e.statusLine
}

// ---------------------------------------------------------------------------
// Preview sample data (WD-1: previews carry believable content). Rendered by
// providePreview via explicit samples, never from whatever is in prefs.
// ---------------------------------------------------------------------------

object Samples {
    private fun entry(
        at: Long,
        className: String,
        detail: String,
        status: String,
        start: String,
        then: String,
        color: String,
        thenColor: String,
    ) = TimedEntry(
        at = at,
        className = className,
        detailLine = detail,
        statusLine = status,
        startLabel = start,
        thenLine = then,
        colorHex = color,
        thenColorHex = thenColor,
    )

    val nextClass = entry(
        at = 0L,
        className = "Mathematics",
        detail = "08:40–09:30 · Room B4",
        status = "in 12 min",
        start = "08:40",
        then = "Then Physics · 10:20",
        color = "FF4F6BED",
        thenColor = "FF30A46C",
    ).copy(thenName = "Physics", thenWhen = "10:20")

    /** Extra lookahead rows shown by the tall hero (dot + "Class · 13:00"),
     *  i.e. the classes after the one already shown by [nextClass]'s thenLine. */
    val later = listOf(
        TimeRow("13:00", "Chemistry lab", "FFE5484D"),
        TimeRow("15:40", "History", "FFF76B15"),
    )

    val week = listOf(
        WeekCell("Mon", "8", isToday = true),
        WeekCell("Tue", "9", false),
        WeekCell("Wed", "10", false),
        WeekCell("Thu", "11", false),
        WeekCell("Fri", "12", false),
        WeekCell("Sat", "13", false),
        WeekCell("Sun", "14", false),
    )

    val agenda = listOf(
        TimeRow("08:40", "Mathematics", "FF4F6BED"),
        TimeRow("10:20", "Physics", "FF30A46C"),
        TimeRow("13:00", "Chemistry lab", "FFE5484D"),
        TimeRow("15:40", "History", "FFF76B15"),
    )

    val tasks = listOf(
        TaskRow("Submit lab report", "tomorrow", urgent = false),
        TaskRow("Read chapter 4", "Fri", urgent = false),
        TaskRow("Problem set 5", "yesterday", urgent = true),
    )

    /** "Looks" rows for the hub class tab: chip time + "Then/Later <name>". */
    val looks = listOf(
        TimeRow("10:20", "Physics", "FF30A46C"),
        TimeRow("13:00", "Chemistry lab", "FFE5484D"),
    )

    val menu = listOf("Lentil soup", "Grilled chicken", "Rice pilaf", "Ayran")

    const val headerTitle = "Due tasks"
    const val tasksCount = "3"
    const val tasksTitle = "Due tasks · 3"
    const val menuTitle = "Lunch · ITU"
    const val titleClass = "Next class"
    const val titleAgenda = "Today"
    const val emptyText = "No classes today"
    const val staleName = "No classes today"
}
