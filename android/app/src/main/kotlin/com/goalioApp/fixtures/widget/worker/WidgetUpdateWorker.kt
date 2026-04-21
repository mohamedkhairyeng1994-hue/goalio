package com.goalioApp.fixtures.widget.worker

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
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
            // Always clear the spinner and force a re-render — even on failure —
            // so the user can retry. Writing REFRESHING=false *and* explicitly
            // calling update() per-instance is belt-and-suspenders: updateAll
            // alone has been seen to not re-trigger provideGlance reliably.
            runCatching { clearRefreshingAndRerender() }
                .onFailure { Log.e(TAG, "post-refresh UI update failed", it) }
        }

        return if (outcome.isSuccess) Result.success() else Result.retry()
    }

    private suspend fun clearRefreshingAndRerender() {
        val manager = GlanceAppWidgetManager(applicationContext)
        val ids = manager.getGlanceIds(GoalioWidget::class.java)
        for (id in ids) {
            updateAppWidgetState(applicationContext, PreferencesGlanceStateDefinition, id) { prefs ->
                prefs.toMutablePreferences().apply { this[PageKeys.REFRESHING] = false }
            }
            GoalioWidget().update(applicationContext, id)
        }
        Log.i(TAG, "refreshed ${ids.size} widget instance(s)")
    }

    companion object {
        private const val TAG = "WidgetUpdateWorker"
        const val KEY_FORCE_SCRAPE = "force_scrape"
        const val UNIQUE_REFRESH_WORK = "goalio_widget_force_refresh"
    }
}
