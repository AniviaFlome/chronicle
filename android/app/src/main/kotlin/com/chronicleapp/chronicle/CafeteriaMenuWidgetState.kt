// Cafeteria-menu widget state (tall-portrait design).
// NOT generated — edit freely. Parsed from the WidgetData wire contract
// (mirrored by lib/services/widget_push.dart); keep both sides in
// lockstep. Only kotlin.* imports (no UI toolkit).
package com.chronicleapp.chronicle

import com.chronicleapp.chronicle.widget.MenuMeal
import com.chronicleapp.chronicle.widget.WidgetSnapshot

/** Cafeteria-menu render state: Loading / Empty / Success / Error. */
sealed interface CafeteriaMenuWidgetUiState {
    data object Loading : CafeteriaMenuWidgetUiState

    /** No menu pushed (no source picked, fetch failed, or stale day). */
    data class Empty(val message: String) : CafeteriaMenuWidgetUiState

    /**
     * Selected meal title (e.g. "Lunch · ITU") + dish names, top-to-bottom.
     * [meals]/[selectedIdx] drive the ‹ › switcher (shown when more than
     * one meal is servable); [title]/[dishes] are the selected meal's.
     * - Compact renders the title + first dish only.
     * - TallColumn renders up to 3 dishes with a "+X more" indicator.
     * - FullPortrait renders up to 8 dishes under a section header.
     */
    data class Success(
        val title: String,
        val dishes: List<String>,
        val meals: List<MenuMeal>,
        val selectedIdx: Int,
        val snap: WidgetSnapshot,
    ) : CafeteriaMenuWidgetUiState

    data class Error(val message: String) : CafeteriaMenuWidgetUiState
}
