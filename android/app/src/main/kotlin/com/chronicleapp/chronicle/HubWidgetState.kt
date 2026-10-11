// Hub widget state.
// NOT generated — edit freely. Parsed from the WidgetData hub wire
// contract (mirrored by lib/services/widget_push.dart); keep both sides in
// lockstep. Only androidx.glance.* / java.* / kotlin.* imports.
package com.chronicleapp.chronicle

import com.chronicleapp.chronicle.widget.MenuMeal
import com.chronicleapp.chronicle.widget.TaskRow
import com.chronicleapp.chronicle.widget.TimedEntry
import com.chronicleapp.chronicle.widget.TimeRow
import com.chronicleapp.chronicle.widget.WidgetSnapshot

/** Hub render state: Loading / Empty / Success / Error. */
sealed interface HubWidgetUiState {
    data object Loading : HubWidgetUiState

    /** Nothing to show on the selected tab set (unreachable while the class
     * tab fallback exists, but rendered as a full-widget empty state). */
    data class Empty(val message: String) : HubWidgetUiState

    /**
     * Active tab + its rows.
     * - Class tab renders the hero entry + [looks] capped at 2 with +X more.
     * - Agenda / tasks / menu tabs render their row lists capped per height
     *   with a "+X more" indicator; per-tab empties render inline.
     */
    data class Success(
        val content: HubContentData,
        val nowMs: Long,
    ) : HubWidgetUiState

    data class Error(val message: String) : HubWidgetUiState
}

/** Everything one hub render needs: tab strip position plus the rows for
 * every tab (tab switches are native-side, so all tabs resolve up front). */
data class HubContentData(
    val snap: WidgetSnapshot,
    val enabled: List<Int>,
    val pos: Int,
    val sel: Int,
    val entry: TimedEntry?,
    val looks: List<TimeRow>,
    val agendaRows: List<TimeRow>,
    val tasksRows: List<TaskRow>,
    val menuRows: List<String>,
    val menuMeals: List<MenuMeal>,
    val menuMealIdx: Int,
    val titleClass: String,
    val titleAgenda: String,
    val tasksTitle: String,
    val menuTitle: String,
    val emptyTasks: String,
    val emptyMenu: String,
)
