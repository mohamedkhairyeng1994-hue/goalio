package com.goalioApp.fixtures.widget.actions

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.goalioApp.fixtures.widget.GoalioWidget
import com.goalioApp.fixtures.widget.state.PageKeys
import com.goalioApp.fixtures.widget.worker.WidgetUpdateWorker

class RefreshAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        // Mark this instance as refreshing so Header swaps the icon for a spinner.
        updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
            prefs.toMutablePreferences().apply { this[PageKeys.REFRESHING] = true }
        }
        GoalioWidget().update(context, glanceId)

        // Enqueue a worker that asks the backend to scrape before returning.
        // Glance has been observed to fire the same action callback twice in
        // quick succession; enqueueUniqueWork(REPLACE) collapses duplicates to
        // a single in-flight scrape so the spinner eventually resolves.
        WorkManager.getInstance(context).enqueueUniqueWork(
            WidgetUpdateWorker.UNIQUE_REFRESH_WORK,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<WidgetUpdateWorker>()
                .setInputData(workDataOf(WidgetUpdateWorker.KEY_FORCE_SCRAPE to true))
                .build()
        )
    }
}
