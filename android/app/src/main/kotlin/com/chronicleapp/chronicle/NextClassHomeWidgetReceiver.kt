// Hand-maintained Glance widget receiver (arms native 15-min refresh loop
// and bumps nextClassNavBump so live sessions re-evaluate nowMs).
package com.chronicleapp.chronicle

import android.appwidget.AppWidgetManager
import android.content.Context
import com.chronicleapp.chronicle.widget.WidgetRefreshWorker
import com.chronicleapp.chronicle.widget.nextClassNavBump
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class NextClassHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<NextClassHomeWidget>() {
    override val glanceAppWidget = NextClassHomeWidget()

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
        nextClassNavBump.intValue++
        WidgetRefreshWorker.ensureScheduled(context)
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
}
