package com.goalioApp.fixtures.widget.util

import android.content.Context

object AuthTokenReader {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val TOKEN_KEY = "flutter.auth_token"

    fun read(context: Context): String? {
        val token = context
            .getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .getString(TOKEN_KEY, null)
            ?.trim()
        return token?.takeIf { it.isNotEmpty() }
    }
}
