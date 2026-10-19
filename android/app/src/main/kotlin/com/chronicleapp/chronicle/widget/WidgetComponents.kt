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
 * Ripple override that actually suppresses press visuals. Glance 1.2.0's
 * `NoRippleOverride` is just int 0, which the appwidget translator maps to
 * the DEFAULT ripple (verified from dex forensics:
 * NormalizeCompositionTreeKt.transformBackgroundImageAndActionRipple uses the
 * override id as the ripple drawable, falling back to `glance_ripple` when
 * it is 0) — so `NoRippleOverride` never suppressed anything and every tap
 * flashed the stock grey ripple. Pass this transparent drawable instead:
 * a non-animating fill renders zero press visuals while the tap keeps
 * working. Use on every tap target that must stay visually silent.
 *
 * Plain `val` with a getter, never `const`: the compile-time R class stubs
 * every id as 0 (real ids only exist at runtime), so a `const` would bake
 * in 0 and silently re-enable the default ripple — verified the hard way
 * from the built dex.
 */
val NoPressFeedback: Int
    get() = R.drawable.widget_no_feedback

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
                rippleOverride = NoPressFeedback,
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

/**
 * Class detail under an expanded hero: teacher + "room · building ·
 * range" as ONE Text node (repeated sibling Texts mismeasure on-device —
 * seen as a squeezed sliver). Blank parts vanish from the join.
 */
@Composable
fun RowDetail(
    palette: ChroniclePalette,
    teacher: String,
    room: String,
    building: String,
    range: String,
) {
    val text = detailText(teacher, room, building, range)
    if (text.isEmpty()) return
    Spacer(modifier = GlanceModifier.height(4.dp))
    Text(
        text = text,
        style = TextStyle(color = palette.onSurfaceVariant, fontSize = 10.sp),
        maxLines = 3,
        modifier = GlanceModifier.fillMaxWidth(),
    )
}

/**
 * One class row (time chip + name + optional where meta) with the shared
 * expand behaviour: tappable when it has any detail to reveal ([at] != 0),
 * tapping toggles a detail line below the card. Every class row in the
 * widgets goes through here so "some rows expand and some don't" can never
 * come back. Rows with no detail render plain (a tappable row that reveals
 * nothing reads as a dead tap). The detail is one Text sibling under the
 * card — inside the card it grows the fill only partially and the tail
 * clips at the card edge (seen-on-device). Safe here because the grow rule
 * in [SharedClassTab] drops the rows underneath first, so the line always
 * has its own room.
 */
@Composable
fun ClassDetailRow(
    palette: ChroniclePalette,
    time: String,
    name: String,
    chipWidth: Dp? = null,
    at: Long = 0,
    teacher: String = "",
    room: String = "",
    building: String = "",
    range: String = "",
    expanded: Boolean = false,
    expandToggle: ((Long) -> Action)? = null,
) {
    // When expanded the detail line already carries room · building, so
    // the compact where meta drops: it would repeat the room and, worse,
    // the extra line tips a short widget into overflow (the tail clips at
    // the card edge — seen-on-device).
    val where = if (expanded) {
        ""
    } else {
        listOf(room, building).filter { it.isNotEmpty() }.joinToString(" · ")
    }
    val detail = detailText(teacher, room, building, range)
    val toggle = expandToggle
    if (at == 0L || detail.isEmpty() || toggle == null) {
        FilledLookaheadRow(palette, time, name, where = where, chipWidth = chipWidth)
        return
    }
    val card: @Composable () -> Unit = {
        FilledLookaheadRow(palette, time, name, where = where, chipWidth = chipWidth)
    }
    if (!expanded) {
        // Collapsed: emit the card alone. The Column wrapper exists only to
        // stack the detail under it — kept as a permanent level it squeezes
        // the NEXT row in the list to a 5px sliver (seen-on-device).
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(fixedProvider(0x00000000L))
                .clickable(onClick = toggle(at), rippleOverride = NoPressFeedback),
        ) {
            card()
        }
        return
    }
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(fixedProvider(0x00000000L))
                .clickable(onClick = toggle(at), rippleOverride = NoPressFeedback),
        ) {
            card()
        }
        RowDetail(palette, teacher, room, building, range)
    }
}

/** Structured lookahead row: tonal time chip + bold name + optional where
 * meta + optional expanded detail (one Text, inside the card). Wide slots
 * keep the compact horizontal form with a FIXED chip width so every name
 * in the list starts at the same x (weekday-prefixed chips like "Wed 13:40"
 * are wider than plain "08:40"); narrow slots (~145.dp columns) stack
 * vertically (full-width name first, chip below) because a weekday-prefixed
 * chip ("Mon 08:40") otherwise eats the whole row and the name collapses
 * into a 3-character sliver (seen on-device). */
@Composable
fun FilledLookaheadRow(
    palette: ChroniclePalette,
    time: String,
    name: String,
    where: String = "",
    chipWidth: Dp? = null,
    detail: String = "",
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
                if (where.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Text(
                        text = where,
                        style = TextStyle(color = palette.onSurfaceVariant, fontSize = 11.sp),
                        maxLines = 1,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
                if (time.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    TonalChip(palette, time)
                }
                if (detail.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Text(
                        text = detail,
                        style = TextStyle(color = palette.onSurfaceVariant, fontSize = 11.sp),
                        maxLines = 2,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            }
        } else {
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (time.isNotEmpty()) {
                        TonalChip(palette, time, width = chipWidth)
                        Spacer(modifier = GlanceModifier.width(6.dp))
                    }
                    Column(modifier = GlanceModifier.defaultWeight()) {
                        Text(
                            text = name,
                            style = TextStyle(color = palette.onSurface, fontSize = 13.sp, fontWeight = FontWeight.Bold),
                            maxLines = 2,
                            modifier = GlanceModifier.fillMaxWidth(),
                        )
                        if (where.isNotEmpty()) {
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Text(
                                text = where,
                                style = TextStyle(color = palette.onSurfaceVariant, fontSize = 11.sp),
                                maxLines = 1,
                                modifier = GlanceModifier.fillMaxWidth(),
                            )
                        }
                    }
                }
                if (detail.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Text(
                        text = detail,
                        style = TextStyle(color = palette.onSurfaceVariant, fontSize = 11.sp),
                        maxLines = 2,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            }
        }
    }
}

/**
 * Then-line for a timeline entry: structured name/when parts when pushed
 * (no baked-in "Then" prefix), legacy composed-string split as fallback
 * for old pushes. A full class row like any other: its expand key and
 * detail come from [thenRow] (the looks[0] duplicate — same class by
 * contract). Old pushes carry no row fields; quiet entries then fall back
 * to the entry-level teacher (which is the next class's teacher there).
 */
@Composable
fun ThenLine(
    palette: ChroniclePalette,
    entry: TimedEntry,
    thenRow: TimeRow? = null,
    expandedAt: Long = -1L,
    expandToggle: ((Long) -> Action)? = null,
) {
    if (entry.thenName.isNotEmpty()) {
        Spacer(modifier = GlanceModifier.height(4.dp))
        val row = thenRow?.takeIf { it.at != 0L }
        val quietFallback = entry.startLabel.isEmpty() && entry.teacher.isNotEmpty()
        val at = row?.at ?: if (quietFallback) entry.at else 0L
        val teacher = row?.teacher ?: if (quietFallback) entry.teacher else ""
        val room = row?.room ?: if (quietFallback) entry.room else ""
        val building = row?.building ?: if (quietFallback) entry.building else ""
        val range = row?.range ?: if (quietFallback) entry.range else ""
        ClassDetailRow(
            palette = palette,
            time = entry.thenWhen,
            name = entry.thenName,
            at = at,
            teacher = teacher,
            room = room,
            building = building,
            range = range,
            expanded = at != 0L && expandedAt == at,
            expandToggle = expandToggle,
        )
    } else if (entry.thenLine.isNotEmpty()) {
        Spacer(modifier = GlanceModifier.height(4.dp))
        FilledMiniRow(palette, entry.thenLine, entry.thenColorHex)
    }
}

/**
 * Shared class hero: big title, gray status/time/room meta, then-line.
 * The lookahead list itself lives in [SharedClassTab] (scrollable or
 * static depending on bucket). Tapping the title toggles the hero's
 * detail (teacher + where + when) when it has any — rows without detail
 * render non-tappable instead of dead taps.
 */
@Composable
fun ClassHero(
    palette: ChroniclePalette,
    entry: TimedEntry,
    snap: WidgetSnapshot,
    nowMs: Long,
    titleSizeSp: Int,
    thenRow: TimeRow? = null,
    expandedAt: Long = -1L,
    expandToggle: ((Long) -> Action)? = null,
    showThen: Boolean = true,
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
    val heroDetail = detailText(entry.teacher, entry.room, entry.building, entry.range)
    val heroToggle = if (heroDetail.isEmpty()) null else expandToggle
    // The whole title is the tap target (a bare Text takes no click
    // action); without an action it renders as a plain title.
    if (heroToggle == null) {
        title()
    } else {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(fixedProvider(0x00000000L))
                .clickable(onClick = heroToggle(entry.at), rippleOverride = NoPressFeedback),
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
    if (heroToggle != null && expandedAt == entry.at) {
        RowDetail(palette, entry.teacher, entry.room, entry.building, entry.range)
    }
    // The then-line sits below the hero: when the hero itself is the
    // expanded row it drops too (see the grow rule in SharedClassTab).
    if (showThen) {
        ThenLine(palette, entry, thenRow, expandedAt, expandToggle)
    }
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
    expandedAt: Long = -1L,
    expandToggle: ((Long) -> Action)? = null,
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
    // The Then-line class rides in looks[0] (same class by contract) — its
    // row carries the expand key + detail; old pushes fall back to the
    // quiet entry's teacher (see ThenLine).
    val thenRow = looks.firstOrNull { it.time == entry.thenWhen && it.name == entry.thenName }
    // An expanded row owns the widget's height: rows BELOW it are dropped
    // until collapse. A short widget cannot fit an expanded card plus the
    // full list, and Glance squeezes the overflow to slivers instead of
    // clipping (seen on-device: detail text cut at the card edge).
    val thenAt = thenRow?.takeIf { it.at != 0L }?.at
    val expandedThen = thenAt != null && expandedAt == thenAt
    val expandedIdx = looks.indexOfFirst { it.at != 0L && it.at == expandedAt }
    val heroExpanded = entry != null && !entry.isSentinel && expandedAt != 0L &&
        expandedAt == entry.at
    val next = looks.filterNot { it.time == entry.thenWhen && it.name == entry.thenName }
    val expandedNextIdx = next.indexOfFirst { it.at != 0L && it.at == expandedAt }
    if (quiet) {
        // The quiet status copy ("No classes today") is the first thing to
        // go when a row expands: the expanded card needs the height, and a
        // short widget otherwise clips the detail tail (seen-on-device).
        if (!(expandedThen || expandedNextIdx >= 0)) {
            Text(
                text = entry.className,
                style = TextStyle(
                    color = palette.onSurfaceVariant,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 2,
            )
        }
        ThenLine(palette, entry, thenRow, expandedAt, expandToggle)
        val nextVisible = when {
            expandedThen -> emptyList()
            expandedNextIdx >= 0 -> next.take(expandedNextIdx + 1)
            else -> next
        }
        if (nextVisible.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(6.dp))
            // Narrow stacked rows are ~3x taller than wide horizontal ones:
            // the Then-card already takes the one row a narrow widget fits,
            // and a squeezed row mismeasures into a 5px sliver instead of
            // clipping (seen-on-device), so narrow renders no further rows.
            // Wide widgets keep two rows plus the indicator. An expanded row
            // shows every row up to itself and no indicator.
            val narrow = isNarrowSlot()
            val growing = expandedThen || expandedNextIdx >= 0
            val shown = if (growing) {
                nextVisible
            } else {
                nextVisible.take(if (narrow) 0 else 2)
            }
            for ((i, row) in shown.withIndex()) {
                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                LookRow(palette, row, expandedAt, expandToggle)
            }
            if (!narrow && !growing) {
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
            thenRow = thenRow,
            expandedAt = expandedAt,
            expandToggle = expandToggle,
            showThen = !heroExpanded,
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
        // Same grow rule as the quiet branch: an expanded row keeps rows
        // up to itself and drops the ones below (the card grows; the tail
        // would squeeze to slivers in a short widget).
        val expandedUpcomingIdx = upcoming.indexOfFirst { it.at != 0L && it.at == expandedAt }
        val growing = heroExpanded || expandedThen || expandedUpcomingIdx >= 0
        val upcomingVisible = when {
            heroExpanded || expandedThen -> emptyList()
            expandedUpcomingIdx >= 0 -> upcoming.take(expandedUpcomingIdx + 1)
            else -> upcoming
        }
        if (upcomingVisible.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(6.dp))
            if (compact) {
                val shown = if (growing) upcomingVisible else upcomingVisible.take(2)
                for ((i, row) in shown.withIndex()) {
                    if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                    LookRow(palette, row, expandedAt, expandToggle)
                }
                if (!growing) {
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    MoreIndicator(palette, upcoming.size - shown.size)
                }
            } else {
                // Plain wrapper: it only exists so the weight below resolves
                // inside a Column scope (a bare weight has no scope here).
                // The weight itself binds against the outer bounded shell —
                // the same arrangement the verified menu lists use. Items
                // wrap in their own Column too: multi-root lazy items do
                // not stack reliably (gap spacers collapse to zero).
                Column(modifier = GlanceModifier.fillMaxWidth()) {
                    LazyColumn(modifier = GlanceModifier.defaultWeight()) {
                        items(upcomingVisible.size) { i ->
                            Column(modifier = GlanceModifier.fillMaxWidth()) {
                                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                                LookRow(palette, upcomingVisible[i], expandedAt, expandToggle)
                            }
                        }
                    }
                }
            }
        }
    }
}

/** One lookahead row rendered through the shared expandable class row. */
@Composable
private fun LookRow(
    palette: ChroniclePalette,
    row: TimeRow,
    expandedAt: Long,
    expandToggle: ((Long) -> Action)?,
) {
    ClassDetailRow(
        palette = palette,
        time = row.time,
        name = row.name,
        chipWidth = lookaheadChipWidth(),
        at = row.at,
        teacher = row.teacher,
        room = row.room,
        building = row.building,
        range = row.range,
        expanded = row.at != 0L && expandedAt == row.at,
        expandToggle = expandToggle,
    )
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
            .clickable(onClick = onClick(), rippleOverride = NoPressFeedback),
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
            .clickable(onClick = arrowAction(1), rippleOverride = NoPressFeedback),
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
