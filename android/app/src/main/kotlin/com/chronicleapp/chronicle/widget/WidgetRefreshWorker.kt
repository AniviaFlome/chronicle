// Native periodic background worker that keeps timeline widgets (NextClass
// and ChronicleHub) ticking without ever launching Flutter or opening the app.
// Re-evaluates the stored multi-day timedData against System.currentTimeMillis()
// every ~15 minutes (Android WorkManager minimum), complementing exact
// class-start / class-end / midnight timeline alarms.
package com.chronicleapp.chronicle.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.chronicleapp.chronicle.CafeteriaMenuHomeWidget
import com.chronicleapp.chronicle.ChronicleHubHomeWidget
import com.chronicleapp.chronicle.DueTasksCompactHomeWidget
import com.chronicleapp.chronicle.NextClassHomeWidget
import com.chronicleapp.chronicle.TodayAgendaHomeWidget
import com.chronicleapp.chronicle.WeeklyCalendarHomeWidget
import java.util.concurrent.TimeUnit

class WidgetRefreshWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val ctx = applicationContext
        val refreshAll = inputData.getBoolean(KEY_REFRESH_ALL, false)
        if (refreshAll) {
            nextClassNavBump.intValue++
            hubNavBump.intValue++
            agendaNavBump.intValue++
            menuNavBump.intValue++
            runCatching { NextClassHomeWidget().updateAll(ctx) }
            runCatching { ChronicleHubHomeWidget().updateAll(ctx) }
            runCatching { CafeteriaMenuHomeWidget().updateAll(ctx) }
            runCatching { TodayAgendaHomeWidget().updateAll(ctx) }
            runCatching { DueTasksCompactHomeWidget().updateAll(ctx) }
            runCatching { WeeklyCalendarHomeWidget().updateAll(ctx) }
            return Result.success()
        }

        val manager = GlanceAppWidgetManager(ctx)
        val nextIds = runCatching {
            manager.getGlanceIds(NextClassHomeWidget::class.java)
        }.getOrDefault(emptyList())
        val hubIds = runCatching {
            manager.getGlanceIds(ChronicleHubHomeWidget::class.java)
        }.getOrDefault(emptyList())

        if (nextIds.isEmpty() && hubIds.isEmpty()) {
            WorkManager.getInstance(ctx).cancelUniqueWork(WORK_NAME)
            return Result.success()
        }

        if (nextIds.isNotEmpty()) {
            nextClassNavBump.intValue++
            runCatching { NextClassHomeWidget().updateAll(ctx) }
        }
        if (hubIds.isNotEmpty()) {
            hubNavBump.intValue++
            runCatching { ChronicleHubHomeWidget().updateAll(ctx) }
        }
        return Result.success()
    }

    companion object {
        const val WORK_NAME = "chronicle_widget_refresh"
        private const val ONE_SHOT_NAME = "chronicle_widget_refresh_all_once"
        private const val KEY_REFRESH_ALL = "refreshAll"

        /**
         * Ensures the 15-minute native refresh loop is armed. Safe to call
         * repeatedly from widget receivers (`KEEP` leaves an existing
         * schedule untouched without resetting its timer).
         */
        fun ensureScheduled(context: Context) {
            runCatching {
                val request = PeriodicWorkRequestBuilder<WidgetRefreshWorker>(
                    15,
                    TimeUnit.MINUTES,
                ).build()
                WorkManager.getInstance(context.applicationContext)
                    .enqueueUniquePeriodicWork(
                        WORK_NAME,
                        ExistingPeriodicWorkPolicy.KEEP,
                        request,
                    )
            }
        }

        /** Re-renders all 6 widgets immediately (e.g. after APK upgrade / boot). */
        fun refreshAllNow(context: Context) {
            runCatching {
                val data = androidx.work.Data.Builder()
                    .putBoolean(KEY_REFRESH_ALL, true)
                    .build()
                val req = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
                    .setInputData(data)
                    .build()
                WorkManager.getInstance(context.applicationContext)
                    .enqueueUniqueWork(ONE_SHOT_NAME, ExistingWorkPolicy.REPLACE, req)
            }
        }
    }
}
