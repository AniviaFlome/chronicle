// Cafeteria-menu widget state (tall-portrait design).
// NOT generated — edit freely. Parsed from the WidgetData wire contract
// (mirrored by lib/services/widget_push.dart); keep both sides in lockstep.
// Only kotlin.* imports (no UI toolkit).
package com.chronicleapp.chronicle

import com.chronicleapp.chronicle.widget.MenuDishItem
import com.chronicleapp.chronicle.widget.MenuMeal
import com.chronicleapp.chronicle.widget.WidgetSnapshot

/** Cafeteria-menu render state: Loading / Empty / Success / Error. */
sealed interface CafeteriaMenuWidgetUiState {
    data object Loading : CafeteriaMenuWidgetUiState

    /** No menu pushed (no source picked, fetch failed, or stale day). */
    data class Empty(val message: String) : CafeteriaMenuWidgetUiState

    /**
     * Selected meal title (e.g. "Lunch · ITU"), structured dish items, and
     * optional service hours / total kcal metadata. [meals]/[selectedIdx]
     * drive the ‹ › switcher when more than one meal is servable.
     */
    data class Success(
        val title: String,
        val dishes: List<String>,
        val items: List<MenuDishItem>,
        val serviceHours: String,
        val totalKcal: Int,
        val meals: List<MenuMeal>,
        val selectedIdx: Int,
        val snap: WidgetSnapshot,
    ) : CafeteriaMenuWidgetUiState

    data class Error(val message: String) : CafeteriaMenuWidgetUiState
}
