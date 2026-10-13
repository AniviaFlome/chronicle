// Hand-written Glance widget (tall-portrait design). NOT generated —
// edit freely. Wire contract lives in
// com.chronicleapp.chronicle.widget.WidgetData and is mirrored by
// lib/services/widget_push.dart; keep both sides in lockstep.
//
// CafeteriaMenu vertical flow: meal title on top, dishes stacked below.
// Row appears only inside DishRow (accent dot + name, inline metadata).
// Buckets (verticalSizeSlots): Compact 120x120 title + first dish,
// TallColumn 120x240 up to 3 dishes + "+X more", FullPortrait 260x240 up
// to 8 dishes under a section header. Outer radius 24.dp, inner cards
// 16.dp via shared components. Only androidx.glance.* composables (plus
// compose unit / runtime primitives dp/sp/Composable).
package com.chronicleapp.chronicle

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.ConfigurationCompat
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.appwidget.lazy.LazyColumn
import com.chronicleapp.chronicle.widget.ChroniclePalette
import com.chronicleapp.chronicle.widget.DishRow
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.MealSwitcher
import com.chronicleapp.chronicle.widget.MenuMeal
import com.chronicleapp.chronicle.widget.MenuMealDirectionKey
import com.chronicleapp.chronicle.widget.menuNavBump
import com.chronicleapp.chronicle.widget.MoreIndicator
import com.chronicleapp.chronicle.widget.SectionHeader
import com.chronicleapp.chronicle.widget.StandaloneMenuMealCallback
import com.chronicleapp.chronicle.widget.VerticalBucket
import com.chronicleapp.chronicle.widget.VerticalShell
import com.chronicleapp.chronicle.widget.WidgetSnapshot
import com.chronicleapp.chronicle.widget.currentVerticalBucket
import com.chronicleapp.chronicle.widget.int
import com.chronicleapp.chronicle.widget.isNarrowSlot
import com.chronicleapp.chronicle.widget.parseMenuMeals
import com.chronicleapp.chronicle.widget.parseStrings
import com.chronicleapp.chronicle.widget.resolveMenuMeal
import com.chronicleapp.chronicle.widget.resolvePalette
import com.chronicleapp.chronicle.widget.snapshot
import com.chronicleapp.chronicle.widget.str
import com.chronicleapp.chronicle.widget.TinyRow
import com.chronicleapp.chronicle.widget.verticalSizeSlots

import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin

class CafeteriaMenuHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    // Portrait-first buckets: Compact / TallColumn / FullPortrait.
    override val sizeMode = verticalSizeSlots

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            // Snapshot-tracked read (see menuNavBump): pins this composition
            // to the bump so live-session recomposes re-read prefs after
            // meal steps instead of replaying the previously resolved state.
            MenuContent(context, resolveState(context, menuNavBump.intValue))
        }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.CAFETERIA_MENU)
        val dishes = listOf(
            "Lentil soup",
            "Grilled chicken",
            "Rice pilaf",
            "Ayran",
        )
        provideContent {
            MenuContent(
                context,
                CafeteriaMenuWidgetUiState.Success(
                    title = "Lunch · ITU",
                    dishes = dishes,
                    meals = listOf(
                        MenuMeal(kind = "ogle", title = "Lunch · ITU", dishes = dishes),
                    ),
                    selectedIdx = 0,
                    snap = snap,
                ),
            )
        }
    }

    fun previewFingerprint(context: Context): String {
        val locales = ConfigurationCompat.getLocales(context.resources.configuration)
        val loc = (0 until locales.size()).mapNotNull { locales[it] }.joinToString(",")
        val snap = HomeWidgetPlugin.getData(context).snapshot(Keys.CAFETERIA_MENU)
        return "v1|menu|$loc|${snap.useYou}|${snap.themeCode}"
    }

    private fun resolveState(context: Context, @Suppress("UNUSED_PARAMETER") navBump: Int): CafeteriaMenuWidgetUiState {
        return try {
            val prefs = HomeWidgetPlugin.getData(context)
            val prefix = Keys.CAFETERIA_MENU
            val snap = prefs.snapshot(prefix)
            if (snap.stale) {
                return CafeteriaMenuWidgetUiState.Empty(
                    snap.staleName.ifEmpty { snap.emptyText }.ifEmpty { "No menu today" },
                )
            }
            val dishes = parseStrings(prefs.str("$prefix.${Keys.MENU_ROWS}"))
                .map { it.trim() }
                .filter { it.isNotEmpty() }
            val meals = parseMenuMeals(prefs.str("$prefix.${Keys.MENU_MEALS}"))
            if (dishes.isEmpty() && meals.isEmpty()) {
                return CafeteriaMenuWidgetUiState.Empty(
                    snap.emptyText.ifEmpty { "No menu today" },
                )
            }
            // New list wins; legacy flat rows cover pushes from older apps.
            val meal = resolveMenuMeal(
                meals,
                prefs.int("$prefix.${Keys.MENU_MEAL_DEFAULT}", 0),
                prefs.str("$prefix.${Keys.MENU_MEAL_KIND}"),
            )
            val title = meal?.title ?: prefs.str("$prefix.${Keys.MENU_TITLE}")
            val served = meal?.dishes ?: dishes
            val selectedIdx = meal?.let { meals.indexOf(it) } ?: 0
            CafeteriaMenuWidgetUiState.Success(
                title = title,
                dishes = served,
                meals = meals,
                selectedIdx = selectedIdx,
                snap = snap,
            )
        } catch (e: Exception) {
            CafeteriaMenuWidgetUiState.Error(e.message ?: "Load failed")
        }
    }
}

@Composable
private fun MenuContent(context: Context, state: CafeteriaMenuWidgetUiState) {
    val snap: WidgetSnapshot = when (state) {
        is CafeteriaMenuWidgetUiState.Success -> state.snap
        else -> HomeWidgetPlugin.getData(context).snapshot(Keys.CAFETERIA_MENU)
    }
    val palette = resolvePalette(context, snap.useYou, snap.themeCode)
    val tiny = state is CafeteriaMenuWidgetUiState.Success &&
        currentVerticalBucket() == VerticalBucket.Tiny
    VerticalShell(context, palette, snap.opacity, paddingDp = if (tiny) 8 else 12) {
        when (state) {
            is CafeteriaMenuWidgetUiState.Loading ->
                EmptyState(palette, R.drawable.ic_widget_menu, snap.emptyText)
            is CafeteriaMenuWidgetUiState.Empty ->
                EmptyState(palette, R.drawable.ic_widget_menu, state.message)
            is CafeteriaMenuWidgetUiState.Error ->
                EmptyState(palette, R.drawable.ic_widget_menu, state.message)
            is CafeteriaMenuWidgetUiState.Success -> when (currentVerticalBucket()) {
                VerticalBucket.Tiny -> Tiny(state, palette)
                VerticalBucket.Compact -> Compact(state, palette)
                VerticalBucket.TallColumn -> TallColumn(state, palette)
                VerticalBucket.FullPortrait -> FullPortrait(state, palette)
            }
        }
    }
}

/** Tiny strip (1x1/2x1): dense dot + first dish. */
@Composable
private fun Tiny(
    state: CafeteriaMenuWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    TinyRow(palette, null, state.dishes.first())
}

/** Compact Square (2x2): meal title + two dishes, tight. */
@Composable
private fun Compact(
    state: CafeteriaMenuWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        if (state.title.isNotEmpty()) {
            Text(
                text = state.title,
                style = TextStyle(
                    color = palette.onSurfaceVariant,
                    fontSize = if (isNarrowSlot()) 10.sp else 11.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
            Spacer(modifier = GlanceModifier.height(3.dp))
        }
        val rows = state.dishes.take(2)
        for ((i, dish) in rows.withIndex()) {
            if (i > 0) Spacer(modifier = GlanceModifier.height(3.dp))
            Text(
                text = "• $dish",
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = if (isNarrowSlot()) 12.sp else 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
        }
        val remaining = state.dishes.size - rows.size
        if (remaining > 0) {
            Spacer(modifier = GlanceModifier.height(3.dp))
            MoreIndicator(palette, remaining)
        }
    }
}

/** Tall Vertical Column (2x3/2x4): title + up to 3 dishes + "+X more". */
@Composable
private fun TallColumn(
    state: CafeteriaMenuWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        // The switcher already shows the meal title; the standalone title
        // line only renders for single-meal days.
        if (state.title.isNotEmpty() && state.meals.size <= 1) {
            Text(
                text = state.title,
                style = TextStyle(
                    color = palette.onSurfaceVariant,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
        }
        if (state.meals.size > 1) {
            MealSwitcher(
                palette = palette,
                title = state.title,
                showArrows = true,
                leftIcon = R.drawable.ic_widget_chevron_left,
                rightIcon = R.drawable.ic_widget_chevron_right,
            ) { dir ->
                actionRunCallback<StandaloneMenuMealCallback>(
                    actionParametersOf(MenuMealDirectionKey to dir),
                )
            }
            Spacer(modifier = GlanceModifier.height(4.dp))
        }
        val rows = state.dishes
        // Scrollable list: LazyColumn fills the remaining space via weight
        // (a wrap-content list would measure only its first item — the exact
        // failure that got LazyColumn banned here before). Every dish is
        // reachable by scrolling: no cap, no "+N more". Items wrap in
        // their own Column: bare single-node items mismeasure.
        LazyColumn(modifier = GlanceModifier.defaultWeight()) {
            items(rows.size) { i ->
                Column(modifier = GlanceModifier.fillMaxWidth()) {
                    if (i > 0) Spacer(modifier = GlanceModifier.height(4.dp))
                    DishRow(palette, rows[i])
                }
            }
        }
    }
}

/** Standard Portrait Feed (4x3/4x4): header + full meal. */
@Composable
private fun FullPortrait(
    state: CafeteriaMenuWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        // Header group (SectionHeader emits 2 nodes) + chunked dish rows:
        // keeps every Column at or under Glance's ~10-child limit.
        Box(modifier = GlanceModifier.fillMaxWidth()) {
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                SectionHeader(palette, "Today's menu")
                if (state.title.isNotEmpty() && state.meals.size <= 1) {
                    Text(
                        text = state.title,
                        style = TextStyle(
                            color = palette.onSurface,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                }
                if (state.meals.size > 1) {
                    MealSwitcher(
                        palette = palette,
                        title = state.title,
                        showArrows = true,
                        leftIcon = R.drawable.ic_widget_chevron_left,
                        rightIcon = R.drawable.ic_widget_chevron_right,
                    ) { dir ->
                        actionRunCallback<StandaloneMenuMealCallback>(
                            actionParametersOf(MenuMealDirectionKey to dir),
                        )
                    }
                }
            }
        }
        val rows = state.dishes
        // Scrollable list (see TallColumn): every dish reachable, no cap.
        // Items wrap in their own Column: bare single-node items mismeasure.
        LazyColumn(modifier = GlanceModifier.defaultWeight()) {
            items(rows.size) { i ->
                Column(modifier = GlanceModifier.fillMaxWidth()) {
                    if (i > 0) Spacer(modifier = GlanceModifier.height(4.dp))
                    DishRow(palette, rows[i])
                }
            }
        }
    }
}
