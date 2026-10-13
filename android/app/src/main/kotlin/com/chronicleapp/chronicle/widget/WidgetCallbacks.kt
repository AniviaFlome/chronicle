// Hand-written widget interactivity. NOT generated — edit freely.
//
// The home_widget DSL has no per-element tap support; these ActionCallbacks
// are the only interactive elements in the widgets (agenda week rail, hub
// tab arrows). Semantics preserved from the previous build:
//  - Agenda: tapping a rail cell writes selectedDay; the next Dart push
//    resets it to 0 (today) — selection is intentionally per-render.
//  - Hub: selectedTab is native-owned (never pushed), stores the position
//    within the *enabled* tab list, wraps around, and every widget update
//    recomputes the enabled list from the pushed tab flags.
//
// Glance 1.2 import split (a build-breaker if mixed up): ActionCallback and
// actionRunCallback live in androidx.glance.appwidget.action, while
// ActionParameters/actionParametersOf stay in androidx.glance.action.
package com.chronicleapp.chronicle.widget

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.mutableIntStateOf
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import com.chronicleapp.chronicle.CafeteriaMenuHomeWidget
import com.chronicleapp.chronicle.ChronicleHubHomeWidget
import com.chronicleapp.chronicle.NextClassHomeWidget
import com.chronicleapp.chronicle.TodayAgendaHomeWidget

/** Hub navigation bump counter.
 *
 * Glance reuses a live composition session for ~45s: taps inside that
 * window do NOT restart `provideGlance`, they only flag the running
 * session to recompose (`updateGlance`). Pure `SharedPreferences` reads
 * are invisible to the Compose runtime, so such a recompose can replay
 * the previously resolved state and the tap looks dead. Every native hub
 * write bumps this snapshot counter, and the hub's `provideContent`
 * lambda reads it (see `resolveState` call site) — the read tracks the
 * recomposition to the bump, forcing a fresh prefs read after each tap.
 * This is the mechanism the Glance docs prescribe ("observe your sources
 * of data within the composition"). State library only — no compose.ui
 * layout imports, per repo discipline. */
val hubNavBump = mutableIntStateOf(0)

/** Same live-session staleness contract as [hubNavBump], for the agenda
 * day rail: [AgendaDaySelectCallback] bumps after each write, and the
 * agenda's `provideContent` lambda reads before resolving. */
val agendaNavBump = mutableIntStateOf(0)

/** Same live-session staleness contract as [hubNavBump], for the
 * standalone menu widget: [StandaloneMenuMealCallback] bumps after each
 * meal step, and the menu's `provideContent` lambda reads before
 * resolving. */
val menuNavBump = mutableIntStateOf(0)

/** Same contract for the standalone next-class widget, which gains its
 * first tap target with hero expand/collapse ([NextClassExpandCallback]).
 * Previously bump-free (nothing was tappable); the hub reuses its
 * existing [hubNavBump]. */
val nextClassNavBump = mutableIntStateOf(0)

/** Week-rail tap: select one of the 7 upcoming days. */
class AgendaDaySelectCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val day = parameters[AgendaDayKey] ?: return
        widgetPrefs(context).edit()
            .putInt("${Keys.TODAY_AGENDA}.${Keys.SELECTED_DAY}", day)
            .apply()
        agendaNavBump.intValue++
        TodayAgendaHomeWidget().update(context, glanceId)
    }
}

/** Hub tab arrow: move to the previous/next enabled tab, wrapping around.
 * The read-modify-write + update runs under a process-wide lock: rapid
 * taps execute on parallel Worker threads, and without the lock they all
 * read the same position and collapse into a single step. */
class HubTabCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val direction = parameters[HubDirectionKey] ?: return
        synchronized(hubTabLock) {
            val prefs = widgetPrefs(context)
            val enabled = buildList {
                if (prefs.bool("${Keys.HUB}.${Keys.TAB_CLASS}", true)) add(0)
                if (prefs.bool("${Keys.HUB}.${Keys.TAB_AGENDA}", true)) add(1)
                if (prefs.bool("${Keys.HUB}.${Keys.TAB_TASKS}", true)) add(2)
                if (prefs.bool("${Keys.HUB}.${Keys.TAB_MENU}", true)) add(3)
            }.ifEmpty { listOf(0) }
            val stored = prefs.int("${Keys.HUB}.${Keys.SELECTED_TAB}", 0)
            val current = ((stored % enabled.size) + enabled.size) % enabled.size
            val next = ((current + direction) % enabled.size + enabled.size) % enabled.size
            prefs.edit().putInt("${Keys.HUB}.${Keys.SELECTED_TAB}", next).commit()
            hubNavBump.intValue++
        }
        ChronicleHubHomeWidget().update(context, glanceId)
    }

    companion object {
        /** Process-wide lock for hub tab read-modify-write cycles. */
        private val hubTabLock = Any()
    }
}

/** Hub segmented tab: jump directly to the tapped enabled tab. */
class HubTabSelectCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val idx = parameters[HubTabKey] ?: return
        val prefs = widgetPrefs(context)
        val enabled = buildList {
            if (prefs.bool("${Keys.HUB}.${Keys.TAB_CLASS}", true)) add(0)
            if (prefs.bool("${Keys.HUB}.${Keys.TAB_AGENDA}", true)) add(1)
            if (prefs.bool("${Keys.HUB}.${Keys.TAB_TASKS}", true)) add(2)
            if (prefs.bool("${Keys.HUB}.${Keys.TAB_MENU}", true)) add(3)
        }.ifEmpty { listOf(0) }
        if (idx !in enabled.indices) return
        prefs.edit().putInt("${Keys.HUB}.${Keys.SELECTED_TAB}", idx).commit()
        hubNavBump.intValue++
        ChronicleHubHomeWidget().update(context, glanceId)
    }
}

/** SharedPreferences shared with the home_widget plugin's storage. */
internal fun widgetPrefs(context: Context) =
    es.antonborri.home_widget.HomeWidgetPlugin.getData(context)

/**
 * Meal arrow step shared by the hub menu tab and the standalone menu
 * widget: moves the native-owned meal-kind override to the previous/next
 * servable meal, wrapping around. The override persists across pushes;
 * renders fall back to the pushed default when it is unset or stale.
 */
private fun stepMenuMeal(prefs: SharedPreferences, prefix: String, direction: Int) {
    // Same read-modify-write race as hub tabs (see hubTabLock): serialize
    // concurrent steps and commit synchronously.
    synchronized(menuMealLock) {
        val meals = parseMenuMeals(prefs.str("$prefix.${Keys.MENU_MEALS}"))
        if (meals.size <= 1) return
        val stored = prefs.str("$prefix.${Keys.MENU_MEAL_KIND}")
        val current = meals.indexOfFirst { it.kind == stored }.takeIf { it >= 0 }
            ?: prefs.int("$prefix.${Keys.MENU_MEAL_DEFAULT}", 0).coerceIn(meals.indices)
        val next = ((current + direction) % meals.size + meals.size) % meals.size
        prefs.edit().putString("$prefix.${Keys.MENU_MEAL_KIND}", meals[next].kind).commit()
    }
}

/** Process-wide lock for meal-kind read-modify-write cycles. */
private val menuMealLock = Any()

/** Hub menu-tab meal arrow: step the shared meal override, refresh hub. */
class HubMenuMealCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val direction = parameters[MenuMealDirectionKey] ?: return
        stepMenuMeal(widgetPrefs(context), Keys.HUB, direction)
        hubNavBump.intValue++
        ChronicleHubHomeWidget().update(context, glanceId)
    }
}

/** Standalone menu meal arrow: step the shared meal override, refresh. */
class StandaloneMenuMealCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val direction = parameters[MenuMealDirectionKey] ?: return
        stepMenuMeal(widgetPrefs(context), Keys.CAFETERIA_MENU, direction)
        menuNavBump.intValue++
        CafeteriaMenuHomeWidget().update(context, glanceId)
    }
}

/**
 * Hub menu summary tap: rotate which dish the one-line summary shows.
 * The summary is a single Text node (repeated rows and explicit
 * newlines both mismeasure on-device), so paging is done by swapping
 * its string: first tap keeps dish 0 with a "+N" tail, further taps
 * walk dish 1..N with a "k/N" position tail, then wrap around.
 */
class HubMenuDishCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val prefs = widgetPrefs(context)
        val prefix = Keys.HUB
        val meals = parseMenuMeals(prefs.str("$prefix.${Keys.MENU_MEALS}"))
        val defaultIdx = prefs.int("$prefix.${Keys.MENU_MEAL_DEFAULT}", 0)
        val kind = prefs.str("$prefix.${Keys.MENU_MEAL_KIND}")
        val meal = resolveMenuMeal(meals, defaultIdx, kind)
        val count = (meal?.dishes ?: parseStrings(prefs.str("$prefix.${Keys.MENU_ROWS}"))).size
        if (count <= 1) return
        val key = "$prefix.${Keys.MENU_DISH_IDX}"
        val next = (prefs.int(key, 0) + 1) % count
        prefs.edit().putInt(key, next).commit()
        hubNavBump.intValue++
        ChronicleHubHomeWidget().update(context, glanceId)
    }
}

/** ActionParameters key for the expanded timeline entry (epoch-ms key). */
val ExpandAtKey = ActionParameters.Key<Long>("expandAt")
/**
 * Toggles the hero detail for one timeline entry: tapping the expanded
 * hero collapses it, tapping another expands that one instead. The marker
 * is native-owned per widget prefix (never pushed); every write bumps the
 * matching snapshot counter so the live session re-reads prefs.
 */
private fun toggleExpanded(context: Context, prefix: String, at: Long) {
    widgetPrefs(context).edit()
        .putLong("$prefix.${Keys.EXPANDED_AT}", at)
        .commit()
}

private fun readExpanded(context: Context, prefix: String): Long =
    widgetPrefs(context).long("$prefix.${Keys.EXPANDED_AT}", -1L)

/** Hub hero expand: flip the marker, refresh hub. */
class HubClassExpandCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val at = parameters[ExpandAtKey] ?: return
        val current = readExpanded(context, Keys.HUB)
        toggleExpanded(context, Keys.HUB, if (current == at) -1L else at)
        hubNavBump.intValue++
        ChronicleHubHomeWidget().update(context, glanceId)
    }
}

/** Standalone next-class hero expand: flip the marker, refresh. */
class NextClassExpandCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val at = parameters[ExpandAtKey] ?: return
        val current = readExpanded(context, Keys.NEXT_CLASS)
        toggleExpanded(context, Keys.NEXT_CLASS, if (current == at) -1L else at)
        nextClassNavBump.intValue++
        NextClassHomeWidget().update(context, glanceId)
    }
}
