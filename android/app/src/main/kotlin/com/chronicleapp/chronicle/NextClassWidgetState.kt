// Next-class widget state (tall-portrait redesign).
// NOT generated — edit freely. Parsed from the WidgetData.timedData wire
// contract (mirrored by lib/services/widget_push.dart); keep both sides in
// lockstep. Only androidx.glance.* / java.* / kotlin.* imports.
package com.chronicleapp.chronicle

import com.chronicleapp.chronicle.widget.TimedEntry
import com.chronicleapp.chronicle.widget.TimeRow
import com.chronicleapp.chronicle.widget.WidgetSnapshot

/** Next-class render state: Loading / Empty / Success / Error. */
sealed interface NextClassWidgetUiState {
    data object Loading : NextClassWidgetUiState

    /** No classes to show (empty timeline, stale prefs, or sentinel). */
    data class Empty(val message: String) : NextClassWidgetUiState

    /**
     * Hero entry + vertical lookahead.
     * - Compact renders [hero] only.
     * - TallColumn renders hero + [upcoming] capped at 2 with +X more.
     * - FullPortrait renders hero + full [upcoming] under section headers.
     */
    data class Success(
        val hero: TimedEntry,
        val upcoming: List<TimeRow>,
        val snap: WidgetSnapshot,
        val nowMs: Long,
    ) : NextClassWidgetUiState

    data class Error(val message: String) : NextClassWidgetUiState
}
