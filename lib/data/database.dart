import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Classes,
  ScheduleItems,
  ScheduleExceptions,
  Holidays,
  Absences,
  Tasks,
  Subtasks,
  TaskReminders,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'chronicle');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  Future<Directory> databaseDirectory() async {
    final dir = await getApplicationSupportDirectory();
    return dir;
  }
}
