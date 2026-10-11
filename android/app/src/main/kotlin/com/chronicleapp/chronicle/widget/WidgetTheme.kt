// Hand-written widget design tokens (Chronicle M3 Expressive redesign).
// NOT generated — edit freely. See AGENTS.md "Home widgets".
package com.chronicleapp.chronicle.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceTheme
// glance.color.ColorProvider(day, night) is a factory FUNCTION and illegal
// as a type — alias it and keep the unit interface as the type name.
import androidx.glance.color.ColorProvider as dayNightColor
import androidx.glance.unit.ColorProvider

/**
 * Resolved color set for one widget render.
 *
 * Two sources:
 *  - Material You (`useYou`): GlanceTheme system roles (Monet on Android 12+),
 *    resolved EAGERLY against the render context.
 *  - App theme: the 12-entry family table keyed by the `themeBg` code
 *    (familyIndex * 2 + darkBit). Raw pushed ARGB crashed Glance on-device
 *    (Color(Int) is ARGB, Color(ULong) is packed) — the code table plus
 *    locally constructed Longs is the crash-safe path. Never push ARGB.
 *
 * Every provider in here is a plain [fixedProvider] (DayNightColorProvider).
 * Glance's RemoteViews translator REJECTS custom ColorProvider
 * implementations for `background()` ("Unexpected background color modifier"
 * — the fill is silently dropped), so tonal steps (card / cardHigh /
 * accentContainer) are blended to concrete ARGB at palette-build time and
 * wrapped in [fixedProvider]. Never pass a hand-written ColorProvider to
 * `background()`.
 */
class ChroniclePalette(
    val bg: ColorProvider,
    val onSurface: ColorProvider,
    val onSurfaceVariant: ColorProvider,
    val outline: ColorProvider,
    val accent: ColorProvider,
    val accentContainer: ColorProvider,
    val onAccentContainer: ColorProvider,
    val card: ColorProvider,
    val cardHigh: ColorProvider,
    val error: ColorProvider,
    val errorContainer: ColorProvider,
) {
    /** Neutral tonal chip (time chips, date pills on plain rows). */
    val chipBg: ColorProvider get() = cardHigh

    /** Accent tonal chip (status pills, counts, selection). */
    val accentChipBg: ColorProvider get() = accentContainer

    val accentChipFg: ColorProvider get() = onAccentContainer
}

/** Static single-color provider (app-theme table + parsed class colors). */
fun fixedProvider(argb: Long): ColorProvider =
    dayNightColor(day = Color(argb.toInt()), night = Color(argb.toInt()))

/** ARGB blend of [over] onto [base] at [alpha], as a plain Long. */
fun blendArgb(base: Long, over: Long, alpha: Float): Long {
    fun ch(sb: Int, so: Int): Int = (sb * (1f - alpha) + so * alpha).toInt().coerceIn(0, 255)
    val b = base.toInt()
    val o = over.toInt()
    return ((255L shl 24) or
        (ch((b shr 16) and 0xFF, (o shr 16) and 0xFF).toLong() shl 16) or
        (ch((b shr 8) and 0xFF, (o shr 8) and 0xFF).toLong() shl 8) or
        ch(b and 0xFF, o and 0xFF).toLong())
}

/** Unsigned ARGB Long out of a compose [Color] (Float channels → packed). */
private fun argbOf(color: Color): Long =
    color.toArgb().toLong() and 0xFFFFFFFFL

/** Parses a pushed class-color hex ("FF4F6BED" or "4F6BED"); null when absent/invalid. */
fun parseClassColor(hex: String?): ColorProvider? {
    val v = classColorArgb(hex) ?: return null
    return fixedProvider(v)
}

/** Raw ARGB Long behind [parseClassColor]; null when absent/invalid. */
fun classColorArgb(hex: String?): Long? {
    val h = hex?.trim().orEmpty()
    if (h.isEmpty()) return null
    return try {
        when (h.length) {
            6 -> 0xFF000000L or h.toLong(16)
            8 -> h.toLong(16)
            else -> null
        }
    } catch (_: NumberFormatException) {
        null
    }
}

/**
 * Readable text color for a solid filled block of [argb]: white on dark
 * fills, near-black on light fills (relative-luminance threshold ~0.4).
 * Filled event blocks use this instead of theme roles.
 */
fun textOnColor(argb: Long): Color {
    val r = ((argb shr 16) and 0xFF).toInt()
    val g = ((argb shr 8) and 0xFF).toInt()
    val b = (argb and 0xFF).toInt()
    val lum = (0.2126f * r + 0.7152f * g + 0.0722f * b) / 255f
    return if (lum < 0.4f) Color.White else Color(0xFF1C1B1F)
}

/**
 * Text-on-fill provider for a class-color block: white/dark by luminance via
 * [textOnColor], or [fallback] when the hex is absent/invalid (callers pass
 * the matching on-color for the block's own fallback fill, e.g.
 * onAccentContainer for an accentContainer block).
 */
fun filledFg(
    palette: ChroniclePalette,
    hex: String?,
    fallback: ColorProvider = palette.onSurface,
): ColorProvider {
    val v = classColorArgb(hex) ?: return fallback
    return fixedProvider(textOnColor(v).toArgb().toLong() and 0xFFFFFFFFL)
}

/**
 * Widget background for the pushed opacity mode (0 solid / 1 translucent /
 * 2 transparent): the palette bg with its alpha stepped down, resolved to a
 * concrete ARGB and wrapped in [fixedProvider] (a lazy custom provider would
 * be rejected by `background()`).
 */
fun widgetBg(context: Context, bg: ColorProvider, opacity: Int): ColorProvider {
    val argb = bg.getColor(context).toArgb().toLong() and 0xFFFFFFFFL
    val rgb = argb and 0x00FFFFFFL
    return when (opacity.coerceIn(0, 2)) {
        1 -> fixedProvider(rgb or 0x99000000L) // ~60% alpha
        2 -> fixedProvider(rgb or 0x33000000L) // ~20% alpha
        else -> fixedProvider(argb)
    }
}

/**
 * The 12 (bg, fg, accent) triples — familyIndex * 2 + darkBit.
 * MUST stay in lockstep with the themeCode mapping in
 * lib/services/home_widgets.dart (widget_push.dart). If theme families
 * change, move both sides together.
 */
private val THEME_TABLE: Map<Int, Triple<Long, Long, Long>> = mapOf(
    0 to Triple(0xFFFEF7FF, 0xFF1C1B1F, 0xFF4F6BED),
    1 to Triple(0xFF131318, 0xFFFFFFFF, 0xFF4F6BED),
    2 to Triple(0xFFEFF1F5, 0xFF1C1B1F, 0xFFCBA6F7),
    3 to Triple(0xFF1E1E2E, 0xFFFFFFFF, 0xFFCBA6F7),
    4 to Triple(0xFFECEFF4, 0xFF1C1B1F, 0xFF88C0D0),
    5 to Triple(0xFF2E3440, 0xFFFFFFFF, 0xFF88C0D0),
    6 to Triple(0xFFF8F8F2, 0xFF1C1B1F, 0xFFBD93F9),
    7 to Triple(0xFF282A36, 0xFFFFFFFF, 0xFFBD93F9),
    8 to Triple(0xFFFBF1C7, 0xFF1C1B1F, 0xFFFABD2F),
    9 to Triple(0xFF282828, 0xFFFFFFFF, 0xFFFABD2F),
    10 to Triple(0xFFD5D6DB, 0xFF1C1B1F, 0xFF7AA2F7),
    11 to Triple(0xFF1A1B26, 0xFFFFFFFF, 0xFF7AA2F7),
)

/**
 * Material You palette from GlanceTheme roles, resolved eagerly to concrete
 * ARGB and re-wrapped in [fixedProvider]. GlanceTheme providers themselves
 * are background-safe, but the derived tonal steps must be mixed at build
 * time — a lazy custom ColorProvider never reaches `background()`.
 */
@Composable
fun youPalette(context: Context): ChroniclePalette {
    val c = GlanceTheme.colors
    val bg = argbOf(c.widgetBackground.getColor(context))
    val fg = argbOf(c.onSurface.getColor(context))
    val accent = argbOf(c.primary.getColor(context))
    return ChroniclePalette(
        bg = fixedProvider(bg),
        onSurface = fixedProvider(fg),
        onSurfaceVariant = fixedProvider(argbOf(c.onSurfaceVariant.getColor(context))),
        outline = fixedProvider(argbOf(c.outline.getColor(context))),
        accent = fixedProvider(accent),
        accentContainer = fixedProvider(argbOf(c.primaryContainer.getColor(context))),
        onAccentContainer = fixedProvider(argbOf(c.onPrimaryContainer.getColor(context))),
        card = fixedProvider(blendArgb(bg, fg, 0.05f)),
        cardHigh = fixedProvider(blendArgb(bg, fg, 0.09f)),
        error = fixedProvider(argbOf(c.error.getColor(context))),
        errorContainer = fixedProvider(argbOf(c.errorContainer.getColor(context))),
    )
}

/** App-theme palette from the 12-entry family table (unknown codes fall back to row 0). */
fun appPalette(themeCode: Int): ChroniclePalette {
    val (bg, fg, accent) = THEME_TABLE[themeCode] ?: THEME_TABLE.getValue(0)
    val bgP = fixedProvider(bg)
    val fgP = fixedProvider(fg)
    val acP = fixedProvider(accent)
    return ChroniclePalette(
        bg = bgP,
        onSurface = fgP,
        onSurfaceVariant = fixedProvider(blendArgb(bg, fg, 0.62f)),
        outline = fixedProvider(blendArgb(bg, fg, 0.38f)),
        accent = acP,
        accentContainer = fixedProvider(blendArgb(bg, accent, 0.22f)),
        onAccentContainer = acP,
        card = fixedProvider(blendArgb(bg, fg, 0.05f)),
        cardHigh = fixedProvider(blendArgb(bg, fg, 0.09f)),
        error = fixedProvider(blendArgb(bg, 0xFFE5484D, 0.9f)),
        errorContainer = fixedProvider(blendArgb(bg, 0xFFE5484D, 0.18f)),
    )
}

/**
 * Resolves the palette for one render: Material You when the pushed
 * `useYou` flag is set (Settings → Widgets → Material You), the app-theme
 * family table otherwise. This is the single wiring point that keeps the
 * toggle honest — render paths never branch on it themselves.
 */
@Composable
fun resolvePalette(context: Context, useYou: Boolean, themeCode: Int): ChroniclePalette =
    if (useYou) youPalette(context) else appPalette(themeCode)

/**
 * Outer-container corner radius per WS-2: use the system widget radius,
 * never a hand-picked one. Falls back to 28dp below Android 12.
 */
fun systemWidgetRadiusDp(context: Context): Float {
    val id = context.resources.getIdentifier(
        "system_app_widget_background_radius", "dimen", "android",
    )
    if (id != 0) {
        return context.resources.getDimension(id) / context.resources.displayMetrics.density
    }
    return 28f
}

/** 28dp fallback radius used with [systemWidgetRadiusDp]. */
val FallbackWidgetRadius = 28.dp
