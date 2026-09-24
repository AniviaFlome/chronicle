import 'package:flutter/material.dart';

/// Shared list/grid switch for calendar and absences screens.
class ViewSwitch extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String listTooltip;
  final String gridTooltip;

  const ViewSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.listTooltip,
    required this.gridTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        ButtonSegment(
          value: 'list',
          icon: const Icon(Icons.view_agenda_outlined, size: 20),
          tooltip: listTooltip,
        ),
        ButtonSegment(
          value: 'grid',
          icon: const Icon(Icons.calendar_view_week_outlined, size: 20),
          tooltip: gridTooltip,
        ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.single),
    );
  }
}
