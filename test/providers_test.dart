import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rotation options degrade gracefully', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    // Missing class: null instead of throwing.
    expect(
      await container.read(rotationOptionsForClassProvider(999).future),
      isNull,
    );

    // Class without a year: null.
    final repo = ClassRepository(db);
    final plainId = await repo.create(
      ClassesCompanion.insert(name: 'Plain', colorValue: 0xFF4F6BED),
    );
    expect(
      await container.read(rotationOptionsForClassProvider(plainId).future),
      isNull,
    );

    // Class with a rotation year: config returned.
    final yearId = await repo.createYear(
      AcademicYearsCompanion.insert(
        name: '2026/27',
        startDate: '2026-09-01',
        endDate: '2027-06-30',
        rotationLength: const Value(6),
        rotationSchoolDays: const Value('[1,2,3,4,5]'),
        rotationLabels: const Value('letters'),
      ),
    );
    final classId = await repo.create(
      ClassesCompanion.insert(
        name: 'Rot',
        colorValue: 0xFF4F6BED,
        yearId: Value(yearId),
      ),
    );
    final rot = await container.read(
      rotationOptionsForClassProvider(classId).future,
    );
    expect(rot?.length, 6);
    expect(rot?.letters, isTrue);
  });
}
