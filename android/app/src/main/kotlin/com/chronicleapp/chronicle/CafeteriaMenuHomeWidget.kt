// Hand-written Glance widget (redesigned elevated Meal Header Card + tonal
// dish cards). NOT generated — edit freely. Wire contract lives in
// com.chronicleapp.chronicle.widget.WidgetData and is mirrored by
// lib/services/widget_push.dart; keep both sides in lockstep.
package com.chronicleapp.chronicle

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.ConfigurationCompat
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
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
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import com.chronicleapp.chronicle.widget.ChroniclePalette
import com.chronicleapp.chronicle.widget.EmptyState
import com.chronicleapp.chronicle.widget.Hairline
import com.chronicleapp.chronicle.widget.Keys
import com.chronicleapp.chronicle.widget.MealSwitcher
import com.chronicleapp.chronicle.widget.MenuDishItem
import com.chronicleapp.chronicle.widget.MenuMeal
import com.chronicleapp.chronicle.widget.MenuMealDirectionKey
import com.chronicleapp.chronicle.widget.Samples
import com.chronicleapp.chronicle.widget.SharedMenuItemList
import com.chronicleapp.chronicle.widget.StandaloneMenuMealCallback
import com.chronicleapp.chronicle.widget.StatusPill
import com.chronicleapp.chronicle.widget.TinyRow
import com.chronicleapp.chronicle.widget.VerticalBucket
import com.chronicleapp.chronicle.widget.VerticalShell
import com.chronicleapp.chronicle.widget.WidgetSnapshot
import com.chronicleapp.chronicle.widget.currentVerticalBucket
import com.chronicleapp.chronicle.widget.deviceTodayIso
import com.chronicleapp.chronicle.widget.int
import com.chronicleapp.chronicle.widget.isNarrowSlot
import com.chronicleapp.chronicle.widget.menuNavBump
import com.chronicleapp.chronicle.widget.parseMenuMeals
import com.chronicleapp.chronicle.widget.parseStrings
import com.chronicleapp.chronicle.widget.resolveMenuMeal
import com.chronicleapp.chronicle.widget.resolvePalette
import com.chronicleapp.chronicle.widget.snapshot
import com.chronicleapp.chronicle.widget.str
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
        val meal = MenuMeal(
            kind = "ogle",
            title = Samples.menuTitle,
            dishes = Samples.menu,
            serviceHours = Samples.menuServiceHours,
            totalKcal = Samples.menuTotalKcal,
            items = Samples.menuItems,
        )
        provideContent {
            MenuContent(
                context,
                CafeteriaMenuWidgetUiState.Success(
                    title = meal.title,
                    dishes = meal.dishes,
                    items = meal.resolvedItems,
                    serviceHours = meal.serviceHours,
                    totalKcal = meal.totalKcal,
                    meals = listOf(meal),
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
        return "v2|menu|$loc|${snap.useYou}|${snap.themeCode}"
    }

    private fun resolveState(
        context: Context,
        @Suppress("UNUSED_PARAMETER") navBump: Int,
    ): CafeteriaMenuWidgetUiState {
        return try {
            val prefs = HomeWidgetPlugin.getData(context)
            val prefix = Keys.CAFETERIA_MENU
            val snap = prefs.snapshot(prefix)
            if (snap.stale) {
                return CafeteriaMenuWidgetUiState.Empty(
                    snap.emptyText.ifEmpty { "No menu today" },
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
                prefs.str("$prefix.${Keys.MENU_MEAL_KIND_DATE}"),
                deviceTodayIso(),
            )
            val title = meal?.title ?: prefs.str("$prefix.${Keys.MENU_TITLE}")
            val served = meal?.dishes ?: dishes
            val items = meal?.resolvedItems ?: served.map { MenuDishItem(it) }
            val selectedIdx = meal?.let { meals.indexOf(it) } ?: 0
            CafeteriaMenuWidgetUiState.Success(
                title = title,
                dishes = served,
                items = items,
                serviceHours = meal?.serviceHours.orEmpty(),
                totalKcal = meal?.totalKcal ?: 0,
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
                EmptyState(palette, R.drawable.ic_widget_menu, snap.emptyText, fill = true)
            is CafeteriaMenuWidgetUiState.Empty ->
                EmptyState(palette, R.drawable.ic_widget_menu, state.message, fill = true)
            is CafeteriaMenuWidgetUiState.Error ->
                EmptyState(palette, R.drawable.ic_widget_menu, state.message, fill = true)
            is CafeteriaMenuWidgetUiState.Success -> when (currentVerticalBucket()) {
                VerticalBucket.Tiny -> Tiny(state, palette)
                VerticalBucket.Compact,
                VerticalBucket.TallColumn,
                VerticalBucket.FullPortrait -> MenuFeed(state, palette)
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
    TinyRow(palette, null, state.items.firstOrNull()?.name ?: state.dishes.firstOrNull().orEmpty())
}

/**
 * Unified menu feed across Compact / TallColumn / FullPortrait: elevated
 * `cardHigh` Meal Header Card (meal kind pill / switcher + optional hours
 * and kcal) over a hairline and scrolling tonal dish cards.
 */
@Composable
private fun MenuFeed(
    state: CafeteriaMenuWidgetUiState.Success,
    palette: ChroniclePalette,
) {
    val narrow = isNarrowSlot()
    val metaLine = listOf(
        state.serviceHours,
        if (state.totalKcal > 0) "${state.totalKcal} kcal" else "",
    ).filter { it.isNotEmpty() }.joinToString(" · ")

    Column(modifier = GlanceModifier.fillMaxSize()) {
        // Elevated Meal Header Card
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(palette.cardHigh)
                .cornerRadius(if (narrow) 14.dp else 16.dp)
                .padding(
                    horizontal = if (narrow) 8.dp else 10.dp,
                    vertical = if (state.meals.size > 1) 4.dp else 8.dp,
                ),
        ) {
            Column(modifier = GlanceModifier.fillMaxWidth()) {
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
                    if (metaLine.isNotEmpty()) {
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Text(
                            text = metaLine,
                            style = TextStyle(
                                color = palette.onSurfaceVariant,
                                fontSize = 10.sp,
                                textAlign = TextAlign.Center,
                            ),
                            maxLines = 1,
                            modifier = GlanceModifier.fillMaxWidth(),
                        )
                    }
                } else {
                    val sep = state.title.indexOf(" · ")
                    val splitTitle = !narrow && sep > 0 && sep + 3 < state.title.length
                    Row(
                        modifier = GlanceModifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(
                            modifier = GlanceModifier
                                .width(if (narrow) 24.dp else 28.dp)
                                .height(if (narrow) 24.dp else 28.dp)
                                .background(palette.accentChipBg)
                                .cornerRadius(50.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_menu),
                                contentDescription = null,
                                modifier = GlanceModifier
                                    .width(if (narrow) 13.dp else 15.dp)
                                    .height(if (narrow) 13.dp else 15.dp),
                                colorFilter = ColorFilter.tint(palette.accentChipFg),
                            )
                        }
                        Spacer(modifier = GlanceModifier.width(8.dp))
                        Column(modifier = GlanceModifier.defaultWeight()) {
                            if (splitTitle) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    StatusPill(palette, state.title.substring(0, sep), compact = true)
                                    Spacer(modifier = GlanceModifier.width(6.dp))
                                    Text(
                                        text = state.title.substring(sep + 3),
                                        style = TextStyle(
                                            color = palette.onSurfaceVariant,
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                        ),
                                        maxLines = 1,
                                    )
                                }
                            } else {
                                Text(
                                    text = state.title,
                                    style = TextStyle(
                                        color = palette.onSurface,
                                        fontSize = if (narrow) 12.sp else 13.sp,
                                        fontWeight = FontWeight.Bold,
                                    ),
                                    maxLines = 1,
                                    modifier = GlanceModifier.fillMaxWidth(),
                                )
                            }
                            if (metaLine.isNotEmpty()) {
                                Spacer(modifier = GlanceModifier.height(2.dp))
                                Text(
                                    text = metaLine,
                                    style = TextStyle(
                                        color = palette.onSurfaceVariant,
                                        fontSize = 10.sp,
                                    ),
                                    maxLines = 1,
                                    modifier = GlanceModifier.fillMaxWidth(),
                                )
                            }
                        }
                    }
                }
            }
        }
        Spacer(modifier = GlanceModifier.height(6.dp))
        Hairline(palette)
        Spacer(modifier = GlanceModifier.height(6.dp))
        // Shared tonal dish cards (identical to the Hub menu tab).
        SharedMenuItemList(palette, state.items)
    }
}
