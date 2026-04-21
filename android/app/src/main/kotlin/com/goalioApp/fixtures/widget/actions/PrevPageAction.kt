package com.goalioApp.fixtures.widget.actions

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.appwidget.updateAll
import com.goalioApp.fixtures.widget.GoalioWidget
import com.goalioApp.fixtures.widget.state.PageKeys

class PrevPageAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        updateAppWidgetState(context, glanceId) { prefs ->
            prefs.toMutablePreferences().apply {
                val cur = this[PageKeys.PAGE] ?: 0
                this[PageKeys.PAGE] = (cur - 1).coerceAtLeast(0)
            }
        }
        GoalioWidget().updateAll(context)
    }
}
