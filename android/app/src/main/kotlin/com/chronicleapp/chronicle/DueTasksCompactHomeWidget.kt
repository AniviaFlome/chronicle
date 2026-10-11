// Hand-written Glance widget (Chronicle M3 Expressive redesign). NOT
// generated — edit freely. Wire contract lives in
// com.chronicleapp.chronicle.widget.WidgetData and is mirrored by
// lib/services/widget_push.dart; keep both sides in lockstep.
//
// DueTasksCompact: checklist rows with drawn circular checkboxes, due-date
// tonal chips, and an accent count pill in the consistent header. Urgent
// tasks get a bold title and an error-container chip. Row takes are 2/4/8
// by height.
package com.chronicleapp.chronicle

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.core.os.ConfigurationCompat
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.height
import com.chronicleapp.chronicle.widget.CountPill
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.Hairline
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.Samples
import com.chronicleapp.chronicle.widget.TaskRow
import com.chronicleapp.chronicle.widget.WidgetHeader
import com.chronicleapp.chronicle.widget.WidgetShell
import com.chronicleapp.chronicle.widget.WidgetSnapshot
import com.chronicleapp.chronicle.widget.parseTaskRows
import com.chronicleapp.chronicle.widget.resolvePalette
import com.chronicleapp.chronicle.widget.snapshot
import com.chronicleapp.chronicle.widget.str
import com.chronicleapp.chronicle.widget.widgetSizeSlots

import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin

class DueTasksCompactHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    // Responsive slots (widgetSizeSlots): LocalSize is the matched slot's
    // dims, never the window.
    override val sizeMode = widgetSizeSlots

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = HomeWidgetPlugin.getData(context)
        val prefix = Keys.DUE_TASKS
        val snap = prefs.snapshot(prefix)
        val headerTitle = prefs.str("$prefix.${Keys.HEADER_TITLE}")
        val tasksCount = prefs.str("$prefix.${Keys.TASKS_COUNT}")
        val tasks = parseTaskRows(prefs.str("$prefix.${Keys.TASKS}"))
        provideContent { TasksContent(context, snap, headerTitle, tasksCount, tasks) }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.DUE_TASKS)
        provideContent {
            TasksContent(context, snap, Samples.headerTitle, Samples.tasksCount, Samples.tasks)
        }
    }

    fun previewFingerprint(context: Context): String {
        val locales = ConfigurationCompat.getLocales(context.resources.configuration)
        val loc = (0 until locales.size()).mapNotNull { locales[it] }.joinToString(",")
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.DUE_TASKS)
        return "v2|dt|$loc|${snap.useYou}|${snap.themeCode}"
    }
}

@Composable
private fun TasksContent(
    context: Context,
    snap: WidgetSnapshot,
    headerTitle: String,
    tasksCount: String,
    tasks: List<TaskRow>,
) {
    val palette = resolvePalette(context, snap.useYou, snap.themeCode)
    val h = LocalSize.current.height
    val take = when {
        h >= 380.dp -> 8
        h >= 250.dp -> 4
        h >= 170.dp -> 2
        else -> 1
    }

    WidgetShell(context, palette, snap.opacity) {
        Column {
            WidgetHeader(
                palette = palette,
                iconRes = R.drawable.ic_widget_task,
                title = headerTitle,
                trailing = { CountPill(palette, tasksCount) },
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
            Hairline(palette)
            Spacer(modifier = GlanceModifier.height(6.dp))
            Column {
                if (tasks.isEmpty()) {
                    // "All caught up" — an intentional, reassuring empty state.
                    EmptyState(palette, R.drawable.ic_widget_done_all, snap.emptyText)
                } else {
                    for (task in tasks.take(take)) {
                        TaskRow(palette, task.title, task.date, task.urgent)
                    }
                }
            }
        }
    }
}
