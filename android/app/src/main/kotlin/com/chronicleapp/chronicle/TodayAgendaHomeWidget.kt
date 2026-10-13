// Hand-written Glance widget (Chronicle M3 Expressive redesign). NOT
// generated — edit freely. Wire contract lives in
// com.chronicleapp.chronicle.widget.WidgetData and is mirrored by
// lib/services/widget_push.dart; keep both sides in lockstep.
//
// TodayAgenda: week rail (tappable day pills, Google-Calendar style) over a
// dense class list. The rail renders at every size (compact 40dp cells when
// short) because it is the widget's only control; the header label yields
// below 250dp and the date line below 170dp. Row takes are 1/2/4/8 by height.
package com.chronicleapp.chronicle

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.ConfigurationCompat
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.chronicleapp.chronicle.widget.AgendaDayKey
import com.chronicleapp.chronicle.widget.AgendaDaySelectCallback
import com.chronicleapp.chronicle.widget.agendaNavBump
import com.chronicleapp.chronicle.widget.ClassRow
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.Hairline
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.MoreIndicator
import com.chronicleapp.chronicle.widget.Samples
import com.chronicleapp.chronicle.widget.TimeRow
import com.chronicleapp.chronicle.widget.WeekCell
import com.chronicleapp.chronicle.widget.WeekCellView
import com.chronicleapp.chronicle.widget.WidgetHeader
import com.chronicleapp.chronicle.widget.WidgetShell
import com.chronicleapp.chronicle.widget.WidgetSnapshot
import com.chronicleapp.chronicle.widget.int
import com.chronicleapp.chronicle.widget.isNarrowSlot
import com.chronicleapp.chronicle.widget.parseTimeRows
import com.chronicleapp.chronicle.widget.parseWeek
import com.chronicleapp.chronicle.widget.resolvePalette
import com.chronicleapp.chronicle.widget.snapshot
import com.chronicleapp.chronicle.widget.str
import com.chronicleapp.chronicle.widget.widgetSizeSlots

import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin

class TodayAgendaHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    // Responsive slots (widgetSizeSlots): LocalSize is the matched slot's
    // dims, never the window — h>=250 only happens on tall widgets.
    override val sizeMode = widgetSizeSlots

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            // Snapshot-tracked read (see agendaNavBump): pins this
            // composition to the bump so live-session recomposes re-read
            // prefs after day taps instead of replaying captured values.
            @Suppress("unused")
            val navBump = agendaNavBump.intValue
            val prefs = HomeWidgetPlugin.getData(context)
            val prefix = Keys.TODAY_AGENDA
            val snap = prefs.snapshot(prefix)
            val week = parseWeek(prefs.str("$prefix.${Keys.WEEK}"))
            // selectedDay is pushed as 0 on every refresh (reset-to-today
            // contract); a native day tap writes the index until the next push.
            val selRaw = prefs.int("$prefix.${Keys.SELECTED_DAY}", 0)
            val sel = if (week.isEmpty()) 0 else selRaw.coerceIn(0, week.lastIndex)
            val rows = parseTimeRows(prefs.str("$prefix.day$sel"))
            AgendaContent(context, snap, week, sel, rows)
        }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.TODAY_AGENDA)
        provideContent {
            AgendaContent(context, snap, Samples.week, 0, Samples.agenda)
        }
    }

    fun previewFingerprint(context: Context): String {
        val locales = ConfigurationCompat.getLocales(context.resources.configuration)
        val loc = (0 until locales.size()).mapNotNull { locales[it] }.joinToString(",")
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.TODAY_AGENDA)
        return "v2|ag|$loc|${snap.useYou}|${snap.themeCode}"
    }
}

@Composable
private fun AgendaContent(
    context: Context,
    snap: WidgetSnapshot,
    week: List<WeekCell>,
    sel: Int,
    rows: List<TimeRow>,
) {
    val palette = resolvePalette(context, snap.useYou, snap.themeCode)
    val h = LocalSize.current.height
    val emptyCopy = snap.staleName.ifEmpty { snap.emptyText }
    // Sliding day window centered on the selection (wrapping around the
    // week): tapping a side cell steps the selection and the window slides
    // with it — no arrows needed. Narrow slots show 3 cells, wide slots 5
    // (Glance 1.2 ships no LazyRow — verified in the artifact — so a
    // scrolling rail is not possible; this window is the mechanism
    // instead).
    val halfWindow = if (isNarrowSlot()) 1 else 2
    val rail: @Composable (Boolean) -> Unit = { compact ->
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            for (k in -halfWindow..halfWindow) {
                val i = ((sel + k) % week.size + week.size) % week.size
                val cell = week[i]
                WeekCellView(
                    palette = palette,
                    cell = cell,
                    selected = i == sel,
                    modifier = GlanceModifier.defaultWeight(),
                    onClick = actionRunCallback<AgendaDaySelectCallback>(
                        actionParametersOf(AgendaDayKey to i),
                    ),
                    cellHeight = if (compact) 34.dp else if (h >= 170.dp) 48.dp else 40.dp,
                )
            }
        }
    }

    WidgetShell(context, palette, snap.opacity) {
        if (week.isEmpty()) {
            // Stale data: the week was not pushed for today — never show
            // yesterday's plan as if it were current.
            EmptyState(palette, R.drawable.ic_widget_event_available, emptyCopy)
        } else {
            Column {
                if (h >= 250.dp) {
                    WidgetHeader(palette, R.drawable.ic_widget_event, "${week[sel].label} ${week[sel].num}")
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Hairline(palette)
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    rail(false)
                    Spacer(modifier = GlanceModifier.height(6.dp))
                } else if (h >= 170.dp) {
                    // Date-on-top for short sizes (Google Calendar
                    // schedule-widget collapse pattern).
                    Text(
                        text = "${week[sel].label} ${week[sel].num}",
                        style = TextStyle(
                            color = palette.onSurface,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Hairline(palette)
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    rail(false)
                    Spacer(modifier = GlanceModifier.height(6.dp))
                } else {
                    // Shortest strips: content first. A full ClassRow never
                    // fits here (day numbers clip, no info visible), so lead
                    // with a one-line summary of the selected day over the
                    // number rail (weekday rides in the summary since the
                    // cells no longer show it).
                    val first = rows.firstOrNull()
                    Text(
                        text = first?.let { "${week[sel].label} ${week[sel].num} · ${it.time} ${it.name}" } ?: emptyCopy,
                        style = TextStyle(
                            color = palette.onSurface,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    rail(true)
                    Spacer(modifier = GlanceModifier.height(4.dp))
                }
                if (h >= 170.dp) {
                    if (rows.isEmpty()) {
                        EmptyState(palette, R.drawable.ic_widget_event_available, emptyCopy)
                    } else if (h < 250.dp) {
                        // Short tiers: whole rows only (static take + "+N
                        // more") — never a row that cannot be fully seen.
                        // Tall tiers scroll the full list instead.
                        val shown = rows.take(2)
                        for ((i, row) in shown.withIndex()) {
                            if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                            ClassRow(context, palette, row.time, row.name, row.colorHex)
                        }
                        Spacer(modifier = GlanceModifier.height(6.dp))
                        MoreIndicator(palette, rows.size - shown.size)
                    } else {
                        // Scrollable day rows: LazyColumn fills the remaining
                        // space via weight, so every class is reachable at
                        // any widget height — no cap, no "+N more". (A
                        // wrap-content list would measure only its first
                        // item; weight against the bounded shell is what
                        // makes this work — same mechanism as the menu.)
                        // Each item wraps in a Column: multi-root items do
                        // not stack reliably (spacers collapse to zero).
                        LazyColumn(modifier = GlanceModifier.defaultWeight()) {
                            items(rows.size) { i ->
                                Column(modifier = GlanceModifier.fillMaxWidth()) {
                                    if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                                    val row = rows[i]
                                    ClassRow(context, palette, row.time, row.name, row.colorHex)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
