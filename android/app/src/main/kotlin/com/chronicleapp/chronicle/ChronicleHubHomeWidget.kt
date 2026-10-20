// Hand-written Glance widget (Chronicle M3 Expressive redesign). NOT
// generated — edit freely. Wire contract lives in
// com.chronicleapp.chronicle.widget.WidgetData and is mirrored by
// lib/services/widget_push.dart; keep both sides in lockstep.
//
// ChronicleHub: dashboard switcher. Two 48dp tab arrows cycle the enabled
// tabs (selection is native-owned in prefs, position-in-enabled with
// wrap-around — see HubTabCallback); the header follows the active tab and
// a page-dot row mirrors position. Tab bodies reuse the shared components
// so the hub stays visually identical to the standalone widgets.
package com.chronicleapp.chronicle

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.ConfigurationCompat
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import com.chronicleapp.chronicle.widget.ChroniclePalette
import com.chronicleapp.chronicle.widget.ClassRow
import com.chronicleapp.chronicle.widget.DishRow
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.FilledLookaheadRow
import com.chronicleapp.chronicle.widget.Hairline
import com.chronicleapp.chronicle.widget.HubDirectionKey
import com.chronicleapp.chronicle.widget.HubTabCallback
import com.chronicleapp.chronicle.widget.MenuMeal
import com.chronicleapp.chronicle.widget.MenuStepArrow
import com.chronicleapp.chronicle.widget.MoreIndicator
import com.chronicleapp.chronicle.widget.NoPressFeedback
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.Samples
import com.chronicleapp.chronicle.widget.SharedClassTab
import com.chronicleapp.chronicle.widget.TabArrow
import com.chronicleapp.chronicle.widget.TaskRow
import com.chronicleapp.chronicle.widget.ThenLine
import com.chronicleapp.chronicle.widget.WidgetHeader
import com.chronicleapp.chronicle.widget.liveStatus
import com.chronicleapp.chronicle.widget.lookaheadChipWidth
import com.chronicleapp.chronicle.widget.VerticalBucket
import com.chronicleapp.chronicle.widget.VerticalShell
import com.chronicleapp.chronicle.widget.WidgetSnapshot
import com.chronicleapp.chronicle.widget.bool
import com.chronicleapp.chronicle.widget.cachedParseMenuMeals
import com.chronicleapp.chronicle.widget.cachedParseStrings
import com.chronicleapp.chronicle.widget.cachedParseTaskRows
import com.chronicleapp.chronicle.widget.cachedParseTimeRows
import com.chronicleapp.chronicle.widget.cachedParseTimed
import com.chronicleapp.chronicle.widget.currentVerticalBucket
import com.chronicleapp.chronicle.widget.hubNavBump
import com.chronicleapp.chronicle.widget.hubSizeSlots
import com.chronicleapp.chronicle.widget.isNarrowSlot
import com.chronicleapp.chronicle.widget.long
import com.chronicleapp.chronicle.widget.int
import com.chronicleapp.chronicle.widget.isSentinel
import com.chronicleapp.chronicle.widget.resolveMenuMeal
import com.chronicleapp.chronicle.widget.resolvePalette
import com.chronicleapp.chronicle.widget.resolveTimed
import com.chronicleapp.chronicle.widget.snapshot
import com.chronicleapp.chronicle.widget.str
import com.chronicleapp.chronicle.widget.TinyRow
import com.chronicleapp.chronicle.widget.widgetBg

import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin

class ChronicleHubHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    // Portrait-first buckets: Compact / TallColumn / FullPortrait.
    override val sizeMode = hubSizeSlots

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            // Snapshot-tracked read (see hubNavBump): pins this composition
            // to the bump so live-session recomposes re-read prefs instead
            // of replaying the previously resolved state.
            HubContent(context, resolveState(context, hubNavBump.intValue))
        }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.HUB)
        val state = HubWidgetUiState.Success(
            content = HubContentData(
                snap = snap,
                enabled = listOf(TAB_CLASS, TAB_AGENDA, TAB_TASKS, TAB_MENU),
                pos = 0,
                sel = TAB_CLASS,
                entry = Samples.nextClass,
                looks = Samples.looks,
                agendaRows = Samples.agenda,
                tasksRows = Samples.tasks,
                menuRows = Samples.menu,
                menuMeals = listOf(
                    MenuMeal(
                        kind = "ogle",
                        title = Samples.menuTitle,
                        dishes = Samples.menu,
                    ),
                ),
                menuMealIdx = 0,
                titleClass = Samples.titleClass,
                titleAgenda = Samples.titleAgenda,
                tasksTitle = Samples.tasksTitle,
                menuTitle = Samples.menuTitle,
                emptyTasks = Samples.emptyText,
                emptyMenu = Samples.emptyText,
            ),
            nowMs = System.currentTimeMillis(),
        )
        provideContent { HubContent(context, state) }
    }

    fun previewFingerprint(context: Context): String {
        val locales = ConfigurationCompat.getLocales(context.resources.configuration)
        val loc = (0 until locales.size()).mapNotNull { locales[it] }.joinToString(",")
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.HUB)
        return "v2|hub|$loc|${snap.useYou}|${snap.themeCode}"
    }

    companion object {
        const val TAB_CLASS = 0
        const val TAB_AGENDA = 1
        const val TAB_TASKS = 2
        const val TAB_MENU = 3

        /** Position-in-enabled wrap, mirrored from HubTabCallback. */
        fun wrap(pos: Int, size: Int): Int =
            if (size <= 0) 0 else ((pos % size) + size) % size
    }

    private fun resolveState(context: Context, @Suppress("UNUSED_PARAMETER") navBump: Int): HubWidgetUiState {
        return try {
            val prefs = HomeWidgetPlugin.getData(context)
            val prefix = Keys.HUB
            val snap = prefs.snapshot(prefix)
            val enabled = buildList {
                if (prefs.bool("$prefix.${Keys.TAB_CLASS}", true)) add(TAB_CLASS)
                if (prefs.bool("$prefix.${Keys.TAB_AGENDA}", true)) add(TAB_AGENDA)
                if (prefs.bool("$prefix.${Keys.TAB_TASKS}", true)) add(TAB_TASKS)
                if (prefs.bool("$prefix.${Keys.TAB_MENU}", true)) add(TAB_MENU)
            }.ifEmpty { listOf(TAB_CLASS) }
            val pos = wrap(prefs.int("$prefix.${Keys.SELECTED_TAB}", 0), enabled.size)
            val sel = enabled[pos]

            val now = System.currentTimeMillis()
            // Lazy per-tab parsing: a tap only shows one tab, so only that
            // tab's JSON is parsed — and through the cache, so the 8 slot
            // compositions per update parse once and hit 7 times. The old
            // code parsed all four blobs on every slot (32 parses per tap).
            val entry = if (sel == TAB_CLASS) {
                resolveTimed(
                    cachedParseTimed(prefs.str("$prefix.${Keys.TIMED_DATA}"), withThen = true),
                    now,
                )
            } else {
                null
            }
            val menuMeals = if (sel == TAB_MENU) {
                cachedParseMenuMeals(prefs.str("$prefix.${Keys.MENU_MEALS}"))
            } else {
                emptyList()
            }
            val menuMealDefault = prefs.int("$prefix.${Keys.MENU_MEAL_DEFAULT}", 0)
            val menuMealKind = prefs.str("$prefix.${Keys.MENU_MEAL_KIND}")
            val menuMealIdx = resolveMenuMeal(menuMeals, menuMealDefault, menuMealKind)
                ?.let { menuMeals.indexOf(it) } ?: 0
            val data = HubContentData(
                snap = snap,
                enabled = enabled,
                pos = pos,
                sel = sel,
                entry = entry,
                looks = entry?.looks ?: emptyList(),
                agendaRows = if (sel == TAB_AGENDA) {
                    cachedParseTimeRows(prefs.str("$prefix.${Keys.AGENDA_ROWS}"))
                } else {
                    emptyList()
                },
                tasksRows = if (sel == TAB_TASKS) {
                    cachedParseTaskRows(prefs.str("$prefix.${Keys.TASKS_ROWS}"))
                } else {
                    emptyList()
                },
                menuRows = if (sel == TAB_MENU) {
                    cachedParseStrings(prefs.str("$prefix.${Keys.MENU_ROWS}"))
                } else {
                    emptyList()
                },
                menuMeals = menuMeals,
                menuMealIdx = menuMealIdx,
                titleClass = prefs.str("$prefix.${Keys.TITLE_CLASS}"),
                titleAgenda = prefs.str("$prefix.${Keys.TITLE_AGENDA}"),
                tasksTitle = prefs.str("$prefix.${Keys.TASKS_TITLE}"),
                menuTitle = prefs.str("$prefix.${Keys.MENU_TITLE}"),
                emptyTasks = prefs.str("$prefix.${Keys.EMPTY_TASKS}"),
                emptyMenu = prefs.str("$prefix.${Keys.EMPTY_MENU}"),
            )
            HubWidgetUiState.Success(data, now)
        } catch (e: Exception) {
            HubWidgetUiState.Error(e.message ?: "Load failed")
        }
    }
}

@Composable
private fun HubContent(context: Context, state: HubWidgetUiState) {
    // Non-success states resolve against the live prefs snapshot for
    // theming, so a cold bind never flashes raw keys.
    // Tracked bump read (see hubNavBump): keeps this composition pinned to
    // the counter even if the resolveState call above gets hoisted, so
    // live-session recomposes after tab taps re-read prefs.
    @Suppress("unused")
    val navBump = hubNavBump.intValue
    val snap: WidgetSnapshot = when (state) {
        is HubWidgetUiState.Success -> state.content.snap
        else -> HomeWidgetPlugin.getData(context).snapshot(Keys.HUB)
    }
    val palette = resolvePalette(context, snap.useYou, snap.themeCode)
    val tiny = state is HubWidgetUiState.Success &&
        currentVerticalBucket() == VerticalBucket.Tiny
    // Short strips (Compact bucket, ~110-150dp tall): the dots bar + header
    // + padding eat ~100dp, leaving ~10dp for content — a stock Compact
    // squeezes rows to textless slivers (seen-on-device). Short widgets get
    // a slim layout instead: header + fitting rows, no bar. Paging still
    // works everywhere via the shell/body tap; the bar returns at
    // TallColumn and up. All Compact slots are narrow, so shellClick stays.
    val short = state is HubWidgetUiState.Success &&
        currentVerticalBucket() == VerticalBucket.Compact
    // The tab bar lives in the shell's flush bottom slot (not in the padded
    // body), so dots + arrows sit stationary at the very bottom edge on
    // every tab and every size. Tiny strips have no bar.
    val barData = (state as? HubWidgetUiState.Success)
        ?.takeUnless { tiny }
        ?.content
    // Narrow hub: a tap ANYWHERE (body, header, shell padding, tiny strip)
    // advances one tab instead of opening the app — on a 1x2 there is no
    // blank corner to spare for an app-open target, and near-miss taps were
    // the whole "can't switch pages" complaint. Tiny strips get it too:
    // they have no dots bar, so without this every tap opens the app and
    // the single visible line (e.g. one dish) is a dead end. The dots bar
    // keeps its own +1 (same action). Wide hub keeps the app-open shell
    // tap, but the tab body below advances (see HubColumn).
    val shellClick = if (isNarrowSlot()) {
        actionRunCallback<HubTabCallback>(
            actionParametersOf(HubDirectionKey to 1),
        )
    } else {
        null
    }
    VerticalShell(
        context,
        palette,
        snap.opacity,
        paddingDp = if (tiny || short) 8 else 12,
        bottomBar = if (barData == null || short) null else ({ TabBar(context, palette, barData) }),
        shellClick = shellClick,
    ) {
        when (state) {
            is HubWidgetUiState.Loading ->
                EmptyState(palette, R.drawable.ic_widget_event_available, snap.emptyText)
            is HubWidgetUiState.Empty ->
                EmptyState(
                    palette,
                    R.drawable.ic_widget_event_available,
                    state.message.ifEmpty { snap.emptyText },
                )
            is HubWidgetUiState.Error ->
                EmptyState(
                    palette,
                    R.drawable.ic_widget_event_available,
                    state.message.ifEmpty { snap.emptyText },
                )
            is HubWidgetUiState.Success -> HubBody(context, palette, state.content, state.nowMs)
        }
    }
}

@Composable
private fun HubBody(
    context: Context,
    palette: ChroniclePalette,
    data: HubContentData,
    nowMs: Long,
) {
    // Portrait buckets: Tiny collapses to one quiet line; lists scroll in
    // every other bucket, so short widgets clip nothing and tall ones
    // fill up. Compact drops the hairline.
    when (currentVerticalBucket()) {
        VerticalBucket.Tiny ->
            Tiny(palette, data)
        VerticalBucket.Compact ->
            ShortHubColumn(context, palette, data, nowMs)
        VerticalBucket.TallColumn ->
            HubColumn(context, palette, data, nowMs, hairline = true)
        VerticalBucket.FullPortrait ->
            HubColumn(context, palette, data, nowMs, hairline = true)
    }
}

/** Tiny strip (1x1/2x1): dense dot + first line of the active tab.
 * The line carries a meta suffix (time/count/next) because a lone name in
 * a stretched tiny card reads as "too little info": hosts can report a
 * much smaller size than they draw (seen-on-device: slot 110x40 drawn at
 * ~150x115), and one centered line over that void is all Tiny can ever
 * afford — so the line itself must say more. All maxLines=1, safe on true
 * strips via ellipsis. */
@Composable
private fun Tiny(palette: ChroniclePalette, data: HubContentData) {
    val line = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> {
            val entry = data.entry?.takeUnless { it.isSentinel || data.snap.stale }
            when {
                entry == null -> data.snap.staleName.ifEmpty { data.snap.emptyText }
                // Hero: name + live status ("in 7 h"); quiet: state copy +
                // tomorrow's class (ellipsized to what fits).
                entry.startLabel.isNotEmpty() ->
                    "${entry.className} · ${entry.startLabel}"
                entry.thenName.isNotEmpty() ->
                    "${entry.className} · ${entry.thenName} ${entry.thenWhen}"
                else -> entry.className
            }
        }
        ChronicleHubHomeWidget.TAB_AGENDA -> data.agendaRows.firstOrNull()
            ?.let { "${it.time} · ${it.name}" }
            ?: data.snap.staleName.ifEmpty { data.snap.emptyText }
        ChronicleHubHomeWidget.TAB_TASKS -> data.tasksRows.firstOrNull()
            ?.let { task ->
                if (task.date.isNotEmpty()) "${task.title} · ${task.date}"
                else task.title
            }
            ?: data.emptyTasks.ifEmpty { data.snap.emptyText }
        else -> {
            val dishes = HubMenuMeal(data)?.dishes ?: data.menuRows
            val first = dishes.firstOrNull()
                ?: data.emptyMenu.ifEmpty { data.snap.emptyText }
            // "+N" answers "lunch menu only shows one" at a glance: the
            // rest is one resize away (tall menu lists every dish).
            if (dishes.size > 1) "$first · +${dishes.size - 1}" else first
        }
    }
    val dot = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> data.entry?.colorHex
        ChronicleHubHomeWidget.TAB_AGENDA -> data.agendaRows.firstOrNull()?.colorHex
        else -> null
    }
    TinyRow(palette, dot, line.ifEmpty { data.snap.emptyText })
}

@Composable
private fun HubColumn(
    context: Context,
    palette: ChroniclePalette,
    data: HubContentData,
    nowMs: Long,
    hairline: Boolean,
) {
    val iconRes = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> R.drawable.ic_widget_school
        ChronicleHubHomeWidget.TAB_AGENDA -> R.drawable.ic_widget_event
        ChronicleHubHomeWidget.TAB_TASKS -> R.drawable.ic_widget_task
        else -> R.drawable.ic_widget_menu
    }
    val title = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> data.titleClass
        ChronicleHubHomeWidget.TAB_AGENDA -> data.titleAgenda
        ChronicleHubHomeWidget.TAB_TASKS -> data.tasksTitle
        else -> HubMenuMeal(data)?.title ?: data.menuTitle
    }
    // Meal steppers live in the header's trailing slot, NOT in the tab
    // body: a switcher Row above the dish list makes the translator drop
    // everything below it on-device (blank tab under the switcher).
    val trailing: (@Composable () -> Unit)? =
        if (data.sel == ChronicleHubHomeWidget.TAB_MENU && data.menuMeals.size > 1) {
            {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    MenuStepArrow(palette, R.drawable.ic_widget_chevron_left, -1)
                    MenuStepArrow(palette, R.drawable.ic_widget_chevron_right, 1)
                }
            }
        } else {
            null
        }

    // fillMaxSize + weight spacer pins the tab bar to the bottom edge;
    // the weight collapses to zero when content fills the widget.
    // Compact buckets render whole rows only (static take + "+N more"):
    // a short widget must never show a row that cannot be fully seen.
    // Taller buckets scroll the full list instead.
    val compact = currentVerticalBucket() == VerticalBucket.Compact
    Column(modifier = GlanceModifier.fillMaxSize()) {
        WidgetHeader(
                palette = palette,
                iconRes = iconRes,
                title = title,
                trailing = trailing,
            )
            // Breathing room between the header and the body in every
            // bucket (Compact previously glued them together).
            Spacer(modifier = GlanceModifier.height(6.dp))
            if (hairline) {
                Spacer(modifier = GlanceModifier.height(4.dp))
                Hairline(palette)
                Spacer(modifier = GlanceModifier.height(6.dp))
            }
            // The tab body takes the remaining shell space with a bound
            // (not wrap-content): unbounded bodies mismeasure everything
            // below an interactive Row (seen on-device as a blank menu tab
            // under the meal switcher), and weight-bound lazy lists need a
            // bound anyway. Same arrangement as the standalone widgets.
            // The body itself advances a tab on tap, on EVERY size: paging
            // must not depend on which slot the host matched (a 1-column
            // widget rendering a wide slot kept the app-open shell and its
            // tiny dots target — "can't switch pages"). Child clickables
            // (tab arrows, meal steppers, agenda rail cells) win on their
            // own bounds; the header above has none, so it still falls
            // through to the shell (app-open on wide, +1 on narrow).
            Column(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxWidth()
                    .clickable(
                        onClick = actionRunCallback<HubTabCallback>(
                            actionParametersOf(HubDirectionKey to 1),
                        ),
                        rippleOverride = NoPressFeedback,
                    ),
            ) {
                when (data.sel) {
                    // Compact renders whole rows only (static take + "+N
                    // more"); taller buckets scroll the full list. True
                    // strips never reach here (Tiny renders one-liners).
                    ChronicleHubHomeWidget.TAB_CLASS ->
                        SharedClassTab(
                            palette,
                            data.entry,
                            data.snap,
                            nowMs,
                            data.looks,
                            compact = currentVerticalBucket() == VerticalBucket.Compact,
                        )
                    ChronicleHubHomeWidget.TAB_AGENDA ->
                        if (data.agendaRows.isEmpty()) {
                            EmptyState(
                                palette,
                                R.drawable.ic_widget_event_available,
                                data.snap.staleName.ifEmpty { data.snap.emptyText },
                            )
                        } else if (compact) {
                            val shown = data.agendaRows.take(2)
                            for ((i, row) in shown.withIndex()) {
                                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                                ClassRow(context, palette, row.time, row.name, row.colorHex)
                            }
                            Spacer(modifier = GlanceModifier.height(6.dp))
                            MoreIndicator(palette, data.agendaRows.size - shown.size)
                        } else {
                            // Scrollable rows: every class reachable at any
                            // height, nothing clips mid-row, no "+N more".
                            // Items wrap in a Column (see agenda widget).
                            LazyColumn(modifier = GlanceModifier.defaultWeight()) {
                                items(data.agendaRows.size) { i ->
                                    Column(modifier = GlanceModifier.fillMaxWidth()) {
                                        if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                                        val row = data.agendaRows[i]
                                        ClassRow(context, palette, row.time, row.name, row.colorHex)
                                    }
                                }
                            }
                        }
                    ChronicleHubHomeWidget.TAB_TASKS ->
                        if (data.tasksRows.isEmpty()) {
                            EmptyState(
                                palette,
                                R.drawable.ic_widget_done_all,
                                data.emptyTasks.ifEmpty { data.snap.emptyText },
                            )
                        } else if (compact) {
                            val shown = data.tasksRows.take(2)
                            for ((i, task) in shown.withIndex()) {
                                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                                TaskRow(palette, task.title, task.date, task.urgent)
                            }
                            Spacer(modifier = GlanceModifier.height(6.dp))
                            MoreIndicator(palette, data.tasksRows.size - shown.size)
                        } else {
                            // Scrollable rows, same mechanism as above.
                            LazyColumn(modifier = GlanceModifier.defaultWeight()) {
                                items(data.tasksRows.size) { i ->
                                    Column(modifier = GlanceModifier.fillMaxWidth()) {
                                        if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                                        val task = data.tasksRows[i]
                                        TaskRow(palette, task.title, task.date, task.urgent)
                                    }
                                }
                            }
                        }
                    else -> {
                        val meal = HubMenuMeal(data)
                        val dishes = meal?.dishes ?: data.menuRows
                        if (dishes.isEmpty()) {
                            EmptyState(
                                palette,
                                R.drawable.ic_widget_menu,
                                data.emptyMenu.ifEmpty { data.snap.emptyText },
                            )
                        } else {
                            // Every bucket lists every dish in a scrolling
                            // list (same mechanism as the agenda/tasks tabs
                            // above: weight-bound LazyColumn inside the
                            // bounded tab body, items wrapped in their own
                            // Column). No capped summary: hosts can display
                            // a small-slot composition in a much taller
                            // widget, and a one-line "+N" summary would
                            // orphan dishes with no way to reach them.
                            LazyColumn(modifier = GlanceModifier.defaultWeight()) {
                                items(dishes.size) { i ->
                                    Column(modifier = GlanceModifier.fillMaxWidth()) {
                                        if (i > 0) Spacer(modifier = GlanceModifier.height(4.dp))
                                        DishRow(palette, dishes[i])
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }
}

/**
 * Slim layout for short strips (Compact bucket, ~110-150dp tall): header +
 * fitting rows, no dots bar. A stock Compact (bar + header + full rows)
 * leaves ~10dp for content at 110dp and squeezes rows to textless slivers
 * (seen-on-device). Paging works via the shell tap; the bar returns at
 * TallColumn and up. Fixed takes only (never lazy: weight-bound lazy lists
 * mismeasure in short bodies) with one height gate at 135dp so taller
 * shorts fill up instead of idling.
 */
@Composable
private fun ShortHubColumn(
    context: Context,
    palette: ChroniclePalette,
    data: HubContentData,
    nowMs: Long,
) {
    val iconRes = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> R.drawable.ic_widget_school
        ChronicleHubHomeWidget.TAB_AGENDA -> R.drawable.ic_widget_event
        ChronicleHubHomeWidget.TAB_TASKS -> R.drawable.ic_widget_task
        else -> R.drawable.ic_widget_menu
    }
    val title = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> data.titleClass
        ChronicleHubHomeWidget.TAB_AGENDA -> data.titleAgenda
        ChronicleHubHomeWidget.TAB_TASKS -> data.tasksTitle
        // Short strips give the title ~20dp next to the steppers (seen as
        // "B…"): with several meals the steppers alone identify the
        // switcher, so the title yields. Single meals keep their title.
        else -> if (data.menuMeals.size > 1) "" else HubMenuMeal(data)?.title ?: data.menuTitle
    }
    val trailing: (@Composable () -> Unit)? =
        if (data.sel == ChronicleHubHomeWidget.TAB_MENU && data.menuMeals.size > 1) {
            {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    MenuStepArrow(palette, R.drawable.ic_widget_chevron_left, -1)
                    MenuStepArrow(palette, R.drawable.ic_widget_chevron_right, 1)
                }
            }
        } else {
            null
        }
    // Taller shorts (drawn ~135dp+) take one more row instead of idling.
    val roomy = LocalSize.current.height.value >= 135

    Column(modifier = GlanceModifier.fillMaxSize()) {
        WidgetHeader(
            palette = palette,
            iconRes = iconRes,
            title = title,
            trailing = trailing,
        )
        Spacer(modifier = GlanceModifier.height(6.dp))
        Column(
            modifier = GlanceModifier
                .defaultWeight()
                .fillMaxWidth(),
        ) {
            when (data.sel) {
                ChronicleHubHomeWidget.TAB_CLASS -> {
                    val entry = data.entry
                    if (entry == null || entry.isSentinel || data.snap.stale) {
                        EmptyState(
                            palette,
                            R.drawable.ic_widget_event_available,
                            data.snap.emptyText,
                        )
                    } else if (entry.startLabel.isEmpty()) {
                        // Quiet: copy + Then-line (the SharedClassTab quiet
                        // lead, ~61dp). Taller shorts add one lookahead row.
                        Text(
                            text = entry.className,
                            style = TextStyle(
                                color = palette.onSurfaceVariant,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 1,
                        )
                        val thenRow = data.looks.firstOrNull {
                            it.time == entry.thenWhen && it.name == entry.thenName
                        }
                        ThenLine(palette, entry, thenRow)
                        if (roomy) {
                            val extra = data.looks.filterNot {
                                it.time == entry.thenWhen && it.name == entry.thenName
                            }.take(1)
                            for (row in extra) {
                                Spacer(modifier = GlanceModifier.height(4.dp))
                                FilledLookaheadRow(
                                    palette = palette,
                                    time = row.time,
                                    name = row.name,
                                    where = listOf(row.room, row.building)
                                        .filter { it.isNotEmpty() }
                                        .joinToString(" · "),
                                    chipWidth = lookaheadChipWidth(),
                                )
                            }
                        }
                    } else {
                        // Hero-short: name + status/range/room meta only. No
                        // teacher line, no Then-line: neither fits ~110dp
                        // (seen-on-device). Tall widgets show the full hero.
                        // 15sp keeps name + 2-line meta inside a 110dp card
                        // with margin (16sp ran ~3dp over the drawn box).
                        Text(
                            text = entry.className,
                            style = TextStyle(
                                color = palette.onSurface,
                                fontSize = if (isNarrowSlot()) 15.sp else 20.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 2,
                        )
                        val meta = listOf(
                            liveStatus(entry, data.snap, nowMs),
                            entry.detailLine,
                        ).filter { it.isNotEmpty() }.joinToString(" · ")
                        if (meta.isNotEmpty()) {
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Text(
                                text = meta,
                                style = TextStyle(
                                    color = palette.onSurfaceVariant,
                                    fontSize = 10.sp,
                                ),
                                maxLines = 2,
                            )
                        }
                    }
                }
                ChronicleHubHomeWidget.TAB_AGENDA ->
                    if (data.agendaRows.isEmpty()) {
                        EmptyState(
                            palette,
                            R.drawable.ic_widget_event_available,
                            data.snap.staleName.ifEmpty { data.snap.emptyText },
                        )
                    } else {
                        val shown = data.agendaRows.take(if (roomy) 2 else 1)
                        for ((i, row) in shown.withIndex()) {
                            if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                            ClassRow(context, palette, row.time, row.name, row.colorHex)
                        }
                    }
                ChronicleHubHomeWidget.TAB_TASKS ->
                    if (data.tasksRows.isEmpty()) {
                        EmptyState(
                            palette,
                            R.drawable.ic_widget_done_all,
                            data.emptyTasks.ifEmpty { data.snap.emptyText },
                        )
                    } else {
                        val shown = data.tasksRows.take(if (roomy) 2 else 1)
                        for ((i, task) in shown.withIndex()) {
                            if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                            TaskRow(palette, task.title, task.date, task.urgent)
                        }
                    }
                else -> {
                    val meal = HubMenuMeal(data)
                    val dishes = meal?.dishes ?: data.menuRows
                    if (dishes.isEmpty()) {
                        EmptyState(
                            palette,
                            R.drawable.ic_widget_menu,
                            data.emptyMenu.ifEmpty { data.snap.emptyText },
                        )
                    } else {
                        val shown = dishes.take(if (roomy) 3 else 2)
                        for ((i, dish) in shown.withIndex()) {
                            if (i > 0) Spacer(modifier = GlanceModifier.height(4.dp))
                            DishRow(palette, dish)
                        }
                    }
                }
            }
        }
    }
}

/**
 * Bottom tab bar: previous arrow, centered page dots, next arrow.
 * The narrow bar wraps the dots in a full-width tap row (anywhere on it
 * advances a tab — a small centered target lets near-misses fall through
 * to the whole-widget tap, reads as "can't switch pages"), but its fill
 * matches the shell exactly so no bubble shows: the dots keep the small
 * v1.12.0 pill look. Wide slots keep the hugging track between chevrons.
 */
@Composable
private fun TabBar(context: Context, palette: ChroniclePalette, data: HubContentData) {
    // The row itself advances too: taps landing between the arrows and
    // the dots would otherwise fall through to the whole-widget tap and
    // open the app instead of switching tabs. Child actions win over
    // the parent's, so arrows keep their own directions.
    if (isNarrowSlot()) {
        // Single-tab widgets get no bar at all (the dots row early-returns
        // under count <= 1).
        if (data.enabled.size > 1) {
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(40.dp)
                    .background(widgetBg(context, palette.bg, data.snap.opacity))
                    .clickable(
                        onClick = actionRunCallback<HubTabCallback>(
                            actionParametersOf(HubDirectionKey to 1),
                        ),
                        rippleOverride = NoPressFeedback,
                    ),
                contentAlignment = Alignment.Center,
            ) {
                DotStrip(palette, data)
            }
        }
        return
    }
    // No row-level tap target here on purpose: a full-width clickable
    // flashes a full-width host-painted pressed bar on every tap, and the
    // user asked for zero press visuals. Taps between the arrows and the
    // dots fall through to the whole-widget tap (opens the app) instead.
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        TabArrow(palette, R.drawable.ic_widget_chevron_left, -1)
        Spacer(modifier = GlanceModifier.defaultWeight())
        DotStrip(palette, data)
        Spacer(modifier = GlanceModifier.defaultWeight())
        TabArrow(palette, R.drawable.ic_widget_chevron_right, 1)
    }
}

/**
 * Page dots on an opaque tonal track: a single advance-on-tap target
 * (HubTabCallback, +1 with wrap-around). The track MUST be opaque: the
 * host paints tap confirmation on the clicked view, and on transparent
 * boxes that reads as a big grey rectangle (seen on-device, three
 * recordings). Behind opaque pixels the flash never surfaces — the same
 * reason rail cells and filled rows never flash. Resting look is a
 * standard page-control pill; size hugs the dots (no dead padding that
 * would flash).
 */
@Composable
private fun DotStrip(palette: ChroniclePalette, data: HubContentData) {
    val count = data.enabled.size
    if (count <= 1) return
    val dotsWidth = 16 + (count.coerceAtMost(7) - 1) * 12
    Box(
        modifier = GlanceModifier
            .width((dotsWidth + 24).dp)
            .height(24.dp)
            .background(palette.cardHigh)
            .cornerRadius(50.dp)
            .clickable(
                onClick = actionRunCallback<HubTabCallback>(
                    actionParametersOf(HubDirectionKey to 1),
                ),
                rippleOverride = NoPressFeedback,
            ),
        contentAlignment = Alignment.Center,
    ) {
        DotRow(palette, data)
    }
}

/** Bare dots row (no tap target): the visuals shared by both bar modes. */
@Composable
private fun DotRow(palette: ChroniclePalette, data: HubContentData) {
    val count = data.enabled.size
    if (count <= 1) return
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        for (i in 0 until count.coerceAtMost(7)) {
            if (i > 0) Spacer(modifier = GlanceModifier.width(6.dp))
            Box(
                modifier = GlanceModifier
                    .width(if (i == data.pos) 16.dp else 6.dp)
                    .height(6.dp)
                    .background(
                        if (i == data.pos) palette.accent else palette.onSurfaceVariant
                    )
                    .cornerRadius(50.dp),
            ) {}
        }
    }
}

/** Selected servable meal for the hub menu tab (legacy flat rows when the
 * new list is absent, e.g. pushes from older app versions). */
private fun HubMenuMeal(data: HubContentData): MenuMeal? =
    if (data.menuMeals.isEmpty()) null
    else data.menuMeals[data.menuMealIdx.coerceIn(data.menuMeals.indices)]
