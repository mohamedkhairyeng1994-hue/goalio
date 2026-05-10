package com.goalioApp.fixtures.widget.di

import android.content.Context
import com.goalioApp.fixtures.widget.data.local.MatchDatabase
import com.goalioApp.fixtures.widget.data.remote.MatchApi
import com.goalioApp.fixtures.widget.data.repository.MatchRepository
import com.goalioApp.fixtures.widget.util.AuthTokenReader
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit

object WidgetGraph {
    // Fallback used only if Flutter hasn't pushed the URL yet (e.g. widget
    // added before the app is opened). Matches ApiConstants.authBaseUrl's
    // production branch.
    private const val DEFAULT_BASE_URL = "https://goalio.site/api/"

    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val BASE_URL_KEY  = "flutter.widget_base_url"

    @Volatile private var repo: MatchRepository? = null
    @Volatile private var cachedBaseUrl: String? = null

    fun repository(context: Context): MatchRepository {
        val appContext = context.applicationContext
        val current = resolveBaseUrl(appContext)

        // Rebuild Retrofit when the base URL changes between launches (e.g.
        // dev flips ApiConstants.currentEnvironment from local → production).
        val existing = repo
        if (existing != null && cachedBaseUrl == current) return existing

        return synchronized(this) {
            val again = repo
            if (again != null && cachedBaseUrl == current) return@synchronized again
            build(appContext, current).also {
                repo = it
                cachedBaseUrl = current
            }
        }
    }

    private fun resolveBaseUrl(context: Context): String {
        val raw = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .getString(BASE_URL_KEY, null)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: DEFAULT_BASE_URL
        // Retrofit requires the base URL to end with a slash.
        return if (raw.endsWith("/")) raw else "$raw/"
    }

    private fun build(appContext: Context, baseUrl: String): MatchRepository {
        val client = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .addInterceptor { chain ->
                val token = AuthTokenReader.read(appContext)
                val request = if (token != null) {
                    chain.request().newBuilder()
                        .header("Authorization", "Bearer $token")
                        .header("Accept", "application/json")
                        .build()
                } else {
                    chain.request()
                }
                chain.proceed(request)
            }
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BASIC
            })
            .build()

        val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()

        val api = Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
            .create(MatchApi::class.java)

        val dao = MatchDatabase.get(appContext).matchDao()
        return MatchRepository(api, dao)
    }
}
