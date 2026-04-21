package com.goalioApp.fixtures.widget.di

import android.content.Context
import com.goalioApp.fixtures.widget.data.local.MatchDatabase
import com.goalioApp.fixtures.widget.data.remote.MatchApi
import com.goalioApp.fixtures.widget.data.repository.MatchRepository
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit

object WidgetGraph {
    private const val BASE_URL = "https://goalio.smartoo.site/api/"

    @Volatile private var repo: MatchRepository? = null

    fun repository(context: Context): MatchRepository = repo ?: synchronized(this) {
        repo ?: build(context.applicationContext).also { repo = it }
    }

    private fun build(context: Context): MatchRepository {
        val client = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BASIC
            })
            .build()

        val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()

        val api = Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(client)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
            .create(MatchApi::class.java)

        val dao = MatchDatabase.get(context).matchDao()
        return MatchRepository(api, dao)
    }
}
