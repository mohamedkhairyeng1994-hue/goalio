package com.goalioApp.fixtures.widget.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction

@Dao
interface MatchDao {
    @Query("SELECT * FROM cached_matches ORDER BY bucket ASC, time ASC")
    suspend fun getAll(): List<CachedMatchEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(items: List<CachedMatchEntity>)

    @Query("DELETE FROM cached_matches")
    suspend fun clear()

    @Transaction
    suspend fun replaceAll(items: List<CachedMatchEntity>) {
        clear()
        insertAll(items)
    }
}
