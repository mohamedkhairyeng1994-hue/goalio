package com.goalioApp.fixtures.widget.data.remote

import com.goalioApp.fixtures.widget.data.dto.WidgetResponseDto
import retrofit2.http.GET

interface MatchApi {
    @GET("widget/matches")
    suspend fun getWidgetMatches(): WidgetResponseDto
}
