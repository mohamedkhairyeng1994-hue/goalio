package com.goalioApp.fixtures.widget.theme

import androidx.compose.ui.graphics.Color
import com.goalioApp.fixtures.R

object WidgetTheme {
    const val APP_NAME   = "Goalio"
    val APP_LOGO_RES     = R.drawable.ic_widget_logo

    // Goalio brand (from lib/core/constants/constants.dart)
    val ACCENT             = Color(0xFF34D399) // greenAccent
    val ACCENT_ON_SURFACE  = Color(0xFF34D399)
    val ACCENT_SECONDARY   = Color(0xFF3B82F6) // blueAccent

    val SURFACE          = Color(0xFF1E293B) // cardBackground — widget container
    val SURFACE_ELEVATED = Color(0xFF0F172A)
    val PILL             = Color(0xFF0A0F1A) // background — Today / Tomorrow pill
    val TEXT_PRIMARY     = Color(0xFFFFFFFF)
    val TEXT_SECONDARY   = Color(0xFF94A3B8)
    val DIVIDER          = Color(0x1AFFFFFF)
    val LIVE             = Color(0xFFEF4444) // red — live match indicator
}
