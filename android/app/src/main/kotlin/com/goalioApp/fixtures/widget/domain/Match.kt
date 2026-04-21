package com.goalioApp.fixtures.widget.domain

data class Match(
    val id: String,
    val homeTeam: String,
    val awayTeam: String,
    val homeLogo: String,
    val awayLogo: String,
    val time: String,
    val bucket: Bucket,
    val homeScore: String? = null,
    val awayScore: String? = null,
    val status: String? = null,
) {
    enum class Bucket { YESTERDAY, TODAY, TOMORROW }
}
