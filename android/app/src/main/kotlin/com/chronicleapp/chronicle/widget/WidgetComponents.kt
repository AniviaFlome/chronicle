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
import androidx.glance.LocalSize
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
import androidx.glance.layout.ColumnScope
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

/** Accent status pill ("in 12 min", "Currently"). */
@Composable
fun StatusPill(
    palette: ChroniclePalette,
    text: String,
    compact: Boolean = false,
) {
    if (text.isEmpty()) return
    Box(
        modifier = GlanceModifier
            .background(palette.accentChipBg)
            .cornerRadius(50.dp)
            .padding(
                horizontal = if (compact) 8.dp else 10.dp,
                vertical = if (compact) 3.dp else 4.dp,
            ),
    ) {
        Text(
            text = text,
            style = TextStyle(
                color = palette.accentChipFg,
                fontSize = if (compact) 11.sp else 12.sp,
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
    compact: Boolean = false,
) {
    if (text.isEmpty()) return
    val useCompact = compact || isNarrowSlot()
    var mod = GlanceModifier
        .background(if (urgent) palette.errorContainer else palette.chipBg)
        .cornerRadius(if (useCompact) 6.dp else 8.dp)
        .padding(
            horizontal = if (useCompact) 5.dp else 6.dp,
            vertical = if (useCompact) 2.dp else 3.dp,
        )
    if (width != null) mod = mod.width(width)
    Box(modifier = mod, contentAlignment = Alignment.Center) {
        Text(
            text = text,
            style = TextStyle(
                color = if (urgent) palette.error else palette.onSurfaceVariant,
                fontSize = if (useCompact) 10.sp else 11.sp,
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
 * Responsive chip width for lookahead lists:
 * - Below 300.dp (medium portrait slots like 260dp): `null` (wrap-content)
 *   so short times like "10:20" stay ~38dp and leave maximum width for the
 *   class name.
 * - 300.dp+ (wide landscape/4-col slots): fixed width aligned to the
 *   widest time shape in the list (`48.dp` for plain "10:20", `68.dp` when
 *   any row carries a weekday prefix like "Fri 15:23").
 * Narrow slots (<200.dp) stack time under the name and never use a side chip.
 */
@Composable
fun lookaheadChipWidth(hasWeekday: Boolean = true): Dp? =
    if (LocalSize.current.width < 300.dp) {
        null
    } else if (hasWeekday) {
        68.dp
    } else {
        48.dp
    }

/** Compact chip styling on medium widths (<300.dp) so the time chip never
 *  crowds out the class name. */
@Composable
fun isCompactLookaheadChip(): Boolean = LocalSize.current.width < 300.dp

/** Structured class row: name + one always-visible meta line in narrow
 * slots ("time · room"); medium/wide slots place a responsive [TonalChip]
 * beside the class name so the chip scales with the widget width. */
@Composable
fun FilledLookaheadRow(
    palette: ChroniclePalette,
    time: String,
    name: String,
    where: String = "",
    chipWidth: Dp? = null,
    wrapName: Boolean = false,
    compactChip: Boolean = isCompactLookaheadChip(),
) {
    // Subtler `card` surface (vs `cardHigh` on the Hero Card and TonalChip)
    // so upcoming rows stay visually subordinate to the hero and the time
    // chip has real tonal contrast against its row background.
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(palette.card)
            .cornerRadius(12.dp)
            .padding(horizontal = 10.dp, vertical = 6.dp),
    ) {
        if (isNarrowSlot()) {
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                Text(
                    text = name,
                    style = TextStyle(color = palette.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Bold),
                    // 1 line: at 2 lines the card's meta line clips at the
                    // widget edge (seen-on-device) — a truncated name + full
                    // "time · room" meta beats a full name with no location.
                    // The wrap-names option opts out of that trade-off.
                    maxLines = if (wrapName) Int.MAX_VALUE else 1,
                    modifier = GlanceModifier.fillMaxWidth(),
                )
                val meta = listOf(time, where).filter { it.isNotEmpty() }
                    .joinToString(" · ")
                if (meta.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Text(
                        text = meta,
                        // 10sp: at 11sp a "Mon 08:40 · C-K3-06[52]" meta
                        // ellipsizes on a 1-column card (~100dp text) — the
                        // room tail was the part that vanished (seen
                        // on-device). Time leads so the "when" never cuts.
                        style = TextStyle(color = palette.onSurfaceVariant, fontSize = 10.sp),
                        maxLines = 1,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            }
        } else {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (time.isNotEmpty()) {
                    TonalChip(palette, time, width = chipWidth, compact = compactChip)
                    Spacer(modifier = GlanceModifier.width(if (compactChip) 6.dp else 8.dp))
                }
                Column(modifier = GlanceModifier.defaultWeight()) {
                    Text(
                        text = name,
                        style = TextStyle(color = palette.onSurface, fontSize = 13.sp, fontWeight = FontWeight.Bold),
                        maxLines = if (wrapName) Int.MAX_VALUE else 2,
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
        }
    }
}

/**
 * Then-line for a timeline entry: structured name/when parts when pushed
 * (no baked-in "Then" prefix), legacy composed-string split as fallback
 * for old pushes. Uses the caller-supplied [chipWidth] so its class name
 * aligns with every [LookRow] below it; spacing above is owned by
 * [SharedClassTab].
 */
@Composable
fun ThenLine(
    palette: ChroniclePalette,
    entry: TimedEntry,
    thenRow: TimeRow? = null,
    wrapName: Boolean = false,
    chipWidth: Dp? = lookaheadChipWidth(hasWeekday = entry.thenWhen.contains(' ')),
) {
    if (entry.thenName.isNotEmpty()) {
        // Tomorrow's room/building ride the quiet entry's own fields (the
        // push side fills them with the class after "No classes today");
        // thenRow carries them on fresh pushes. The fallback is gated on
        // the quiet entry only — never the teacher — so a teacherless class
        // keeps its location. Either source may be an empty string (old
        // pushes), which ?: alone does not catch — hence takeIf.
        val quiet = entry.startLabel.isEmpty()
        val room = thenRow?.room?.takeIf { !it.isNullOrEmpty() }
            ?: entry.room.takeIf { quiet && it.isNotEmpty() }.orEmpty()
        val building = thenRow?.building?.takeIf { !it.isNullOrEmpty() }
            ?: entry.building.takeIf { quiet && it.isNotEmpty() }.orEmpty()
        FilledLookaheadRow(
            palette = palette,
            time = entry.thenWhen,
            name = entry.thenName,
            where = listOf(room, building).filter { it.isNotEmpty() }
                .joinToString(" · "),
            chipWidth = chipWidth,
            wrapName = wrapName,
        )
    } else if (entry.thenLine.isNotEmpty()) {
        FilledMiniRow(palette, entry.thenLine, entry.thenColorHex)
    }
}

/**
 * Shared class hero card: elevated tonal container (`cardHigh`, 16dp radius)
 * with an accent [StatusPill] eyebrow (+ right-aligned time range on slots
 * >= 260dp wide so it never clips), bold class title, grouped
 * `room · building` location line, and teacher line. Solid fill survives
 * translucent/transparent widget backgrounds. The upcoming section lives
 * in [SharedClassTab].
 */
@Composable
fun ClassHero(
    palette: ChroniclePalette,
    entry: TimedEntry,
    snap: WidgetSnapshot,
    nowMs: Long,
    titleSizeSp: Int,
    compact: Boolean = false,
) {
    val widthDp = LocalSize.current.width
    val narrow = widthDp < 200.dp
    val wideEyebrow = widthDp >= 260.dp
    val status = liveStatus(entry, snap, nowMs)
    val timeRange = entry.range.ifEmpty { entry.startLabel }
    val fittedTitleSp = when {
        narrow -> if (compact) 14 else 15
        !wideEyebrow -> if (compact) 16 else 18
        else -> titleSizeSp
    }
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(palette.cardHigh)
            .cornerRadius(16.dp)
            .padding(
                horizontal = if (narrow) 10.dp else 12.dp,
                vertical = if (narrow) 8.dp else 10.dp,
            ),
    ) {
        Column(modifier = GlanceModifier.fillMaxWidth()) {
            val hasEyebrow = if (wideEyebrow) {
                status.isNotEmpty() || timeRange.isNotEmpty()
            } else {
                status.isNotEmpty()
            }
            if (hasEyebrow) {
                if (wideEyebrow) {
                    Row(
                        modifier = GlanceModifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        if (status.isNotEmpty()) {
                            StatusPill(palette, status, compact = true)
                            if (timeRange.isNotEmpty()) {
                                Spacer(modifier = GlanceModifier.defaultWeight())
                                Text(
                                    text = timeRange,
                                    style = TextStyle(
                                        color = palette.onSurfaceVariant,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                    ),
                                    maxLines = 1,
                                )
                            }
                        } else if (timeRange.isNotEmpty()) {
                            TonalChip(palette, timeRange, compact = true)
                        }
                    }
                } else {
                    StatusPill(palette, status, compact = true)
                }
                Spacer(modifier = GlanceModifier.height(if (narrow) 4.dp else 6.dp))
            }
            Text(
                text = entry.className,
                style = TextStyle(
                    color = palette.onSurface,
                    fontSize = fittedTitleSp.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = if (snap.wrapName) Int.MAX_VALUE else 2,
                modifier = GlanceModifier.fillMaxWidth(),
            )
            if (!wideEyebrow) {
                val primaryMeta = if (timeRange.isNotEmpty()) {
                    listOf(timeRange, entry.room)
                        .filter { it.isNotEmpty() }
                        .joinToString(" · ")
                } else {
                    entry.detailLine
                }
                if (primaryMeta.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Text(
                        text = primaryMeta,
                        style = TextStyle(
                            color = palette.onSurfaceVariant,
                            fontSize = 11.sp,
                        ),
                        maxLines = 2,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
                if (!compact) {
                    val secondaryMeta = listOf(entry.teacher, entry.building)
                        .filter { it.isNotEmpty() }
                        .joinToString(" · ")
                    if (secondaryMeta.isNotEmpty()) {
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Text(
                            text = secondaryMeta,
                            style = TextStyle(
                                color = palette.onSurfaceVariant,
                                fontSize = 10.sp,
                            ),
                            maxLines = 1,
                            modifier = GlanceModifier.fillMaxWidth(),
                        )
                    }
                }
            } else {
                val where = listOf(entry.room, entry.building)
                    .filter { it.isNotEmpty() }
                    .joinToString(" · ")
                val locationLine = where.ifEmpty {
                    if (timeRange.isEmpty()) entry.detailLine else ""
                }
                if (locationLine.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Text(
                        text = locationLine,
                        style = TextStyle(
                            color = palette.onSurfaceVariant,
                            fontSize = 12.sp,
                        ),
                        maxLines = 1,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
                if (entry.teacher.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Text(
                        text = entry.teacher,
                        style = TextStyle(
                            color = palette.onSurfaceVariant,
                            fontSize = 11.sp,
                        ),
                        maxLines = 1,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            }
        }
    }
}

/**
 * Shared class tab body — the single source of truth used by the hub
 * class tab AND the standalone Next-class widget, so the two render
 * identically: quiet/sentinel entries as a compact banner or empty state,
 * otherwise the elevated [ClassHero] card separated from an aligned
 * upcoming lookahead section.
 *
 * [chromeDp] accounts for surrounding widget chrome (24dp for standalone
 * shell padding; 92dp for the hub's header + bottom tab bar).
 *
 * IMPORTANT: this emits multiple root nodes. Always invoke it inside a
 * vertical [Column] — a bare multi-root composition has no stacking
 * container and siblings paint on top of each other.
 */
@Composable
fun SharedClassTab(
    palette: ChroniclePalette,
    entry: TimedEntry?,
    snap: WidgetSnapshot,
    nowMs: Long,
    looks: List<TimeRow>,
    compact: Boolean = false,
    chromeDp: Int = 24,
) {
    // Timeline is self-expiring via its closing "—" sentinel: never gate on
    // snap.stale (todayIso != deviceToday), which threw away valid multi-day
    // entries at midnight until the user opened the app.
    if (entry == null || entry.isSentinel) {
        EmptyState(
            palette,
            R.drawable.ic_widget_event_available,
            entry?.heroName(snap)?.ifEmpty { snap.emptyText }
                ?: snap.staleName.ifEmpty { snap.emptyText },
        )
        return
    }
    val quiet = entry.startLabel.isEmpty()
    // The Then-line class rides in looks[0] (same class by contract) —
    // its row carries the where meta; old pushes fall back to the quiet
    // entry's own fields (see ThenLine). Drop ONLY looks[0] (never
    // filterNot across the full 14-day list, which would also delete the
    // same class next week).
    val firstMatchesThen = looks.isNotEmpty() &&
        looks[0].time == entry.thenWhen &&
        looks[0].name == entry.thenName
    val thenRow = if (firstMatchesThen) looks[0] else looks.firstOrNull {
        it.time == entry.thenWhen && it.name == entry.thenName
    }
    val next = if (firstMatchesThen) looks.drop(1) else looks
    val hasThen = entry.thenName.isNotEmpty() || entry.thenLine.isNotEmpty()
    val leadDp = when {
        quiet -> 92
        compact -> 150
        else -> 164
    }
    val rawBudget = lookRowBudget(chromeDp = chromeDp, leadDp = leadDp)
    val budget = if (compact) rawBudget.coerceAtMost(1) else rawBudget
    val shown = next.take(budget)
    val hasWeekday = (entry.thenName.isNotEmpty() && entry.thenWhen.contains(' ')) ||
        shown.any { it.time.contains(' ') }
    val chipWidth = lookaheadChipWidth(hasWeekday = hasWeekday)

    if (quiet) {
        val narrow = isNarrowSlot()
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(palette.cardHigh)
                .cornerRadius(if (narrow) 14.dp else 16.dp)
                .padding(
                    horizontal = if (narrow) 10.dp else 12.dp,
                    vertical = if (narrow) 8.dp else 10.dp,
                ),
        ) {
            if (narrow) {
                // Narrow slots stack the circular accent badge above the title
                // so "No classes today" gets 100% card width and never clips.
                Column(modifier = GlanceModifier.fillMaxWidth()) {
                    Box(
                        modifier = GlanceModifier
                            .width(24.dp)
                            .height(24.dp)
                            .background(palette.accentChipBg)
                            .cornerRadius(50.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_event_available),
                            contentDescription = null,
                            modifier = GlanceModifier.width(13.dp).height(13.dp),
                            colorFilter = ColorFilter.tint(palette.accentChipFg),
                        )
                    }
                    Spacer(modifier = GlanceModifier.height(5.dp))
                    Text(
                        text = entry.className,
                        style = TextStyle(
                            color = palette.onSurface,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 2,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            } else {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        modifier = GlanceModifier
                            .width(32.dp)
                            .height(32.dp)
                            .background(palette.accentChipBg)
                            .cornerRadius(50.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_event_available),
                            contentDescription = null,
                            modifier = GlanceModifier.width(16.dp).height(16.dp),
                            colorFilter = ColorFilter.tint(palette.accentChipFg),
                        )
                    }
                    Spacer(modifier = GlanceModifier.width(10.dp))
                    Column(modifier = GlanceModifier.defaultWeight()) {
                        Text(
                            text = entry.className,
                            style = TextStyle(
                                color = palette.onSurface,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 1,
                            modifier = GlanceModifier.fillMaxWidth(),
                        )
                        if (entry.thenWhen.isNotEmpty()) {
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Text(
                                text = entry.thenWhen,
                                style = TextStyle(
                                    color = palette.onSurfaceVariant,
                                    fontSize = 11.sp,
                                ),
                                maxLines = 1,
                                modifier = GlanceModifier.fillMaxWidth(),
                            )
                        }
                    }
                }
            }
        }
    } else {
        ClassHero(
            palette = palette,
            entry = entry,
            snap = snap,
            nowMs = nowMs,
            titleSizeSp = if (compact) 18 else 20,
            compact = compact,
        )
    }

    if (hasThen || shown.isNotEmpty()) {
        if (compact) {
            Spacer(modifier = GlanceModifier.height(6.dp))
        } else {
            Spacer(modifier = GlanceModifier.height(8.dp))
            Hairline(palette)
            Spacer(modifier = GlanceModifier.height(6.dp))
        }
        // Group upcoming rows inside a dedicated Column so the parent
        // Column stays well under Glance's ~10-child RemoteViews limit.
        Column(modifier = GlanceModifier.fillMaxWidth()) {
            if (hasThen) {
                ThenLine(palette, entry, thenRow, wrapName = snap.wrapName, chipWidth = chipWidth)
            }
            for ((i, row) in shown.withIndex()) {
                if (hasThen || i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                LookRow(palette, row, chipWidth = chipWidth)
            }
        }
    }
}

/**
 * How many extra lookahead rows fit after the lead block (quiet banner +
 * Then-card, or Hero Card + Hairline + Then-card). Rounded down hard:
 * Glance squeezes overflow to slivers instead of clipping (seen-on-device),
 * so a row only renders when it has real room.
 */
@Composable
private fun lookRowBudget(chromeDp: Int, leadDp: Int): Int {
    val height = LocalSize.current.height.value
    return ((height - chromeDp - leadDp) / 46).toInt().coerceIn(0, 3)
}

/** One lookahead row rendered through the shared class row. */
@Composable
private fun LookRow(
    palette: ChroniclePalette,
    row: TimeRow,
    chipWidth: Dp? = lookaheadChipWidth(hasWeekday = row.time.contains(' ')),
) {
    FilledLookaheadRow(
        palette = palette,
        time = row.time,
        name = row.name,
        where = listOf(row.room, row.building).filter { it.isNotEmpty() }
            .joinToString(" · "),
        chipWidth = chipWidth,
    )
}

/**
 * Keep-style checklist row: tonal block with filled square checkbox, 14sp
 * single-line title, 11sp details meta (class · steps) and due chip. Dense
 * by design: the block is the unit that repeats 2/4/8 times per widget,
 * so the title stays one line and the details ride a small meta line
 * instead of a second tall row.
 */
@Composable
fun FilledCheckRow(
    palette: ChroniclePalette,
    title: String,
    date: String,
    urgent: Boolean,
    className: String = "",
    steps: String = "",
) {
    val blockBg = if (urgent) palette.errorContainer else palette.cardHigh
    val meta = listOf(className, steps).filter { it.isNotEmpty() }
        .joinToString(" · ")
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(blockBg)
            .cornerRadius(12.dp)
            .padding(horizontal = 10.dp, vertical = 6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            SquareCheck(
                fill = if (urgent) palette.error else palette.accent,
                inset = blockBg,
            )
            Spacer(modifier = GlanceModifier.width(10.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = title,
                    style = TextStyle(
                        color = palette.onSurface,
                        fontSize = 14.sp,
                        fontWeight = if (urgent) FontWeight.Bold else FontWeight.Normal,
                    ),
                    maxLines = 1,
                    modifier = GlanceModifier.fillMaxWidth(),
                )
                if (meta.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Text(
                        text = meta,
                        style = TextStyle(
                            color = palette.onSurfaceVariant,
                            fontSize = 11.sp,
                        ),
                        maxLines = 1,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            }
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

/** Drawn square checkbox: accent fill + block-colored inset (no stroke).
 *  16dp: rows repeat up to 8 per widget, so the box stays compact. */
@Composable
private fun SquareCheck(fill: androidx.glance.unit.ColorProvider, inset: androidx.glance.unit.ColorProvider) {
    Box(
        modifier = GlanceModifier
            .width(16.dp)
            .height(16.dp)
            .background(fill)
            .cornerRadius(5.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = GlanceModifier
                .width(12.dp)
                .height(12.dp)
                .background(inset)
                .cornerRadius(3.dp),
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
 * Intentional empty state: tonal surface card with a circular accent-tinted
 * icon badge and bold message. Pass [fill] = true on standalone empty widgets
 * so the card centers vertically instead of clinging to the top edge; keep
 * [fill] = false (default) inside wrapping Columns (Hub, Agenda, Tasks).
 */
@Composable
fun EmptyState(
    palette: ChroniclePalette,
    iconRes: Int,
    text: String,
    subtitle: String = "",
    fill: Boolean = false,
) {
    val narrow = isNarrowSlot()
    val containerMod = if (fill) {
        GlanceModifier.fillMaxSize()
    } else {
        GlanceModifier.fillMaxWidth().padding(vertical = 4.dp)
    }
    Box(
        modifier = containerMod,
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(palette.card)
                .cornerRadius(16.dp)
                .padding(
                    horizontal = if (narrow) 10.dp else 14.dp,
                    vertical = if (narrow) 12.dp else 14.dp,
                ),
            contentAlignment = Alignment.Center,
        ) {
            Column(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(
                    modifier = GlanceModifier
                        .width(if (narrow) 32.dp else 36.dp)
                        .height(if (narrow) 32.dp else 36.dp)
                        .background(palette.accentChipBg)
                        .cornerRadius(50.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Image(
                        provider = ImageProvider(iconRes),
                        contentDescription = null,
                        modifier = GlanceModifier
                            .width(if (narrow) 16.dp else 18.dp)
                            .height(if (narrow) 16.dp else 18.dp),
                        colorFilter = ColorFilter.tint(palette.accentChipFg),
                    )
                }
                Spacer(modifier = GlanceModifier.height(8.dp))
                Text(
                    text = text,
                    style = TextStyle(
                        color = palette.onSurface,
                        fontSize = if (narrow) 12.sp else 13.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    ),
                    maxLines = 2,
                    modifier = GlanceModifier.fillMaxWidth(),
                )
                if (subtitle.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Text(
                        text = subtitle,
                        style = TextStyle(
                            color = palette.onSurfaceVariant,
                            fontSize = 11.sp,
                            textAlign = TextAlign.Center,
                        ),
                        maxLines = 1,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            }
        }
    }
}

/**
 * Redesigned menu dish card: subtle tonal container (`card`, 10dp radius)
 * with a vertical accent pill, bold dish name, optional garnish/side
 * subtitle, and trailing kcal chip on wide slots.
 */
@Composable
fun DishRow(palette: ChroniclePalette, item: MenuDishItem) {
    val narrow = isNarrowSlot()
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(palette.card)
            .cornerRadius(10.dp)
            .padding(
                horizontal = if (narrow) 8.dp else 10.dp,
                vertical = if (narrow) 5.dp else 6.dp,
            ),
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = GlanceModifier
                    .width(3.dp)
                    .height(if (item.side.isNotEmpty()) 22.dp else 14.dp)
                    .background(palette.accent)
                    .cornerRadius(50.dp),
            ) {}
            Spacer(modifier = GlanceModifier.width(8.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = item.name,
                    style = TextStyle(
                        color = palette.onSurface,
                        fontSize = if (narrow) 12.sp else 13.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 2,
                    modifier = GlanceModifier.fillMaxWidth(),
                )
                if (item.side.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Text(
                        text = item.side,
                        style = TextStyle(
                            color = palette.onSurfaceVariant,
                            fontSize = 10.sp,
                        ),
                        maxLines = 1,
                        modifier = GlanceModifier.fillMaxWidth(),
                    )
                }
            }
            if (!narrow && item.kcal > 0) {
                Spacer(modifier = GlanceModifier.width(6.dp))
                TonalChip(palette, "${item.kcal} kcal", compact = true)
            }
        }
    }
}

/** Legacy plain-string overload for short/compact callers. */
@Composable
fun DishRow(palette: ChroniclePalette, text: String) {
    DishRow(palette, MenuDishItem(name = text))
}

/**
 * Shared scrolling dish list (structured items): the hub menu tab and the
 * standalone cafeteria-menu widget render the exact same tonal dish cards.
 */
@Composable
fun ColumnScope.SharedMenuItemList(
    palette: ChroniclePalette,
    items: List<MenuDishItem>,
) {
    // Weight-bound LazyColumn inside a bounded body (a wrap-content list
    // would measure only its first item); items wrap in their own Column
    // (bare single-node items mismeasure, spacers collapse to zero).
    LazyColumn(modifier = GlanceModifier.defaultWeight()) {
        items(items.size) { i ->
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                if (i > 0) Spacer(modifier = GlanceModifier.height(5.dp))
                DishRow(palette, items[i])
            }
        }
    }
}

/** Legacy string-list wrapper delegating to [SharedMenuItemList]. */
@Composable
fun ColumnScope.SharedMenuList(palette: ChroniclePalette, dishes: List<String>) {
    SharedMenuItemList(palette, dishes.map { MenuDishItem(name = it) })
}

/**
 * Shared scrolling agenda list: the hub agenda tab and the standalone
 * agenda widget render the very same rows (a copy, not a second design).
 * Short tiers keep their fitting-take variants as the documented space
 * adjustment; everything tall scrolls this full list.
 */
@Composable
fun ColumnScope.SharedAgendaList(
    context: Context,
    palette: ChroniclePalette,
    rows: List<TimeRow>,
) {
    LazyColumn(modifier = GlanceModifier.defaultWeight()) {
        items(rows.size) { i ->
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                val row = rows[i]
                ClassRow(context, palette, row.time, row.name, row.colorHex)
            }
        }
    }
}

/**
 * Shared scrolling tasks list: the hub tasks tab and the standalone
 * due-tasks widget render the very same rows (a copy, not a second
 * design). Short tiers keep their fitting-take variants as the documented
 * space adjustment; everything tall scrolls this full list.
 */
@Composable
fun ColumnScope.SharedTasksList(
    palette: ChroniclePalette,
    tasks: List<TaskRow>,
) {
    LazyColumn(modifier = GlanceModifier.defaultWeight()) {
        items(tasks.size) { i ->
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                if (i > 0) Spacer(modifier = GlanceModifier.height(6.dp))
                val task = tasks[i]
                TaskRow(
                    palette,
                    task.title,
                    task.date,
                    task.urgent,
                    task.className,
                    task.steps,
                )
            }
        }
    }
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
fun TaskRow(
    palette: ChroniclePalette,
    title: String,
    date: String,
    urgent: Boolean,
    className: String = "",
    steps: String = "",
) {
    FilledCheckRow(palette, title, date, urgent, className, steps)
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
    tonal: Boolean = false,
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
        if (tonal) {
            Box(
                modifier = GlanceModifier
                    .width(28.dp)
                    .height(28.dp)
                    .background(palette.card)
                    .cornerRadius(10.dp),
                contentAlignment = Alignment.Center,
            ) {
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = null,
                    modifier = GlanceModifier.width(16.dp).height(16.dp),
                    colorFilter = ColorFilter.tint(palette.onSurface),
                )
            }
        } else {
            Image(
                provider = ImageProvider(iconRes),
                contentDescription = null,
                modifier = GlanceModifier.width(20.dp).height(20.dp),
                colorFilter = ColorFilter.tint(palette.onSurfaceVariant),
            )
        }
    }
}

/**
 * Meal switcher row: ‹ centered meal title ›. Arrows step the native-owned
 * meal-kind override via [arrowAction] (±1); hidden when a single meal is
 * servable. One Row with 3 children — safely under the RemoteViews limit.
 * On wide slots, "Lunch · ITU" splits into an accent [StatusPill] ("Lunch")
 * over a muted source label ("ITU").
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
    val narrow = isNarrowSlot()
    val arrowBox = if (narrow) 32.dp else 40.dp
    val sep = title.indexOf(" · ")
    val splitTitle = !narrow && sep > 0 && sep + 3 < title.length
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (showArrows) {
            MealArrow(palette, leftIcon, boxDp = arrowBox, tonal = true) { arrowAction(-1) }
        }
        Box(
            modifier = GlanceModifier.defaultWeight(),
            contentAlignment = Alignment.Center,
        ) {
            if (splitTitle) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    StatusPill(palette, title.substring(0, sep), compact = true)
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Text(
                        text = title.substring(sep + 3),
                        style = TextStyle(
                            color = palette.onSurfaceVariant,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center,
                        ),
                        maxLines = 1,
                    )
                }
            } else {
                // Narrow slots strip the " · Provider" suffix ("Lunch · Hacettepe"
                // -> "Lunch") so the meal name never truncates to "Lun..." between
                // the stepper buttons.
                val compactLabel = if (narrow && sep > 0) title.substring(0, sep) else title
                Text(
                    text = compactLabel,
                    style = TextStyle(
                        color = palette.onSurface,
                        fontSize = if (narrow) 11.sp else 13.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    ),
                    maxLines = 1,
                )
            }
        }
        if (showArrows) {
            MealArrow(palette, rightIcon, boxDp = arrowBox, tonal = true) { arrowAction(1) }
        }
    }
}
