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
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
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
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.FilledLookaheadRow
import com.chronicleapp.chronicle.widget.Hairline
import com.chronicleapp.chronicle.widget.HubDirectionKey
import com.chronicleapp.chronicle.widget.HubMenuMealCallback
import com.chronicleapp.chronicle.widget.HubTabCallback
import com.chronicleapp.chronicle.widget.MealSwitcher
import com.chronicleapp.chronicle.widget.MenuMeal
import com.chronicleapp.chronicle.widget.MenuMealDirectionKey
import com.chronicleapp.chronicle.widget.MenuStepArrow
import com.chronicleapp.chronicle.widget.NoPressFeedback
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.Samples
import com.chronicleapp.chronicle.widget.SharedAgendaList
import com.chronicleapp.chronicle.widget.SharedClassTab
import com.chronicleapp.chronicle.widget.SharedMenuList
import com.chronicleapp.chronicle.widget.SharedTasksList
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
import com.chronicleapp.chronicle.widget.deviceTodayIso
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
        return "v3|hub|$loc|${snap.useYou}|${snap.themeCode}"
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
            val menuMealIdx = resolveMenuMeal(
                menuMeals,
                menuMealDefault,
                menuMealKind,
                prefs.str("$prefix.${Keys.MENU_MEAL_KIND_DATE}"),
                deviceTodayIso(),
            )
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
    // a slim layout instead: header + fitting rows, no bar. Paging needs
    // TallColumn+ where the bar fits; short/tiny taps open the app.
    val short = state is HubWidgetUiState.Success &&
        currentVerticalBucket() == VerticalBucket.Compact
    // The tab bar lives in the shell's flush bottom slot (not in the padded
    // body), so dots + arrows sit stationary at the very bottom edge on
    // every tab and every size. Tiny strips have no bar; short strips get
    // the slim dots-only bar (see ShortHubColumn) so 1-column widgets can
    // page without growing.
    val barData = (state as? HubWidgetUiState.Success)
        ?.takeUnless { tiny }
        ?.content
    // Single-tab shorts skip the bar (nothing to page to); the dots row
    // early-returns under count <= 1, so an empty bar would just eat 36dp.
    // Tall single-tab hubs also skip it: chevrons wrapping to the same tab
    // are a no-op that wastes ~48dp.
    val multiTab = barData?.enabled?.size?.let { it > 1 } == true
    // Bar visibility: any multi-tab hub (tall or short slim dots bar).
    // Single-tab hubs get no bar at all — dots/arrows would be dead.
    val showBar = barData != null && !tiny && multiTab
    // Paging is dots/arrows-only: every other tap (body, header, shell
    // padding, tiny strips) falls through to the shell's app-open action.
    // (Narrow shells used to advance on any tap; the dots target was tiny
    // and near-misses read as "can't switch pages". The contract is now
    // inverted: dots switch, taps open the app.)
    VerticalShell(
        context,
        palette,
        snap.opacity,
        paddingDp = if (tiny || short) 8 else 12,
        bottomBar = if (!showBar) null else ({ TabBar(context, palette, barData!!, slim = short) }),
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
            is HubWidgetUiState.Success -> HubBody(context, palette, state.content, state.nowMs, hasBar = showBar && short)
        }
    }
}

@Composable
private fun HubBody(
    context: Context,
    palette: ChroniclePalette,
    data: HubContentData,
    nowMs: Long,
    hasBar: Boolean = false,
) {
    // Portrait buckets: Tiny collapses to one quiet line; shorts get a
    // slim rows layout with the dots-only bar (no header: the bar eats
    // that budget at ~110dp); lists scroll in the taller buckets so
    // nothing clips and tall ones fill up.
    when (currentVerticalBucket()) {
        VerticalBucket.Tiny ->
            Tiny(palette, data)
        VerticalBucket.Compact ->
            ShortHubColumn(context, palette, data, nowMs, hasBar)
        VerticalBucket.TallColumn ->
            HubColumn(context, palette, data, nowMs)
        VerticalBucket.FullPortrait ->
            HubColumn(context, palette, data, nowMs)
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

/** Header model shared by HubColumn and ShortHubColumn: icon + title +
 * whether the meal steppers show. The title always renders (ellipsized):
 * blanking it next to the steppers read as a broken widget. */
private data class HubHeaderData(
    val iconRes: Int,
    val title: String,
    val showSteppers: Boolean,
)

private fun hubHeaderData(data: HubContentData, @Suppress("UNUSED_PARAMETER") compactTitle: Boolean): HubHeaderData {
    // Meal steppers pin to the header's top edge (see HubHeaderRow), NOT
    // the tab body: a switcher Row above the dish list makes the
    // translator drop everything below it on-device (blank tab under the
    // switcher).
    val showSteppers =
        data.sel == ChronicleHubHomeWidget.TAB_MENU && data.menuMeals.size > 1
    val title = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> data.titleClass
        ChronicleHubHomeWidget.TAB_AGENDA -> data.titleAgenda
        ChronicleHubHomeWidget.TAB_TASKS -> data.tasksTitle
        else -> HubMenuMeal(data)?.title ?: data.menuTitle
    }
    val iconRes = when (data.sel) {
        ChronicleHubHomeWidget.TAB_CLASS -> R.drawable.ic_widget_school
        ChronicleHubHomeWidget.TAB_AGENDA -> R.drawable.ic_widget_event
        ChronicleHubHomeWidget.TAB_TASKS -> R.drawable.ic_widget_task
        else -> R.drawable.ic_widget_menu
    }
    return HubHeaderData(iconRes, title, showSteppers)
}

/**
 * Hub header: WidgetHeader, except the menu tab with meal steppers, which
 * pins everything to the top edge. Centered 40dp stepper boxes stretch the
 * header row to 40dp and the shared centered header floats the 16dp icon
 * ~10dp below every other tab's icon (seen-on-device); top-pinning keeps
 * the icon (and the title's top edge) exactly where the other tabs put
 * them, and the steppers grow downward when meal data arrives instead of
 * shoving the icon down. Other widgets keep the shared header untouched.
 */
@Composable
private fun HubHeaderRow(
    palette: ChroniclePalette,
    iconRes: Int,
    title: String,
    showSteppers: Boolean,
) {
    if (!showSteppers) {
        WidgetHeader(
            palette = palette,
            iconRes = iconRes,
            title = title,
            trailing = null,
        )
        return
    }
    Row(
        // +1dp: WidgetHeader centers its 16dp icon in a ~20dp row, so the
        // icon sits ~1dp below the row top; match that exactly or the menu
        // icon floats a hair above every other tab's (seen-on-device).
        modifier = GlanceModifier.fillMaxWidth().padding(top = 1.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Image(
            provider = ImageProvider(iconRes),
            contentDescription = null,
            modifier = GlanceModifier.width(16.dp).height(16.dp),
            colorFilter = ColorFilter.tint(palette.accent),
        )
        Spacer(modifier = GlanceModifier.width(6.dp))
        Box(modifier = GlanceModifier.defaultWeight()) {
            Text(
                text = title,
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
        }
        Spacer(modifier = GlanceModifier.width(6.dp))
        MenuStepArrow(palette, R.drawable.ic_widget_chevron_left, -1)
        MenuStepArrow(palette, R.drawable.ic_widget_chevron_right, 1)
    }
}

/**
 * Menu-tab header that never loses meal switching: on wide slots the
 * shared top-pinned icon + title + steppers; on narrow slots the
 * standalone switcher row (`MealSwitcher` — the standalone widget proves
 * it fits where icon + title + steppers crush the title to zero and clip
 * the far stepper). Same arrows and contract as the standalone widget,
 * only the callback targets the hub's override. The switcher stays in the
 * header slot, never the tab body (an interactive row above the dish list
 * blanks the tab on-device).
 */
@Composable
private fun HubMenuHeaderRow(
    palette: ChroniclePalette,
    data: HubContentData,
    header: HubHeaderData,
) {
    if (data.sel == ChronicleHubHomeWidget.TAB_MENU &&
        data.menuMeals.size > 1 &&
        isNarrowSlot()
    ) {
        MealSwitcher(
            palette = palette,
            title = header.title,
            showArrows = true,
            leftIcon = R.drawable.ic_widget_chevron_left,
            rightIcon = R.drawable.ic_widget_chevron_right,
        ) { dir ->
            actionRunCallback<HubMenuMealCallback>(
                actionParametersOf(MenuMealDirectionKey to dir),
            )
        }
    } else {
        HubHeaderRow(
            palette = palette,
            iconRes = header.iconRes,
            title = header.title,
            showSteppers = header.showSteppers,
        )
    }
}

@Composable
private fun HubColumn(
    context: Context,
    palette: ChroniclePalette,
    data: HubContentData,
    nowMs: Long,
) {
    // Narrow strips can't fit icon + title + two 40dp steppers (~108dp of
    // chrome alone): the title crushes to zero and the far stepper clips
    // off-screen (seen on-device on a 1-column hub). Narrow menu tabs reuse
    // the standalone switcher row instead (see HubMenuHeaderRow) — meal
    // switching is never lost, only restyled for the width.
    val baseHeader = hubHeaderData(data, compactTitle = false)
    val header = baseHeader.copy(showSteppers = baseHeader.showSteppers && !isNarrowSlot())

    // fillMaxSize + weight spacer pins the tab bar to the bottom edge;
    // the weight collapses to zero when content fills the widget.
    // Taller buckets scroll the full list; shorts never reach here
    // (ShortHubColumn owns the Compact bucket).
    Column(modifier = GlanceModifier.fillMaxSize()) {
        HubMenuHeaderRow(palette, data, header)
            // Breathing room between the header and the body.
            Spacer(modifier = GlanceModifier.height(6.dp))
            Spacer(modifier = GlanceModifier.height(4.dp))
            Hairline(palette)
            Spacer(modifier = GlanceModifier.height(6.dp))
            // The tab body takes the remaining shell space with a bound
            // (not wrap-content): unbounded bodies mismeasure everything
            // below an interactive Row (seen on-device as a blank menu tab
            // under the meal switcher), and weight-bound lazy lists need a
            // bound anyway. Same arrangement as the standalone widgets.
            // The body has no tap action: dots/arrows page, everything else
            // falls through to the shell's app-open tap. Child clickables
            // (tab arrows, meal steppers) win on their own bounds.
            Column(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxWidth(),
            ) {
                when (data.sel) {
                    // Tall buckets scroll the full list. True strips never
                    // reach here (Tiny renders one-liners, shorts render
                    // ShortHubColumn).
                    ChronicleHubHomeWidget.TAB_CLASS ->
                        SharedClassTab(
                            palette,
                            data.entry,
                            data.snap,
                            nowMs,
                            data.looks,
                        )
                    ChronicleHubHomeWidget.TAB_AGENDA ->
                        if (data.agendaRows.isEmpty()) {
                            EmptyState(
                                palette,
                                R.drawable.ic_widget_event_available,
                                data.snap.staleName.ifEmpty { data.snap.emptyText },
                            )
                        } else {
                            // Same rows as the standalone agenda widget
                            // ([SharedAgendaList]): a copy, not a second design.
                            SharedAgendaList(context, palette, data.agendaRows)
                        }
                    ChronicleHubHomeWidget.TAB_TASKS ->
                        if (data.tasksRows.isEmpty()) {
                            EmptyState(
                                palette,
                                R.drawable.ic_widget_done_all,
                                data.emptyTasks.ifEmpty { data.snap.emptyText },
                            )
                        } else {
                            // Same rows as the standalone tasks widget
                            // ([SharedTasksList]): a copy, not a second design.
                            SharedTasksList(palette, data.tasksRows)
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
                            // Same rows as the standalone menu widget
                            // ([SharedMenuList]): a copy, not a second design.
                            SharedMenuList(palette, dishes)
                        }
                    }
                }
            }
    }
}

/**
 * Slim layout for short strips (Compact bucket, ~110-120dp slots):
 * fitting rows plus the slim dots-only bar — no header while the bar
 * shows (bar + header + paddings leave ~40dp for content at 110dp and
 * squeeze rows to textless slivers, seen-on-device). Dots page,
 * everything else opens the app. Fixed takes only (never lazy:
 * weight-bound lazy lists mismeasure in short bodies) with a 135dp gate
 * for taller shorts. Without the bar (single tab) the header returns.
 */
@Composable
private fun ShortHubColumn(
    context: Context,
    palette: ChroniclePalette,
    data: HubContentData,
    nowMs: Long,
    hasBar: Boolean,
) {
    // Same narrow-strip rule as HubColumn (see above): the menu tab swaps
    // in the standalone switcher row instead of dropping its steppers.
    val baseHeader = hubHeaderData(data, compactTitle = true)
    val header = baseHeader.copy(showSteppers = baseHeader.showSteppers && !isNarrowSlot())
    // Taller shorts (drawn ~135dp+) take one more row instead of idling.
    val roomy = LocalSize.current.height.value >= 135

    Column(modifier = GlanceModifier.fillMaxSize()) {
        // The header (icon + per-tab title) always renders, matching the
        // tall buckets and the standalone widgets. Bar mode keeps the slim
        // dots-only bar; single-tab hubs skip it (nothing to page to).
        HubMenuHeaderRow(palette, data, header)
        Spacer(modifier = GlanceModifier.height(4.dp))
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
                        if (hasBar) {
                            // Bar mode: copy + one plain then-line with the
                            // next class location when known. The Then-card
                            // (45dp) doesn't fit under the bar + header.
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
                            val thenWhere = thenRow?.let {
                                listOf(it.room, it.building)
                                    .filter { w -> w.isNotEmpty() }
                                    .joinToString(" · ")
                            }.orEmpty()
                            val thenBits = listOf(
                                entry.thenName,
                                entry.thenWhen,
                                thenWhere,
                            ).filter { it.isNotEmpty() }
                            if (thenBits.isNotEmpty()) {
                                Spacer(modifier = GlanceModifier.height(2.dp))
                                Text(
                                    text = thenBits.joinToString(" · "),
                                    style = TextStyle(
                                        color = palette.onSurfaceVariant,
                                        fontSize = 11.sp,
                                    ),
                                    maxLines = 1,
                                )
                            }
                        } else {
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
                        }
                    } else {
                        if (hasBar) {
                            // Bar mode: name + status/range/room meta (the
                            // location lives in detailLine). Name stays one
                            // line so header + meta + slim bar fit ~110dp;
                            // the Then-card only renders in taller buckets.
                            Text(
                                text = entry.className,
                                style = TextStyle(
                                    color = palette.onSurface,
                                    fontSize = if (isNarrowSlot()) 15.sp else 20.sp,
                                    fontWeight = FontWeight.Bold,
                                ),
                                maxLines = 1,
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
                            TaskRow(palette, task.title, task.date, task.urgent, task.className, task.steps)
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
                        // Same scrolling full list as the standalone menu
                        // widget's Compact tier ([SharedMenuList]): hosts
                        // report a short slot and then draw it tall (the
                        // void below a 2-row take proves the lie), so a
                        // capped take orphans dishes behind empty space.
                        // The switcher lives in the header slot, never above
                        // the list in the body, so the translator keeps the
                        // rows (same arrangement as the tall tab).
                        SharedMenuList(palette, dishes)
                    }
                }
            }
        }
    }
}

/**
 * Bottom tab bar: previous arrow, centered page dots, next arrow.
 * Dots/arrows are the only paging targets: the narrow bar centers the
 * dots pill with no row-level tap (misses open the app), and wide slots
 * keep the hugging track between chevrons. The dots keep the small
 * v1.12.0 pill look. Short strips pass slim=true: the container hugs the
 * 24dp pill (28dp) instead of the 40dp touch row, leaving ~58dp of content
 * room at 110dp.
 */
@Composable
private fun TabBar(context: Context, palette: ChroniclePalette, data: HubContentData, slim: Boolean = false) {
    // Single tab: nothing to page to — no bar (chevrons would wrap to the
    // same tab, a no-op wasting ~48dp).
    if (data.enabled.size <= 1) return
    // Narrow bar: dots only. The outer box is a plain centering container
    // with no tap action, so misses fall through to the shell (open app);
    // only the dots pill itself (DotStrip) advances. (The whole row used
    // to advance, which read as "can't open the app" from a 1-column
    // widget.)
    if (isNarrowSlot()) {
        // Single-tab widgets get no bar at all (the dots row early-returns
        // under count <= 1).
        if (data.enabled.size > 1) {
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(if (slim) 28.dp else 40.dp),
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
