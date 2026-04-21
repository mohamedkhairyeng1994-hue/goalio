package com.goalioApp.fixtures.widget.data.mapper

import com.goalioApp.fixtures.widget.data.dto.MatchDto
import com.goalioApp.fixtures.widget.data.local.CachedMatchEntity
import com.goalioApp.fixtures.widget.domain.Match

fun MatchDto.toDomain(bucket: Match.Bucket): Match = Match(
    id = id ?: "${homeTeam}_${awayTeam}_${time}_${bucket.name}",
    homeTeam = homeTeam,
    awayTeam = awayTeam,
    homeLogo = homeLogo,
    awayLogo = awayLogo,
    time = time,
    bucket = bucket,
    homeScore = homeScore,
    awayScore = awayScore,
    status = status,
)

fun Match.toEntity(fetchedAt: Long) = CachedMatchEntity(
    id = id,
    homeTeam = homeTeam,
    awayTeam = awayTeam,
    homeLogo = homeLogo,
    awayLogo = awayLogo,
    time = time,
    bucket = bucket.name,
    fetchedAt = fetchedAt,
    homeScore = homeScore,
    awayScore = awayScore,
    status = status,
)

fun CachedMatchEntity.toDomain() = Match(
    id = id,
    homeTeam = homeTeam,
    awayTeam = awayTeam,
    homeLogo = homeLogo,
    awayLogo = awayLogo,
    time = time,
    bucket = Match.Bucket.valueOf(bucket),
    homeScore = homeScore,
    awayScore = awayScore,
    status = status,
)
