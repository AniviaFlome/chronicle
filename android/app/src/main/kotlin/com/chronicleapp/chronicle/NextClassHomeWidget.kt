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
import androidx.glance.layout.Row
import androidx.glance.layout.Alignment
import androidx.glance.layout.width
import androidx.compose.ui.unit.dp
import androidx.glance.layout.fillMaxHeight
import androidx.glance.appwidget.cornerRadius
import androidx.glance.text.TextStyle
import androidx.glance.GlanceTheme
import androidx.glance.layout.Column
import androidx.glance.color.ColorProvider
import androidx.glance.unit.ColorProvider as UnitColorProvider
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.text.TextAlign
import androidx.glance.layout.padding
import androidx.core.os.ConfigurationCompat
import java.util.Locale
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity

class NextClassHomeWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { WidgetContent(context, currentState()) }
  }

  override suspend fun providePreview(context: Context, widgetCategory: Int) {
    provideContent { WidgetContent(context, HomeWidgetGlanceState(HomeWidgetPlugin.getData(context))) }
  }

  fun previewFingerprint(context: Context): String {
    val hwLocales = hwCurrentLocales(context)
    val hwPreviewData =
        NextClassData.fromPreferences(HomeWidgetPlugin.getData(context))
    return listOf(
      "4402aa66",
      hwLocales.joinToString(","),
      hwPreviewData.toString(),
    ).joinToString("|")
  }

  @Composable
  private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val widgetData = NextClassData.fromPreferences(prefs)
    // CHRONICLE THEME: theme code pushed by the app (family*2+darkBit).
    // Unknown codes fall back to the generated Glance colors below.
    val themeCode: Int = try { prefs.getInt("home_widget.NextClass.themeBg", 0) } catch (e: ClassCastException) { prefs.getLong("home_widget.NextClass.themeBg", 0L).toInt() }
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

    GlanceTheme {
            Box(modifier = GlanceModifier.background(chronicleBg ?: GlanceTheme.colors.widgetBackground).fillMaxSize().clickable(onClick = actionStartActivity<MainActivity>()), contentAlignment = Alignment.TopStart) {
                Row(modifier = GlanceModifier.fillMaxSize(), verticalAlignment = Alignment.Top) {
                    // Flush with the card's left edge (no padding gap).
                    Box(modifier = GlanceModifier.background((chronicleAccent ?: ColorProvider(day = Color(0xFF4F6BED), night = Color(0xFF4F6BED)))).width(6.0.dp).fillMaxHeight()) {}
                    Column(modifier = GlanceModifier.padding(start = 28.0.dp, top = 16.0.dp, end = 16.0.dp, bottom = 16.0.dp), horizontalAlignment = Alignment.Start) {
                        Text(text = context.getString(R.string.home_widget_next_class_t_fb138ae6), style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.Start))
                        Text(text = widgetData.className ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 20.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Start))
                        Text(text = widgetData.detailLine ?: "", style = TextStyle(color = ColorProvider(day = Color(0xFF49454F), night = Color(0xFFCAC4D0)), fontSize = 12.sp, textAlign = TextAlign.Start))
                        Text(text = widgetData.thenLine ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, textAlign = TextAlign.Start))
                    }
                }
            }
    }

  }
}

data class NextClassData(
    val themeBg: Long? = null,
    val themeFg: Long? = null,
    val themeAccent: Long? = null,
    val className: String? = null,
    val detailLine: String? = null,
    val thenLine: String? = null,
) {
    companion object {
        private const val PREFERENCES_PREFIX = "home_widget.NextClass"

        fun fromPreferences(prefs: android.content.SharedPreferences, now: Long = System.currentTimeMillis()): NextClassData {
            val timedValues = resolveTimedValues(prefs, now)
            return NextClassData(
                themeBg = if (prefs.contains("${PREFERENCES_PREFIX}.themeBg")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeBg", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeBg", 0L) }) else 0L,
                themeFg = if (prefs.contains("${PREFERENCES_PREFIX}.themeFg")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeFg", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeFg", 0L) }) else 0L,
                themeAccent = if (prefs.contains("${PREFERENCES_PREFIX}.themeAccent")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeAccent", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeAccent", 0L) }) else 0L,
                className = if (timedValues.has("className") && !timedValues.isNull("className")) timedValues.optString("className") else "—",
                detailLine = if (timedValues.has("detailLine") && !timedValues.isNull("detailLine")) timedValues.optString("detailLine") else "",
                thenLine = if (timedValues.has("thenLine") && !timedValues.isNull("thenLine")) timedValues.optString("thenLine") else "",
            )
        }

        private fun resolveTimedValues(prefs: android.content.SharedPreferences, now: Long): org.json.JSONObject {
            val path = prefs.getString("${PREFERENCES_PREFIX}.timedData", null) ?: return org.json.JSONObject()
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return org.json.JSONObject()
                val json = org.json.JSONObject(file.readText())
                var activeKey: String? = null
                var activeTimestamp = 0L
                val keys = json.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val timestamp = key.toLongOrNull() ?: continue
                    if (timestamp <= now && (activeKey == null || timestamp > activeTimestamp)) {
                        activeKey = key
                        activeTimestamp = timestamp
                    }
                }
                val resolvedKey = activeKey ?: return org.json.JSONObject()
                json.optJSONObject(resolvedKey) ?: org.json.JSONObject()
            } catch (_: Exception) {
                org.json.JSONObject()
            }
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
