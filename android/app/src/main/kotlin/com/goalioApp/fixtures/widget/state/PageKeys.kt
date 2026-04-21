package com.goalioApp.fixtures.widget.state

import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey

object PageKeys {
    val PAGE = intPreferencesKey("page_index")
    val REFRESHING = booleanPreferencesKey("refreshing")
}
