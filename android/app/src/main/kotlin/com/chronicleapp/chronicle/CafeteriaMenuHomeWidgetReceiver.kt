// Hand-maintained receiver (no codegen). Manifest contract: the class
// name is referenced by AndroidManifest.xml and WidgetReceivers.menu.
package com.chronicleapp.chronicle

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class CafeteriaMenuHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<CafeteriaMenuHomeWidget>() {
    override val glanceAppWidget = CafeteriaMenuHomeWidget()

    override fun previewFingerprint(context: Context): String =
        glanceAppWidget.previewFingerprint(context)
}
