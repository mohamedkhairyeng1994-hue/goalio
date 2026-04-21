package com.goalioApp.fixtures.widget.actions

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.goalioApp.fixtures.widget.worker.WidgetUpdateWorker

class RefreshAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        // Glance has been observed to fire the same action callback twice in
        // quick succession; enqueueUniqueWork(REPLACE) collapses duplicates to
        // a single in-flight scrape.
        WorkManager.getInstance(context).enqueueUniqueWork(
            WidgetUpdateWorker.UNIQUE_REFRESH_WORK,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<WidgetUpdateWorker>()
                .setInputData(workDataOf(WidgetUpdateWorker.KEY_FORCE_SCRAPE to true))
                .build()
        )
    }
}
