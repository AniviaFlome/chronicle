import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories.dart';
import '../domain/grades.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../providers.dart';

/// GPA overview, per-class averages and the graded exam list.
class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(gradesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.gradesTitle)),
      body: grades.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
              Center(child: Text(context.l10n.couldNotLoadGrades('$e'))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grade_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(context.l10n.noGradesYet, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.recordExamsHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          final overall = gpa([
            for (final g in list) gradePercent(g.grade.score, g.grade.maxScore),
          ]);
          final byClass = <int?, List<GradeWithExam>>{};
          for (final g in list) {
            byClass.putIfAbsent(g.classRow?.id, () => []).add(g);
          }
          final classEntries = byClass.entries.toList()
            ..sort((a, b) {
              final an = a.value.first.classRow?.name ?? 'No class';
              final bn = b.value.first.classRow?.name ?? 'No class';
              return an.compareTo(bn);
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        overall == null ? '–' : overall.toStringAsFixed(2),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        context.l10n.gpaSummary(list.length),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By subject',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              for (final entry in classEntries)
                _ClassAverageRow(items: entry.value),
              const SizedBox(height: 12),
              Text(
                'Exams',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              for (final g in list) _GradeTile(item: g),
            ],
          );
        },
      ),
    );
  }
}

class _ClassAverageRow extends StatelessWidget {
  final List<GradeWithExam> items;

  const _ClassAverageRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classRow = items.first.classRow;
    final avg =
        items
            .map((g) => gradePercent(g.grade.score, g.grade.maxScore))
            .reduce((a, b) => a + b) /
        items.length;
    final color = classAccentColor(
      theme.colorScheme,
      classRow == null
          ? theme.colorScheme.primary
          : Color(classRow.colorValue),
    );

    return Card(
      child: ListTile(
        leading: Container(
          width: 10,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        title: Text(classRow?.name ?? context.l10n.noClass),
        subtitle: Text(
          context.l10n.examsAverage(items.length, avg.toStringAsFixed(1)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            letterGrade(avg),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeTile extends ConsumerWidget {
  final GradeWithExam item;

  const _GradeTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final percent = gradePercent(item.grade.score, item.grade.maxScore);

    return Card(
      child: ListTile(
        title: Text(item.exam.title),
        subtitle: Text(
          [
            if (item.classRow != null) item.classRow!.name,
            '${item.grade.score} / ${item.grade.maxScore} · '
                '${percent.toStringAsFixed(1)}%',
            item.grade.date,
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(letterGrade(percent)),
            ),
            IconButton(
              tooltip: context.l10n.deleteGradeTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(gradeRepositoryProvider).delete(item.grade.id),
            ),
          ],
        ),
      ),
    );
  }
}
