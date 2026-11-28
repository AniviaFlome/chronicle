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
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.chronicleapp.chronicle.ChronicleHubHomeWidget
import com.chronicleapp.chronicle.NextClassHomeWidget
import java.util.concurrent.TimeUnit

class WidgetRefreshWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val ctx = applicationContext
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
    }
}
