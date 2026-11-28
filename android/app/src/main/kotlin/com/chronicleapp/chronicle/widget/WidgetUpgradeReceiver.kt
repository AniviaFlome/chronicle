// Re-renders all Chronicle home widgets and re-arms the periodic refresh loop
// right after an APK upgrade or device reboot so users immediately see updated
// widget layouts without needing to open the app or re-add widgets.
package com.chronicleapp.chronicle.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetUpgradeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == Intent.ACTION_BOOT_COMPLETED
        ) {
            WidgetRefreshWorker.ensureScheduled(context)
            WidgetRefreshWorker.refreshAllNow(context)
        }
    }
}
