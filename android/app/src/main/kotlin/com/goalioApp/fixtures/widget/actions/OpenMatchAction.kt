package com.goalioApp.fixtures.widget.actions

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback

class OpenMatchAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val id = parameters[MATCH_ID_KEY] ?: return
        val intent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("goalio://match?id=$id"),
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            setPackage(context.packageName)
        }
        context.startActivity(intent)
    }

    companion object {
        val MATCH_ID_KEY = ActionParameters.Key<String>("match_id")
    }
}
