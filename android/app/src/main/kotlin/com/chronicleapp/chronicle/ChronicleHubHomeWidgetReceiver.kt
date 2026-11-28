// Hand-maintained Glance widget receiver (arms native 15-min refresh loop
// and bumps hubNavBump so live sessions re-evaluate nowMs).
package com.chronicleapp.chronicle

import android.appwidget.AppWidgetManager
import android.content.Context
import com.chronicleapp.chronicle.widget.WidgetRefreshWorker
import com.chronicleapp.chronicle.widget.hubNavBump
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class ChronicleHubHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ChronicleHubHomeWidget>() {
    override val glanceAppWidget = ChronicleHubHomeWidget()

    override fun previewFingerprint(context: Context): String =
        glanceAppWidget.previewFingerprint(context)

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshWorker.ensureScheduled(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        hubNavBump.intValue++
        WidgetRefreshWorker.ensureScheduled(context)
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
}
