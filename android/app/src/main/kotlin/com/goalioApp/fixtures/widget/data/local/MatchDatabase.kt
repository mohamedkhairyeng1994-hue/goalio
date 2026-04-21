package com.goalioApp.fixtures.widget.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [CachedMatchEntity::class], version = 1, exportSchema = false)
abstract class MatchDatabase : RoomDatabase() {
    abstract fun matchDao(): MatchDao

    companion object {
        @Volatile private var instance: MatchDatabase? = null

        fun get(context: Context): MatchDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(
                context.applicationContext,
                MatchDatabase::class.java,
                "goalio_widget.db",
            ).fallbackToDestructiveMigration().build().also { instance = it }
        }
    }
}
