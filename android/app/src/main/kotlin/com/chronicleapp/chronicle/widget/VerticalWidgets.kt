// Vertical-first shared foundation for tall-portrait widgets.
// NOT generated — edit freely. Complements WidgetComponents.kt: this file
// owns the portrait-first responsive contract (Compact / TallColumn /
// FullPortrait), the 24dp-outer / 16dp-inner radii, and the vertical-flow
// helpers. Wire contract unchanged (WidgetData.kt Keys + widget_push.dart).
//
// Glance discipline: only androidx.glance.* imports, every Text sets
// maxLines, Rows <= ~10 children, backgrounds are fixedProvider fills.
package com.chronicleapp.chronicle.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
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
import com.chronicleapp.chronicle.MainActivity

/**
 * Portrait-first responsive buckets (goal spec):
 * - Compact Square (2x2): 120x120 -> single upcoming class card.
 * - Tall Vertical Column (2x3/2x4): 120x240 -> current + 2 stacked.
 * - Standard Portrait Feed (4x3/4x4): 260x240 -> full agenda + headers.
 * Small strip slots (1x1 = 40dp, 2x1 = 110x40, 1x2 = 40x110 per the
 * Android cell formula 70 x n - 30) match Tiny renders exactly instead of
 * stretching the nearest larger slot.
 * Wide slots (320/470 wide) cover user-enlarged widgets: without a
 * covering entry the host stretches the nearest slot (wrong tier,
 * oversized text), and once stretched small the widget never picks the
 * portrait slot again. Tall-narrow slots (120/260 wide, 320/450 tall)
 * cover shrunken tall widgets: a 1-column tall widget must match a
 * narrow slot to get the stacked layout. ORDER MATTERS: the host
 * applies first-fit over this set, so narrow slots sort before wide
 * ones (a wide slot earlier in the set shadows them — seen on-device:
 * a 1-column widget kept rendering the 470x320 view). 13 slots, under
 * the framework MAX_INIT_VIEW_COUNT=16 cap — do not grow past 16.
 */
val verticalSizeSlots = SizeMode.Responsive(
    setOf(
        DpSize(40.dp, 40.dp),
        DpSize(110.dp, 40.dp),
        DpSize(40.dp, 110.dp),
        DpSize(120.dp, 80.dp),
        DpSize(120.dp, 120.dp),
        DpSize(120.dp, 240.dp),
        DpSize(120.dp, 320.dp),
        DpSize(120.dp, 450.dp),
        DpSize(260.dp, 240.dp),
        DpSize(260.dp, 320.dp),
        DpSize(320.dp, 240.dp),
        DpSize(470.dp, 240.dp),
        DpSize(470.dp, 320.dp),
    ),
)

/**
 * Slim slot set for the weekly calendar: 8 entries instead of 13. Every
 * widget update composes + translates one view PER SLOT, and the weekly
 * feed (7 day sections) is the heaviest composition — the full set made
 * its updates visibly laggy. Buckets still resolve the same way; wide
 * enlargements fall back to the nearest covering slot.
 */
val weeklySizeSlots = SizeMode.Responsive(
    setOf(
        DpSize(40.dp, 40.dp),
        DpSize(110.dp, 40.dp),
        DpSize(40.dp, 110.dp),
        DpSize(120.dp, 120.dp),
        DpSize(120.dp, 240.dp),
        DpSize(120.dp, 320.dp),
        DpSize(260.dp, 240.dp),
        DpSize(470.dp, 320.dp),
    ),
)

/**
 * Slim slot set for the hub: 10 entries instead of 13. Every widget update
 * composes + translates one view PER SLOT, and tab switches pay that cost
 * on every tap — the full set made them visibly laggy (same mechanism as
 * the weekly feed, which got its slim set first). The two short 1-column
 * slots (140x110/150x110) match real short strips that otherwise fall back
 * to Tiny; buckets still resolve the same way. Stays under the framework
 * MAX_INIT_VIEW_COUNT=16 cap — do not grow past 16.
 */
val hubSizeSlots = SizeMode.Responsive(
    setOf(
        DpSize(40.dp, 40.dp),
        DpSize(110.dp, 40.dp),
        DpSize(40.dp, 110.dp),
        // Short 1-column slots: hosts can report ~140-150x110 for a short
        // wide strip (seen-on-device); without a slot covering that size
        // the pick falls back to a Tiny slot and one centered line floats
        // in the drawn card. Decisive test for report-vs-tiebreak.
        DpSize(140.dp, 110.dp),
        DpSize(150.dp, 110.dp),
        DpSize(120.dp, 120.dp),
        DpSize(120.dp, 240.dp),
        DpSize(120.dp, 320.dp),
        DpSize(260.dp, 240.dp),
        DpSize(470.dp, 320.dp),
    ),
)

/** Which portrait bucket the current LocalSize falls in. */
enum class VerticalBucket { Tiny, Compact, TallColumn, FullPortrait }

@Composable
fun currentVerticalBucket(): VerticalBucket {
    val size = LocalSize.current
    return when {
        size.width >= 180.dp && size.height >= 200.dp -> VerticalBucket.FullPortrait
        size.height >= 150.dp -> VerticalBucket.TallColumn
        size.height >= 110.dp -> VerticalBucket.Compact
        else -> VerticalBucket.Tiny
    }
}

/**
 * Narrow-slot flag for graceful degradation: below ~200.dp wide, labels
 * switch to compact forms (smaller type, shorter counts, number-only
 * rail cells) instead of ellipsizing mid-word. Wide layouts are
 * untouched. Thresholds operate on the matched slot size — the same
 * basis as [currentVerticalBucket].
 */
@Composable
fun isNarrowSlot(): Boolean = LocalSize.current.width < 200.dp

/**
 * Outer shell for vertical widgets: 24.dp outer radius, 12.dp content
 * insets, whole-widget tap opens the app (no press ripple: the app
 * opening is feedback enough, and the shell flash reads as a white
 * flicker on tab switches). Inner cards use 16.dp (see
 * FilledBlock default 20.dp — pass radius = 16.dp at call sites).
 *
 * The optional [bottomBar] renders OUTSIDE the padded content box, pinned
 * near the background's bottom edge (12.dp side insets plus an 8.dp bottom
 * inset: fully flush bars get their dots clipped by some hosts).
 * Widgets without a bar pass null and get
 * the exact legacy tree (single padded box).
 *
 * [shellClick] replaces the whole-widget app-open tap when set — the
 * narrow hub passes its next-tab action so a tap anywhere (including the
 * shell padding) advances a page instead of opening the app. Child
 * clickables (the dots bar) still win on their own bounds.
 */
@Composable
fun VerticalShell(
    context: Context,
    palette: ChroniclePalette,
    opacity: Int,
    paddingDp: Int = 12,
    bottomBar: (@Composable () -> Unit)? = null,
    shellClick: Action? = null,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(widgetBg(context, palette.bg, opacity))
            .cornerRadius(24.dp)
            .clickable(
                onClick = shellClick ?: actionStartActivity<MainActivity>(),
                rippleOverride = NoPressFeedback,
            ),
        contentAlignment = Alignment.TopStart,
    ) {
        if (bottomBar == null) {
            Box(modifier = GlanceModifier.fillMaxSize().padding(paddingDp.dp)) {
                content()
            }
        } else {
            Column(modifier = GlanceModifier.fillMaxSize()) {
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .fillMaxWidth()
                        .padding(paddingDp.dp),
                ) {
                    content()
                }
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .padding(horizontal = paddingDp.dp)
                        .padding(bottom = 8.dp),
                ) {
                    bottomBar()
                }
            }
        }
    }
}

/** Section header for FullPortrait feeds (e.g. "Today", "This week"). */
@Composable
fun SectionHeader(palette: ChroniclePalette, title: String) {
    Text(
        text = title,
        style = TextStyle(
            color = palette.onSurfaceVariant,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
        ),
        maxLines = 1,
    )
    Spacer(modifier = GlanceModifier.height(4.dp))
}

/** "+X more" overflow indicator for capped TallColumn lists. Narrow slots
 * use the short "+X" form so the count itself never truncates.
 * NOTE: keep the Column wrapper even for a single child — a bare Text
 * directly in a centered fillMaxWidth Box mismeasures on-device (the same
 * collapse WeekCellView documents); the text rendered 6px tall. */
@Composable
fun MoreIndicator(palette: ChroniclePalette, remaining: Int) {
    if (remaining <= 0) return
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(palette.cardHigh)
            .cornerRadius(12.dp)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = if (isNarrowSlot()) "+$remaining" else "+$remaining more",
                style = TextStyle(
                    color = palette.onSurfaceVariant,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
        }
    }
}

/**
 * Dense Tiny row (1x1/2x1 strips): class-color dot over one centered 12sp
 * line. 3 nodes, ~38dp tall — fits a 40dp strip with 8dp shell padding.
 */
@Composable
fun TinyRow(palette: ChroniclePalette, colorHex: String?, text: String) {
    // NOTE: colorHex intentionally ignored — small widgets stay neutral;
    // the dot uses the theme accent for identity.
    Box(
        modifier = GlanceModifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = GlanceModifier
                    .width(6.dp)
                    .height(6.dp)
                    .background(palette.accent)
                    .cornerRadius(50.dp),
            ) {}
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = text,
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                ),
                maxLines = 1,
                modifier = GlanceModifier.fillMaxWidth(),
            )
        }
    }
}

/**
 * Renders [count] vertical items in groups of at most [perGroup], each group * wrapped in its own Box + inner Column. Glance's RemoteViews translator
 * silently drops Column children past ~10, so long feeds MUST be chunked:
 * the outer Column only ever holds ceil(count / perGroup) Box children plus
 * inter-group spacers. Each [item] emission must be a single layout node
 * (one Row/Box/Text — never a bare multi-emit helper like SectionHeader).
 * Emits nothing for count <= 0.
 */
@Composable
fun ChunkedRows(
    count: Int,
    perGroup: Int = 3,
    gapDp: Int = 4,
    item: @Composable (index: Int) -> Unit,
) {
    if (count <= 0 || perGroup <= 0) return
    val groups = (count + perGroup - 1) / perGroup
    for (g in 0 until groups) {
        if (g > 0) Spacer(modifier = GlanceModifier.height(gapDp.dp))
        val start = g * perGroup
        val end = minOf(start + perGroup, count)
        Box(modifier = GlanceModifier.fillMaxWidth()) {
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                for (i in start until end) {
                    if (i > start) Spacer(modifier = GlanceModifier.height(gapDp.dp))
                    item(i)
                }
            }
        }
    }
}
