package com.goalioApp.fixtures.widget

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.LocalContext
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.getAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.goalioApp.fixtures.R
import com.goalioApp.fixtures.widget.actions.NextPageAction
import com.goalioApp.fixtures.widget.actions.OpenMatchAction
import com.goalioApp.fixtures.widget.actions.PrevPageAction
import com.goalioApp.fixtures.widget.actions.RefreshAction
import com.goalioApp.fixtures.widget.di.WidgetGraph
import com.goalioApp.fixtures.widget.domain.Match
import com.goalioApp.fixtures.widget.state.PageKeys
import com.goalioApp.fixtures.widget.theme.WidgetTheme
import com.goalioApp.fixtures.widget.util.loadBitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope

class GoalioWidget : GlanceAppWidget() {

    override val stateDefinition = PreferencesGlanceStateDefinition

    override val sizeMode = SizeMode.Responsive(
        setOf(
            androidx.compose.ui.unit.DpSize(180.dp, 220.dp),
            androidx.compose.ui.unit.DpSize(260.dp, 280.dp),
            androidx.compose.ui.unit.DpSize(320.dp, 360.dp),
        )
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val repo = WidgetGraph.repository(context)
        val page: Int = runCatching {
            getAppWidgetState(context, PreferencesGlanceStateDefinition, id)[PageKeys.PAGE] ?: 0
        }.getOrDefault(0)

        val cached = runCatching { repo.cached() }.getOrDefault(emptyList())

        val state: WidgetUiState = runCatching {
            repo.refresh().fold(
                onSuccess = { snapshot ->
                    if (!snapshot.hasFavorites) WidgetUiState.NoFavorites
                    else WidgetUiState.Content(snapshot.matches)
                },
                onFailure = {
                    android.util.Log.e(TAG, "refresh failed", it)
                    if (cached.isNotEmpty()) WidgetUiState.Content(cached)
                    else WidgetUiState.Error(it.message ?: "Failed to load")
                }
            )
        }.getOrElse {
            android.util.Log.e(TAG, "provideGlance failed", it)
            if (cached.isNotEmpty()) WidgetUiState.Content(cached)
            else WidgetUiState.Error(it.message ?: it::class.simpleName ?: "Unknown")
        }

        val matches = (state as? WidgetUiState.Content)?.matches.orEmpty()
        val logos = runCatching { preloadLogos(context, matches) }
            .onFailure { android.util.Log.e(TAG, "preloadLogos crashed", it) }
            .getOrDefault(emptyMap())

        provideContent { Root(state, logos, page) }
    }

    companion object { private const val TAG = "GoalioWidget" }

    private suspend fun preloadLogos(context: Context, matches: List<Match>) = coroutineScope {
        matches.flatMap { listOf(it.homeLogo, it.awayLogo) }
            .distinct()
            .map { url -> async(Dispatchers.IO) { url to loadBitmap(context, url, 96) } }
            .awaitAll()
            .mapNotNull { (url, bmp) -> bmp?.let { url to it } }
            .toMap()
    }
}

/* ------------------------------ Composables ------------------------------ */

@Composable
private fun Root(state: WidgetUiState, logos: Map<String, Bitmap>, page: Int) {
    val openAppIntent = Intent(Intent.ACTION_VIEW, Uri.parse("goalio://home")).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .cornerRadius(24.dp)
            .background(WidgetTheme.SURFACE)
            .padding(horizontal = 14.dp, vertical = 12.dp)
            .clickable(actionStartActivity(openAppIntent))
    ) {
        Header()
        Spacer(GlanceModifier.height(12.dp))

        when (state) {
            is WidgetUiState.Loading -> LoadingBody()
            is WidgetUiState.NoFavorites -> NoFavoritesBody()
            is WidgetUiState.Error   -> ErrorBody(state.message)
            is WidgetUiState.Content -> {
                val yesterday = state.matches.filter { it.bucket == Match.Bucket.YESTERDAY }
                val today     = state.matches.filter { it.bucket == Match.Bucket.TODAY }
                val tomorrow  = state.matches.filter { it.bucket == Match.Bucket.TOMORROW }
                val pageSize = 2
                val totalPages = maxOf(
                    ceilDiv(yesterday.size, pageSize),
                    maxOf(
                        ceilDiv(today.size, pageSize),
                        ceilDiv(tomorrow.size, pageSize),
                    ),
                ).coerceAtLeast(1)
                val safe = page.coerceIn(0, totalPages - 1)

                Sections(
                    yesterday = yesterday.pageSlice(safe, pageSize),
                    today = today.pageSlice(safe, pageSize),
                    tomorrow = tomorrow.pageSlice(safe, pageSize),
                    logos = logos,
                )
                Spacer(GlanceModifier.defaultWeight())
                Pager(safe + 1, totalPages)
            }
        }
    }
}

@Composable
private fun Header() {
    val titleStyle = TextStyle(
        color = ColorProvider(WidgetTheme.TEXT_PRIMARY),
        fontWeight = FontWeight.Bold,
        fontSize = 16.sp,
    )
    val refreshAffordance: @Composable () -> Unit = {
        Image(
            provider = ImageProvider(R.drawable.ic_widget_refresh),
            contentDescription = "Refresh",
            colorFilter = ColorFilter.tint(ColorProvider(WidgetTheme.ACCENT)),
            modifier = GlanceModifier
                .size(22.dp)
                .clickable(actionRunCallback<RefreshAction>()),
        )
    }

    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Glance reverses child order under RTL; emit in reverse there so the
        // final pixel layout is always logo-left, title-hugs-logo, refresh-right.
        if (isRtl()) {
            refreshAffordance()
            Spacer(GlanceModifier.defaultWeight())
            Text(WidgetTheme.APP_NAME, style = titleStyle)
            Spacer(GlanceModifier.width(8.dp))
            Image(
                provider = ImageProvider(WidgetTheme.APP_LOGO_RES),
                contentDescription = WidgetTheme.APP_NAME,
                modifier = GlanceModifier.size(24.dp).cornerRadius(6.dp),
            )
        } else {
            Image(
                provider = ImageProvider(WidgetTheme.APP_LOGO_RES),
                contentDescription = WidgetTheme.APP_NAME,
                modifier = GlanceModifier.size(24.dp).cornerRadius(6.dp),
            )
            Spacer(GlanceModifier.width(8.dp))
            Text(WidgetTheme.APP_NAME, style = titleStyle)
            Spacer(GlanceModifier.defaultWeight())
            refreshAffordance()
        }
    }
}

@Composable
private fun isRtl(): Boolean =
    LocalContext.current.resources.configuration.layoutDirection == View.LAYOUT_DIRECTION_RTL

@Composable
private fun Sections(
    yesterday: List<Match>,
    today: List<Match>,
    tomorrow: List<Match>,
    logos: Map<String, Bitmap>,
) {
    if (yesterday.isNotEmpty()) {
        SectionPill("Yesterday")
        yesterday.forEach { MatchRow(it, logos) }
        Spacer(GlanceModifier.height(10.dp))
    }

    SectionPill("Today")
    if (today.isEmpty()) EmptyRow("No matches today")
    else today.forEach { MatchRow(it, logos) }

    Spacer(GlanceModifier.height(10.dp))

    SectionPill("Tomorrow")
    if (tomorrow.isEmpty()) EmptyRow("No matches tomorrow")
    else tomorrow.forEach { MatchRow(it, logos) }
}

@Composable
private fun SectionPill(label: String) {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .cornerRadius(20.dp)
            .background(WidgetTheme.PILL)
            .padding(vertical = 6.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            style = TextStyle(
                color = ColorProvider(WidgetTheme.TEXT_PRIMARY),
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
            ),
        )
    }
}

@Composable
private fun MatchRow(match: Match, logos: Map<String, Bitmap>) {
    val rtl = isRtl()
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(vertical = 10.dp)
            .clickable(
                actionRunCallback<OpenMatchAction>(
                    actionParametersOf(OpenMatchAction.MATCH_ID_KEY to match.id)
                )
            ),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // In RTL, Glance reverses the row children AND flips Alignment.Start/End,
        // so we reverse emission order AND flip `alignEnd` to keep the home team
        // visually on the left (left-aligned) and away on the right (right-aligned).
        if (rtl) {
            TeamSide(
                name = match.awayTeam,
                logo = logos[match.awayLogo],
                modifier = GlanceModifier.defaultWeight(),
                alignEnd = false,
            )
            CenterTime(match)
            TeamSide(
                name = match.homeTeam,
                logo = logos[match.homeLogo],
                modifier = GlanceModifier.defaultWeight(),
                alignEnd = true,
            )
        } else {
            TeamSide(
                name = match.homeTeam,
                logo = logos[match.homeLogo],
                modifier = GlanceModifier.defaultWeight(),
                alignEnd = false,
            )
            CenterTime(match)
            TeamSide(
                name = match.awayTeam,
                logo = logos[match.awayLogo],
                modifier = GlanceModifier.defaultWeight(),
                alignEnd = true,
            )
        }
    }
}

@Composable
private fun TeamSide(
    name: String,
    logo: Bitmap?,
    modifier: GlanceModifier,
    alignEnd: Boolean,
) {
    Column(
        modifier = modifier,
        horizontalAlignment = if (alignEnd) Alignment.End else Alignment.Start,
    ) {
        if (logo != null) {
            Image(
                provider = ImageProvider(logo),
                contentDescription = name,
                modifier = GlanceModifier.size(28.dp),
            )
        } else {
            Box(
                modifier = GlanceModifier
                    .size(28.dp)
                    .cornerRadius(14.dp)
                    .background(WidgetTheme.DIVIDER),
            ) {}
        }
        Spacer(GlanceModifier.height(4.dp))
        Text(
            name,
            maxLines = 1,
            style = TextStyle(
                color = ColorProvider(WidgetTheme.TEXT_SECONDARY),
                fontSize = 12.sp,
                textAlign = if (alignEnd) TextAlign.End else TextAlign.Start,
            ),
        )
    }
}

@Composable
private fun CenterTime(match: Match) {
    val hasScore = match.homeScore != null && match.awayScore != null
    val isLive = isLive(match.status)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = GlanceModifier.padding(horizontal = 8.dp),
    ) {
        if (hasScore) {
            val scoreColor = if (isLive) WidgetTheme.LIVE else WidgetTheme.TEXT_PRIMARY
            // ‎ = LEFT-TO-RIGHT MARK. Forces the "home - away" order on the
            // text even inside an RTL paragraph; without it the numbers flip.
            Text(
                "‎${match.homeScore} - ${match.awayScore}",
                style = TextStyle(
                    color = ColorProvider(scoreColor),
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                ),
            )
            Spacer(GlanceModifier.height(4.dp))
            if (isLive) {
                Text(
                    "‎" + match.time.ifBlank { match.status ?: "Live" },
                    style = TextStyle(
                        color = ColorProvider(WidgetTheme.LIVE),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
            } else {
                Text(
                    match.status ?: "FT",
                    style = TextStyle(
                        color = ColorProvider(WidgetTheme.TEXT_SECONDARY),
                        fontSize = 10.sp,
                    ),
                )
            }
        } else {
            Text(
                "‎" + match.time,
                style = TextStyle(
                    color = ColorProvider(WidgetTheme.TEXT_PRIMARY),
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                ),
            )
            Spacer(GlanceModifier.height(4.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Image(
                    provider = ImageProvider(R.drawable.ic_widget_ball),
                    contentDescription = null,
                    modifier = GlanceModifier.size(12.dp),
                )
                Spacer(GlanceModifier.width(4.dp))
                Text(
                    "-",
                    style = TextStyle(
                        color = ColorProvider(WidgetTheme.TEXT_SECONDARY),
                        fontSize = 11.sp,
                    ),
                )
            }
        }
    }
}

private fun isLive(status: String?): Boolean {
    val s = status?.lowercase()?.trim() ?: return false
    // Common "match in progress" statuses from the scraper. "ht" (half-time) and
    // "live" both count as live for the red-minute treatment.
    return s == "live" || s == "ht" || s == "1h" || s == "2h" ||
            s == "in_play" || s == "playing" || s == "inplay" || s.startsWith("live")
}

@Composable
private fun Pager(current: Int, total: Int) {
    val labelStyle = TextStyle(
        color = ColorProvider(WidgetTheme.TEXT_SECONDARY),
        fontSize = 13.sp,
        fontWeight = FontWeight.Medium,
    )
    val accent = ColorFilter.tint(ColorProvider(WidgetTheme.ACCENT_ON_SURFACE))
    Box(
        modifier = GlanceModifier.fillMaxWidth().padding(vertical = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (isRtl()) {
                Image(
                    provider = ImageProvider(R.drawable.ic_widget_chevron_right),
                    contentDescription = "Next",
                    colorFilter = accent,
                    modifier = GlanceModifier.size(20.dp).clickable(actionRunCallback<NextPageAction>()),
                )
                Spacer(GlanceModifier.width(14.dp))
                Text("$current/$total", style = labelStyle)
                Spacer(GlanceModifier.width(14.dp))
                Image(
                    provider = ImageProvider(R.drawable.ic_widget_chevron_left),
                    contentDescription = "Prev",
                    colorFilter = accent,
                    modifier = GlanceModifier.size(20.dp).clickable(actionRunCallback<PrevPageAction>()),
                )
            } else {
                Image(
                    provider = ImageProvider(R.drawable.ic_widget_chevron_left),
                    contentDescription = "Prev",
                    colorFilter = accent,
                    modifier = GlanceModifier.size(20.dp).clickable(actionRunCallback<PrevPageAction>()),
                )
                Spacer(GlanceModifier.width(14.dp))
                Text("$current/$total", style = labelStyle)
                Spacer(GlanceModifier.width(14.dp))
                Image(
                    provider = ImageProvider(R.drawable.ic_widget_chevron_right),
                    contentDescription = "Next",
                    colorFilter = accent,
                    modifier = GlanceModifier.size(20.dp).clickable(actionRunCallback<NextPageAction>()),
                )
            }
        }
    }
}

/* ------------------------------ States ------------------------------ */

@Composable
private fun LoadingBody() {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        repeat(2) {
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth().height(20.dp)
                    .padding(vertical = 6.dp)
                    .cornerRadius(10.dp)
                    .background(WidgetTheme.PILL),
            ) {}
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth().height(44.dp)
                    .padding(vertical = 8.dp)
                    .cornerRadius(12.dp)
                    .background(WidgetTheme.SURFACE_ELEVATED),
            ) {}
        }
    }
}

@Composable
private fun ErrorBody(message: String) {
    Column(
        modifier = GlanceModifier.fillMaxSize().padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            "Couldn't load matches",
            style = TextStyle(color = ColorProvider(WidgetTheme.TEXT_PRIMARY), fontSize = 13.sp),
        )
        Spacer(GlanceModifier.height(6.dp))
        Text(
            message,
            maxLines = 3,
            style = TextStyle(color = ColorProvider(WidgetTheme.TEXT_SECONDARY), fontSize = 10.sp, textAlign = TextAlign.Center),
        )
        Spacer(GlanceModifier.height(10.dp))
        Box(
            modifier = GlanceModifier
                .cornerRadius(10.dp)
                .background(WidgetTheme.ACCENT)
                .padding(horizontal = 18.dp, vertical = 8.dp)
                .clickable(actionRunCallback<RefreshAction>()),
        ) {
            Text(
                "Retry",
                style = TextStyle(
                    color = ColorProvider(Color(0xFF0F172A)),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                ),
            )
        }
    }
}

@Composable
private fun NoFavoritesBody() {
    Column(
        modifier = GlanceModifier.fillMaxSize().padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            "No favorite teams",
            style = TextStyle(
                color = ColorProvider(WidgetTheme.TEXT_PRIMARY),
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
            ),
        )
        Spacer(GlanceModifier.height(6.dp))
        Text(
            "Pick favorite teams in the app to see their matches here",
            maxLines = 3,
            style = TextStyle(
                color = ColorProvider(WidgetTheme.TEXT_SECONDARY),
                fontSize = 11.sp,
                textAlign = TextAlign.Center,
            ),
        )
    }
}

@Composable
private fun EmptyRow(msg: String) {
    Text(
        msg,
        style = TextStyle(color = ColorProvider(WidgetTheme.TEXT_SECONDARY), fontSize = 12.sp),
        modifier = GlanceModifier.padding(vertical = 10.dp),
    )
}

private fun ceilDiv(a: Int, b: Int) = if (b == 0) 0 else (a + b - 1) / b
private fun <T> List<T>.pageSlice(page: Int, size: Int): List<T> {
    val from = page * size
    if (from >= this.size) return emptyList()
    return subList(from, (from + size).coerceAtMost(this.size))
}
