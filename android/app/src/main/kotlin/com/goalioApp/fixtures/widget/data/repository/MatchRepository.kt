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
    suspend fun refresh(): Result<List<Match>> = withContext(Dispatchers.IO) {
        runCatching {
            val resp = api.getWidgetMatches()
            val domain = resp.today.map { it.toDomain(Match.Bucket.TODAY) } +
                    resp.tomorrow.map { it.toDomain(Match.Bucket.TOMORROW) }
            val now = System.currentTimeMillis()
            dao.replaceAll(domain.map { it.toEntity(now) })
            domain
        }
    }

    suspend fun cached(): List<Match> = withContext(Dispatchers.IO) {
        dao.getAll().map { it.toDomain() }
    }
}
