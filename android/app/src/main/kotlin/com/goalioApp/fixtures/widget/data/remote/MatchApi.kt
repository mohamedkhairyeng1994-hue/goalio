package com.goalioApp.fixtures.widget.data.remote

import com.goalioApp.fixtures.widget.data.dto.WidgetResponseDto
import retrofit2.http.GET
import retrofit2.http.Query

interface MatchApi {
    @GET("widget/matches")
    suspend fun getWidgetMatches(@Query("refresh") refresh: Int? = null): WidgetResponseDto
}
