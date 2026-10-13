// Hand-written Glance widget (tall-portrait design). NOT generated —
// edit freely. Wire contract lives in
// com.chronicleapp.chronicle.widget.WidgetData and is mirrored by
// lib/services/widget_push.dart; keep both sides in lockstep.
//
// WeeklyCalendar vertical flow: day sections stack top-to-bottom in week
// order; each section is a per-day header over stacked class rows. No
// horizontal day-strip: a 7-cell rail cannot survive 120.dp widths. Row
// appears only inside ClassRow (inline time chip + name). Buckets
// (weeklySizeSlots, slimmed for update speed): Compact 120x120 today
// only, TallColumn 120x240 today + tomorrow, FullPortrait 260x240 up to
// 4 class days under headers. Tall lists cap statically with a "+X more"
// indicator (no LazyColumn: static RemoteViews are the crash-safe path). Outer radius
// 24.dp, inner cards 16.dp via shared components. Only
// androidx.glance.* composables (plus compose unit / runtime primitives
// dp/sp/Composable).
package com.chronicleapp.chronicle

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.ConfigurationCompat
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import com.chronicleapp.chronicle.widget.ChroniclePalette
import com.chronicleapp.chronicle.widget.ChunkedRows
import com.chronicleapp.chronicle.widget.ClassRow
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.MoreIndicator
import com.chronicleapp.chronicle.widget.Samples
import com.chronicleapp.chronicle.widget.SectionHeader
import com.chronicleapp.chronicle.widget.TimeRow
import com.chronicleapp.chronicle.widget.VerticalBucket
import com.chronicleapp.chronicle.widget.VerticalShell
import com.chronicleapp.chronicle.widget.WidgetSnapshot
import com.chronicleapp.chronicle.widget.currentVerticalBucket
import com.chronicleapp.chronicle.widget.parseTimeRows
import com.chronicleapp.chronicle.widget.parseWeek
import com.chronicleapp.chronicle.widget.resolvePalette
import com.chronicleapp.chronicle.widget.snapshot
import com.chronicleapp.chronicle.widget.str
import com.chronicleapp.chronicle.widget.TinyRow
import com.chronicleapp.chronicle.widget.weeklySizeSlots

import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin

class WeeklyCalendarHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    // Slim slot set (weeklySizeSlots): the weekly feed is the heaviest
    // composition, and every update renders one view per slot.
    override val sizeMode = weeklySizeSlots

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WeekContent(context, resolveState(context)) }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.WEEKLY_CALENDAR)
        provideContent {
            WeekContent(
                context,
                WeeklyCalendarWidgetUiState.Success(
                    days = Samples.week.zip(
                        listOf(
                            Samples.agenda,
                            Samples.agenda.take(2),
                            emptyList(),
                            Samples.agenda.take(1),
                            emptyList(),
                            emptyList(),
                            emptyList(),
                        ),
                    ) { cell, rows -> WeekDayColumn(cell, rows) },
                    snap = snap,
                ),
            )
        }
    }

    fun previewFingerprint(context: Context): String {
        val locales = ConfigurationCompat.getLocales(context.resources.configuration)
        val loc = (0 until locales.size()).mapNotNull { locales[it] }.joinToString(",")
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.WEEKLY_CALENDAR)
        return "v1|wc|$loc|${snap.useYou}|${snap.themeCode}"
    }

    private fun resolveState(context: Context): WeeklyCalendarWidgetUiState {
        return try {
            val prefs = HomeWidgetPlugin.getData(context)
            val prefix = Keys.WEEKLY_CALENDAR
            val snap = prefs.snapshot(prefix)
            if (snap.stale) {
                return WeeklyCalendarWidgetUiState.Empty(
                    snap.staleName.ifEmpty { snap.emptyText }.ifEmpty { "No classes" },
                )
            }
            val week = parseWeek(prefs.str("$prefix.${Keys.WEEK}"))
            if (week.isEmpty()) {
                return WeeklyCalendarWidgetUiState.Empty(
                    snap.emptyText.ifEmpty { "No classes" },
                )
            }
            val days = week.mapIndexed { i, cell ->
                WeekDayColumn(
                    cell = cell,
                    rows = parseTimeRows(prefs.str("$prefix.day$i")),
                )
            }
            if (days.all { it.rows.isEmpty() }) {
                return WeeklyCalendarWidgetUiState.Empty(
                    snap.emptyText.ifEmpty { "No classes" },
                )
            }
            WeeklyCalendarWidgetUiState.Success(days, snap)
        } catch (e: Exception) {
            WeeklyCalendarWidgetUiState.Error(e.message ?: "Load failed")
        }
    }
}

@Composable
private fun WeekContent(context: Context, state: WeeklyCalendarWidgetUiState) {
    val snap: WidgetSnapshot = when (state) {
        is WeeklyCalendarWidgetUiState.Success -> state.snap
        else -> HomeWidgetPlugin.getData(context).snapshot(Keys.WEEKLY_CALENDAR)
    }
    val palette = resolvePalette(context, snap.useYou, snap.themeCode)
    val tiny = state is WeeklyCalendarWidgetUiState.Success &&
        currentVerticalBucket() == VerticalBucket.Tiny
    VerticalShell(context, palette, snap.opacity, paddingDp = if (tiny) 8 else 12) {
        when (state) {
            is WeeklyCalendarWidgetUiState.Loading ->
                EmptyState(palette, R.drawable.ic_widget_event_available, snap.emptyText)
            is WeeklyCalendarWidgetUiState.Empty ->
                EmptyState(palette, R.drawable.ic_widget_event_available, state.message)
            is WeeklyCalendarWidgetUiState.Error ->
                EmptyState(palette, R.drawable.ic_widget_event_available, state.message)
            is WeeklyCalendarWidgetUiState.Success -> when (currentVerticalBucket()) {
                VerticalBucket.Tiny -> Tiny(state, palette)
                VerticalBucket.Compact -> Compact(context, state, palette)
                VerticalBucket.TallColumn -> TallColumn(context, state, palette)
                VerticalBucket.FullPortrait -> FullPortrait(context, state, palette)
            }
        }
    }
}

/** Tiny strip (1x1/2x1): dense dot + today's first class. */
@Composable
private fun Tiny(
    state: WeeklyCalendarWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    val day = state.days.firstOrNull()
    val first = day?.rows?.firstOrNull()
    TinyRow(
        palette,
        first?.colorHex,
        if (first != null) "${first.time} · ${first.name}"
        else day?.let { "${it.cell.label} ${it.cell.num}" }.orEmpty(),
    )
}

/** Compact Square (2x2): today's classes only, first row + "+X more". */
@Composable
private fun Compact(
    context: Context,
    state: WeeklyCalendarWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    val today = state.days.first()
    DaySection(context, palette, label = "${today.cell.label} ${today.cell.num}", rows = today.rows, take = 2)
}

/** Tall Vertical Column (2x3/2x4): today + tomorrow, up to 2 rows each. */
@Composable
private fun TallColumn(
    context: Context,
    state: WeeklyCalendarWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        val days = state.days.take(2)
        for ((i, day) in days.withIndex()) {
            if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
            DaySection(
                context,
                palette,
                label = "${day.cell.label} ${day.cell.num}",
                rows = day.rows,
                take = 2,
            )
        }
    }
}

/**
 * Standard Portrait Feed (4x3/4x4): the full week with classes, up to 7
 * days with up to 2 rows each. Static: a Glance LazyColumn here composed
 * only its first item on-device (verified by dumpsys subtree inspection),
 * so day sections render statically, chunked to respect the ~10-child
 * RemoteViews limit (each DaySection is one node).
 */
@Composable
private fun FullPortrait(
    context: Context,
    state: WeeklyCalendarWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        SectionHeader(palette, "This week")
        val days = state.days.filter { it.rows.isNotEmpty() }.take(7)
        ChunkedRows(count = days.size, perGroup = 2, gapDp = 6) { i ->
            val day = days[i]
            DaySection(
                context,
                palette,
                label = "${day.cell.label} ${day.cell.num}",
                rows = day.rows,
                take = 2,
            )
        }
    }
}

/** One day section: header over stacked class rows + overflow pill. */
@Composable
private fun DaySection(
    context: Context,
    palette: ChroniclePalette,
    label: String,
    rows: List<TimeRow>,
    take: Int,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        Text(
            text = label,
            style = TextStyle(
                color = palette.onSurfaceVariant,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
        Spacer(modifier = GlanceModifier.height(4.dp))
        if (rows.isEmpty()) {
            Text(
                text = "—",
                style = TextStyle(color = palette.onSurfaceVariant, fontSize = 12.sp),
                maxLines = 1,
            )
        } else {
            val shown = rows.take(take)
            for ((i, row) in shown.withIndex()) {
                if (i > 0) Spacer(modifier = GlanceModifier.height(4.dp))
                ClassRow(context, palette, row.time, row.name, row.colorHex)
            }
            val remaining = rows.size - shown.size
            if (remaining > 0) {
                Spacer(modifier = GlanceModifier.height(4.dp))
                MoreIndicator(palette, remaining)
            }
        }
    }
}
