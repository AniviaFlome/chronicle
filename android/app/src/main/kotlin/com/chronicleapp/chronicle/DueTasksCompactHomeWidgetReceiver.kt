// GENERATED CODE - DO NOT MODIFY BY HAND
package com.chronicleapp.chronicle

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class DueTasksCompactHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<DueTasksCompactHomeWidget>() {
  override val glanceAppWidget = DueTasksCompactHomeWidget()

  override fun previewFingerprint(context: Context): String =
      glanceAppWidget.previewFingerprint(context)
}
