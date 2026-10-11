// Weekly-calendar widget state (tall-portrait design).
// NOT generated — edit freely. Parsed from the WidgetData wire contract
// (mirrored by lib/services/widget_push.dart); keep both sides in
// lockstep. Only kotlin.* imports (no UI toolkit).
package com.chronicleapp.chronicle

import com.chronicleapp.chronicle.widget.TimeRow
import com.chronicleapp.chronicle.widget.WeekCell
import com.chronicleapp.chronicle.widget.WidgetSnapshot

/** One day column of the weekly calendar: rail cell + its class rows. */
data class WeekDayColumn(
    val cell: WeekCell,
    val rows: List<TimeRow>,
)

/** Weekly-calendar render state: Loading / Empty / Success / Error. */
sealed interface WeeklyCalendarWidgetUiState {
    data object Loading : WeeklyCalendarWidgetUiState

    /** No week pushed (or stale day): never show yesterday's plan. */
    data class Empty(val message: String) : WeeklyCalendarWidgetUiState

    /**
     * Seven day columns, top-to-bottom in week order.
     * - Compact renders today's column only (first row + "+X more").
     * - TallColumn renders today + tomorrow (up to 2 rows each).
     * - FullPortrait renders up to 4 days that have classes (up to 2
     *   rows each) under per-day section headers.
     */
    data class Success(
        val days: List<WeekDayColumn>,
        val snap: WidgetSnapshot,
    ) : WeeklyCalendarWidgetUiState

    data class Error(val message: String) : WeeklyCalendarWidgetUiState
}
