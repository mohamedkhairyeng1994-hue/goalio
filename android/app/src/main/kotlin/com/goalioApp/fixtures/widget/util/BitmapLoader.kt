package com.goalioApp.fixtures.widget.util

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import androidx.core.graphics.drawable.toBitmap
import coil.ImageLoader
import coil.request.ErrorResult
import coil.request.ImageRequest
import coil.request.SuccessResult

suspend fun loadBitmap(context: Context, url: String, sizePx: Int = 96): Bitmap? {
    if (url.isBlank()) return null
    return runCatching {
        val request = ImageRequest.Builder(context)
            .data(url)
            .size(sizePx)
            .allowHardware(false)
            .build()
        when (val result = ImageLoader(context).execute(request)) {
            is SuccessResult -> result.drawable.toBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
            is ErrorResult -> {
                Log.w("BitmapLoader", "Failed $url: ${result.throwable.message}")
                null
            }
        }
    }.onFailure { Log.w("BitmapLoader", "Exception $url: ${it.message}") }
        .getOrNull()
}
