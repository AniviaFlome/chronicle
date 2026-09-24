import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import 'class_edit_screen.dart';
import 'year_widgets.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesStreamProvider);
    final activeYear = ref.watch(activeYearIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.classesTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (v) {
              if (v == 'delete-all') _confirmDeleteAll(context, ref);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete-all',
                child: Text(context.l10n.deleteAllClasses),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addClass),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: YearDropdown(
              value: activeYear.value,
              showAllYears: true,
              label: context.l10n.showingYear,
              onChanged: (v) =>
                  ref.read(settingsRepositoryProvider).setActiveYearId(v),
            ),
          ),
          Expanded(
            child: classes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                    child: Text(context.l10n.couldNotLoadClasses('$e')),
                  ),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    return _ClassCard(
                      classRow: list[i],
                      onOpen: () => _openEditor(context, existing: list[i]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, {ClassesData? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassEditScreen(existing: existing),
        fullscreenDialog: true,
      ),
    );
  }

  /// Bulk-deletes every class (with slots and absence records) after
  /// confirmation. Tasks are kept without a class.
  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(classRepositoryProvider);
    final existing = await repo.all();
    if (!context.mounted) return;
    if (existing.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noClasses)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteAllClassesTitle),
        content: Text(context.l10n.deleteAllClassesBody(existing.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final deleted = await repo.deleteAll();
      if (!context.mounted) return;
      ref.invalidate(engineProvider);
      ref.invalidate(classesByIdProvider);
      await ref.read(reminderSchedulerProvider).refreshClassReminders();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.classesDeleted(deleted))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotDeleteClasses('$e'))),
      );
    }
  }
}

class _ClassCard extends StatelessWidget {
  final ClassesData classRow;
  final VoidCallback onOpen;

  const _ClassCard({required this.classRow, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final raw = Color(classRow.colorValue);
    final theme = Theme.of(context);
    final color = classAccentColor(theme.colorScheme, raw);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classRow.name, style: theme.textTheme.titleMedium),
                    if (classRow.teacher != null &&
                        classRow.teacher!.isNotEmpty)
                      Text(classRow.teacher!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.noClassesYet, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.l10n.addFirstClass,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
