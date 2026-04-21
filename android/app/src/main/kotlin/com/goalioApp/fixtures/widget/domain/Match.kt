package com.goalioApp.fixtures.widget.domain

data class Match(
    val id: String,
    val homeTeam: String,
    val awayTeam: String,
    val homeLogo: String,
    val awayLogo: String,
    val time: String,
    val bucket: Bucket,
) {
    enum class Bucket { TODAY, TOMORROW }
}
