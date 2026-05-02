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

class NextPageAction : ActionCallback {

    companion object {
        // Pager passes the current totalPages so we can clamp without having
        // to re-fetch matches inside the action. Without this, repeated taps
        // on the last page bump PAGE past totalPages-1 and provideGlance just
        // coerces it back, making the click look broken.
        val TOTAL_PAGES_KEY = ActionParameters.Key<Int>("total_pages")
    }

    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val total = (parameters[TOTAL_PAGES_KEY] ?: Int.MAX_VALUE).coerceAtLeast(1)
        // Write directly to the MutablePreferences the framework hands us —
        // calling .toMutablePreferences() here would allocate a discarded copy
        // and the persisted state would never change.
        updateAppWidgetState(context, glanceId) { prefs ->
            val current = prefs[PageKeys.PAGE] ?: 0
            prefs[PageKeys.PAGE] = (current + 1).coerceIn(0, total - 1)
        }
        val app = context.applicationContext

        // Fire updateAll on a detached coroutine so it isn't bound to this
        // ActionCallback's broadcast lifetime — that lifetime is the reason
        // direct updateAll inside onAction was getting cancelled before
        // composition completed in earlier attempts.
        CoroutineScope(Dispatchers.Default).launch {
            runCatching { GoalioWidget().updateAll(app) }
        }

        // Belt-and-suspenders: also enqueue the render-only worker. WorkManager
        // schedules it within a few hundred ms and it re-runs updateAll on its
        // own coroutine context, so even if the launch above is no-op'd on
        // some Glance/OEM combos the page still swaps shortly after.
        WorkManager.getInstance(context).enqueueUniqueWork(
            WidgetUpdateWorker.UNIQUE_RENDER_WORK,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<WidgetUpdateWorker>()
                .setInputData(workDataOf(WidgetUpdateWorker.KEY_RENDER_ONLY to true))
                .build()
        )
    }
}
