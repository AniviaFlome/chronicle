import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/schedule_repository.dart';
import '../providers.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import 'attachment_panel.dart';

/// Academic-year picker shared by the class editor, classes screen and
/// settings. Null means "no year".
class YearDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;
  final bool showAllYears;

  const YearDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Academic year',
    this.showAllYears = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = ref.watch(yearsStreamProvider);
    return years.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(context.l10n.couldNotLoadYears('$e')),
      data: (list) {
        final effective = list.any((y) => y.id == value) ? value : null;
        return DropdownButtonFormField<int?>(
          initialValue: effective,
          decoration: InputDecoration(labelText: label),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(showAllYears ? context.l10n.allYears : context.l10n.noYearOption),
            ),
            for (final y in list)
              DropdownMenuItem(value: y.id, child: Text(y.name)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

/// Add/edit dialog for one academic year. Returns true when saved.
Future<bool> showYearDialog(
  BuildContext context,
  WidgetRef ref, {
  AcademicYear? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  DateTime? start = existing == null
      ? null
      : DateTime.tryParse(existing.startDate);
  DateTime? end = existing == null ? null : DateTime.tryParse(existing.endDate);
  int? rotationLength = existing?.rotationLength;
  final schoolDays = <int>{
    if (existing?.rotationSchoolDays != null)
      ...decodeIntList(existing!.rotationSchoolDays!)
    else
      1,
    2,
    3,
    4,
    5,
  };
  bool rotationLetters = existing?.rotationLabels == 'letters';
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? context.l10n.addAcademicYear : context.l10n.editYear),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: InputDecoration(labelText: context.l10n.nameLabel),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DialogDateButton(
                      label: context.l10n.startsLabel,
                      value: start,
                      onPick: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: start ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => start = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogDateButton(
                      label: context.l10n.endsLabel,
                      value: end,
                      onPick: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: end ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => end = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: rotationLength,
                decoration: InputDecoration(
                  labelText: context.l10n.dayRotationLabel,
                  helperText: context.l10n.dayRotationHint,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.l10n.offLabel)),
                  for (var n = 2; n <= 10; n++)
                    DropdownMenuItem(value: n, child: Text(context.l10n.daysCount(n))),
                ],
                onChanged: (v) => setDialogState(() => rotationLength = v),
              ),
              if (rotationLength != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      FilterChip(
                        label: Text(shortWeekdayName(d, context.l10n.localeName)),
                        selected: schoolDays.contains(d),
                        onSelected: (sel) => setDialogState(() {
                          sel ? schoolDays.add(d) : schoolDays.remove(d);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('1 2 3')),
                    ButtonSegment(value: true, label: Text('A B C')),
                  ],
                  selected: {rotationLetters},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setDialogState(() => rotationLetters = s.single),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              if (start == null || end == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(context.l10n.pickStartEnd)),
                );
                return;
              }
              if (end!.isBefore(start!)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.endBeforeStart),
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    ),
  );

  if (saved != true || !context.mounted) return false;
  final rotationDays = (schoolDays.toList()..sort());
  try {
    final repo = ref.read(classRepositoryProvider);
    if (existing == null) {
      await repo.createYear(
        AcademicYearsCompanion.insert(
          name: name.text.trim(),
          startDate: isoFromDateTime(start!),
          endDate: isoFromDateTime(end!),
          rotationLength: Value(rotationLength),
          rotationSchoolDays: Value(
            rotationLength == null ? null : encodeIntList(rotationDays),
          ),
          rotationLabels: Value(
            rotationLength == null
                ? null
                : (rotationLetters ? 'letters' : 'numbers'),
          ),
        ),
      );
    } else {
      final updated = await repo.updateYear(
        existing.copyWith(
          name: name.text.trim(),
          startDate: isoFromDateTime(start!),
          endDate: isoFromDateTime(end!),
          rotationLength: Value(rotationLength),
          rotationSchoolDays: Value(
            rotationLength == null ? null : encodeIntList(rotationDays),
          ),
          rotationLabels: Value(
            rotationLength == null
                ? null
                : (rotationLetters ? 'letters' : 'numbers'),
          ),
        ),
      );
      if (!updated) throw StateError('Year no longer exists');
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.couldNotSaveYear('$e'))));
    }
    return false;
  }
}

class _DialogDateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const _DialogDateButton({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: InkWell(
        onTap: onPick,
        child: Text(value == null ? context.l10n.pickPlaceholder : isoFromDateTime(value!)),
      ),
    );
  }
}

/// Settings section: list, add, edit, delete years and pick the active one.
class YearsSection extends ConsumerWidget {
  const YearsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = ref.watch(yearsStreamProvider);
    final activeYear = ref.watch(activeYearIdProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                activeYear.value == null ? context.l10n.filteringAllYears : context.l10n.filteringOneYear,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.addAcademicYear,
              icon: const Icon(Icons.add),
              onPressed: () => showYearDialog(context, ref),
            ),
          ],
        ),
        years.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(context.l10n.couldNotLoadYears('$e')),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(context.l10n.noYearsYet),
              );
            }
            final activeId = activeYear.value;
            return RadioGroup<int?>(
              groupValue: activeId,
              onChanged: (v) =>
                  ref.read(settingsRepositoryProvider).setActiveYearId(v),
              child: Column(
                children: [
                  for (final y in list)
                    RadioListTile<int?>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(y.name),
                      subtitle: Text('${y.startDate} – ${y.endDate}'),
                      value: y.id,
                      secondary: _YearActions(year: y),
                    ),
                  RadioListTile<int?>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(context.l10n.allYears),
                    value: null,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bottom sheet listing an academic year's attached files (official
/// program PDFs, etc.) with add/open/delete. Synced like class files.
class _YearFilesSheet extends ConsumerWidget {
  final AcademicYear year;

  const _YearFilesSheet({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(yearFilesForYearProvider(year.id));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(year.name, style: Theme.of(context).textTheme.titleLarge),
            Flexible(
              child: SingleChildScrollView(
                child: AttachmentPanel(
                  files: files.whenData(
                    (list) => [
                      for (final f in list)
                        AttachedFile(
                          id: f.id,
                          fileName: f.fileName,
                          storedPath: f.storedPath,
                          sizeBytes: f.sizeBytes,
                        ),
                    ],
                  ),
                  onAdd: () =>
                      ref.read(classFilesServiceProvider).pickAndSaveYear(year.id),
                  onOpen: (f) => ref
                      .read(classFilesServiceProvider)
                      .openStoredFile(
                        fileName: f.fileName,
                        storedPath: f.storedPath,
                      ),
                  onDelete: (f) =>
                      ref.read(yearFileRepositoryProvider).delete(f.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit/delete menu for one academic year.
class _YearActions extends ConsumerWidget {
  final AcademicYear year;

  const _YearActions({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.yearActions,
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(context.l10n.editAction)),
        PopupMenuItem(
          value: 'files',
          child: Text(context.l10n.classFilesSection),
        ),
        PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'edit') {
      await showYearDialog(context, ref, existing: year);
      return;
    }
    if (action == 'files') {
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => _YearFilesSheet(year: year),
      );
      return;
    }
    if (action != 'delete' || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.deleteYearTitle),
        content: Text(
          context.l10n.deleteYearBody(year.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(classRepositoryProvider).deleteYear(year.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.l10n.couldNotDelete('$e'))));
        }
      }
    }
  }
}
