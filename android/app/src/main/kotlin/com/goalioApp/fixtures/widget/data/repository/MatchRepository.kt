package com.goalioApp.fixtures.widget.data.repository

import com.goalioApp.fixtures.widget.data.local.MatchDao
import com.goalioApp.fixtures.widget.data.mapper.toDomain
import com.goalioApp.fixtures.widget.data.mapper.toEntity
import com.goalioApp.fixtures.widget.data.remote.MatchApi
import com.goalioApp.fixtures.widget.domain.Match
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class MatchRepository(
    private val api: MatchApi,
    private val dao: MatchDao,
) {
    data class Snapshot(val matches: List<Match>, val hasFavorites: Boolean)

    suspend fun refresh(forceScrape: Boolean = false): Result<Snapshot> = withContext(Dispatchers.IO) {
        runCatching {
            val resp = api.getWidgetMatches(refresh = if (forceScrape) 1 else null)
            val domain = resp.yesterday.map { it.toDomain(Match.Bucket.YESTERDAY) } +
                    resp.today.map { it.toDomain(Match.Bucket.TODAY) } +
                    resp.tomorrow.map { it.toDomain(Match.Bucket.TOMORROW) }
            val now = System.currentTimeMillis()
            dao.replaceAll(domain.map { it.toEntity(now) })
            Snapshot(domain, resp.hasFavorites)
        }
    }

    suspend fun cached(): List<Match> = withContext(Dispatchers.IO) {
        dao.getAll().map { it.toDomain() }
    }
}
