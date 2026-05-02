package com.goalioApp.fixtures.widget.actions

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.appwidget.updateAll
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.goalioApp.fixtures.widget.GoalioWidget
import com.goalioApp.fixtures.widget.state.PageKeys
import com.goalioApp.fixtures.widget.worker.WidgetUpdateWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class PrevPageAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        // See NextPageAction — write to the MutablePreferences passed in;
        // .toMutablePreferences().apply { } targets a copy that gets discarded.
        updateAppWidgetState(context, glanceId) { prefs ->
            val cur = prefs[PageKeys.PAGE] ?: 0
            prefs[PageKeys.PAGE] = (cur - 1).coerceAtLeast(0)
        }
        // Same two-stage refresh as NextPageAction — see comments there.
        val app = context.applicationContext
        CoroutineScope(Dispatchers.Default).launch {
            runCatching { GoalioWidget().updateAll(app) }
        }

        WorkManager.getInstance(context).enqueueUniqueWork(
            WidgetUpdateWorker.UNIQUE_RENDER_WORK,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<WidgetUpdateWorker>()
                .setInputData(workDataOf(WidgetUpdateWorker.KEY_RENDER_ONLY to true))
                .build()
        )
    }
}
