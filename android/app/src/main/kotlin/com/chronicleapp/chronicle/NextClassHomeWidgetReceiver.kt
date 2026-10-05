// GENERATED CODE - DO NOT MODIFY BY HAND
package com.chronicleapp.chronicle

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class NextClassHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<NextClassHomeWidget>() {
  override val glanceAppWidget = NextClassHomeWidget()

  override fun previewFingerprint(context: Context): String =
      glanceAppWidget.previewFingerprint(context)
}
