package com.goalioApp.fixtures.widget.util

import android.content.Context
import android.graphics.Bitmap
import androidx.core.graphics.drawable.toBitmap
import coil.ImageLoader
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
        val result = ImageLoader(context).execute(request)
        (result as? SuccessResult)?.drawable?.toBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    }.getOrNull()
}
