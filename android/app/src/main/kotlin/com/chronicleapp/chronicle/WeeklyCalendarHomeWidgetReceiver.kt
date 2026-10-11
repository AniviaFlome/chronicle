// Hand-maintained receiver (no codegen). Manifest contract: the class
// name is referenced by AndroidManifest.xml and WidgetReceivers.weekly.
package com.chronicleapp.chronicle

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class WeeklyCalendarHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<WeeklyCalendarHomeWidget>() {
    override val glanceAppWidget = WeeklyCalendarHomeWidget()

    override fun previewFingerprint(context: Context): String =
        glanceAppWidget.previewFingerprint(context)
}
