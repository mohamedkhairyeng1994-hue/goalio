package com.goalioApp.fixtures.widget.worker

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.goalioApp.fixtures.widget.GoalioWidget
import com.goalioApp.fixtures.widget.di.WidgetGraph

class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val renderOnly  = inputData.getBoolean(KEY_RENDER_ONLY, false)
        val forceScrape = inputData.getBoolean(KEY_FORCE_SCRAPE, false)

        // Render-only path: triggered by chevron taps. We just need
        // provideGlance to re-run with the already-updated page index in
        // DataStore — no network fetch, no scrape. The action callback's
        // own GoalioWidget().updateAll() has been observed to no-op in this
        // Glance version, but a worker-driven updateAll consistently does.
        if (renderOnly) {
            GoalioWidget().updateAll(applicationContext)
            return Result.success()
        }

        val repo = WidgetGraph.repository(applicationContext)
        val outcome = repo.refresh(forceScrape = forceScrape)
        GoalioWidget().updateAll(applicationContext)
        return if (outcome.isSuccess) Result.success() else Result.retry()
    }

    companion object {
        const val KEY_FORCE_SCRAPE = "force_scrape"
        const val KEY_RENDER_ONLY  = "render_only"
        const val UNIQUE_REFRESH_WORK = "goalio_widget_force_refresh"
        // Separate unique-work lane for pagination so a chevron tap doesn't
        // cancel an in-flight Refresh, and vice versa.
        const val UNIQUE_RENDER_WORK  = "goalio_widget_render_only"
    }
}
