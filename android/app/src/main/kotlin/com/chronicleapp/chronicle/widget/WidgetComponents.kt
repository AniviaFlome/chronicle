// Hand-written widget component library (Chronicle from-scratch redesign).
// NOT generated — edit freely. Shared by all four widgets so the hub and the
// standalone widgets stay visually consistent (T1 consistent-header rule).
//
// Design language (v2): filled class-color event blocks (Google Calendar
// pattern) with luminance-picked text, compact letter-strip rails, segmented
// hub tabs, Keep-style filled checkbox squares. No leading stripes/dots.
// The pushed `widgetOpacity` (0 solid / 1 translucent / 2 transparent) only
// affects the OUTER shell background via [widgetBg]; chips and blocks stay
// solid so content survives on wallpaper (Glance has no text shadows).
//
// Glance discipline (paid for in build failures): keep each Row/Column under
// ~10 children (RemoteViews silently drops beyond), no gradients/shadows/
// strokes (border = fill inset by a nested Box), text weights are only
// bold/regular, and interactive hit targets are padded to >= 40dp.
package com.chronicleapp.chronicle.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.action.NoRippleOverride
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
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
import com.chronicleapp.chronicle.MainActivity
import com.chronicleapp.chronicle.R

/** ActionParameters key for the agenda rail day index (letter strip cells). */
val AgendaDayKey = ActionParameters.Key<Int>("dayIdx")

/** ActionParameters key for the hub segmented-tab index. */
val HubTabKey = ActionParameters.Key<Int>("tabIdx")

/** ActionParameters key for the hub tab arrow direction (+1 / -1). */
val HubDirectionKey = ActionParameters.Key<Int>("direction")

/** ActionParameters key for the menu-meal arrow direction (+1 / -1). */
val MenuMealDirectionKey = ActionParameters.Key<Int>("mealDirection")

/**
 * Shared responsive slot grid for all four widgets. Proven on-device
 * (Launcher3, fresh binds still pick narrow): whatever the host's exact rule
 * is (largest-fitting, smallest-fitting, first-fit, or the no-fit fallback),
 * the sub-h170 slots kept winning every steady state, so they are GONE —
 * every slot in this set except the 4x1 strip renders the FULL design
 * (rail/dots always, takes >= 2, date-on-top from h>=170). All candidate host rules now converge on a
 * full-design pick: smallest-area/no-fit-fallback = (195x270); first-fit =
 * set order below (small full-design slots first); largest-fitting =
 * (310x195) for the 2x2 landscape bucket (~324x215), (195x270) portrait
 * (~214x295). Widths sit ~8dp inside their target buckets: a slot that
 * misses the reported size by even 2dp loses to a smaller one (seen
 * on-device). Tall windows reach (315x275)/(470x320) hero/lookahead tiers on
 * resize (resize re-picks with real sizes). 13 slots, under the framework
 * MAX_INIT_VIEW_COUNT=16 cap — do not grow past 16. Trade-off: a widget
 * shrunk to a 1x1-ish strip renders the (195x270) fallback clipped; the
 * provider minResize attrs discourage that.
 */
val widgetSizeSlots = SizeMode.Responsive(
    setOf(
        DpSize(310.dp, 195.dp), // 2x2 landscape bucket (current ~318x225)
        DpSize(195.dp, 270.dp), // 2x2 portrait bucket (~214x295)
        DpSize(315.dp, 275.dp), // tall narrow (NextClass portrait)
        DpSize(320.dp, 220.dp), // wider 2x2 buckets
        DpSize(470.dp, 220.dp), // 3x2 (NextClass default)
        DpSize(470.dp, 320.dp), // tall wide (hero 28sp + lookahead)
        DpSize(320.dp, 450.dp), // 2x4
        DpSize(470.dp, 450.dp), // 3x4
        DpSize(320.dp, 880.dp), // extreme tall
        DpSize(640.dp, 220.dp), // 4x2
        DpSize(640.dp, 450.dp), // 4x4
        DpSize(640.dp, 120.dp), // 4x1 strip (wide short: hero 22sp, rows take 1)
        DpSize(1280.dp, 450.dp), // full-width stretch
    )
)

/** Outer-container corner radius per WS-2 (system radius, 28dp fallback). */
fun GlanceModifier.widgetCornerRadius(context: Context): GlanceModifier =
    cornerRadius(systemWidgetRadiusDp(context).dp)

/**
 * Whole-widget shell: edge-to-edge background at the pushed opacity (see
 * [widgetBg]), light content insets, whole-widget tap opens the app.
 * Row-level callbacks override this. No press ripple: the app opening is
 * feedback enough, and the flash reads as a rendering glitch (seen
 * on-device as a white flicker on every tab switch, since the press
 * lands on the shell before the child action wins on release).
 */
@Composable
fun WidgetShell(
    context: Context,
    palette: ChroniclePalette,
    opacity: Int,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(widgetBg(context, palette.bg, opacity))
            .widgetCornerRadius(context)
            .clickable(
                onClick = actionStartActivity<MainActivity>(),
                rippleOverride = NoRippleOverride,
            ),
        contentAlignment = Alignment.TopStart,
    ) {
        Box(modifier = GlanceModifier.fillMaxSize().padding(12.dp)) {
            content()
        }
    }
}

/**
 * Consistent header: tinted icon + title, optional trailing element.
 * Present on every widget whenever space allows (T1).
 */
@Composable
fun WidgetHeader(
    palette: ChroniclePalette,
    iconRes: Int,
    title: String,
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            provider = ImageProvider(iconRes),
            contentDescription = null,
            modifier = GlanceModifier.width(16.dp).height(16.dp),
            colorFilter = ColorFilter.tint(palette.accent),
        )
        Spacer(modifier = GlanceModifier.width(6.dp))
        Box(modifier = GlanceModifier.defaultWeight()) {
            Text(
                text = title,
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
        }
        if (trailing != null) {
            Spacer(modifier = GlanceModifier.width(6.dp))
            trailing()
        }
    }
}

/** Accent status pill ("Currently · ends 09:30"). */
@Composable
fun StatusPill(palette: ChroniclePalette, text: String) {
    if (text.isEmpty()) return
    Box(
        modifier = GlanceModifier
            .background(palette.accentChipBg)
            .cornerRadius(50.dp)
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(
            text = text,
            style = TextStyle(
                color = palette.accentChipFg,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
    }
}

/** Neutral tonal chip (times, dates, counts). Solid — survives transparency. */
@Composable
fun TonalChip(
    palette: ChroniclePalette,
    text: String,
    width: Dp? = null,
    urgent: Boolean = false,
) {
    if (text.isEmpty()) return
    var mod = GlanceModifier
        .background(if (urgent) palette.errorContainer else palette.chipBg)
        .cornerRadius(8.dp)
        .padding(horizontal = 6.dp, vertical = 3.dp)
    if (width != null) mod = mod.width(width)
    Box(modifier = mod, contentAlignment = Alignment.Center) {
        Text(
            text = text,
            style = TextStyle(
                color = if (urgent) palette.error else palette.onSurfaceVariant,
                fontSize = if (isNarrowSlot()) 10.sp else 11.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
    }
}

/** Accent count pill for headers ("3"). Hidden for empty/"0" counts:
 *  a zero pill next to an "All caught up" body is redundant noise. */
@Composable
fun CountPill(palette: ChroniclePalette, count: String) {
    if (count.isEmpty() || count.trim() == "0") return
    Box(
        modifier = GlanceModifier
            .background(palette.accentChipBg)
            .cornerRadius(50.dp)
            .padding(horizontal = 8.dp, vertical = 2.dp),
    ) {
        Text(
            text = count,
            style = TextStyle(
                color = palette.accentChipFg,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
    }
}

/**
 * Neutral tonal event block (deliberately NOT per-class colored: small
 * widgets stay calm and readable). Text always rides on [cardHigh] in
 * [onSurface]; [colorHex] is accepted for wire compatibility but ignored.
 * Slim vertical padding keeps stacked rows compact.
 */
@Composable
fun FilledBlock(
    palette: ChroniclePalette,
    colorHex: String,
    radius: Dp = 12.dp,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(palette.cardHigh)
            .cornerRadius(radius)
            .padding(horizontal = 10.dp, vertical = 6.dp),
    ) {
        content()
    }
}

/** Agenda/hub event row: tonal block with name + time line. The name
 * steps down (16sp → 14sp → 13sp) with length so long titles fit narrow
 * widths instead of spilling past the block edge. */
@Composable
fun FilledEventRow(
    palette: ChroniclePalette,
    time: String,
    name: String,
    colorHex: String,
    meta: String = "",
) {
    // Narrow slots step down 1sp more: long Turkish titles ("EFL201
    // İNGİLİZCE ÖĞRETİM") need every dp they can get.
    val nameSize = when {
        name.length > 28 -> 13
        name.length > 18 -> 14
        else -> 16
    }.let { if (isNarrowSlot()) (it - 1).coerceAtLeast(12) else it }
    val timeSize = if (isNarrowSlot()) 12 else 13
    FilledBlock(palette, colorHex) {
        Column(modifier = GlanceModifier.fillMaxWidth()) {
            Text(
                text = name,
                style = TextStyle(color = palette.onSurface, fontSize = nameSize.sp, fontWeight = FontWeight.Bold),
                maxLines = 2,
                modifier = GlanceModifier.fillMaxWidth(),
            )
            Spacer(modifier = GlanceModifier.height(2.dp))
            Text(
                text = if (meta.isEmpty()) time else "$time · $meta",
                style = TextStyle(color = palette.onSurfaceVariant, fontSize = timeSize.sp),
                maxLines = 1,
                modifier = GlanceModifier.fillMaxWidth(),
            )
        }
    }
}

/** Compact single-line lookahead block ("Then Physics · 10:20").
 * Renders as [time chip] + bold name; falls back to plain text when the
 * string carries no " · " separator. */
@Composable
fun FilledMiniRow(palette: ChroniclePalette, text: String, colorHex: String) {
    if (text.isEmpty()) return
    val sep = text.lastIndexOf(" · ")
    if (sep < 0 || sep + 3 >= text.length) {
        FilledBlock(palette, colorHex, radius = 16.dp) {
            Text(
                text = text,
                style = TextStyle(color = palette.onSurface, fontSize = 13.sp),
                maxLines = 1,
                modifier = GlanceModifier.fillMaxWidth(),
            )
        }
        return
    }
    FilledLookaheadRow(palette, time = text.substring(sep + 3), name = text.substring(0, sep))
}

/**
 * Fixed chip width for lookahead lists so every class name in the list
 * starts at the same x. Sized for weekday-prefixed chips ("Wed 13:40");
 * plain times ("08:40") just leave air. Wide rows only — narrow slots
 * stack the chip below the name where widths don't interact.
 */
fun lookaheadChipWidth(): Dp = 72.dp

/** Structured lookahead row: tonal time chip + bold name. Wide slots keep
 * the compact horizontal form with a FIXED chip width so every name in
 * the list starts at the same x (weekday-prefixed chips like "Wed 13:40"
 * are wider than plain "08:40"); narrow slots (~145.dp columns) stack
 * vertically (full-width name first, chip below) because a weekday-prefixed
 * chip ("Mon 08:40") otherwise eats the whole row and the name collapses
 * into a 3-character sliver (seen on-device). */
@Composable
fun FilledLookaheadRow(
    palette: ChroniclePalette,
    time: String,
    name: String,
    chipWidth: Dp? = null,
) {
    FilledBlock(palette, "", radius = 12.dp) {
        if (isNarrowSlot()) {
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                Text(
                    text = name,
                    style = TextStyle(color = palette.onSurface, fontSize = 13.sp, fontWeight = FontWeight.Bold),
                    maxLines = 2,
                    modifier = GlanceModifier.fillMaxWidth(),
                )
                if (time.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    TonalChip(palette, time)
                }
            }
        } else {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (time.isNotEmpty()) {
                    TonalChip(palette, time, width = chipWidth)
                    Spacer(modifier = GlanceModifier.width(6.dp))
                }
                Text(
                    text = name,
                    style = TextStyle(color = palette.onSurface, fontSize = 13.sp, fontWeight = FontWeight.Bold),
                    maxLines = 2,
                    modifier = GlanceModifier.defaultWeight(),
                )
            }
        }
    }
}

/**
 * Then-line for a timeline entry: structured name/when parts when pushed
 * (no baked-in "Then" prefix), legacy composed-string split as fallback
 * for old pushes. Tappable with [expandAction] (quiet "tomorrow" entries
 * expand to the next class's teacher); without it, a plain row.
 */
@Composable
fun ThenLine(
    palette: ChroniclePalette,
    entry: TimedEntry,
    expandAction: (() -> Action)? = null,
) {
    if (entry.thenName.isNotEmpty()) {
        Spacer(modifier = GlanceModifier.height(4.dp))
        if (expandAction == null) {
            FilledLookaheadRow(palette, entry.thenWhen, entry.thenName)
        } else {
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .background(fixedProvider(0x00000000L))
                    .clickable(onClick = expandAction(), rippleOverride = NoRippleOverride),
            ) {
                FilledLookaheadRow(palette, entry.thenWhen, entry.thenName)
            }
        }
    } else if (entry.thenLine.isNotEmpty()) {
        Spacer(modifier = GlanceModifier.height(4.dp))
        FilledMiniRow(palette, entry.thenLine, entry.thenColorHex)
    }
}

/**
 * Shared class hero: big title, gray status/time/room meta, then-line.
 * The lookahead list itself lives in [SharedClassTab] (scrollable or
 * static depending on bucket). Tapping the title toggles the teacher
 * detail line when [expandAction] is supplied (hub + standalone hero).
 */
@Composable
fun ClassHero(
    palette: ChroniclePalette,
    entry: TimedEntry,
    snap: WidgetSnapshot,
    nowMs: Long,
    titleSizeSp: Int,
    expanded: Boolean = false,
    expandAction: (() -> Action)? = null,
) {
    // Narrow slots step the hero down 2sp so titles survive ~200dp widths.
    val fittedTitleSp = if (isNarrowSlot()) (titleSizeSp - 2).coerceAtLeast(14) else titleSizeSp
    val title = @Composable {
        Text(
            text = entry.className,
            style = TextStyle(color = palette.onSurface, fontSize = fittedTitleSp.sp, fontWeight = FontWeight.Bold),
            maxLines = 2,
        )
    }
    // The whole title is the tap target (a bare Text takes no click
    // action); without an action it renders as a plain title.
    if (expandAction == null) {
        title()
    } else {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(fixedProvider(0x00000000L))
                .clickable(onClick = expandAction(), rippleOverride = NoRippleOverride),
        ) {
            Column(modifier = GlanceModifier.fillMaxWidth()) { title() }
        }
    }
    val meta = listOf(liveStatus(entry, snap, nowMs), entry.detailLine)
        .filter { it.isNotEmpty() }
        .joinToString(" · ")
    if (meta.isNotEmpty()) {
        Spacer(modifier = GlanceModifier.height(4.dp))
        Text(
            text = meta,
            style = TextStyle(color = palette.onSurfaceVariant, fontSize = 13.sp),
            maxLines = 2,
        )
    }
    if (expanded && entry.teacher.isNotEmpty()) {
        Spacer(modifier = GlanceModifier.height(4.dp))
        Text(
            text = entry.teacher,
            style = TextStyle(color = palette.onSurfaceVariant, fontSize = 13.sp),
            maxLines = 2,
        )
    }
    ThenLine(palette, entry, expandAction)
}

/**
 * Shared class tab body — the single source of truth used by the hub
 * class tab AND the standalone Next-class widget, so the two render
 * identically: quiet/sentinel entries as plain copy, otherwise [ClassHero]
 * plus a lookahead list. Tall buckets scroll the full list (nothing clips,
 * nothing hides); [compact] buckets render at most 2 whole rows plus a
 * "+N more" indicator instead, so a short widget never shows a row that
 * cannot be fully seen.
 *
 * IMPORTANT: this emits multiple root nodes (title, meta, lookahead
 * list). Always invoke it inside a vertical [Column] — a bare multi-root
 * composition has no stacking container and siblings paint on top of each
 * other. (All in-repo call sites do this.)
 */
@Composable
fun SharedClassTab(
    palette: ChroniclePalette,
    entry: TimedEntry?,
    snap: WidgetSnapshot,
    nowMs: Long,
    looks: List<TimeRow>,
    compact: Boolean = false,
    expanded: Boolean = false,
    expandAction: (() -> Action)? = null,
) {
    if (entry == null || entry.isSentinel || snap.stale) {
        EmptyState(
            palette,
            R.drawable.ic_widget_event_available,
            entry?.heroName(snap)?.ifEmpty { snap.emptyText }
                ?: snap.staleName.ifEmpty { snap.emptyText },
        )
        return
    }
    // Synthetic "no classes today" entries carry status copy in className
    // and no class times — render them quiet, not as a hero class name.
    // (True strips never reach here: Tiny buckets render one-liners, and
    // the shortest agenda tier renders its own summary.)
    // The quiet entry still carries tomorrow in thenName/thenWhen ("tomorrow
    // rides in the Then-line") plus the classes after that in looks — render
    // both, otherwise tall widgets show one line over a large blank void.
    // Quiet always renders the static take-2 + "+N more" form (never the
    // scrolling LazyColumn): the hub's tab container is wrap-content, where
    // a weight-bound lazy list mismeasures rows past the first two
    // (seen on-device: 1px-tall third row). Two rows + an indicator always
    // fit and always measure. The hub's nested looks repeat tomorrow as
    // looks[0], so drop rows duplicating the Then-line.
    val quiet = entry.startLabel.isEmpty()
    if (quiet) {
        Text(
            text = entry.className,
            style = TextStyle(
                color = palette.onSurfaceVariant,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 2,
        )
        // Tomorrow's class expands to its teacher (pushed as the quiet
        // entry's teacher): the evening use-case is planning tomorrow.
        if (expanded && entry.teacher.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = entry.teacher,
                style = TextStyle(color = palette.onSurfaceVariant, fontSize = 13.sp),
                maxLines = 2,
            )
        }
        ThenLine(palette, entry, expandAction)
        val next = looks.filterNot { it.time == entry.thenWhen && it.name == entry.thenName }
        if (next.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(6.dp))
            // Narrow stacked rows are ~3x taller than wide horizontal ones:
            // one row is all a narrow widget fits — and the "+N more" pill
            // with it: squeezed last children mismeasure instead of clipping
            // (seen on-device: 6px-tall pill), so narrow omits the pill.
            // Wide widgets keep two rows plus the indicator.
            val narrow = isNarrowSlot()
            val shown = next.take(if (narrow) 1 else 2)
            for ((i, row) in shown.withIndex()) {
                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                FilledLookaheadRow(palette, row.time, row.name, chipWidth = lookaheadChipWidth())
            }
            if (!narrow) {
                Spacer(modifier = GlanceModifier.height(6.dp))
                MoreIndicator(palette, next.size - shown.size)
            }
        }
    } else {
        ClassHero(
            palette = palette,
            entry = entry,
            snap = snap,
            nowMs = nowMs,
            titleSizeSp = 20,
            expanded = expanded,
            expandAction = expandAction,
        )
        // The pushed looks start with the Then-line class itself
        // (looks[0] == thenName/thenWhen by contract), so drop it here —
        // otherwise the hero's Then-line and the first lookahead row show
        // the same class twice (seen on-device: Viyolonsel I twice).
        // The quiet branch above already does the same filtering.
        val upcoming = if (entry.thenName.isEmpty() && entry.thenWhen.isEmpty()) {
            looks
        } else {
            looks.filterNot { it.time == entry.thenWhen && it.name == entry.thenName }
        }
        if (upcoming.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(6.dp))
            if (compact) {
                val shown = upcoming.take(2)
                for ((i, row) in shown.withIndex()) {
                    if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                    FilledLookaheadRow(palette, row.time, row.name, chipWidth = lookaheadChipWidth())
                }
                Spacer(modifier = GlanceModifier.height(6.dp))
                MoreIndicator(palette, upcoming.size - shown.size)
            } else {
                // Plain wrapper: it only exists so the weight below resolves
                // inside a Column scope (a bare weight has no scope here).
                // The weight itself binds against the outer bounded shell —
                // the same arrangement the verified menu lists use. Items
                // wrap in their own Column too: multi-root lazy items do
                // not stack reliably (gap spacers collapse to zero).
                Column(modifier = GlanceModifier.fillMaxWidth()) {
                    LazyColumn(modifier = GlanceModifier.defaultWeight()) {
                        items(upcoming.size) { i ->
                            Column(modifier = GlanceModifier.fillMaxWidth()) {
                                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                                FilledLookaheadRow(palette, upcoming[i].time, upcoming[i].name, chipWidth = lookaheadChipWidth())
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Keep-style checklist row: tonal block + filled square checkbox + 16sp
 * title + due chip (solid red w/ white text when urgent).
 */
@Composable
fun FilledCheckRow(palette: ChroniclePalette, title: String, date: String, urgent: Boolean) {
    val blockBg = if (urgent) palette.errorContainer else palette.cardHigh
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(blockBg)
            .cornerRadius(12.dp)
            .padding(horizontal = 10.dp, vertical = 8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            SquareCheck(
                fill = if (urgent) palette.error else palette.accent,
                inset = blockBg,
            )
            Spacer(modifier = GlanceModifier.width(10.dp))
            Text(
                text = title,
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = 16.sp,
                    fontWeight = if (urgent) FontWeight.Bold else FontWeight.Normal,
                ),
                maxLines = 2,
                modifier = GlanceModifier.defaultWeight(),
            )
            if (date.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.width(6.dp))
                if (urgent) {
                    Box(
                        modifier = GlanceModifier
                            .background(palette.error)
                            .cornerRadius(8.dp)
                            .padding(horizontal = 8.dp, vertical = 3.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = date,
                            style = TextStyle(
                                color = fixedProvider(0xFFFFFFFFL),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 1,
                        )
                    }
                } else {
                    TonalChip(palette, date)
                }
            }
        }
    }
}

/** Drawn square checkbox: accent fill + block-colored inset (no stroke). */
@Composable
private fun SquareCheck(fill: androidx.glance.unit.ColorProvider, inset: androidx.glance.unit.ColorProvider) {
    Box(
        modifier = GlanceModifier
            .width(20.dp)
            .height(20.dp)
            .background(fill)
            .cornerRadius(6.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = GlanceModifier
                .width(16.dp)
                .height(16.dp)
                .background(inset)
                .cornerRadius(4.dp),
        ) {}
    }
}

/**
 * Compact tappable letter strip (one letter per weekday). Selected = filled
 * accent, today = tonal, else plain. ~40dp tall — the rail that always fits.
 */
@Composable
fun LetterRail(palette: ChroniclePalette, week: List<WeekCell>, sel: Int) {
    if (week.isEmpty()) return
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        for (i in week.indices) {
            val cell = week[i]
            val selected = i == sel
            Box(modifier = GlanceModifier.defaultWeight().padding(horizontal = 2.dp)) {
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .height(40.dp)
                        .background(
                            when {
                                selected -> palette.accent
                                cell.isToday -> palette.cardHigh
                                else -> palette.cardHigh
                            },
                        )
                        .cornerRadius(12.dp)
                        .clickable(
                            onClick = actionRunCallback<AgendaDaySelectCallback>(
                                actionParametersOf(AgendaDayKey to i),
                            ),
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = cell.label.take(1).uppercase(),
                        style = TextStyle(
                            color = when {
                                selected -> fixedProvider(0xFFFFFFFFL)
                                cell.isToday -> palette.onSurface
                                else -> palette.onSurfaceVariant
                            },
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

/**
 * Hub segmented tab bar: tonal track, selected tab = filled accent pill.
 * Direct tab select (replaces the chevron arrows).
 */
@Composable
fun SegmentedTabs(palette: ChroniclePalette, tabs: List<String>, selected: Int) {
    if (tabs.isEmpty()) return
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(palette.cardHigh)
            .cornerRadius(50.dp)
            .padding(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        for (idx in tabs.indices) {
            val isSel = idx == selected
            Box(modifier = GlanceModifier.defaultWeight().padding(horizontal = 2.dp)) {
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .background(if (isSel) palette.accentContainer else palette.cardHigh)
                        .cornerRadius(50.dp)
                        .padding(vertical = 6.dp)
                        .clickable(
                            onClick = actionRunCallback<HubTabSelectCallback>(
                                actionParametersOf(HubTabKey to idx),
                            ),
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = tabs[idx],
                        style = TextStyle(
                            color = if (isSel) palette.onAccentContainer else palette.onSurfaceVariant,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

/** Agenda date pillar: weekday over a giant day number. */
@Composable
fun DatePillar(palette: ChroniclePalette, label: String, num: String) {
    Column(
        modifier = GlanceModifier.width(64.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = label,
            style = TextStyle(color = palette.onSurfaceVariant, fontSize = 12.sp),
            maxLines = 1,
        )
        Text(
            text = num,
            style = TextStyle(
                color = palette.onSurface,
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
    }
}

/** Hero countdown: prefix + huge numeral + unit on ONE baseline row
 * ("in 17 h") — never stacked, never clipped. */
@Composable
fun CountdownHero(palette: ChroniclePalette, prefix: String, number: String, suffix: String) {
    Row(verticalAlignment = Alignment.Bottom) {
        if (prefix.trim().isNotEmpty()) {
            Text(
                text = prefix.trim(),
                style = TextStyle(color = palette.onSurfaceVariant, fontSize = 14.sp),
                maxLines = 1,
            )
            Spacer(modifier = GlanceModifier.width(6.dp))
        }
        Text(
            text = number,
            style = TextStyle(
                color = palette.onSurface,
                fontSize = 44.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
        )
        if (suffix.trim().isNotEmpty()) {
            Spacer(modifier = GlanceModifier.width(6.dp))
            Text(
                text = suffix.trim(),
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
        }
    }
}

/** Intentional empty state: outlined icon + one line of copy (pushed, l10n).
 * Wraps content height (never fillMaxSize): inside a wrapping Column a
 * max-size child distorts measurement and can push siblings off-screen. */
@Composable
fun EmptyState(palette: ChroniclePalette, iconRes: Int, text: String) {
    Column(
        modifier = GlanceModifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // 8.dp, not 16: 4x1 strips are only ~120.dp tall and 16.dp pushed
        // the copy off the bottom edge (seen on-device).
        Spacer(modifier = GlanceModifier.height(8.dp))
        Image(
            provider = ImageProvider(iconRes),
            contentDescription = null,
            modifier = GlanceModifier.width(24.dp).height(24.dp),
            colorFilter = ColorFilter.tint(palette.outline),
        )
        Spacer(modifier = GlanceModifier.height(8.dp))
        Text(
            text = text,
            style = TextStyle(
                color = palette.onSurfaceVariant,
                fontSize = 12.sp,
                textAlign = TextAlign.Center,
            ),
            maxLines = 2,
        )
    }
}

/** Menu dish row: bulleted plain dish name text, deliberately NOT a
 * filled block — food rows render bubble-free by design. (A FilledBlock
 * here is fine structurally, but the menu look is plain text rows.)
 * Single Text node, full width, 2 lines max: the only shape that
 * measures everywhere (repeated siblings and explicit newlines both
 * mismeasure on-device). */
@Composable
fun DishRow(palette: ChroniclePalette, text: String) {
    Text(
        text = "• $text",
        style = TextStyle(
            color = palette.onSurface,
            fontSize = if (isNarrowSlot()) 12.sp else 14.sp,
        ),
        maxLines = 2,
        modifier = GlanceModifier.fillMaxWidth(),
    )
}

/** Subtle full-width divider (fill, not stroke). */
@Composable
fun Hairline(palette: ChroniclePalette) {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(1.dp)
            .background(palette.cardHigh),
    ) {}
}

// ---------------------------------------------------------------------------
// Missing-row shims (referenced by TodayAgenda / Hub / DueTasks, never
// finished in the hand-written migration). All vertical-first: primary
// content flows top-to-bottom in Column; Row only for inline metadata.
// Every Text sets maxLines. Backgrounds use fixedProvider-wrapped fills
// (never a custom ColorProvider) so RemoteViews keeps them.
// ---------------------------------------------------------------------------

/**
 * Class event row: filled class-color block with the name on top and the
 * time (+ optional meta) below. Vertical Column — safe under 180.dp.
 */
@Composable
fun ClassRow(
    context: Context,
    palette: ChroniclePalette,
    time: String,
    name: String,
    colorHex: String,
    chipWidth: Dp? = null,
) {
    // chipWidth is a hub cross-day hint (wide "Fri 18:09" chips wrap);
    // the filled block already wraps, so the hint is intentionally ignored
    // beyond keeping the signature stable.
    FilledEventRow(palette, time, name, colorHex)
}

/**
 * Task checklist row. Same name as the WidgetData.TaskRow data class is
 * intentional: the 4-arg composable overload coexists with the 3-arg
 * data-class constructor (arity differs, so call sites resolve cleanly).
 */
@Composable
fun TaskRow(palette: ChroniclePalette, title: String, date: String, urgent: Boolean) {
    FilledCheckRow(palette, title, date, urgent)
}

/**
 * Week-rail day cell: weekday label over the day number, centered.
 * Today (unselected) gets accent-tinted bold content; the selection keeps
 * its filled accent + white. Tappable via [onClick].
 */
@Composable
fun WeekCellView(
    palette: ChroniclePalette,
    cell: WeekCell,
    selected: Boolean,
    modifier: GlanceModifier = GlanceModifier,
    onClick: Action,
    cellHeight: Dp = 48.dp,
) {
    Box(modifier = modifier.padding(horizontal = 3.dp)) {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(cellHeight)
                .background(
                    when {
                        selected -> palette.accent
                        cell.isToday -> palette.cardHigh
                        else -> palette.card
                    },
                )
                .cornerRadius(12.dp)
                .clickable(onClick = onClick),
            contentAlignment = Alignment.Center,
        ) {
            // NOTE: keep this Column wrapper even for a single child —
            // a bare Text directly in a centered Box mismeasures to zero
            // width on-device (renders as "…"); every other text in these
            // widgets goes through a Column and measures correctly.
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = cell.label,
                    style = TextStyle(
                        color = when {
                            selected -> fixedProvider(0xFFFFFFFFL)
                            cell.isToday -> palette.accent
                            else -> palette.onSurfaceVariant
                        },
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
                Text(
                    text = cell.num,
                    style = TextStyle(
                        color = when {
                            selected -> fixedProvider(0xFFFFFFFFL)
                            cell.isToday -> palette.accent
                            else -> palette.onSurface
                        },
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
            }
        }
    }
}

/** Page dots: selected = accent pill, rest = tonal dots. Centered Row. */
@Composable
fun PageDots(palette: ChroniclePalette, count: Int, selected: Int) {
    if (count <= 1) return
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        for (i in 0 until count.coerceAtMost(7)) {
            if (i > 0) Spacer(modifier = GlanceModifier.width(6.dp))
            Box(
                modifier = GlanceModifier
                    .width(if (i == selected) 16.dp else 6.dp)
                    .height(6.dp)
                    .background(if (i == selected) palette.accent else palette.cardHigh)
                    .cornerRadius(50.dp),
            ) {}
        }
    }
}

/**
 * Hub tab arrow: 48.dp tappable chevron cycling enabled tabs.
 * Direction is +1 (next) or -1 (previous), wrap-around in HubTabCallback.
 */
@Composable
fun TabArrow(palette: ChroniclePalette, iconRes: Int, direction: Int) {
    MealArrow(palette, iconRes) {
        actionRunCallback<HubTabCallback>(
            actionParametersOf(HubDirectionKey to direction),
        )
    }
}

/**
 * Meal stepper chevron: steps the native-owned meal override shared by
 * the hub menu tab and the standalone menu widget. Lives in tight
 * spaces (tab headers), so the box is 40.dp.
 */
@Composable
fun MenuStepArrow(palette: ChroniclePalette, iconRes: Int, direction: Int) {
    MealArrow(palette, iconRes, boxDp = 40.dp) {
        actionRunCallback<HubMenuMealCallback>(
            actionParametersOf(MenuMealDirectionKey to direction),
        )
    }
}

/** 48.dp tappable chevron box with a caller-supplied click action.
 * No press ripple: chevrons sit on the widget background and the flash
 * reads as a rendering glitch, not feedback (the tab/meal visibly steps). */
@Composable
private fun MealArrow(
    palette: ChroniclePalette,
    iconRes: Int,
    boxDp: Dp = 48.dp,
    onClick: () -> Action,
) {
    Box(
        modifier = GlanceModifier
            .width(boxDp)
            .height(boxDp)
            .background(fixedProvider(0x00000000L))
            .clickable(onClick = onClick(), rippleOverride = NoRippleOverride),
        contentAlignment = Alignment.Center,
    ) {
        Image(
            provider = ImageProvider(iconRes),
            contentDescription = null,
            modifier = GlanceModifier.width(20.dp).height(20.dp),
            colorFilter = ColorFilter.tint(palette.onSurfaceVariant),
        )
    }
}

/**
 * Meal switcher row: ‹ centered meal title ›. Arrows step the native-owned
 * meal-kind override via [arrowAction] (±1); hidden when a single meal is
 * servable. One Row with 3 children — safely under the RemoteViews limit.
 * The row itself also advances (+1) so near-misses don't fall through to
 * the whole-widget tap and open the app instead. Compact 40.dp arrows
 * (the ≥40dp hit-target floor) and a 12.sp title leave room for dishes.
 */
@Composable
fun MealSwitcher(
    palette: ChroniclePalette,
    title: String,
    showArrows: Boolean,
    leftIcon: Int,
    rightIcon: Int,
    arrowAction: (Int) -> Action,
) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(fixedProvider(0x00000000L))
            .clickable(onClick = arrowAction(1), rippleOverride = NoRippleOverride),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (showArrows) {
            MealArrow(palette, leftIcon, boxDp = 40.dp) { arrowAction(-1) }
        }
        Box(
            modifier = GlanceModifier.defaultWeight(),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = title,
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = if (isNarrowSlot()) 11.sp else 12.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                ),
                maxLines = 1,
            )
        }
        if (showArrows) {
            MealArrow(palette, rightIcon, boxDp = 40.dp) { arrowAction(1) }
        }
    }
}
