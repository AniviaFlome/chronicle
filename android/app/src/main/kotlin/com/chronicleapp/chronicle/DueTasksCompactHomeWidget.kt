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
import androidx.glance.layout.Column
import androidx.glance.layout.Alignment
import androidx.glance.text.TextStyle
import androidx.glance.color.ColorProvider
import androidx.glance.unit.ColorProvider as UnitColorProvider
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.text.TextAlign
import androidx.glance.layout.Row
import androidx.core.os.ConfigurationCompat
import java.util.Locale
import androidx.glance.GlanceTheme
import androidx.compose.ui.unit.dp
import androidx.glance.layout.padding
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity

class DueTasksCompactHomeWidget : GlanceAppWidget() {
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
        DueTasksCompactData.fromPreferences(HomeWidgetPlugin.getData(context))
    return listOf(
      "af83e92a",
      hwLocales.joinToString(","),
      hwPreviewData.toString(),
    ).joinToString("|")
  }

  @Composable
  private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val widgetData = DueTasksCompactData.fromPreferences(prefs)
    // CHRONICLE THEME: theme code pushed by the app (family*2+darkBit).
    // Unknown codes fall back to the generated Glance colors below.
    val themeCode: Int = try { prefs.getInt("home_widget.DueTasksCompact.themeBg", 0) } catch (e: ClassCastException) { prefs.getLong("home_widget.DueTasksCompact.themeBg", 0L).toInt() }
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
            Box(modifier = GlanceModifier.background(chronicleBg ?: GlanceTheme.colors.widgetBackground).padding(16.dp).fillMaxSize().clickable(onClick = actionStartActivity<MainActivity>()), contentAlignment = Alignment.TopStart) {
                Column(horizontalAlignment = Alignment.Start) {
                    Text(text = widgetData.headerLine ?: "", style = TextStyle(color = (chronicleAccent ?: ColorProvider(day = Color(0xFF6750A4), night = Color(0xFFD0BCFF))), fontSize = 12.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.Start))
                    Column(horizontalAlignment = Alignment.Start) {
                        if (widgetData.tasks.isNullOrEmpty()) {
                            Text(text = context.getString(R.string.home_widget_due_tasks_compact_t_5c236a5d), style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp, textAlign = TextAlign.Start))
                        } else {
                            val hwItems = widgetData.tasks.orEmpty().take(3)
                            hwItems.forEachIndexed { _, hwItem ->
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(text = hwItem.title ?: "", style = TextStyle(color = (chronicleFg ?: ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFFFFFFF))), fontSize = 14.sp))
                                    Text(text = hwItem.date ?: "", style = TextStyle(color = ColorProvider(day = Color(0xFF49454F), night = Color(0xFFCAC4D0)), fontSize = 12.sp))
                                }
                            }
                        }
                    }
                }
            }
    }

  }
}

data class DueTasksCompactData(
    val themeBg: Long? = null,
    val themeFg: Long? = null,
    val themeAccent: Long? = null,
    val headerLine: String? = null,
    val tasks: List<DueTasksCompactTasksItem>? = null,
) {
    companion object {
        private const val PREFERENCES_PREFIX = "home_widget.DueTasksCompact"

        fun fromPreferences(prefs: android.content.SharedPreferences): DueTasksCompactData {
            return DueTasksCompactData(
                themeBg = if (prefs.contains("${PREFERENCES_PREFIX}.themeBg")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeBg", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeBg", 0L) }) else 0L,
                themeFg = if (prefs.contains("${PREFERENCES_PREFIX}.themeFg")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeFg", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeFg", 0L) }) else 0L,
                themeAccent = if (prefs.contains("${PREFERENCES_PREFIX}.themeAccent")) (try { prefs.getInt("${PREFERENCES_PREFIX}.themeAccent", 0).toLong() } catch (_: ClassCastException) { prefs.getLong("${PREFERENCES_PREFIX}.themeAccent", 0L) }) else 0L,
                headerLine = prefs.getString("${PREFERENCES_PREFIX}.headerLine", "Due tasks"),
                tasks = DueTasksCompactTasksItem.fromPath(prefs.getString("${PREFERENCES_PREFIX}.tasks", null)),
            )
        }
    }
}

data class DueTasksCompactTasksItem(
    val title: String? = null,
    val date: String? = null,
) {
    companion object {
        fun fromPath(path: String?): List<DueTasksCompactTasksItem>? {
            if (path == null) return null
            return try {
                val file = java.io.File(path)
                if (!file.exists()) return null
                fromJsonArray(org.json.JSONArray(file.readText()))
            } catch (_: Exception) {
                null
            }
        }

        fun fromJsonArray(array: org.json.JSONArray?): List<DueTasksCompactTasksItem>? {
            if (array == null) return null
            return List(array.length()) { index -> fromJson(array.optJSONObject(index)) }
        }

        fun fromJson(obj: org.json.JSONObject?): DueTasksCompactTasksItem {
            val json = obj ?: org.json.JSONObject()
            return DueTasksCompactTasksItem(
                title = if (json.has("title") && !json.isNull("title")) json.optString("title") else null,
                date = if (json.has("date") && !json.isNull("date")) json.optString("date") else null,
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
