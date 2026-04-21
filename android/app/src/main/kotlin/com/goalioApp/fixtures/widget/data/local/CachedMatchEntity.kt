package com.goalioApp.fixtures.widget.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "cached_matches")
data class CachedMatchEntity(
    @PrimaryKey val id: String,
    val homeTeam: String,
    val awayTeam: String,
    val homeLogo: String,
    val awayLogo: String,
    val time: String,
    val bucket: String,
    val fetchedAt: Long,
    val homeScore: String? = null,
    val awayScore: String? = null,
    val status: String? = null,
)
