// GENERATED CODE - DO NOT MODIFY BY HAND
//
// This is a placeholder Glance (Jetpack Compose) widget.
package com.chronicleapp.chronicle

import androidx.compose.runtime.Composable
import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import androidx.glance.LocalSize
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.layout.Column
import androidx.glance.layout.Alignment
import androidx.glance.layout.Row
import androidx.glance.text.TextStyle
import androidx.glance.color.ColorProvider
import androidx.glance.unit.ColorProvider as UnitColorProvider
import androidx.compose.ui.unit.sp
import androidx.glance.text.TextAlign
import androidx.glance.layout.padding
import androidx.glance.GlanceTheme
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.core.os.ConfigurationCompat
import java.util.Locale
import androidx.glance.appwidget.SizeMode
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.action.actionParametersOf
import androidx.glance.layout.size

class TodayAgendaHomeWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override val sizeMode = SizeMode.Responsive(
      setOf(
          DpSize(110.dp, 110.dp),
          DpSize(250.dp, 110.dp),
          DpSize(250.dp, 250.dp),
          DpSize(530.dp, 250.dp),
          DpSize(250.dp, 530.dp),
      )
  )
  override val previewSizeMode = sizeMode

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { WidgetContent(context, currentState()) }
  }

  override suspend fun providePreview(context: Context, widgetCategory: Int) {
    provideContent { WidgetContent(context, HomeWidgetGlanceState(HomeWidgetPlugin.getData(context))) }
  }

  fun previewFingerprint(context: Context): String {
    val hwLocales = hwCurrentLocales(context)
    val hwPreviewData =
        TodayAgendaData.fromPreferences(HomeWidgetPlugin.getData(context))
    return listOf(
      "72bd12ef",
      hwLocales.joinToString(","),
      hwPreviewData.toString(),
    ).joinToString("|")
  }

  @Composable
  private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val widgetData = TodayAgendaData.fromPreferences(prefs)
    // CHRONICLE THEME: theme code pushed by the app (family*2+darkBit).
    // Unknown codes fall back to the generated Glance colors below.
    val themeCode: Int = try { prefs.getInt("home_widget.TodayAgenda.themeBg", 0) } catch (e: ClassCastException) { prefs.getLong("home_widget.TodayAgenda.themeBg", 0L).toInt() }
    val chronicleTriple: Triple<Long, Long, Long>? = when (themeCode) {
      0 -> Triple(0xFFFEF7FF, 0xFF1C1B1F, 0xFF4F6BED)
      1 -> Triple(0xFF131318, 0xFFFFFFFF, 0xFF4F6BED)
      2 -> Triple(0xFFEFF1F5, 0xFF1C1B1F, 0xFFCBA6F7)
      3 -> Triple(0xFF1E1E2E, 0xFFFFFFFF, 0xFFCBA6F7)
      4 -> Triple(0xFFECEFF4, 0xFF1C1B1F, 0xFF88C0D0)
      5 -> Triple(0xFF2E3440, 0xFFFFFFFF, 0xFF88C0D0)
      6 -> Triple(0xFFF8F8F2, 0xFF1C1B1F, 0xFFBD93F9)
      7 -> Triple(0xFF282A36, 0xFFFFFFFF, 0xFFBD93F9)
      8 -> Triple(0xFFFBF1C7, 0xFF1C1B1F, 0xFFFABD2F)
      9 -> Triple(0xFF282828, 0xFFFFFFFF, 0xFFFABD2F)
      10 -> Triple(0xFFD5D6DB, 0xFF1C1B1F, 0xFF7AA2F7)
      11 -> Triple(0xFF1A1B26, 0xFFFFFFFF, 0xFF7AA2F7)
      else -> null
    }
    val chronicleBg: UnitColorProvider? = chronicleTriple?.let { ColorProvider(day = Color(it.first.toInt()), night = Color(it.first.toInt())) }
    val chronicleFg: UnitColorProvider? = chronicleTriple?.let { ColorProvider(day = Color(it.second.toInt()), night = Color(it.second.toInt())) }
    val chronicleAccent: UnitColorProvider? = chronicleTriple?.let { ColorProvider(day = Color(it.third.toInt()), night = Color(it.third.toInt())) }
    val selectedDay: Int = try { prefs.getInt("home_widget.TodayAgenda.selectedDay", -1) } catch (e: ClassCastException) { try { prefs.getLong("home_widget.TodayAgenda.selectedDay", -1L).toInt() } catch (e2: ClassCastException) { -1 } }
    val effectiveDay = if (selectedDay in 0..6) selectedDay else 0

    GlanceTheme {
            Box(modifier = GlanceModifier.background(chronicleBg ?: GlanceTheme.colors.widgetBackground).padding(16.dp).fillMaxSize().clickable(onClick = actionStartActivity<MainActivity>()), contentAlignment = Alignment.TopStart) {
                when (LocalSize.current) {
                    DpSize(250.dp, 110.dp), DpSize(250.dp, 250.dp), DpSize(530.dp, 250.dp), DpSize(250.dp, 530.dp) -> {
                        Column(horizontalAlignment = Alignment.Start) {
                            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                if (widgetData.week.isNullOrEmpty()) {
                                    Text(text = "", style = TextStyle(color = GlanceTheme.colors.onSurface))
                                } else {
                                    val hwItems = widgetData.week.orEmpty().take(7)
                                    hwItems.forEachIndexed { hwIndex, hwItem ->
                                        Box(modifier = GlanceModifier.defaultWeight().clickable(onClick = actionRunCallback<AgendaDaySelectCallback>(actionParametersOf(SelectedDayKey to hwIndex))), contentAlignment = Alignment.Center) {
                                            Text(text = hwItem.label ?: "", style = TextStyle(color = if (hwIndex == effectiveDay) (chronicleAccent ?: (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF)))) else ColorProvider(day = Color(0xFF49454F), night = Color(0xFFCAC4D0)), fontSize = 14.sp, textAlign = TextAlign.Center))
                                        }
                                    }
                                }
                            }
                            Text(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFFCAC4D0), night = Color(0xFF49454F))).fillMaxWidth().height(1.0.dp), text = "", style = TextStyle(color = GlanceTheme.colors.onSurface))
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 0) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day0.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day0.orEmpty().take(4)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 1) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day1.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day1.orEmpty().take(4)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 2) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day2.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day2.orEmpty().take(4)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 3) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day3.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day3.orEmpty().take(4)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 4) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day4.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day4.orEmpty().take(4)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 5) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day5.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day5.orEmpty().take(4)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 6) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day6.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day6.orEmpty().take(4)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else -> {
                        Column(horizontalAlignment = Alignment.Start) {
                            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                if (widgetData.week.isNullOrEmpty()) {
                                    Text(text = "", style = TextStyle(color = GlanceTheme.colors.onSurface))
                                } else {
                                    val hwItems = widgetData.week.orEmpty().take(7)
                                    hwItems.forEachIndexed { hwIndex, hwItem ->
                                        Box(modifier = GlanceModifier.defaultWeight().clickable(onClick = actionRunCallback<AgendaDaySelectCallback>(actionParametersOf(SelectedDayKey to hwIndex))), contentAlignment = Alignment.Center) {
                                            Text(text = hwItem.label ?: "", style = TextStyle(color = if (hwIndex == effectiveDay) (chronicleAccent ?: (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF)))) else ColorProvider(day = Color(0xFF49454F), night = Color(0xFFCAC4D0)), fontSize = 14.sp, textAlign = TextAlign.Center))
                                        }
                                    }
                                }
                            }
                            Text(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFFCAC4D0), night = Color(0xFF49454F))).fillMaxWidth().height(1.0.dp), text = "", style = TextStyle(color = GlanceTheme.colors.onSurface))
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 0) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day0.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day0.orEmpty().take(3)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 1) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day1.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day1.orEmpty().take(3)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 2) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day2.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day2.orEmpty().take(3)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 3) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day3.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day3.orEmpty().take(3)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 4) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day4.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day4.orEmpty().take(3)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 5) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day5.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day5.orEmpty().take(3)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                            Column(modifier = GlanceModifier.padding(top = 12.0.dp), horizontalAlignment = Alignment.Start) {
                                if (effectiveDay != 6) Box(modifier = GlanceModifier.size(0.dp)) {} else if (widgetData.day6.isNullOrEmpty()) {
                                    Text(text = context.getString(R.string.home_widget_today_agenda_t_e3f61d22), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                                } else {
                                    val hwItems = widgetData.day6.orEmpty().take(3)
                                    hwItems.forEachIndexed { _, hwItem ->
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Text(modifier = GlanceModifier.width(40.0.dp), text = hwItem.time ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                                            Text(modifier = GlanceModifier.padding(start = 4.0.dp), text = hwItem.name ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

  }
}

data class TodayAgendaData(
    val themeBg: Long? = null,
    val themeFg: Long? = null,
    val themeAccent: Long? = null,
    val selectedDay: Long? = null,
    val week: List<TodayAgendaWeekItem>? = null,
    val day0: List<TodayAgendaDay0Item>? = null,
    val day1: List<TodayAgendaDay1Item>? = null,
    val day2: List<TodayAgendaDay2Item>? = null,
    val day3: List<TodayAgendaDay3Item>? = null,
    val day4: List<TodayAgendaDay4Item>? = null,
    val day5: List<TodayAgendaDay5Item>? = null,
    val day6: List<TodayAgendaDay6Item>? = null,
) {
    companion object {
        private const val PREFERENCES_PREFIX = "home_widget.TodayAgenda"

        fun fromPreferences(prefs: android.content.SharedPreferences): TodayAgendaData {
            return TodayAgendaData(
                themeBg = if (prefs.contains("${PREFERENCES_PREFIX}.themeBg")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeBg", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeBg", 0L) }) else 0L,
                themeFg = if (prefs.contains("${PREFERENCES_PREFIX}.themeFg")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeFg", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeFg", 0L) }) else 0L,
                themeAccent = if (prefs.contains("${PREFERENCES_PREFIX}.themeAccent")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeAccent", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeAccent", 0L) }) else 0L,
                selectedDay = if (prefs.contains("${PREFERENCES_PREFIX}.selectedDay")) (try { prefs.getInt("${PREFERENCES_PREFIX}.selectedDay", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.selectedDay", 0L) }) else 0L,
                week = TodayAgendaWeekItem.fromPath(prefs.getString("${PREFERENCES_PREFIX}.week", null)),
                day0 = TodayAgendaDay0Item.fromPath(prefs.getString("${PREFERENCES_PREFIX}.day0", null)),
                day1 = TodayAgendaDay1Item.fromPath(prefs.getString("${PREFERENCES_PREFIX}.day1", null)),
                day2 = TodayAgendaDay2Item.fromPath(prefs.getString("${PREFERENCES_PREFIX}.day2", null)),
                day3 = TodayAgendaDay3Item.fromPath(prefs.getString("${PREFERENCES_PREFIX}.day3", null)),
                day4 = TodayAgendaDay4Item.fromPath(prefs.getString("${PREFERENCES_PREFIX}.day4", null)),
                day5 = TodayAgendaDay5Item.fromPath(prefs.getString("${PREFERENCES_PREFIX}.day5", null)),
                day6 = TodayAgendaDay6Item.fromPath(prefs.getString("${PREFERENCES_PREFIX}.day6", null)),
            )
        }
    }
}

data class TodayAgendaWeekItem(
    val label: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaWeekItem>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaWeekItem>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaWeekItem {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaWeekItem(
                label = if (json.has("label") && !json.isNull("label")) json.optString("label") else null,
            )
        }
    }
}

data class TodayAgendaDay0Item(
    val time: String? = null,
    val name: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaDay0Item>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaDay0Item>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaDay0Item {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaDay0Item(
                time = if (json.has("time") && !json.isNull("time")) json.optString("time") else null,
                name = if (json.has("name") && !json.isNull("name")) json.optString("name") else null,
            )
        }
    }
}

data class TodayAgendaDay1Item(
    val time: String? = null,
    val name: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaDay1Item>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaDay1Item>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaDay1Item {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaDay1Item(
                time = if (json.has("time") && !json.isNull("time")) json.optString("time") else null,
                name = if (json.has("name") && !json.isNull("name")) json.optString("name") else null,
            )
        }
    }
}

data class TodayAgendaDay2Item(
    val time: String? = null,
    val name: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaDay2Item>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaDay2Item>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaDay2Item {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaDay2Item(
                time = if (json.has("time") && !json.isNull("time")) json.optString("time") else null,
                name = if (json.has("name") && !json.isNull("name")) json.optString("name") else null,
            )
        }
    }
}

data class TodayAgendaDay3Item(
    val time: String? = null,
    val name: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaDay3Item>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaDay3Item>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaDay3Item {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaDay3Item(
                time = if (json.has("time") && !json.isNull("time")) json.optString("time") else null,
                name = if (json.has("name") && !json.isNull("name")) json.optString("name") else null,
            )
        }
    }
}

data class TodayAgendaDay4Item(
    val time: String? = null,
    val name: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaDay4Item>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaDay4Item>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaDay4Item {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaDay4Item(
                time = if (json.has("time") && !json.isNull("time")) json.optString("time") else null,
                name = if (json.has("name") && !json.isNull("name")) json.optString("name") else null,
            )
        }
    }
}

data class TodayAgendaDay5Item(
    val time: String? = null,
    val name: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaDay5Item>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaDay5Item>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaDay5Item {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaDay5Item(
                time = if (json.has("time") && !json.isNull("time")) json.optString("time") else null,
                name = if (json.has("name") && !json.isNull("name")) json.optString("name") else null,
            )
        }
    }
}

data class TodayAgendaDay6Item(
    val time: String? = null,
    val name: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<TodayAgendaDay6Item>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<TodayAgendaDay6Item>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): TodayAgendaDay6Item {
            val json = obj ?: org.json.JSONObject()
            return TodayAgendaDay6Item(
                time = if (json.has("time") && !json.isNull("time")) json.optString("time") else null,
                name = if (json.has("name") && !json.isNull("name")) json.optString("name") else null,
            )
        }
    }
}


private fun hwCurrentLocales(context: Context): List<String> {
    val configured = ConfigurationCompat
        .getLocales(context.resources.configuration)
    val tags = mutableListOf<String>()
    for (index in 0 until configured.size()) {
        val locale = configured[index] ?: continue
        val tag = locale.toLanguageTag()
        if (tag.isNotEmpty() && tag != "und") tags.add(tag)
    }
    if (tags.isEmpty()) {
        val fallback = Locale.getDefault().toLanguageTag()
        if (fallback.isNotEmpty() && fallback != "und") tags.add(fallback)
    }
    return tags
}

private val SelectedDayKey = ActionParameters.Key<Int>("selectedDay")

class AgendaDaySelectCallback : ActionCallback {
  override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
    val day = parameters[SelectedDayKey] ?: return
    HomeWidgetPlugin.getData(context).edit().putInt("home_widget.TodayAgenda.selectedDay", day).apply()
    TodayAgendaHomeWidget().update(context, glanceId)
  }
}
