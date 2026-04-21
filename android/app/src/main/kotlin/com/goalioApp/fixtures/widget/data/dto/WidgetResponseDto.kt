package com.goalioApp.fixtures.widget.data.dto

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class WidgetResponseDto(
    @Json(name = "today") val today: List<MatchDto> = emptyList(),
    @Json(name = "tomorrow") val tomorrow: List<MatchDto> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class MatchDto(
    @Json(name = "id") val id: String? = null,
    @Json(name = "home_team") val homeTeam: String,
    @Json(name = "away_team") val awayTeam: String,
    @Json(name = "time") val time: String,
    @Json(name = "home_logo") val homeLogo: String,
    @Json(name = "away_logo") val awayLogo: String,
)
