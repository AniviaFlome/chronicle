// Hand-written Glance widget (tall-portrait redesign). NOT generated —
// edit freely. Wire contract lives in
// com.chronicleapp.chronicle.widget.WidgetData and is mirrored by
// lib/services/widget_push.dart; keep both sides in lockstep.
//
// NextClass vertical flow: every bucket renders the shared hub class tab
// (SharedClassTab), so the standalone widget and the hub can never
// diverge. Outer radius 24.dp, inner cards 16.dp. Only androidx.glance.*
// composables (plus compose unit / runtime primitives dp/sp/Composable,
// which carry no UI toolkit).
package com.chronicleapp.chronicle

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.core.os.ConfigurationCompat
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.Action
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxWidth
import com.chronicleapp.chronicle.widget.ChroniclePalette
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.ExpandAtKey
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.NextClassExpandCallback
import com.chronicleapp.chronicle.widget.Samples
import com.chronicleapp.chronicle.widget.SharedClassTab
import com.chronicleapp.chronicle.widget.TimeRow
import com.chronicleapp.chronicle.widget.VerticalBucket
import com.chronicleapp.chronicle.widget.VerticalShell
import com.chronicleapp.chronicle.widget.WidgetSnapshot
import com.chronicleapp.chronicle.widget.currentVerticalBucket
import com.chronicleapp.chronicle.widget.heroName
import com.chronicleapp.chronicle.widget.isSentinel
import com.chronicleapp.chronicle.widget.long
import com.chronicleapp.chronicle.widget.nextClassNavBump
import com.chronicleapp.chronicle.widget.parseTimed
import com.chronicleapp.chronicle.widget.resolvePalette
import com.chronicleapp.chronicle.widget.snapshot
import com.chronicleapp.chronicle.widget.str
import com.chronicleapp.chronicle.widget.TinyRow
import com.chronicleapp.chronicle.widget.verticalSizeSlots

import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin

class NextClassHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    // Portrait-first buckets: Compact / TallColumn / FullPortrait.
    override val sizeMode = verticalSizeSlots

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { NextClassContent(context, resolveState(context)) }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.NEXT_CLASS)
        val state = NextClassWidgetUiState.Success(
            hero = Samples.nextClass,
            upcoming = Samples.later,
            snap = snap,
            nowMs = System.currentTimeMillis(),
        )
        provideContent { NextClassContent(context, state) }
    }

    fun previewFingerprint(context: Context): String {
        val locales = ConfigurationCompat.getLocales(context.resources.configuration)
        val loc = (0 until locales.size()).mapNotNull { locales[it] }.joinToString(",")
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.NEXT_CLASS)
        return "v3|nc|$loc|${snap.useYou}|${snap.themeCode}"
    }

    private fun resolveState(context: Context): NextClassWidgetUiState {
        return try {
            val prefs = HomeWidgetPlugin.getData(context)
            val prefix = Keys.NEXT_CLASS
            val snap = prefs.snapshot(prefix)
            val entries = parseTimed(prefs.str("$prefix.${Keys.TIMED_DATA}"), withThen = true)
            val now = System.currentTimeMillis()
            val idx = entries.indexOfLast { it.at <= now }
            val entry = if (idx >= 0) entries[idx] else null
            if (entry == null || entry.isSentinel || snap.stale) {
                val msg = entry?.heroName(snap)?.ifEmpty { snap.emptyText }
                    ?: snap.staleName.ifEmpty { snap.emptyText }
                return NextClassWidgetUiState.Empty(msg.ifEmpty { "No classes" })
            }
            val lookahead = if (idx >= 0) {
                entries.drop(idx + 2)
                    .filter { !it.isSentinel }
                    .take(12)
                    .map { TimeRow(it.startLabel, it.className, it.colorHex) }
            } else {
                emptyList()
            }
            NextClassWidgetUiState.Success(entry, lookahead, snap, now)
        } catch (e: Exception) {
            NextClassWidgetUiState.Error(e.message ?: "Load failed")
        }
    }
}

@Composable
private fun NextClassContent(context: Context, state: NextClassWidgetUiState) {
    // Loading resolves against the live prefs snapshot for theming; the
    // body is a quiet empty state so a cold bind never flashes raw keys.
    // Tracked bump read (see nextClassNavBump): hero expand taps re-read
    // prefs on live-session recomposes instead of replaying old state.
    @Suppress("unused")
    val navBump = nextClassNavBump.intValue
    val snap: WidgetSnapshot = when (state) {
        is NextClassWidgetUiState.Success -> state.snap
        else -> HomeWidgetPlugin.getData(context).snapshot(Keys.NEXT_CLASS)
    }
    val palette = resolvePalette(context, snap.useYou, snap.themeCode)
    val tiny = state is NextClassWidgetUiState.Success &&
        currentVerticalBucket() == VerticalBucket.Tiny
    // Hero/row expand state: native-owned marker (per-row epoch keys,
    // -1 = collapsed). Tiny strips stay untappable one-liners.
    val success = state as? NextClassWidgetUiState.Success
    val hero = success?.hero
    val expandedAt = HomeWidgetPlugin.getData(context)
        .long("${Keys.NEXT_CLASS}.${Keys.EXPANDED_AT}", -1L)
    val expandToggle: ((Long) -> Action)? = hero
        ?.takeUnless { it.isSentinel }
        ?.let { _ ->
            { at: Long ->
                actionRunCallback<NextClassExpandCallback>(
                    actionParametersOf(ExpandAtKey to at),
                )
            }
        }
    VerticalShell(context, palette, snap.opacity, paddingDp = if (tiny) 8 else 12) {
        when (state) {
            is NextClassWidgetUiState.Loading ->
                EmptyState(palette, R.drawable.ic_widget_event_available, snap.emptyText)
            is NextClassWidgetUiState.Empty ->
                EmptyState(palette, R.drawable.ic_widget_event_available, state.message)
            is NextClassWidgetUiState.Error ->
                EmptyState(palette, R.drawable.ic_widget_event_available, state.message)
            is NextClassWidgetUiState.Success -> when (currentVerticalBucket()) {
                VerticalBucket.Tiny -> Tiny(state, palette)
                VerticalBucket.Compact -> Compact(state, palette, expandedAt, expandToggle)
                VerticalBucket.TallColumn -> TallColumn(state, palette, expandedAt, expandToggle)
                VerticalBucket.FullPortrait -> FullPortrait(state, palette, expandedAt, expandToggle)
            }
        }
    }
}

/** Tiny strip (1x1/2x1): dense dot + hero class name. */
@Composable
private fun Tiny(
    state: NextClassWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    TinyRow(palette, state.hero.colorHex, state.hero.className)
}

/** Compact Square (2x2): hero + at most 2 whole rows, like the hub. */
@Composable
private fun Compact(
    state: NextClassWidgetUiState.Success,
    palette: ChroniclePalette,
    expandedAt: Long = -1L,
    expandToggle: ((Long) -> Action)? = null,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        SharedClassTab(
            palette, state.hero, state.snap, state.nowMs, state.upcoming,
            compact = true, expandedAt = expandedAt, expandToggle = expandToggle,
        )
    }
}

/** Tall Vertical Column (2x3/2x4): same hero + 3-row lookahead as the hub. */
@Composable
private fun TallColumn(
    state: NextClassWidgetUiState.Success,
    palette: ChroniclePalette,
    expandedAt: Long = -1L,
    expandToggle: ((Long) -> Action)? = null,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        SharedClassTab(
            palette, state.hero, state.snap, state.nowMs, state.upcoming,
            expandedAt = expandedAt, expandToggle = expandToggle,
        )
    }
}

/** Standard Portrait Feed (4x3/4x4): same hero + lookahead as the hub. */
@Composable
private fun FullPortrait(
    state: NextClassWidgetUiState.Success,
    palette: ChroniclePalette,
    expandedAt: Long = -1L,
    expandToggle: ((Long) -> Action)? = null,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        SharedClassTab(
            palette, state.hero, state.snap, state.nowMs, state.upcoming,
            expandedAt = expandedAt, expandToggle = expandToggle,
        )
    }
}
