// Hub widget configuration activity (tall-portrait companion, NOT a
// Glance widget — normal Android framework views, so android.widget.*
// here does not touch the Glance vertical-flow contract).
//
// Lets the user pick which tabs the Chronicle Hub cycles through (class /
// agenda / tasks / menu). Writes the same tab-flag prefs the Dart push
// maintains (`home_widget.ChronicleHub.tab*`), resets the native-owned
// selectedTab to 0, and re-renders every hub instance. At least one tab
// stays enabled. Declared via android:configure on the hub receiver.
package com.chronicleapp.chronicle

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.glance.appwidget.GlanceAppWidgetManager
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.bool
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class HubConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        setResult(RESULT_CANCELED)

        val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(this)
        val prefix = Keys.HUB
        fun flag(key: String) = prefs.bool("$prefix.$key", true)

        val padding = (16 * resources.displayMetrics.density).toInt()
        val root = ScrollView(this).apply {
            addView(
                LinearLayout(this@HubConfigureActivity).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(padding, padding, padding, padding)
                    addView(
                        TextView(this@HubConfigureActivity).apply {
                            text = "Hub tabs"
                            textSize = 20f
                        },
                    )
                    val boxes = listOf(
                        CheckBox(this@HubConfigureActivity).apply {
                            text = "Next class"
                            isChecked = flag(Keys.TAB_CLASS)
                            tag = Keys.TAB_CLASS
                        },
                        CheckBox(this@HubConfigureActivity).apply {
                            text = "Today's agenda"
                            isChecked = flag(Keys.TAB_AGENDA)
                            tag = Keys.TAB_AGENDA
                        },
                        CheckBox(this@HubConfigureActivity).apply {
                            text = "Due tasks"
                            isChecked = flag(Keys.TAB_TASKS)
                            tag = Keys.TAB_TASKS
                        },
                        CheckBox(this@HubConfigureActivity).apply {
                            text = "Today's menu"
                            isChecked = flag(Keys.TAB_MENU)
                            tag = Keys.TAB_MENU
                        },
                    )
                    for (box in boxes) addView(box)
                    addView(
                        Button(this@HubConfigureActivity).apply {
                            text = "Save"
                            setOnClickListener {
                                val editor = prefs.edit()
                                var anyOn = false
                                for (box in boxes) {
                                    val on = box.isChecked
                                    anyOn = anyOn || on
                                    editor.putBoolean("$prefix.${box.tag}", on)
                                }
                                if (!anyOn) {
                                    // Keep at least one tab: fall back to class.
                                    editor.putBoolean("$prefix.${Keys.TAB_CLASS}", true)
                                }
                                editor.putInt("$prefix.${Keys.SELECTED_TAB}", 0)
                                editor.apply()
                                CoroutineScope(Dispatchers.IO).launch {
                                    runCatching {
                                        val manager = GlanceAppWidgetManager(this@HubConfigureActivity)
                                        val ids = manager.getGlanceIds(ChronicleHubHomeWidget::class.java)
                                        for (id in ids) {
                                            ChronicleHubHomeWidget().update(this@HubConfigureActivity, id)
                                        }
                                    }
                                }
                                val done = Intent().putExtra(
                                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                                    appWidgetId,
                                )
                                setResult(RESULT_OK, done)
                                finish()
                            }
                        },
                    )
                },
            )
        }
        setContentView(root)
    }
}
