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
        val forceScrape = inputData.getBoolean(KEY_FORCE_SCRAPE, false)
        val repo = WidgetGraph.repository(applicationContext)
        val outcome = repo.refresh(forceScrape = forceScrape)
        GoalioWidget().updateAll(applicationContext)
        return if (outcome.isSuccess) Result.success() else Result.retry()
    }

    companion object {
        const val KEY_FORCE_SCRAPE = "force_scrape"
        const val UNIQUE_REFRESH_WORK = "goalio_widget_force_refresh"
    }
}
