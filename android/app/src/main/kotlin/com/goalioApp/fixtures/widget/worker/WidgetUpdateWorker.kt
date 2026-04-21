package com.goalioApp.fixtures.widget.worker

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.appwidget.updateAll
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.goalioApp.fixtures.widget.GoalioWidget
import com.goalioApp.fixtures.widget.di.WidgetGraph
import com.goalioApp.fixtures.widget.state.PageKeys

class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val forceScrape = inputData.getBoolean(KEY_FORCE_SCRAPE, false)
        val repo = WidgetGraph.repository(applicationContext)

        val outcome = try {
            repo.refresh(forceScrape = forceScrape)
        } finally {
            // Always clear the spinner — even on failure — so the user can retry.
            clearRefreshingOnAllInstances()
            GoalioWidget().updateAll(applicationContext)
        }

        return if (outcome.isSuccess) Result.success() else Result.retry()
    }

    private suspend fun clearRefreshingOnAllInstances() {
        val manager = GlanceAppWidgetManager(applicationContext)
        manager.getGlanceIds(GoalioWidget::class.java).forEach { id ->
            updateAppWidgetState(applicationContext, PreferencesGlanceStateDefinition, id) { prefs ->
                prefs.toMutablePreferences().apply { this[PageKeys.REFRESHING] = false }
            }
        }
    }

    companion object {
        const val KEY_FORCE_SCRAPE = "force_scrape"
    }
}
