package com.goalioApp.fixtures.widget

import com.goalioApp.fixtures.widget.domain.Match

sealed interface WidgetUiState {
    data object Loading : WidgetUiState
    data class Content(val matches: List<Match>) : WidgetUiState
    data class Error(val message: String) : WidgetUiState
}
