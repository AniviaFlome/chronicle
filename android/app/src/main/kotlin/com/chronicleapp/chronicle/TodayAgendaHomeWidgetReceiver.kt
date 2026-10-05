// GENERATED CODE - DO NOT MODIFY BY HAND
package com.chronicleapp.chronicle

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class TodayAgendaHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodayAgendaHomeWidget>() {
  override val glanceAppWidget = TodayAgendaHomeWidget()

  override fun previewFingerprint(context: Context): String =
      glanceAppWidget.previewFingerprint(context)
}
