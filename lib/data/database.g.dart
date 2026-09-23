// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AcademicYearsTable extends AcademicYears
    with TableInfo<$AcademicYearsTable, AcademicYear> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcademicYearsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rotationLengthMeta = const VerificationMeta(
    'rotationLength',
  );
  @override
  late final GeneratedColumn<int> rotationLength = GeneratedColumn<int>(
    'rotation_length',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rotationSchoolDaysMeta =
      const VerificationMeta('rotationSchoolDays');
  @override
  late final GeneratedColumn<String> rotationSchoolDays =
      GeneratedColumn<String>(
        'rotation_school_days',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rotationLabelsMeta = const VerificationMeta(
    'rotationLabels',
  );
  @override
  late final GeneratedColumn<String> rotationLabels = GeneratedColumn<String>(
    'rotation_labels',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDate,
    endDate,
    rotationLength,
    rotationSchoolDays,
    rotationLabels,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'academic_years';
  @override
  VerificationContext validateIntegrity(
    Insertable<AcademicYear> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('rotation_length')) {
      context.handle(
        _rotationLengthMeta,
        rotationLength.isAcceptableOrUnknown(
          data['rotation_length']!,
          _rotationLengthMeta,
        ),
      );
    }
    if (data.containsKey('rotation_school_days')) {
      context.handle(
        _rotationSchoolDaysMeta,
        rotationSchoolDays.isAcceptableOrUnknown(
          data['rotation_school_days']!,
          _rotationSchoolDaysMeta,
        ),
      );
    }
    if (data.containsKey('rotation_labels')) {
      context.handle(
        _rotationLabelsMeta,
        rotationLabels.isAcceptableOrUnknown(
          data['rotation_labels']!,
          _rotationLabelsMeta,
        ),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AcademicYear map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AcademicYear(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      rotationLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation_length'],
      ),
      rotationSchoolDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rotation_school_days'],
      ),
      rotationLabels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rotation_labels'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AcademicYearsTable createAlias(String alias) {
    return $AcademicYearsTable(attachedDatabase, alias);
  }
}

class AcademicYear extends DataClass implements Insertable<AcademicYear> {
  final int id;
  final String name;

  /// ISO-8601 date strings (yyyy-MM-dd).
  final String startDate;
  final String endDate;

  /// Day-rotation cycle length (2-10). Null = no day rotation.
  final int? rotationLength;

  /// JSON list of ISO weekdays the rotation advances on, e.g. "[1,2,3,4,5]".
  final String? rotationSchoolDays;

  /// 'numbers' or 'letters'. Defaults to numbers.
  final String? rotationLabels;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const AcademicYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.rotationLength,
    this.rotationSchoolDays,
    this.rotationLabels,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    if (!nullToAbsent || rotationLength != null) {
      map['rotation_length'] = Variable<int>(rotationLength);
    }
    if (!nullToAbsent || rotationSchoolDays != null) {
      map['rotation_school_days'] = Variable<String>(rotationSchoolDays);
    }
    if (!nullToAbsent || rotationLabels != null) {
      map['rotation_labels'] = Variable<String>(rotationLabels);
    }
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AcademicYearsCompanion toCompanion(bool nullToAbsent) {
    return AcademicYearsCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      rotationLength: rotationLength == null && nullToAbsent
          ? const Value.absent()
          : Value(rotationLength),
      rotationSchoolDays: rotationSchoolDays == null && nullToAbsent
          ? const Value.absent()
          : Value(rotationSchoolDays),
      rotationLabels: rotationLabels == null && nullToAbsent
          ? const Value.absent()
          : Value(rotationLabels),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory AcademicYear.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AcademicYear(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      rotationLength: serializer.fromJson<int?>(json['rotationLength']),
      rotationSchoolDays: serializer.fromJson<String?>(
        json['rotationSchoolDays'],
      ),
      rotationLabels: serializer.fromJson<String?>(json['rotationLabels']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'rotationLength': serializer.toJson<int?>(rotationLength),
      'rotationSchoolDays': serializer.toJson<String?>(rotationSchoolDays),
      'rotationLabels': serializer.toJson<String?>(rotationLabels),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AcademicYear copyWith({
    int? id,
    String? name,
    String? startDate,
    String? endDate,
    Value<int?> rotationLength = const Value.absent(),
    Value<String?> rotationSchoolDays = const Value.absent(),
    Value<String?> rotationLabels = const Value.absent(),
    String? uuid,
    int? updatedAt,
  }) => AcademicYear(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    rotationLength: rotationLength.present
        ? rotationLength.value
        : this.rotationLength,
    rotationSchoolDays: rotationSchoolDays.present
        ? rotationSchoolDays.value
        : this.rotationSchoolDays,
    rotationLabels: rotationLabels.present
        ? rotationLabels.value
        : this.rotationLabels,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AcademicYear copyWithCompanion(AcademicYearsCompanion data) {
    return AcademicYear(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      rotationLength: data.rotationLength.present
          ? data.rotationLength.value
          : this.rotationLength,
      rotationSchoolDays: data.rotationSchoolDays.present
          ? data.rotationSchoolDays.value
          : this.rotationSchoolDays,
      rotationLabels: data.rotationLabels.present
          ? data.rotationLabels.value
          : this.rotationLabels,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AcademicYear(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rotationLength: $rotationLength, ')
          ..write('rotationSchoolDays: $rotationSchoolDays, ')
          ..write('rotationLabels: $rotationLabels, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDate,
    endDate,
    rotationLength,
    rotationSchoolDays,
    rotationLabels,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcademicYear &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.rotationLength == this.rotationLength &&
          other.rotationSchoolDays == this.rotationSchoolDays &&
          other.rotationLabels == this.rotationLabels &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class AcademicYearsCompanion extends UpdateCompanion<AcademicYear> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int?> rotationLength;
  final Value<String?> rotationSchoolDays;
  final Value<String?> rotationLabels;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const AcademicYearsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rotationLength = const Value.absent(),
    this.rotationSchoolDays = const Value.absent(),
    this.rotationLabels = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AcademicYearsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String startDate,
    required String endDate,
    this.rotationLength = const Value.absent(),
    this.rotationSchoolDays = const Value.absent(),
    this.rotationLabels = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<AcademicYear> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? rotationLength,
    Expression<String>? rotationSchoolDays,
    Expression<String>? rotationLabels,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rotationLength != null) 'rotation_length': rotationLength,
      if (rotationSchoolDays != null)
        'rotation_school_days': rotationSchoolDays,
      if (rotationLabels != null) 'rotation_labels': rotationLabels,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AcademicYearsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<int?>? rotationLength,
    Value<String?>? rotationSchoolDays,
    Value<String?>? rotationLabels,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return AcademicYearsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rotationLength: rotationLength ?? this.rotationLength,
      rotationSchoolDays: rotationSchoolDays ?? this.rotationSchoolDays,
      rotationLabels: rotationLabels ?? this.rotationLabels,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (rotationLength.present) {
      map['rotation_length'] = Variable<int>(rotationLength.value);
    }
    if (rotationSchoolDays.present) {
      map['rotation_school_days'] = Variable<String>(rotationSchoolDays.value);
    }
    if (rotationLabels.present) {
      map['rotation_labels'] = Variable<String>(rotationLabels.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcademicYearsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rotationLength: $rotationLength, ')
          ..write('rotationSchoolDays: $rotationSchoolDays, ')
          ..write('rotationLabels: $rotationLabels, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ClassesTable extends Classes with TableInfo<$ClassesTable, ClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearIdMeta = const VerificationMeta('yearId');
  @override
  late final GeneratedColumn<int> yearId = GeneratedColumn<int>(
    'year_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES academic_years (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teacherEmailMeta = const VerificationMeta(
    'teacherEmail',
  );
  @override
  late final GeneratedColumn<String> teacherEmail = GeneratedColumn<String>(
    'teacher_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buildingMeta = const VerificationMeta(
    'building',
  );
  @override
  late final GeneratedColumn<String> building = GeneratedColumn<String>(
    'building',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onlineLinkMeta = const VerificationMeta(
    'onlineLink',
  );
  @override
  late final GeneratedColumn<String> onlineLink = GeneratedColumn<String>(
    'online_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxAbsencesMeta = const VerificationMeta(
    'maxAbsences',
  );
  @override
  late final GeneratedColumn<int> maxAbsences = GeneratedColumn<int>(
    'max_absences',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxAbsencesTheoryMeta = const VerificationMeta(
    'maxAbsencesTheory',
  );
  @override
  late final GeneratedColumn<int> maxAbsencesTheory = GeneratedColumn<int>(
    'max_absences_theory',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxAbsencesPracticalMeta =
      const VerificationMeta('maxAbsencesPractical');
  @override
  late final GeneratedColumn<int> maxAbsencesPractical = GeneratedColumn<int>(
    'max_absences_practical',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorValue,
    yearId,
    startDate,
    endDate,
    teacher,
    teacherEmail,
    room,
    building,
    module,
    onlineLink,
    notes,
    maxAbsences,
    maxAbsencesTheory,
    maxAbsencesPractical,
    reminderMinutes,
    active,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('year_id')) {
      context.handle(
        _yearIdMeta,
        yearId.isAcceptableOrUnknown(data['year_id']!, _yearIdMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('teacher_email')) {
      context.handle(
        _teacherEmailMeta,
        teacherEmail.isAcceptableOrUnknown(
          data['teacher_email']!,
          _teacherEmailMeta,
        ),
      );
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('building')) {
      context.handle(
        _buildingMeta,
        building.isAcceptableOrUnknown(data['building']!, _buildingMeta),
      );
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    }
    if (data.containsKey('online_link')) {
      context.handle(
        _onlineLinkMeta,
        onlineLink.isAcceptableOrUnknown(data['online_link']!, _onlineLinkMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('max_absences')) {
      context.handle(
        _maxAbsencesMeta,
        maxAbsences.isAcceptableOrUnknown(
          data['max_absences']!,
          _maxAbsencesMeta,
        ),
      );
    }
    if (data.containsKey('max_absences_theory')) {
      context.handle(
        _maxAbsencesTheoryMeta,
        maxAbsencesTheory.isAcceptableOrUnknown(
          data['max_absences_theory']!,
          _maxAbsencesTheoryMeta,
        ),
      );
    }
    if (data.containsKey('max_absences_practical')) {
      context.handle(
        _maxAbsencesPracticalMeta,
        maxAbsencesPractical.isAcceptableOrUnknown(
          data['max_absences_practical']!,
          _maxAbsencesPracticalMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      yearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year_id'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      ),
      teacherEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_email'],
      ),
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      ),
      building: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}building'],
      ),
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      ),
      onlineLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}online_link'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      maxAbsences: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_absences'],
      ),
      maxAbsencesTheory: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_absences_theory'],
      ),
      maxAbsencesPractical: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_absences_practical'],
      ),
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ClassesTable createAlias(String alias) {
    return $ClassesTable(attachedDatabase, alias);
  }
}

class ClassesData extends DataClass implements Insertable<ClassesData> {
  final int id;
  final String name;
  final int colorValue;
  final int? yearId;

  /// ISO-8601 date strings (yyyy-MM-dd), null = unbounded.
  final String? startDate;
  final String? endDate;
  final String? teacher;
  final String? teacherEmail;
  final String? room;
  final String? building;
  final String? module;
  final String? onlineLink;
  final String? notes;

  /// Max tolerated unexcused absences; null = no quota tracking.
  /// Legacy single limit: applies to theory when the per-kind limits below
  /// are unset.
  final int? maxAbsences;

  /// Max tolerated unexcused theoretical absences; null = none (or legacy).
  final int? maxAbsencesTheory;

  /// Max tolerated unexcused practical absences; null = none.
  final int? maxAbsencesPractical;

  /// Minutes before class start to remind; null = follow default setting.
  final int? reminderMinutes;
  final bool active;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const ClassesData({
    required this.id,
    required this.name,
    required this.colorValue,
    this.yearId,
    this.startDate,
    this.endDate,
    this.teacher,
    this.teacherEmail,
    this.room,
    this.building,
    this.module,
    this.onlineLink,
    this.notes,
    this.maxAbsences,
    this.maxAbsencesTheory,
    this.maxAbsencesPractical,
    this.reminderMinutes,
    required this.active,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    if (!nullToAbsent || yearId != null) {
      map['year_id'] = Variable<int>(yearId);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || teacher != null) {
      map['teacher'] = Variable<String>(teacher);
    }
    if (!nullToAbsent || teacherEmail != null) {
      map['teacher_email'] = Variable<String>(teacherEmail);
    }
    if (!nullToAbsent || room != null) {
      map['room'] = Variable<String>(room);
    }
    if (!nullToAbsent || building != null) {
      map['building'] = Variable<String>(building);
    }
    if (!nullToAbsent || module != null) {
      map['module'] = Variable<String>(module);
    }
    if (!nullToAbsent || onlineLink != null) {
      map['online_link'] = Variable<String>(onlineLink);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || maxAbsences != null) {
      map['max_absences'] = Variable<int>(maxAbsences);
    }
    if (!nullToAbsent || maxAbsencesTheory != null) {
      map['max_absences_theory'] = Variable<int>(maxAbsencesTheory);
    }
    if (!nullToAbsent || maxAbsencesPractical != null) {
      map['max_absences_practical'] = Variable<int>(maxAbsencesPractical);
    }
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    map['active'] = Variable<bool>(active);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ClassesCompanion toCompanion(bool nullToAbsent) {
    return ClassesCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: Value(colorValue),
      yearId: yearId == null && nullToAbsent
          ? const Value.absent()
          : Value(yearId),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      teacher: teacher == null && nullToAbsent
          ? const Value.absent()
          : Value(teacher),
      teacherEmail: teacherEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(teacherEmail),
      room: room == null && nullToAbsent ? const Value.absent() : Value(room),
      building: building == null && nullToAbsent
          ? const Value.absent()
          : Value(building),
      module: module == null && nullToAbsent
          ? const Value.absent()
          : Value(module),
      onlineLink: onlineLink == null && nullToAbsent
          ? const Value.absent()
          : Value(onlineLink),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      maxAbsences: maxAbsences == null && nullToAbsent
          ? const Value.absent()
          : Value(maxAbsences),
      maxAbsencesTheory: maxAbsencesTheory == null && nullToAbsent
          ? const Value.absent()
          : Value(maxAbsencesTheory),
      maxAbsencesPractical: maxAbsencesPractical == null && nullToAbsent
          ? const Value.absent()
          : Value(maxAbsencesPractical),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      active: Value(active),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassesData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      yearId: serializer.fromJson<int?>(json['yearId']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      teacher: serializer.fromJson<String?>(json['teacher']),
      teacherEmail: serializer.fromJson<String?>(json['teacherEmail']),
      room: serializer.fromJson<String?>(json['room']),
      building: serializer.fromJson<String?>(json['building']),
      module: serializer.fromJson<String?>(json['module']),
      onlineLink: serializer.fromJson<String?>(json['onlineLink']),
      notes: serializer.fromJson<String?>(json['notes']),
      maxAbsences: serializer.fromJson<int?>(json['maxAbsences']),
      maxAbsencesTheory: serializer.fromJson<int?>(json['maxAbsencesTheory']),
      maxAbsencesPractical: serializer.fromJson<int?>(
        json['maxAbsencesPractical'],
      ),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      active: serializer.fromJson<bool>(json['active']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
      'yearId': serializer.toJson<int?>(yearId),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'teacher': serializer.toJson<String?>(teacher),
      'teacherEmail': serializer.toJson<String?>(teacherEmail),
      'room': serializer.toJson<String?>(room),
      'building': serializer.toJson<String?>(building),
      'module': serializer.toJson<String?>(module),
      'onlineLink': serializer.toJson<String?>(onlineLink),
      'notes': serializer.toJson<String?>(notes),
      'maxAbsences': serializer.toJson<int?>(maxAbsences),
      'maxAbsencesTheory': serializer.toJson<int?>(maxAbsencesTheory),
      'maxAbsencesPractical': serializer.toJson<int?>(maxAbsencesPractical),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'active': serializer.toJson<bool>(active),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ClassesData copyWith({
    int? id,
    String? name,
    int? colorValue,
    Value<int?> yearId = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    Value<String?> teacher = const Value.absent(),
    Value<String?> teacherEmail = const Value.absent(),
    Value<String?> room = const Value.absent(),
    Value<String?> building = const Value.absent(),
    Value<String?> module = const Value.absent(),
    Value<String?> onlineLink = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> maxAbsences = const Value.absent(),
    Value<int?> maxAbsencesTheory = const Value.absent(),
    Value<int?> maxAbsencesPractical = const Value.absent(),
    Value<int?> reminderMinutes = const Value.absent(),
    bool? active,
    String? uuid,
    int? updatedAt,
  }) => ClassesData(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    yearId: yearId.present ? yearId.value : this.yearId,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    teacher: teacher.present ? teacher.value : this.teacher,
    teacherEmail: teacherEmail.present ? teacherEmail.value : this.teacherEmail,
    room: room.present ? room.value : this.room,
    building: building.present ? building.value : this.building,
    module: module.present ? module.value : this.module,
    onlineLink: onlineLink.present ? onlineLink.value : this.onlineLink,
    notes: notes.present ? notes.value : this.notes,
    maxAbsences: maxAbsences.present ? maxAbsences.value : this.maxAbsences,
    maxAbsencesTheory: maxAbsencesTheory.present
        ? maxAbsencesTheory.value
        : this.maxAbsencesTheory,
    maxAbsencesPractical: maxAbsencesPractical.present
        ? maxAbsencesPractical.value
        : this.maxAbsencesPractical,
    reminderMinutes: reminderMinutes.present
        ? reminderMinutes.value
        : this.reminderMinutes,
    active: active ?? this.active,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClassesData copyWithCompanion(ClassesCompanion data) {
    return ClassesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      yearId: data.yearId.present ? data.yearId.value : this.yearId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      teacherEmail: data.teacherEmail.present
          ? data.teacherEmail.value
          : this.teacherEmail,
      room: data.room.present ? data.room.value : this.room,
      building: data.building.present ? data.building.value : this.building,
      module: data.module.present ? data.module.value : this.module,
      onlineLink: data.onlineLink.present
          ? data.onlineLink.value
          : this.onlineLink,
      notes: data.notes.present ? data.notes.value : this.notes,
      maxAbsences: data.maxAbsences.present
          ? data.maxAbsences.value
          : this.maxAbsences,
      maxAbsencesTheory: data.maxAbsencesTheory.present
          ? data.maxAbsencesTheory.value
          : this.maxAbsencesTheory,
      maxAbsencesPractical: data.maxAbsencesPractical.present
          ? data.maxAbsencesPractical.value
          : this.maxAbsencesPractical,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      active: data.active.present ? data.active.value : this.active,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('yearId: $yearId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('teacher: $teacher, ')
          ..write('teacherEmail: $teacherEmail, ')
          ..write('room: $room, ')
          ..write('building: $building, ')
          ..write('module: $module, ')
          ..write('onlineLink: $onlineLink, ')
          ..write('notes: $notes, ')
          ..write('maxAbsences: $maxAbsences, ')
          ..write('maxAbsencesTheory: $maxAbsencesTheory, ')
          ..write('maxAbsencesPractical: $maxAbsencesPractical, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('active: $active, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorValue,
    yearId,
    startDate,
    endDate,
    teacher,
    teacherEmail,
    room,
    building,
    module,
    onlineLink,
    notes,
    maxAbsences,
    maxAbsencesTheory,
    maxAbsencesPractical,
    reminderMinutes,
    active,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.yearId == this.yearId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.teacher == this.teacher &&
          other.teacherEmail == this.teacherEmail &&
          other.room == this.room &&
          other.building == this.building &&
          other.module == this.module &&
          other.onlineLink == this.onlineLink &&
          other.notes == this.notes &&
          other.maxAbsences == this.maxAbsences &&
          other.maxAbsencesTheory == this.maxAbsencesTheory &&
          other.maxAbsencesPractical == this.maxAbsencesPractical &&
          other.reminderMinutes == this.reminderMinutes &&
          other.active == this.active &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class ClassesCompanion extends UpdateCompanion<ClassesData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<int?> yearId;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<String?> teacher;
  final Value<String?> teacherEmail;
  final Value<String?> room;
  final Value<String?> building;
  final Value<String?> module;
  final Value<String?> onlineLink;
  final Value<String?> notes;
  final Value<int?> maxAbsences;
  final Value<int?> maxAbsencesTheory;
  final Value<int?> maxAbsencesPractical;
  final Value<int?> reminderMinutes;
  final Value<bool> active;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const ClassesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.yearId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.teacher = const Value.absent(),
    this.teacherEmail = const Value.absent(),
    this.room = const Value.absent(),
    this.building = const Value.absent(),
    this.module = const Value.absent(),
    this.onlineLink = const Value.absent(),
    this.notes = const Value.absent(),
    this.maxAbsences = const Value.absent(),
    this.maxAbsencesTheory = const Value.absent(),
    this.maxAbsencesPractical = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.active = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ClassesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int colorValue,
    this.yearId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.teacher = const Value.absent(),
    this.teacherEmail = const Value.absent(),
    this.room = const Value.absent(),
    this.building = const Value.absent(),
    this.module = const Value.absent(),
    this.onlineLink = const Value.absent(),
    this.notes = const Value.absent(),
    this.maxAbsences = const Value.absent(),
    this.maxAbsencesTheory = const Value.absent(),
    this.maxAbsencesPractical = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.active = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       colorValue = Value(colorValue);
  static Insertable<ClassesData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<int>? yearId,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? teacher,
    Expression<String>? teacherEmail,
    Expression<String>? room,
    Expression<String>? building,
    Expression<String>? module,
    Expression<String>? onlineLink,
    Expression<String>? notes,
    Expression<int>? maxAbsences,
    Expression<int>? maxAbsencesTheory,
    Expression<int>? maxAbsencesPractical,
    Expression<int>? reminderMinutes,
    Expression<bool>? active,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (yearId != null) 'year_id': yearId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (teacher != null) 'teacher': teacher,
      if (teacherEmail != null) 'teacher_email': teacherEmail,
      if (room != null) 'room': room,
      if (building != null) 'building': building,
      if (module != null) 'module': module,
      if (onlineLink != null) 'online_link': onlineLink,
      if (notes != null) 'notes': notes,
      if (maxAbsences != null) 'max_absences': maxAbsences,
      if (maxAbsencesTheory != null) 'max_absences_theory': maxAbsencesTheory,
      if (maxAbsencesPractical != null)
        'max_absences_practical': maxAbsencesPractical,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (active != null) 'active': active,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ClassesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? colorValue,
    Value<int?>? yearId,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<String?>? teacher,
    Value<String?>? teacherEmail,
    Value<String?>? room,
    Value<String?>? building,
    Value<String?>? module,
    Value<String?>? onlineLink,
    Value<String?>? notes,
    Value<int?>? maxAbsences,
    Value<int?>? maxAbsencesTheory,
    Value<int?>? maxAbsencesPractical,
    Value<int?>? reminderMinutes,
    Value<bool>? active,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return ClassesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      yearId: yearId ?? this.yearId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      teacher: teacher ?? this.teacher,
      teacherEmail: teacherEmail ?? this.teacherEmail,
      room: room ?? this.room,
      building: building ?? this.building,
      module: module ?? this.module,
      onlineLink: onlineLink ?? this.onlineLink,
      notes: notes ?? this.notes,
      maxAbsences: maxAbsences ?? this.maxAbsences,
      maxAbsencesTheory: maxAbsencesTheory ?? this.maxAbsencesTheory,
      maxAbsencesPractical: maxAbsencesPractical ?? this.maxAbsencesPractical,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      active: active ?? this.active,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (yearId.present) {
      map['year_id'] = Variable<int>(yearId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (teacherEmail.present) {
      map['teacher_email'] = Variable<String>(teacherEmail.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (building.present) {
      map['building'] = Variable<String>(building.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (onlineLink.present) {
      map['online_link'] = Variable<String>(onlineLink.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (maxAbsences.present) {
      map['max_absences'] = Variable<int>(maxAbsences.value);
    }
    if (maxAbsencesTheory.present) {
      map['max_absences_theory'] = Variable<int>(maxAbsencesTheory.value);
    }
    if (maxAbsencesPractical.present) {
      map['max_absences_practical'] = Variable<int>(maxAbsencesPractical.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('yearId: $yearId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('teacher: $teacher, ')
          ..write('teacherEmail: $teacherEmail, ')
          ..write('room: $room, ')
          ..write('building: $building, ')
          ..write('module: $module, ')
          ..write('onlineLink: $onlineLink, ')
          ..write('notes: $notes, ')
          ..write('maxAbsences: $maxAbsences, ')
          ..write('maxAbsencesTheory: $maxAbsencesTheory, ')
          ..write('maxAbsencesPractical: $maxAbsencesPractical, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('active: $active, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduleItemsTable extends ScheduleItems
    with TableInfo<$ScheduleItemsTable, ScheduleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES classes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RotationKind, String> rotation =
      GeneratedColumn<String>(
        'rotation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RotationKind>($ScheduleItemsTable.$converterrotation);
  @override
  late final GeneratedColumnWithTypeConverter<WeekParity?, int> weekParity =
      GeneratedColumn<int>(
        'week_parity',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<WeekParity?>($ScheduleItemsTable.$converterweekParityn);
  static const VerificationMeta _cycleLengthMeta = const VerificationMeta(
    'cycleLength',
  );
  @override
  late final GeneratedColumn<int> cycleLength = GeneratedColumn<int>(
    'cycle_length',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleWeeksMeta = const VerificationMeta(
    'cycleWeeks',
  );
  @override
  late final GeneratedColumn<String> cycleWeeks = GeneratedColumn<String>(
    'cycle_weeks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rotationDaysMeta = const VerificationMeta(
    'rotationDays',
  );
  @override
  late final GeneratedColumn<String> rotationDays = GeneratedColumn<String>(
    'rotation_days',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<String> validFrom = GeneratedColumn<String>(
    'valid_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validToMeta = const VerificationMeta(
    'validTo',
  );
  @override
  late final GeneratedColumn<String> validTo = GeneratedColumn<String>(
    'valid_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    classId,
    dayOfWeek,
    startMinutes,
    endMinutes,
    room,
    rotation,
    weekParity,
    cycleLength,
    cycleWeeks,
    rotationDays,
    validFrom,
    validTo,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('cycle_length')) {
      context.handle(
        _cycleLengthMeta,
        cycleLength.isAcceptableOrUnknown(
          data['cycle_length']!,
          _cycleLengthMeta,
        ),
      );
    }
    if (data.containsKey('cycle_weeks')) {
      context.handle(
        _cycleWeeksMeta,
        cycleWeeks.isAcceptableOrUnknown(data['cycle_weeks']!, _cycleWeeksMeta),
      );
    }
    if (data.containsKey('rotation_days')) {
      context.handle(
        _rotationDaysMeta,
        rotationDays.isAcceptableOrUnknown(
          data['rotation_days']!,
          _rotationDaysMeta,
        ),
      );
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    }
    if (data.containsKey('valid_to')) {
      context.handle(
        _validToMeta,
        validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_id'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      )!,
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      ),
      rotation: $ScheduleItemsTable.$converterrotation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rotation'],
        )!,
      ),
      weekParity: $ScheduleItemsTable.$converterweekParityn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}week_parity'],
        ),
      ),
      cycleLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_length'],
      ),
      cycleWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_weeks'],
      ),
      rotationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rotation_days'],
      ),
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_from'],
      ),
      validTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_to'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScheduleItemsTable createAlias(String alias) {
    return $ScheduleItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RotationKind, String, String> $converterrotation =
      const EnumNameConverter<RotationKind>(RotationKind.values);
  static JsonTypeConverter2<WeekParity, int, int> $converterweekParity =
      const EnumIndexConverter<WeekParity>(WeekParity.values);
  static JsonTypeConverter2<WeekParity?, int?, int?> $converterweekParityn =
      JsonTypeConverter2.asNullable($converterweekParity);
}

class ScheduleItem extends DataClass implements Insertable<ScheduleItem> {
  final int id;
  final int classId;

  /// 1 = Monday .. 7 = Sunday (ISO weekday).
  final int dayOfWeek;

  /// Minutes from midnight.
  final int startMinutes;
  final int endMinutes;

  /// Room override; falls back to Classes.room.
  final String? room;
  final RotationKind rotation;
  final WeekParity? weekParity;
  final int? cycleLength;

  /// JSON-encoded list of 1-based cycle week indices, e.g. "[1,3]".
  final String? cycleWeeks;

  /// JSON-encoded list of 1-based rotation day indices, e.g. "[1,3]".
  final String? rotationDays;

  /// ISO-8601 date strings, null = unbounded.
  final String? validFrom;
  final String? validTo;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const ScheduleItem({
    required this.id,
    required this.classId,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.room,
    required this.rotation,
    this.weekParity,
    this.cycleLength,
    this.cycleWeeks,
    this.rotationDays,
    this.validFrom,
    this.validTo,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['class_id'] = Variable<int>(classId);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    if (!nullToAbsent || room != null) {
      map['room'] = Variable<String>(room);
    }
    {
      map['rotation'] = Variable<String>(
        $ScheduleItemsTable.$converterrotation.toSql(rotation),
      );
    }
    if (!nullToAbsent || weekParity != null) {
      map['week_parity'] = Variable<int>(
        $ScheduleItemsTable.$converterweekParityn.toSql(weekParity),
      );
    }
    if (!nullToAbsent || cycleLength != null) {
      map['cycle_length'] = Variable<int>(cycleLength);
    }
    if (!nullToAbsent || cycleWeeks != null) {
      map['cycle_weeks'] = Variable<String>(cycleWeeks);
    }
    if (!nullToAbsent || rotationDays != null) {
      map['rotation_days'] = Variable<String>(rotationDays);
    }
    if (!nullToAbsent || validFrom != null) {
      map['valid_from'] = Variable<String>(validFrom);
    }
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<String>(validTo);
    }
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ScheduleItemsCompanion toCompanion(bool nullToAbsent) {
    return ScheduleItemsCompanion(
      id: Value(id),
      classId: Value(classId),
      dayOfWeek: Value(dayOfWeek),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
      room: room == null && nullToAbsent ? const Value.absent() : Value(room),
      rotation: Value(rotation),
      weekParity: weekParity == null && nullToAbsent
          ? const Value.absent()
          : Value(weekParity),
      cycleLength: cycleLength == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleLength),
      cycleWeeks: cycleWeeks == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleWeeks),
      rotationDays: rotationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(rotationDays),
      validFrom: validFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScheduleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleItem(
      id: serializer.fromJson<int>(json['id']),
      classId: serializer.fromJson<int>(json['classId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
      room: serializer.fromJson<String?>(json['room']),
      rotation: $ScheduleItemsTable.$converterrotation.fromJson(
        serializer.fromJson<String>(json['rotation']),
      ),
      weekParity: $ScheduleItemsTable.$converterweekParityn.fromJson(
        serializer.fromJson<int?>(json['weekParity']),
      ),
      cycleLength: serializer.fromJson<int?>(json['cycleLength']),
      cycleWeeks: serializer.fromJson<String?>(json['cycleWeeks']),
      rotationDays: serializer.fromJson<String?>(json['rotationDays']),
      validFrom: serializer.fromJson<String?>(json['validFrom']),
      validTo: serializer.fromJson<String?>(json['validTo']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'classId': serializer.toJson<int>(classId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
      'room': serializer.toJson<String?>(room),
      'rotation': serializer.toJson<String>(
        $ScheduleItemsTable.$converterrotation.toJson(rotation),
      ),
      'weekParity': serializer.toJson<int?>(
        $ScheduleItemsTable.$converterweekParityn.toJson(weekParity),
      ),
      'cycleLength': serializer.toJson<int?>(cycleLength),
      'cycleWeeks': serializer.toJson<String?>(cycleWeeks),
      'rotationDays': serializer.toJson<String?>(rotationDays),
      'validFrom': serializer.toJson<String?>(validFrom),
      'validTo': serializer.toJson<String?>(validTo),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ScheduleItem copyWith({
    int? id,
    int? classId,
    int? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
    Value<String?> room = const Value.absent(),
    RotationKind? rotation,
    Value<WeekParity?> weekParity = const Value.absent(),
    Value<int?> cycleLength = const Value.absent(),
    Value<String?> cycleWeeks = const Value.absent(),
    Value<String?> rotationDays = const Value.absent(),
    Value<String?> validFrom = const Value.absent(),
    Value<String?> validTo = const Value.absent(),
    String? uuid,
    int? updatedAt,
  }) => ScheduleItem(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    room: room.present ? room.value : this.room,
    rotation: rotation ?? this.rotation,
    weekParity: weekParity.present ? weekParity.value : this.weekParity,
    cycleLength: cycleLength.present ? cycleLength.value : this.cycleLength,
    cycleWeeks: cycleWeeks.present ? cycleWeeks.value : this.cycleWeeks,
    rotationDays: rotationDays.present ? rotationDays.value : this.rotationDays,
    validFrom: validFrom.present ? validFrom.value : this.validFrom,
    validTo: validTo.present ? validTo.value : this.validTo,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScheduleItem copyWithCompanion(ScheduleItemsCompanion data) {
    return ScheduleItem(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      room: data.room.present ? data.room.value : this.room,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      weekParity: data.weekParity.present
          ? data.weekParity.value
          : this.weekParity,
      cycleLength: data.cycleLength.present
          ? data.cycleLength.value
          : this.cycleLength,
      cycleWeeks: data.cycleWeeks.present
          ? data.cycleWeeks.value
          : this.cycleWeeks,
      rotationDays: data.rotationDays.present
          ? data.rotationDays.value
          : this.rotationDays,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleItem(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('room: $room, ')
          ..write('rotation: $rotation, ')
          ..write('weekParity: $weekParity, ')
          ..write('cycleLength: $cycleLength, ')
          ..write('cycleWeeks: $cycleWeeks, ')
          ..write('rotationDays: $rotationDays, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classId,
    dayOfWeek,
    startMinutes,
    endMinutes,
    room,
    rotation,
    weekParity,
    cycleLength,
    cycleWeeks,
    rotationDays,
    validFrom,
    validTo,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleItem &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.room == this.room &&
          other.rotation == this.rotation &&
          other.weekParity == this.weekParity &&
          other.cycleLength == this.cycleLength &&
          other.cycleWeeks == this.cycleWeeks &&
          other.rotationDays == this.rotationDays &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class ScheduleItemsCompanion extends UpdateCompanion<ScheduleItem> {
  final Value<int> id;
  final Value<int> classId;
  final Value<int> dayOfWeek;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<String?> room;
  final Value<RotationKind> rotation;
  final Value<WeekParity?> weekParity;
  final Value<int?> cycleLength;
  final Value<String?> cycleWeeks;
  final Value<String?> rotationDays;
  final Value<String?> validFrom;
  final Value<String?> validTo;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const ScheduleItemsCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.room = const Value.absent(),
    this.rotation = const Value.absent(),
    this.weekParity = const Value.absent(),
    this.cycleLength = const Value.absent(),
    this.cycleWeeks = const Value.absent(),
    this.rotationDays = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ScheduleItemsCompanion.insert({
    this.id = const Value.absent(),
    required int classId,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    this.room = const Value.absent(),
    required RotationKind rotation,
    this.weekParity = const Value.absent(),
    this.cycleLength = const Value.absent(),
    this.cycleWeeks = const Value.absent(),
    this.rotationDays = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : classId = Value(classId),
       dayOfWeek = Value(dayOfWeek),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes),
       rotation = Value(rotation);
  static Insertable<ScheduleItem> custom({
    Expression<int>? id,
    Expression<int>? classId,
    Expression<int>? dayOfWeek,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? room,
    Expression<String>? rotation,
    Expression<int>? weekParity,
    Expression<int>? cycleLength,
    Expression<String>? cycleWeeks,
    Expression<String>? rotationDays,
    Expression<String>? validFrom,
    Expression<String>? validTo,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (room != null) 'room': room,
      if (rotation != null) 'rotation': rotation,
      if (weekParity != null) 'week_parity': weekParity,
      if (cycleLength != null) 'cycle_length': cycleLength,
      if (cycleWeeks != null) 'cycle_weeks': cycleWeeks,
      if (rotationDays != null) 'rotation_days': rotationDays,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ScheduleItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? classId,
    Value<int>? dayOfWeek,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<String?>? room,
    Value<RotationKind>? rotation,
    Value<WeekParity?>? weekParity,
    Value<int?>? cycleLength,
    Value<String?>? cycleWeeks,
    Value<String?>? rotationDays,
    Value<String?>? validFrom,
    Value<String?>? validTo,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return ScheduleItemsCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      room: room ?? this.room,
      rotation: rotation ?? this.rotation,
      weekParity: weekParity ?? this.weekParity,
      cycleLength: cycleLength ?? this.cycleLength,
      cycleWeeks: cycleWeeks ?? this.cycleWeeks,
      rotationDays: rotationDays ?? this.rotationDays,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<String>(
        $ScheduleItemsTable.$converterrotation.toSql(rotation.value),
      );
    }
    if (weekParity.present) {
      map['week_parity'] = Variable<int>(
        $ScheduleItemsTable.$converterweekParityn.toSql(weekParity.value),
      );
    }
    if (cycleLength.present) {
      map['cycle_length'] = Variable<int>(cycleLength.value);
    }
    if (cycleWeeks.present) {
      map['cycle_weeks'] = Variable<String>(cycleWeeks.value);
    }
    if (rotationDays.present) {
      map['rotation_days'] = Variable<String>(rotationDays.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<String>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<String>(validTo.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleItemsCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('room: $room, ')
          ..write('rotation: $rotation, ')
          ..write('weekParity: $weekParity, ')
          ..write('cycleLength: $cycleLength, ')
          ..write('cycleWeeks: $cycleWeeks, ')
          ..write('rotationDays: $rotationDays, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduleExceptionsTable extends ScheduleExceptions
    with TableInfo<$ScheduleExceptionsTable, ScheduleException> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleExceptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scheduleItemIdMeta = const VerificationMeta(
    'scheduleItemId',
  );
  @override
  late final GeneratedColumn<int> scheduleItemId = GeneratedColumn<int>(
    'schedule_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedule_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExceptionKind, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExceptionKind>($ScheduleExceptionsTable.$converterstatus);
  static const VerificationMeta _newStartMinutesMeta = const VerificationMeta(
    'newStartMinutes',
  );
  @override
  late final GeneratedColumn<int> newStartMinutes = GeneratedColumn<int>(
    'new_start_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newEndMinutesMeta = const VerificationMeta(
    'newEndMinutes',
  );
  @override
  late final GeneratedColumn<int> newEndMinutes = GeneratedColumn<int>(
    'new_end_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newRoomMeta = const VerificationMeta(
    'newRoom',
  );
  @override
  late final GeneratedColumn<String> newRoom = GeneratedColumn<String>(
    'new_room',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduleItemId,
    date,
    status,
    newStartMinutes,
    newEndMinutes,
    newRoom,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleException> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('schedule_item_id')) {
      context.handle(
        _scheduleItemIdMeta,
        scheduleItemId.isAcceptableOrUnknown(
          data['schedule_item_id']!,
          _scheduleItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleItemIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('new_start_minutes')) {
      context.handle(
        _newStartMinutesMeta,
        newStartMinutes.isAcceptableOrUnknown(
          data['new_start_minutes']!,
          _newStartMinutesMeta,
        ),
      );
    }
    if (data.containsKey('new_end_minutes')) {
      context.handle(
        _newEndMinutesMeta,
        newEndMinutes.isAcceptableOrUnknown(
          data['new_end_minutes']!,
          _newEndMinutesMeta,
        ),
      );
    }
    if (data.containsKey('new_room')) {
      context.handle(
        _newRoomMeta,
        newRoom.isAcceptableOrUnknown(data['new_room']!, _newRoomMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleException map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleException(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scheduleItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_item_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      status: $ScheduleExceptionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      newStartMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_start_minutes'],
      ),
      newEndMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_end_minutes'],
      ),
      newRoom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_room'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScheduleExceptionsTable createAlias(String alias) {
    return $ScheduleExceptionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExceptionKind, String, String> $converterstatus =
      const EnumNameConverter<ExceptionKind>(ExceptionKind.values);
}

class ScheduleException extends DataClass
    implements Insertable<ScheduleException> {
  final int id;
  final int scheduleItemId;

  /// ISO-8601 date string of the affected occurrence.
  final String date;
  final ExceptionKind status;
  final int? newStartMinutes;
  final int? newEndMinutes;
  final String? newRoom;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const ScheduleException({
    required this.id,
    required this.scheduleItemId,
    required this.date,
    required this.status,
    this.newStartMinutes,
    this.newEndMinutes,
    this.newRoom,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['schedule_item_id'] = Variable<int>(scheduleItemId);
    map['date'] = Variable<String>(date);
    {
      map['status'] = Variable<String>(
        $ScheduleExceptionsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || newStartMinutes != null) {
      map['new_start_minutes'] = Variable<int>(newStartMinutes);
    }
    if (!nullToAbsent || newEndMinutes != null) {
      map['new_end_minutes'] = Variable<int>(newEndMinutes);
    }
    if (!nullToAbsent || newRoom != null) {
      map['new_room'] = Variable<String>(newRoom);
    }
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ScheduleExceptionsCompanion toCompanion(bool nullToAbsent) {
    return ScheduleExceptionsCompanion(
      id: Value(id),
      scheduleItemId: Value(scheduleItemId),
      date: Value(date),
      status: Value(status),
      newStartMinutes: newStartMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(newStartMinutes),
      newEndMinutes: newEndMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(newEndMinutes),
      newRoom: newRoom == null && nullToAbsent
          ? const Value.absent()
          : Value(newRoom),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScheduleException.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleException(
      id: serializer.fromJson<int>(json['id']),
      scheduleItemId: serializer.fromJson<int>(json['scheduleItemId']),
      date: serializer.fromJson<String>(json['date']),
      status: $ScheduleExceptionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      newStartMinutes: serializer.fromJson<int?>(json['newStartMinutes']),
      newEndMinutes: serializer.fromJson<int?>(json['newEndMinutes']),
      newRoom: serializer.fromJson<String?>(json['newRoom']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scheduleItemId': serializer.toJson<int>(scheduleItemId),
      'date': serializer.toJson<String>(date),
      'status': serializer.toJson<String>(
        $ScheduleExceptionsTable.$converterstatus.toJson(status),
      ),
      'newStartMinutes': serializer.toJson<int?>(newStartMinutes),
      'newEndMinutes': serializer.toJson<int?>(newEndMinutes),
      'newRoom': serializer.toJson<String?>(newRoom),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ScheduleException copyWith({
    int? id,
    int? scheduleItemId,
    String? date,
    ExceptionKind? status,
    Value<int?> newStartMinutes = const Value.absent(),
    Value<int?> newEndMinutes = const Value.absent(),
    Value<String?> newRoom = const Value.absent(),
    String? uuid,
    int? updatedAt,
  }) => ScheduleException(
    id: id ?? this.id,
    scheduleItemId: scheduleItemId ?? this.scheduleItemId,
    date: date ?? this.date,
    status: status ?? this.status,
    newStartMinutes: newStartMinutes.present
        ? newStartMinutes.value
        : this.newStartMinutes,
    newEndMinutes: newEndMinutes.present
        ? newEndMinutes.value
        : this.newEndMinutes,
    newRoom: newRoom.present ? newRoom.value : this.newRoom,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScheduleException copyWithCompanion(ScheduleExceptionsCompanion data) {
    return ScheduleException(
      id: data.id.present ? data.id.value : this.id,
      scheduleItemId: data.scheduleItemId.present
          ? data.scheduleItemId.value
          : this.scheduleItemId,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      newStartMinutes: data.newStartMinutes.present
          ? data.newStartMinutes.value
          : this.newStartMinutes,
      newEndMinutes: data.newEndMinutes.present
          ? data.newEndMinutes.value
          : this.newEndMinutes,
      newRoom: data.newRoom.present ? data.newRoom.value : this.newRoom,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleException(')
          ..write('id: $id, ')
          ..write('scheduleItemId: $scheduleItemId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('newStartMinutes: $newStartMinutes, ')
          ..write('newEndMinutes: $newEndMinutes, ')
          ..write('newRoom: $newRoom, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scheduleItemId,
    date,
    status,
    newStartMinutes,
    newEndMinutes,
    newRoom,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleException &&
          other.id == this.id &&
          other.scheduleItemId == this.scheduleItemId &&
          other.date == this.date &&
          other.status == this.status &&
          other.newStartMinutes == this.newStartMinutes &&
          other.newEndMinutes == this.newEndMinutes &&
          other.newRoom == this.newRoom &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class ScheduleExceptionsCompanion extends UpdateCompanion<ScheduleException> {
  final Value<int> id;
  final Value<int> scheduleItemId;
  final Value<String> date;
  final Value<ExceptionKind> status;
  final Value<int?> newStartMinutes;
  final Value<int?> newEndMinutes;
  final Value<String?> newRoom;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const ScheduleExceptionsCompanion({
    this.id = const Value.absent(),
    this.scheduleItemId = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.newStartMinutes = const Value.absent(),
    this.newEndMinutes = const Value.absent(),
    this.newRoom = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ScheduleExceptionsCompanion.insert({
    this.id = const Value.absent(),
    required int scheduleItemId,
    required String date,
    required ExceptionKind status,
    this.newStartMinutes = const Value.absent(),
    this.newEndMinutes = const Value.absent(),
    this.newRoom = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : scheduleItemId = Value(scheduleItemId),
       date = Value(date),
       status = Value(status);
  static Insertable<ScheduleException> custom({
    Expression<int>? id,
    Expression<int>? scheduleItemId,
    Expression<String>? date,
    Expression<String>? status,
    Expression<int>? newStartMinutes,
    Expression<int>? newEndMinutes,
    Expression<String>? newRoom,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleItemId != null) 'schedule_item_id': scheduleItemId,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (newStartMinutes != null) 'new_start_minutes': newStartMinutes,
      if (newEndMinutes != null) 'new_end_minutes': newEndMinutes,
      if (newRoom != null) 'new_room': newRoom,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ScheduleExceptionsCompanion copyWith({
    Value<int>? id,
    Value<int>? scheduleItemId,
    Value<String>? date,
    Value<ExceptionKind>? status,
    Value<int?>? newStartMinutes,
    Value<int?>? newEndMinutes,
    Value<String?>? newRoom,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return ScheduleExceptionsCompanion(
      id: id ?? this.id,
      scheduleItemId: scheduleItemId ?? this.scheduleItemId,
      date: date ?? this.date,
      status: status ?? this.status,
      newStartMinutes: newStartMinutes ?? this.newStartMinutes,
      newEndMinutes: newEndMinutes ?? this.newEndMinutes,
      newRoom: newRoom ?? this.newRoom,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scheduleItemId.present) {
      map['schedule_item_id'] = Variable<int>(scheduleItemId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ScheduleExceptionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (newStartMinutes.present) {
      map['new_start_minutes'] = Variable<int>(newStartMinutes.value);
    }
    if (newEndMinutes.present) {
      map['new_end_minutes'] = Variable<int>(newEndMinutes.value);
    }
    if (newRoom.present) {
      map['new_room'] = Variable<String>(newRoom.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleExceptionsCompanion(')
          ..write('id: $id, ')
          ..write('scheduleItemId: $scheduleItemId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('newStartMinutes: $newStartMinutes, ')
          ..write('newEndMinutes: $newEndMinutes, ')
          ..write('newRoom: $newRoom, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HolidaysTable extends Holidays with TableInfo<$HolidaysTable, Holiday> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HolidaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDate,
    endDate,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holidays';
  @override
  VerificationContext validateIntegrity(
    Insertable<Holiday> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Holiday map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Holiday(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HolidaysTable createAlias(String alias) {
    return $HolidaysTable(attachedDatabase, alias);
  }
}

class Holiday extends DataClass implements Insertable<Holiday> {
  final int id;
  final String name;
  final String startDate;
  final String endDate;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const Holiday({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  HolidaysCompanion toCompanion(bool nullToAbsent) {
    return HolidaysCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory Holiday.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Holiday(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Holiday copyWith({
    int? id,
    String? name,
    String? startDate,
    String? endDate,
    String? uuid,
    int? updatedAt,
  }) => Holiday(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Holiday copyWithCompanion(HolidaysCompanion data) {
    return Holiday(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Holiday(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, startDate, endDate, uuid, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Holiday &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class HolidaysCompanion extends UpdateCompanion<Holiday> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const HolidaysCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HolidaysCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String startDate,
    required String endDate,
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<Holiday> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HolidaysCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return HolidaysCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HolidaysCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AbsencesTable extends Absences with TableInfo<$AbsencesTable, Absence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbsencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES classes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isExcusedMeta = const VerificationMeta(
    'isExcused',
  );
  @override
  late final GeneratedColumn<bool> isExcused = GeneratedColumn<bool>(
    'is_excused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_excused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AbsenceKind?, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<AbsenceKind?>($AbsencesTable.$converterkindn);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    classId,
    date,
    startMinutes,
    endMinutes,
    reason,
    isExcused,
    kind,
    notes,
    createdAt,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'absences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Absence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('is_excused')) {
      context.handle(
        _isExcusedMeta,
        isExcused.isAcceptableOrUnknown(data['is_excused']!, _isExcusedMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Absence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Absence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      isExcused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_excused'],
      )!,
      kind: $AbsencesTable.$converterkindn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        ),
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AbsencesTable createAlias(String alias) {
    return $AbsencesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AbsenceKind, String, String> $converterkind =
      const EnumNameConverter<AbsenceKind>(AbsenceKind.values);
  static JsonTypeConverter2<AbsenceKind?, String?, String?> $converterkindn =
      JsonTypeConverter2.asNullable($converterkind);
}

class Absence extends DataClass implements Insertable<Absence> {
  final int id;
  final int classId;

  /// ISO-8601 date string.
  final String date;

  /// Minutes-from-midnight snapshots so history survives schedule edits.
  final int startMinutes;
  final int endMinutes;
  final String? reason;
  final bool isExcused;

  /// Theory vs practical session. Null = legacy rows, counted as theory.
  final AbsenceKind? kind;
  final String? notes;
  final DateTime createdAt;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const Absence({
    required this.id,
    required this.classId,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    this.reason,
    required this.isExcused,
    this.kind,
    this.notes,
    required this.createdAt,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['class_id'] = Variable<int>(classId);
    map['date'] = Variable<String>(date);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['is_excused'] = Variable<bool>(isExcused);
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(
        $AbsencesTable.$converterkindn.toSql(kind),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AbsencesCompanion toCompanion(bool nullToAbsent) {
    return AbsencesCompanion(
      id: Value(id),
      classId: Value(classId),
      date: Value(date),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      isExcused: Value(isExcused),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory Absence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Absence(
      id: serializer.fromJson<int>(json['id']),
      classId: serializer.fromJson<int>(json['classId']),
      date: serializer.fromJson<String>(json['date']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
      reason: serializer.fromJson<String?>(json['reason']),
      isExcused: serializer.fromJson<bool>(json['isExcused']),
      kind: $AbsencesTable.$converterkindn.fromJson(
        serializer.fromJson<String?>(json['kind']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'classId': serializer.toJson<int>(classId),
      'date': serializer.toJson<String>(date),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
      'reason': serializer.toJson<String?>(reason),
      'isExcused': serializer.toJson<bool>(isExcused),
      'kind': serializer.toJson<String?>(
        $AbsencesTable.$converterkindn.toJson(kind),
      ),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Absence copyWith({
    int? id,
    int? classId,
    String? date,
    int? startMinutes,
    int? endMinutes,
    Value<String?> reason = const Value.absent(),
    bool? isExcused,
    Value<AbsenceKind?> kind = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    String? uuid,
    int? updatedAt,
  }) => Absence(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    date: date ?? this.date,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    reason: reason.present ? reason.value : this.reason,
    isExcused: isExcused ?? this.isExcused,
    kind: kind.present ? kind.value : this.kind,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Absence copyWithCompanion(AbsencesCompanion data) {
    return Absence(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      date: data.date.present ? data.date.value : this.date,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      reason: data.reason.present ? data.reason.value : this.reason,
      isExcused: data.isExcused.present ? data.isExcused.value : this.isExcused,
      kind: data.kind.present ? data.kind.value : this.kind,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Absence(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('reason: $reason, ')
          ..write('isExcused: $isExcused, ')
          ..write('kind: $kind, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classId,
    date,
    startMinutes,
    endMinutes,
    reason,
    isExcused,
    kind,
    notes,
    createdAt,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Absence &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.date == this.date &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.reason == this.reason &&
          other.isExcused == this.isExcused &&
          other.kind == this.kind &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class AbsencesCompanion extends UpdateCompanion<Absence> {
  final Value<int> id;
  final Value<int> classId;
  final Value<String> date;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<String?> reason;
  final Value<bool> isExcused;
  final Value<AbsenceKind?> kind;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const AbsencesCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.date = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.reason = const Value.absent(),
    this.isExcused = const Value.absent(),
    this.kind = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AbsencesCompanion.insert({
    this.id = const Value.absent(),
    required int classId,
    required String date,
    required int startMinutes,
    required int endMinutes,
    this.reason = const Value.absent(),
    this.isExcused = const Value.absent(),
    this.kind = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : classId = Value(classId),
       date = Value(date),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes);
  static Insertable<Absence> custom({
    Expression<int>? id,
    Expression<int>? classId,
    Expression<String>? date,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? reason,
    Expression<bool>? isExcused,
    Expression<String>? kind,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (date != null) 'date': date,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (reason != null) 'reason': reason,
      if (isExcused != null) 'is_excused': isExcused,
      if (kind != null) 'kind': kind,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AbsencesCompanion copyWith({
    Value<int>? id,
    Value<int>? classId,
    Value<String>? date,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<String?>? reason,
    Value<bool>? isExcused,
    Value<AbsenceKind?>? kind,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return AbsencesCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      reason: reason ?? this.reason,
      isExcused: isExcused ?? this.isExcused,
      kind: kind ?? this.kind,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (isExcused.present) {
      map['is_excused'] = Variable<bool>(isExcused.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AbsencesTable.$converterkindn.toSql(kind.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbsencesCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('reason: $reason, ')
          ..write('isExcused: $isExcused, ')
          ..write('kind: $kind, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
    'class_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES classes (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 240,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('homework'),
      ).withConverter<TaskKind>($TasksTable.$convertertype);
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMinutesMeta = const VerificationMeta(
    'dueMinutes',
  );
  @override
  late final GeneratedColumn<int> dueMinutes = GeneratedColumn<int>(
    'due_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskPriority, int> priority =
      GeneratedColumn<int>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      ).withConverter<TaskPriority>($TasksTable.$converterpriority);
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<int> progressPercent = GeneratedColumn<int>(
    'progress_percent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RepeatKind?, String> repeatKind =
      GeneratedColumn<String>(
        'repeat_kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<RepeatKind?>($TasksTable.$converterrepeatKindn);
  static const VerificationMeta _repeatUntilMeta = const VerificationMeta(
    'repeatUntil',
  );
  @override
  late final GeneratedColumn<String> repeatUntil = GeneratedColumn<String>(
    'repeat_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedExamIdMeta = const VerificationMeta(
    'linkedExamId',
  );
  @override
  late final GeneratedColumn<int> linkedExamId = GeneratedColumn<int>(
    'linked_exam_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    classId,
    title,
    notes,
    type,
    dueDate,
    dueMinutes,
    priority,
    isDone,
    doneAt,
    createdAt,
    progressPercent,
    repeatKind,
    repeatUntil,
    linkedExamId,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('due_minutes')) {
      context.handle(
        _dueMinutesMeta,
        dueMinutes.isAcceptableOrUnknown(data['due_minutes']!, _dueMinutesMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    }
    if (data.containsKey('repeat_until')) {
      context.handle(
        _repeatUntilMeta,
        repeatUntil.isAcceptableOrUnknown(
          data['repeat_until']!,
          _repeatUntilMeta,
        ),
      );
    }
    if (data.containsKey('linked_exam_id')) {
      context.handle(
        _linkedExamIdMeta,
        linkedExamId.isAcceptableOrUnknown(
          data['linked_exam_id']!,
          _linkedExamIdMeta,
        ),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      type: $TasksTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      dueMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_minutes'],
      ),
      priority: $TasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}priority'],
        )!,
      ),
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress_percent'],
      ),
      repeatKind: $TasksTable.$converterrepeatKindn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repeat_kind'],
        ),
      ),
      repeatUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_until'],
      ),
      linkedExamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_exam_id'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskKind, String, String> $convertertype =
      const EnumNameConverter<TaskKind>(TaskKind.values);
  static JsonTypeConverter2<TaskPriority, int, int> $converterpriority =
      const EnumIndexConverter<TaskPriority>(TaskPriority.values);
  static JsonTypeConverter2<RepeatKind, String, String> $converterrepeatKind =
      const EnumNameConverter<RepeatKind>(RepeatKind.values);
  static JsonTypeConverter2<RepeatKind?, String?, String?>
  $converterrepeatKindn = JsonTypeConverter2.asNullable($converterrepeatKind);
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final int? classId;
  final String title;
  final String? notes;
  final TaskKind type;
  final String? dueDate;

  /// Minutes from midnight; null = all-day due.
  final int? dueMinutes;
  final TaskPriority priority;
  final bool isDone;
  final DateTime? doneAt;
  final DateTime createdAt;

  /// Partial completion 0-100. Null = binary done/not-done tracking.
  final int? progressPercent;

  /// Auto-repeat rule. Null = no repeat.
  final RepeatKind? repeatKind;

  /// ISO date: stop generating repeats after this day. Null = forever.
  final String? repeatUntil;

  /// For revision tasks: the exam task they prepare for.
  final int? linkedExamId;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const Task({
    required this.id,
    this.classId,
    required this.title,
    this.notes,
    required this.type,
    this.dueDate,
    this.dueMinutes,
    required this.priority,
    required this.isDone,
    this.doneAt,
    required this.createdAt,
    this.progressPercent,
    this.repeatKind,
    this.repeatUntil,
    this.linkedExamId,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || classId != null) {
      map['class_id'] = Variable<int>(classId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['type'] = Variable<String>($TasksTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || dueMinutes != null) {
      map['due_minutes'] = Variable<int>(dueMinutes);
    }
    {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority),
      );
    }
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || progressPercent != null) {
      map['progress_percent'] = Variable<int>(progressPercent);
    }
    if (!nullToAbsent || repeatKind != null) {
      map['repeat_kind'] = Variable<String>(
        $TasksTable.$converterrepeatKindn.toSql(repeatKind),
      );
    }
    if (!nullToAbsent || repeatUntil != null) {
      map['repeat_until'] = Variable<String>(repeatUntil);
    }
    if (!nullToAbsent || linkedExamId != null) {
      map['linked_exam_id'] = Variable<int>(linkedExamId);
    }
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      classId: classId == null && nullToAbsent
          ? const Value.absent()
          : Value(classId),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      type: Value(type),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueMinutes: dueMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(dueMinutes),
      priority: Value(priority),
      isDone: Value(isDone),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      createdAt: Value(createdAt),
      progressPercent: progressPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(progressPercent),
      repeatKind: repeatKind == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatKind),
      repeatUntil: repeatUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatUntil),
      linkedExamId: linkedExamId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedExamId),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      classId: serializer.fromJson<int?>(json['classId']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      type: $TasksTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      dueMinutes: serializer.fromJson<int?>(json['dueMinutes']),
      priority: $TasksTable.$converterpriority.fromJson(
        serializer.fromJson<int>(json['priority']),
      ),
      isDone: serializer.fromJson<bool>(json['isDone']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      progressPercent: serializer.fromJson<int?>(json['progressPercent']),
      repeatKind: $TasksTable.$converterrepeatKindn.fromJson(
        serializer.fromJson<String?>(json['repeatKind']),
      ),
      repeatUntil: serializer.fromJson<String?>(json['repeatUntil']),
      linkedExamId: serializer.fromJson<int?>(json['linkedExamId']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'classId': serializer.toJson<int?>(classId),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'type': serializer.toJson<String>(
        $TasksTable.$convertertype.toJson(type),
      ),
      'dueDate': serializer.toJson<String?>(dueDate),
      'dueMinutes': serializer.toJson<int?>(dueMinutes),
      'priority': serializer.toJson<int>(
        $TasksTable.$converterpriority.toJson(priority),
      ),
      'isDone': serializer.toJson<bool>(isDone),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'progressPercent': serializer.toJson<int?>(progressPercent),
      'repeatKind': serializer.toJson<String?>(
        $TasksTable.$converterrepeatKindn.toJson(repeatKind),
      ),
      'repeatUntil': serializer.toJson<String?>(repeatUntil),
      'linkedExamId': serializer.toJson<int?>(linkedExamId),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Task copyWith({
    int? id,
    Value<int?> classId = const Value.absent(),
    String? title,
    Value<String?> notes = const Value.absent(),
    TaskKind? type,
    Value<String?> dueDate = const Value.absent(),
    Value<int?> dueMinutes = const Value.absent(),
    TaskPriority? priority,
    bool? isDone,
    Value<DateTime?> doneAt = const Value.absent(),
    DateTime? createdAt,
    Value<int?> progressPercent = const Value.absent(),
    Value<RepeatKind?> repeatKind = const Value.absent(),
    Value<String?> repeatUntil = const Value.absent(),
    Value<int?> linkedExamId = const Value.absent(),
    String? uuid,
    int? updatedAt,
  }) => Task(
    id: id ?? this.id,
    classId: classId.present ? classId.value : this.classId,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    type: type ?? this.type,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueMinutes: dueMinutes.present ? dueMinutes.value : this.dueMinutes,
    priority: priority ?? this.priority,
    isDone: isDone ?? this.isDone,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    createdAt: createdAt ?? this.createdAt,
    progressPercent: progressPercent.present
        ? progressPercent.value
        : this.progressPercent,
    repeatKind: repeatKind.present ? repeatKind.value : this.repeatKind,
    repeatUntil: repeatUntil.present ? repeatUntil.value : this.repeatUntil,
    linkedExamId: linkedExamId.present ? linkedExamId.value : this.linkedExamId,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      type: data.type.present ? data.type.value : this.type,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueMinutes: data.dueMinutes.present
          ? data.dueMinutes.value
          : this.dueMinutes,
      priority: data.priority.present ? data.priority.value : this.priority,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      repeatKind: data.repeatKind.present
          ? data.repeatKind.value
          : this.repeatKind,
      repeatUntil: data.repeatUntil.present
          ? data.repeatUntil.value
          : this.repeatUntil,
      linkedExamId: data.linkedExamId.present
          ? data.linkedExamId.value
          : this.linkedExamId,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('type: $type, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinutes: $dueMinutes, ')
          ..write('priority: $priority, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('repeatUntil: $repeatUntil, ')
          ..write('linkedExamId: $linkedExamId, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classId,
    title,
    notes,
    type,
    dueDate,
    dueMinutes,
    priority,
    isDone,
    doneAt,
    createdAt,
    progressPercent,
    repeatKind,
    repeatUntil,
    linkedExamId,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.type == this.type &&
          other.dueDate == this.dueDate &&
          other.dueMinutes == this.dueMinutes &&
          other.priority == this.priority &&
          other.isDone == this.isDone &&
          other.doneAt == this.doneAt &&
          other.createdAt == this.createdAt &&
          other.progressPercent == this.progressPercent &&
          other.repeatKind == this.repeatKind &&
          other.repeatUntil == this.repeatUntil &&
          other.linkedExamId == this.linkedExamId &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<int?> classId;
  final Value<String> title;
  final Value<String?> notes;
  final Value<TaskKind> type;
  final Value<String?> dueDate;
  final Value<int?> dueMinutes;
  final Value<TaskPriority> priority;
  final Value<bool> isDone;
  final Value<DateTime?> doneAt;
  final Value<DateTime> createdAt;
  final Value<int?> progressPercent;
  final Value<RepeatKind?> repeatKind;
  final Value<String?> repeatUntil;
  final Value<int?> linkedExamId;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.type = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueMinutes = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.repeatKind = const Value.absent(),
    this.repeatUntil = const Value.absent(),
    this.linkedExamId = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.type = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueMinutes = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.repeatKind = const Value.absent(),
    this.repeatUntil = const Value.absent(),
    this.linkedExamId = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<int>? classId,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? type,
    Expression<String>? dueDate,
    Expression<int>? dueMinutes,
    Expression<int>? priority,
    Expression<bool>? isDone,
    Expression<DateTime>? doneAt,
    Expression<DateTime>? createdAt,
    Expression<int>? progressPercent,
    Expression<String>? repeatKind,
    Expression<String>? repeatUntil,
    Expression<int>? linkedExamId,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (type != null) 'type': type,
      if (dueDate != null) 'due_date': dueDate,
      if (dueMinutes != null) 'due_minutes': dueMinutes,
      if (priority != null) 'priority': priority,
      if (isDone != null) 'is_done': isDone,
      if (doneAt != null) 'done_at': doneAt,
      if (createdAt != null) 'created_at': createdAt,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (repeatKind != null) 'repeat_kind': repeatKind,
      if (repeatUntil != null) 'repeat_until': repeatUntil,
      if (linkedExamId != null) 'linked_exam_id': linkedExamId,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? classId,
    Value<String>? title,
    Value<String?>? notes,
    Value<TaskKind>? type,
    Value<String?>? dueDate,
    Value<int?>? dueMinutes,
    Value<TaskPriority>? priority,
    Value<bool>? isDone,
    Value<DateTime?>? doneAt,
    Value<DateTime>? createdAt,
    Value<int?>? progressPercent,
    Value<RepeatKind?>? repeatKind,
    Value<String?>? repeatUntil,
    Value<int?>? linkedExamId,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      dueMinutes: dueMinutes ?? this.dueMinutes,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      doneAt: doneAt ?? this.doneAt,
      createdAt: createdAt ?? this.createdAt,
      progressPercent: progressPercent ?? this.progressPercent,
      repeatKind: repeatKind ?? this.repeatKind,
      repeatUntil: repeatUntil ?? this.repeatUntil,
      linkedExamId: linkedExamId ?? this.linkedExamId,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TasksTable.$convertertype.toSql(type.value),
      );
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (dueMinutes.present) {
      map['due_minutes'] = Variable<int>(dueMinutes.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<int>(progressPercent.value);
    }
    if (repeatKind.present) {
      map['repeat_kind'] = Variable<String>(
        $TasksTable.$converterrepeatKindn.toSql(repeatKind.value),
      );
    }
    if (repeatUntil.present) {
      map['repeat_until'] = Variable<String>(repeatUntil.value);
    }
    if (linkedExamId.present) {
      map['linked_exam_id'] = Variable<int>(linkedExamId.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('type: $type, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinutes: $dueMinutes, ')
          ..write('priority: $priority, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('repeatUntil: $repeatUntil, ')
          ..write('linkedExamId: $linkedExamId, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks with TableInfo<$SubtasksTable, Subtask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 240,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    title,
    isDone,
    position,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subtask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subtask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class Subtask extends DataClass implements Insertable<Subtask> {
  final int id;
  final int taskId;
  final String title;
  final bool isDone;
  final int position;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.position,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['title'] = Variable<String>(title);
    map['is_done'] = Variable<bool>(isDone);
    map['position'] = Variable<int>(position);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      title: Value(title),
      isDone: Value(isDone),
      position: Value(position),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory Subtask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtask(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      position: serializer.fromJson<int>(json['position']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'title': serializer.toJson<String>(title),
      'isDone': serializer.toJson<bool>(isDone),
      'position': serializer.toJson<int>(position),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Subtask copyWith({
    int? id,
    int? taskId,
    String? title,
    bool? isDone,
    int? position,
    String? uuid,
    int? updatedAt,
  }) => Subtask(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    position: position ?? this.position,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Subtask copyWithCompanion(SubtasksCompanion data) {
    return Subtask(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      position: data.position.present ? data.position.value : this.position,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtask(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('position: $position, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, title, isDone, position, uuid, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtask &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.isDone == this.isDone &&
          other.position == this.position &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class SubtasksCompanion extends UpdateCompanion<Subtask> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> title;
  final Value<bool> isDone;
  final Value<int> position;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.isDone = const Value.absent(),
    this.position = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubtasksCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required String title,
    this.isDone = const Value.absent(),
    this.position = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : taskId = Value(taskId),
       title = Value(title);
  static Insertable<Subtask> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? title,
    Expression<bool>? isDone,
    Expression<int>? position,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (isDone != null) 'is_done': isDone,
      if (position != null) 'position': position,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubtasksCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? title,
    Value<bool>? isDone,
    Value<int>? position,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return SubtasksCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('position: $position, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TaskRemindersTable extends TaskReminders
    with TableInfo<$TaskRemindersTable, TaskReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    offsetMinutes,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TaskRemindersTable createAlias(String alias) {
    return $TaskRemindersTable(attachedDatabase, alias);
  }
}

class TaskReminder extends DataClass implements Insertable<TaskReminder> {
  final int id;
  final int taskId;

  /// Minutes before the due moment.
  final int offsetMinutes;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const TaskReminder({
    required this.id,
    required this.taskId,
    required this.offsetMinutes,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TaskRemindersCompanion toCompanion(bool nullToAbsent) {
    return TaskRemindersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      offsetMinutes: Value(offsetMinutes),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskReminder(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TaskReminder copyWith({
    int? id,
    int? taskId,
    int? offsetMinutes,
    String? uuid,
    int? updatedAt,
  }) => TaskReminder(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskReminder copyWithCompanion(TaskRemindersCompanion data) {
    return TaskReminder(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskReminder(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, offsetMinutes, uuid, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskReminder &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.offsetMinutes == this.offsetMinutes &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class TaskRemindersCompanion extends UpdateCompanion<TaskReminder> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<int> offsetMinutes;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const TaskRemindersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TaskRemindersCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    this.offsetMinutes = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : taskId = Value(taskId);
  static Insertable<TaskReminder> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? offsetMinutes,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TaskRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<int>? offsetMinutes,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return TaskRemindersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRemindersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GradesTable extends Grades with TableInfo<$GradesTable, Grade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _examTaskIdMeta = const VerificationMeta(
    'examTaskId',
  );
  @override
  late final GeneratedColumn<int> examTaskId = GeneratedColumn<int>(
    'exam_task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxScoreMeta = const VerificationMeta(
    'maxScore',
  );
  @override
  late final GeneratedColumn<double> maxScore = GeneratedColumn<double>(
    'max_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    examTaskId,
    score,
    maxScore,
    date,
    notes,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grades';
  @override
  VerificationContext validateIntegrity(
    Insertable<Grade> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exam_task_id')) {
      context.handle(
        _examTaskIdMeta,
        examTaskId.isAcceptableOrUnknown(
          data['exam_task_id']!,
          _examTaskIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examTaskIdMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('max_score')) {
      context.handle(
        _maxScoreMeta,
        maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Grade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grade(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      examTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exam_task_id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      maxScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_score'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GradesTable createAlias(String alias) {
    return $GradesTable(attachedDatabase, alias);
  }
}

class Grade extends DataClass implements Insertable<Grade> {
  final int id;
  final int examTaskId;
  final double score;
  final double maxScore;

  /// ISO-8601 date the result was recorded.
  final String date;
  final String? notes;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const Grade({
    required this.id,
    required this.examTaskId,
    required this.score,
    required this.maxScore,
    required this.date,
    this.notes,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exam_task_id'] = Variable<int>(examTaskId);
    map['score'] = Variable<double>(score);
    map['max_score'] = Variable<double>(maxScore);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  GradesCompanion toCompanion(bool nullToAbsent) {
    return GradesCompanion(
      id: Value(id),
      examTaskId: Value(examTaskId),
      score: Value(score),
      maxScore: Value(maxScore),
      date: Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory Grade.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grade(
      id: serializer.fromJson<int>(json['id']),
      examTaskId: serializer.fromJson<int>(json['examTaskId']),
      score: serializer.fromJson<double>(json['score']),
      maxScore: serializer.fromJson<double>(json['maxScore']),
      date: serializer.fromJson<String>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'examTaskId': serializer.toJson<int>(examTaskId),
      'score': serializer.toJson<double>(score),
      'maxScore': serializer.toJson<double>(maxScore),
      'date': serializer.toJson<String>(date),
      'notes': serializer.toJson<String?>(notes),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Grade copyWith({
    int? id,
    int? examTaskId,
    double? score,
    double? maxScore,
    String? date,
    Value<String?> notes = const Value.absent(),
    String? uuid,
    int? updatedAt,
  }) => Grade(
    id: id ?? this.id,
    examTaskId: examTaskId ?? this.examTaskId,
    score: score ?? this.score,
    maxScore: maxScore ?? this.maxScore,
    date: date ?? this.date,
    notes: notes.present ? notes.value : this.notes,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Grade copyWithCompanion(GradesCompanion data) {
    return Grade(
      id: data.id.present ? data.id.value : this.id,
      examTaskId: data.examTaskId.present
          ? data.examTaskId.value
          : this.examTaskId,
      score: data.score.present ? data.score.value : this.score,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Grade(')
          ..write('id: $id, ')
          ..write('examTaskId: $examTaskId, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    examTaskId,
    score,
    maxScore,
    date,
    notes,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grade &&
          other.id == this.id &&
          other.examTaskId == this.examTaskId &&
          other.score == this.score &&
          other.maxScore == this.maxScore &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class GradesCompanion extends UpdateCompanion<Grade> {
  final Value<int> id;
  final Value<int> examTaskId;
  final Value<double> score;
  final Value<double> maxScore;
  final Value<String> date;
  final Value<String?> notes;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const GradesCompanion({
    this.id = const Value.absent(),
    this.examTaskId = const Value.absent(),
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GradesCompanion.insert({
    this.id = const Value.absent(),
    required int examTaskId,
    required double score,
    this.maxScore = const Value.absent(),
    required String date,
    this.notes = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : examTaskId = Value(examTaskId),
       score = Value(score),
       date = Value(date);
  static Insertable<Grade> custom({
    Expression<int>? id,
    Expression<int>? examTaskId,
    Expression<double>? score,
    Expression<double>? maxScore,
    Expression<String>? date,
    Expression<String>? notes,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examTaskId != null) 'exam_task_id': examTaskId,
      if (score != null) 'score': score,
      if (maxScore != null) 'max_score': maxScore,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GradesCompanion copyWith({
    Value<int>? id,
    Value<int>? examTaskId,
    Value<double>? score,
    Value<double>? maxScore,
    Value<String>? date,
    Value<String?>? notes,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return GradesCompanion(
      id: id ?? this.id,
      examTaskId: examTaskId ?? this.examTaskId,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (examTaskId.present) {
      map['exam_task_id'] = Variable<int>(examTaskId.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (maxScore.present) {
      map['max_score'] = Variable<double>(maxScore.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradesCompanion(')
          ..write('id: $id, ')
          ..write('examTaskId: $examTaskId, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PomodoroSessionsTable extends PomodoroSessions
    with TableInfo<$PomodoroSessionsTable, PomodoroSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PomodoroSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workMinutesMeta = const VerificationMeta(
    'workMinutes',
  );
  @override
  late final GeneratedColumn<int> workMinutes = GeneratedColumn<int>(
    'work_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    workMinutes,
    taskId,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pomodoro_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PomodoroSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('work_minutes')) {
      context.handle(
        _workMinutesMeta,
        workMinutes.isAcceptableOrUnknown(
          data['work_minutes']!,
          _workMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workMinutesMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PomodoroSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PomodoroSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      workMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}work_minutes'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PomodoroSessionsTable createAlias(String alias) {
    return $PomodoroSessionsTable(attachedDatabase, alias);
  }
}

class PomodoroSession extends DataClass implements Insertable<PomodoroSession> {
  final int id;
  final DateTime startedAt;
  final int workMinutes;
  final int? taskId;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const PomodoroSession({
    required this.id,
    required this.startedAt,
    required this.workMinutes,
    this.taskId,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['work_minutes'] = Variable<int>(workMinutes);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<int>(taskId);
    }
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PomodoroSessionsCompanion toCompanion(bool nullToAbsent) {
    return PomodoroSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      workMinutes: Value(workMinutes),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory PomodoroSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PomodoroSession(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      workMinutes: serializer.fromJson<int>(json['workMinutes']),
      taskId: serializer.fromJson<int?>(json['taskId']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'workMinutes': serializer.toJson<int>(workMinutes),
      'taskId': serializer.toJson<int?>(taskId),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PomodoroSession copyWith({
    int? id,
    DateTime? startedAt,
    int? workMinutes,
    Value<int?> taskId = const Value.absent(),
    String? uuid,
    int? updatedAt,
  }) => PomodoroSession(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    workMinutes: workMinutes ?? this.workMinutes,
    taskId: taskId.present ? taskId.value : this.taskId,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PomodoroSession copyWithCompanion(PomodoroSessionsCompanion data) {
    return PomodoroSession(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      workMinutes: data.workMinutes.present
          ? data.workMinutes.value
          : this.workMinutes,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSession(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('workMinutes: $workMinutes, ')
          ..write('taskId: $taskId, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startedAt, workMinutes, taskId, uuid, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PomodoroSession &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.workMinutes == this.workMinutes &&
          other.taskId == this.taskId &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class PomodoroSessionsCompanion extends UpdateCompanion<PomodoroSession> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<int> workMinutes;
  final Value<int?> taskId;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const PomodoroSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.workMinutes = const Value.absent(),
    this.taskId = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PomodoroSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    required int workMinutes,
    this.taskId = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : startedAt = Value(startedAt),
       workMinutes = Value(workMinutes);
  static Insertable<PomodoroSession> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<int>? workMinutes,
    Expression<int>? taskId,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (workMinutes != null) 'work_minutes': workMinutes,
      if (taskId != null) 'task_id': taskId,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PomodoroSessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<int>? workMinutes,
    Value<int?>? taskId,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return PomodoroSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      workMinutes: workMinutes ?? this.workMinutes,
      taskId: taskId ?? this.taskId,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (workMinutes.present) {
      map['work_minutes'] = Variable<int>(workMinutes.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('workMinutes: $workMinutes, ')
          ..write('taskId: $taskId, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $XtraEventsTable extends XtraEvents
    with TableInfo<$XtraEventsTable, XtraEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $XtraEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 240,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF30A46C),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    date,
    startMinutes,
    endMinutes,
    location,
    notes,
    colorValue,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'xtra_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<XtraEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  XtraEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return XtraEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      ),
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $XtraEventsTable createAlias(String alias) {
    return $XtraEventsTable(attachedDatabase, alias);
  }
}

class XtraEvent extends DataClass implements Insertable<XtraEvent> {
  final int id;
  final String title;

  /// ISO-8601 date string.
  final String date;
  final int? startMinutes;
  final int? endMinutes;
  final String? location;
  final String? notes;
  final int colorValue;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  final int updatedAt;
  const XtraEvent({
    required this.id,
    required this.title,
    required this.date,
    this.startMinutes,
    this.endMinutes,
    this.location,
    this.notes,
    required this.colorValue,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || startMinutes != null) {
      map['start_minutes'] = Variable<int>(startMinutes);
    }
    if (!nullToAbsent || endMinutes != null) {
      map['end_minutes'] = Variable<int>(endMinutes);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['color_value'] = Variable<int>(colorValue);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  XtraEventsCompanion toCompanion(bool nullToAbsent) {
    return XtraEventsCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      startMinutes: startMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinutes),
      endMinutes: endMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinutes),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      colorValue: Value(colorValue),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory XtraEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return XtraEvent(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<String>(json['date']),
      startMinutes: serializer.fromJson<int?>(json['startMinutes']),
      endMinutes: serializer.fromJson<int?>(json['endMinutes']),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<String>(date),
      'startMinutes': serializer.toJson<int?>(startMinutes),
      'endMinutes': serializer.toJson<int?>(endMinutes),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
      'colorValue': serializer.toJson<int>(colorValue),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  XtraEvent copyWith({
    int? id,
    String? title,
    String? date,
    Value<int?> startMinutes = const Value.absent(),
    Value<int?> endMinutes = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? colorValue,
    String? uuid,
    int? updatedAt,
  }) => XtraEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    startMinutes: startMinutes.present ? startMinutes.value : this.startMinutes,
    endMinutes: endMinutes.present ? endMinutes.value : this.endMinutes,
    location: location.present ? location.value : this.location,
    notes: notes.present ? notes.value : this.notes,
    colorValue: colorValue ?? this.colorValue,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  XtraEvent copyWithCompanion(XtraEventsCompanion data) {
    return XtraEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('XtraEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('colorValue: $colorValue, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    startMinutes,
    endMinutes,
    location,
    notes,
    colorValue,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XtraEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.date == this.date &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.location == this.location &&
          other.notes == this.notes &&
          other.colorValue == this.colorValue &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class XtraEventsCompanion extends UpdateCompanion<XtraEvent> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> date;
  final Value<int?> startMinutes;
  final Value<int?> endMinutes;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<int> colorValue;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const XtraEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  XtraEventsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String date,
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       date = Value(date);
  static Insertable<XtraEvent> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? date,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<int>? colorValue,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (colorValue != null) 'color_value': colorValue,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  XtraEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? date,
    Value<int?>? startMinutes,
    Value<int?>? endMinutes,
    Value<String?>? location,
    Value<String?>? notes,
    Value<int>? colorValue,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return XtraEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      colorValue: colorValue ?? this.colorValue,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('XtraEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('colorValue: $colorValue, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncTombstonesTable extends SyncTombstones
    with TableInfo<$SyncTombstonesTable, SyncTombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tableKeyMeta = const VerificationMeta(
    'tableKey',
  );
  @override
  late final GeneratedColumn<String> tableKey = GeneratedColumn<String>(
    'table_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [tableKey, uuid, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncTombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_key')) {
      context.handle(
        _tableKeyMeta,
        tableKey.isAcceptableOrUnknown(data['table_key']!, _tableKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_tableKeyMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tableKey, uuid};
  @override
  SyncTombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTombstone(
      tableKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_key'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $SyncTombstonesTable createAlias(String alias) {
    return $SyncTombstonesTable(attachedDatabase, alias);
  }
}

class SyncTombstone extends DataClass implements Insertable<SyncTombstone> {
  final String tableKey;
  final String uuid;
  final int deletedAt;
  const SyncTombstone({
    required this.tableKey,
    required this.uuid,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_key'] = Variable<String>(tableKey);
    map['uuid'] = Variable<String>(uuid);
    map['deleted_at'] = Variable<int>(deletedAt);
    return map;
  }

  SyncTombstonesCompanion toCompanion(bool nullToAbsent) {
    return SyncTombstonesCompanion(
      tableKey: Value(tableKey),
      uuid: Value(uuid),
      deletedAt: Value(deletedAt),
    );
  }

  factory SyncTombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTombstone(
      tableKey: serializer.fromJson<String>(json['tableKey']),
      uuid: serializer.fromJson<String>(json['uuid']),
      deletedAt: serializer.fromJson<int>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tableKey': serializer.toJson<String>(tableKey),
      'uuid': serializer.toJson<String>(uuid),
      'deletedAt': serializer.toJson<int>(deletedAt),
    };
  }

  SyncTombstone copyWith({String? tableKey, String? uuid, int? deletedAt}) =>
      SyncTombstone(
        tableKey: tableKey ?? this.tableKey,
        uuid: uuid ?? this.uuid,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  SyncTombstone copyWithCompanion(SyncTombstonesCompanion data) {
    return SyncTombstone(
      tableKey: data.tableKey.present ? data.tableKey.value : this.tableKey,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstone(')
          ..write('tableKey: $tableKey, ')
          ..write('uuid: $uuid, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tableKey, uuid, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTombstone &&
          other.tableKey == this.tableKey &&
          other.uuid == this.uuid &&
          other.deletedAt == this.deletedAt);
}

class SyncTombstonesCompanion extends UpdateCompanion<SyncTombstone> {
  final Value<String> tableKey;
  final Value<String> uuid;
  final Value<int> deletedAt;
  final Value<int> rowid;
  const SyncTombstonesCompanion({
    this.tableKey = const Value.absent(),
    this.uuid = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTombstonesCompanion.insert({
    required String tableKey,
    required String uuid,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tableKey = Value(tableKey),
       uuid = Value(uuid);
  static Insertable<SyncTombstone> custom({
    Expression<String>? tableKey,
    Expression<String>? uuid,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tableKey != null) 'table_key': tableKey,
      if (uuid != null) 'uuid': uuid,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTombstonesCompanion copyWith({
    Value<String>? tableKey,
    Value<String>? uuid,
    Value<int>? deletedAt,
    Value<int>? rowid,
  }) {
    return SyncTombstonesCompanion(
      tableKey: tableKey ?? this.tableKey,
      uuid: uuid ?? this.uuid,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tableKey.present) {
      map['table_key'] = Variable<String>(tableKey.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstonesCompanion(')
          ..write('tableKey: $tableKey, ')
          ..write('uuid: $uuid, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuCacheTable extends MenuCache
    with TableInfo<$MenuCacheTable, MenuCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    locationId,
    date,
    payload,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenuCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $MenuCacheTable createAlias(String alias) {
    return $MenuCacheTable(attachedDatabase, alias);
  }
}

class MenuCacheData extends DataClass implements Insertable<MenuCacheData> {
  final int id;
  final String providerId;
  final String locationId;
  final String date;
  final String payload;
  final int fetchedAt;
  const MenuCacheData({
    required this.id,
    required this.providerId,
    required this.locationId,
    required this.date,
    required this.payload,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['location_id'] = Variable<String>(locationId);
    map['date'] = Variable<String>(date);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  MenuCacheCompanion toCompanion(bool nullToAbsent) {
    return MenuCacheCompanion(
      id: Value(id),
      providerId: Value(providerId),
      locationId: Value(locationId),
      date: Value(date),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory MenuCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuCacheData(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      locationId: serializer.fromJson<String>(json['locationId']),
      date: serializer.fromJson<String>(json['date']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<String>(providerId),
      'locationId': serializer.toJson<String>(locationId),
      'date': serializer.toJson<String>(date),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  MenuCacheData copyWith({
    int? id,
    String? providerId,
    String? locationId,
    String? date,
    String? payload,
    int? fetchedAt,
  }) => MenuCacheData(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    locationId: locationId ?? this.locationId,
    date: date ?? this.date,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  MenuCacheData copyWithCompanion(MenuCacheCompanion data) {
    return MenuCacheData(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      date: data.date.present ? data.date.value : this.date,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuCacheData(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('locationId: $locationId, ')
          ..write('date: $date, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, providerId, locationId, date, payload, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuCacheData &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.locationId == this.locationId &&
          other.date == this.date &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt);
}

class MenuCacheCompanion extends UpdateCompanion<MenuCacheData> {
  final Value<int> id;
  final Value<String> providerId;
  final Value<String> locationId;
  final Value<String> date;
  final Value<String> payload;
  final Value<int> fetchedAt;
  const MenuCacheCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.date = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  MenuCacheCompanion.insert({
    this.id = const Value.absent(),
    required String providerId,
    required String locationId,
    required String date,
    required String payload,
    this.fetchedAt = const Value.absent(),
  }) : providerId = Value(providerId),
       locationId = Value(locationId),
       date = Value(date),
       payload = Value(payload);
  static Insertable<MenuCacheData> custom({
    Expression<int>? id,
    Expression<String>? providerId,
    Expression<String>? locationId,
    Expression<String>? date,
    Expression<String>? payload,
    Expression<int>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (locationId != null) 'location_id': locationId,
      if (date != null) 'date': date,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  MenuCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? providerId,
    Value<String>? locationId,
    Value<String>? date,
    Value<String>? payload,
    Value<int>? fetchedAt,
  }) {
    return MenuCacheCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      locationId: locationId ?? this.locationId,
      date: date ?? this.date,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuCacheCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('locationId: $locationId, ')
          ..write('date: $date, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $ClassFilesTable extends ClassFiles
    with TableInfo<$ClassFilesTable, ClassFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES classes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedPathMeta = const VerificationMeta(
    'storedPath',
  );
  @override
  late final GeneratedColumn<String> storedPath = GeneratedColumn<String>(
    'stored_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    classId,
    fileName,
    storedPath,
    sizeBytes,
    mimeType,
    createdAt,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('stored_path')) {
      context.handle(
        _storedPathMeta,
        storedPath.isAcceptableOrUnknown(data['stored_path']!, _storedPathMeta),
      );
    } else if (isInserting) {
      context.missing(_storedPathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      storedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ClassFilesTable createAlias(String alias) {
    return $ClassFilesTable(attachedDatabase, alias);
  }
}

class ClassFile extends DataClass implements Insertable<ClassFile> {
  final int id;
  final int classId;
  final String fileName;
  final String storedPath;
  final int sizeBytes;
  final String? mimeType;
  final DateTime createdAt;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins.
  final int updatedAt;
  const ClassFile({
    required this.id,
    required this.classId,
    required this.fileName,
    required this.storedPath,
    required this.sizeBytes,
    this.mimeType,
    required this.createdAt,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['class_id'] = Variable<int>(classId);
    map['file_name'] = Variable<String>(fileName);
    map['stored_path'] = Variable<String>(storedPath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ClassFilesCompanion toCompanion(bool nullToAbsent) {
    return ClassFilesCompanion(
      id: Value(id),
      classId: Value(classId),
      fileName: Value(fileName),
      storedPath: Value(storedPath),
      sizeBytes: Value(sizeBytes),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      createdAt: Value(createdAt),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClassFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassFile(
      id: serializer.fromJson<int>(json['id']),
      classId: serializer.fromJson<int>(json['classId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      storedPath: serializer.fromJson<String>(json['storedPath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'classId': serializer.toJson<int>(classId),
      'fileName': serializer.toJson<String>(fileName),
      'storedPath': serializer.toJson<String>(storedPath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'mimeType': serializer.toJson<String?>(mimeType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ClassFile copyWith({
    int? id,
    int? classId,
    String? fileName,
    String? storedPath,
    int? sizeBytes,
    Value<String?> mimeType = const Value.absent(),
    DateTime? createdAt,
    String? uuid,
    int? updatedAt,
  }) => ClassFile(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    fileName: fileName ?? this.fileName,
    storedPath: storedPath ?? this.storedPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    createdAt: createdAt ?? this.createdAt,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClassFile copyWithCompanion(ClassFilesCompanion data) {
    return ClassFile(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      storedPath: data.storedPath.present
          ? data.storedPath.value
          : this.storedPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassFile(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('fileName: $fileName, ')
          ..write('storedPath: $storedPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classId,
    fileName,
    storedPath,
    sizeBytes,
    mimeType,
    createdAt,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassFile &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.fileName == this.fileName &&
          other.storedPath == this.storedPath &&
          other.sizeBytes == this.sizeBytes &&
          other.mimeType == this.mimeType &&
          other.createdAt == this.createdAt &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class ClassFilesCompanion extends UpdateCompanion<ClassFile> {
  final Value<int> id;
  final Value<int> classId;
  final Value<String> fileName;
  final Value<String> storedPath;
  final Value<int> sizeBytes;
  final Value<String?> mimeType;
  final Value<DateTime> createdAt;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const ClassFilesCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.storedPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ClassFilesCompanion.insert({
    this.id = const Value.absent(),
    required int classId,
    required String fileName,
    required String storedPath,
    this.sizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : classId = Value(classId),
       fileName = Value(fileName),
       storedPath = Value(storedPath);
  static Insertable<ClassFile> custom({
    Expression<int>? id,
    Expression<int>? classId,
    Expression<String>? fileName,
    Expression<String>? storedPath,
    Expression<int>? sizeBytes,
    Expression<String>? mimeType,
    Expression<DateTime>? createdAt,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (fileName != null) 'file_name': fileName,
      if (storedPath != null) 'stored_path': storedPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (createdAt != null) 'created_at': createdAt,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ClassFilesCompanion copyWith({
    Value<int>? id,
    Value<int>? classId,
    Value<String>? fileName,
    Value<String>? storedPath,
    Value<int>? sizeBytes,
    Value<String?>? mimeType,
    Value<DateTime>? createdAt,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return ClassFilesCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      fileName: fileName ?? this.fileName,
      storedPath: storedPath ?? this.storedPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (storedPath.present) {
      map['stored_path'] = Variable<String>(storedPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassFilesCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('fileName: $fileName, ')
          ..write('storedPath: $storedPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $YearFilesTable extends YearFiles
    with TableInfo<$YearFilesTable, YearFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YearFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _yearIdMeta = const VerificationMeta('yearId');
  @override
  late final GeneratedColumn<int> yearId = GeneratedColumn<int>(
    'year_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES academic_years (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedPathMeta = const VerificationMeta(
    'storedPath',
  );
  @override
  late final GeneratedColumn<String> storedPath = GeneratedColumn<String>(
    'stored_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    yearId,
    fileName,
    storedPath,
    sizeBytes,
    mimeType,
    createdAt,
    uuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'year_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<YearFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year_id')) {
      context.handle(
        _yearIdMeta,
        yearId.isAcceptableOrUnknown(data['year_id']!, _yearIdMeta),
      );
    } else if (isInserting) {
      context.missing(_yearIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('stored_path')) {
      context.handle(
        _storedPathMeta,
        storedPath.isAcceptableOrUnknown(data['stored_path']!, _storedPathMeta),
      );
    } else if (isInserting) {
      context.missing(_storedPathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  YearFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YearFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      yearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      storedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $YearFilesTable createAlias(String alias) {
    return $YearFilesTable(attachedDatabase, alias);
  }
}

class YearFile extends DataClass implements Insertable<YearFile> {
  final int id;
  final int yearId;
  final String fileName;
  final String storedPath;
  final int sizeBytes;
  final String? mimeType;
  final DateTime createdAt;

  /// Stable cross-device identity for folder sync (Syncthing transport).
  final String uuid;

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins.
  final int updatedAt;
  const YearFile({
    required this.id,
    required this.yearId,
    required this.fileName,
    required this.storedPath,
    required this.sizeBytes,
    this.mimeType,
    required this.createdAt,
    required this.uuid,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year_id'] = Variable<int>(yearId);
    map['file_name'] = Variable<String>(fileName);
    map['stored_path'] = Variable<String>(storedPath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  YearFilesCompanion toCompanion(bool nullToAbsent) {
    return YearFilesCompanion(
      id: Value(id),
      yearId: Value(yearId),
      fileName: Value(fileName),
      storedPath: Value(storedPath),
      sizeBytes: Value(sizeBytes),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      createdAt: Value(createdAt),
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
    );
  }

  factory YearFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YearFile(
      id: serializer.fromJson<int>(json['id']),
      yearId: serializer.fromJson<int>(json['yearId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      storedPath: serializer.fromJson<String>(json['storedPath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'yearId': serializer.toJson<int>(yearId),
      'fileName': serializer.toJson<String>(fileName),
      'storedPath': serializer.toJson<String>(storedPath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'mimeType': serializer.toJson<String?>(mimeType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  YearFile copyWith({
    int? id,
    int? yearId,
    String? fileName,
    String? storedPath,
    int? sizeBytes,
    Value<String?> mimeType = const Value.absent(),
    DateTime? createdAt,
    String? uuid,
    int? updatedAt,
  }) => YearFile(
    id: id ?? this.id,
    yearId: yearId ?? this.yearId,
    fileName: fileName ?? this.fileName,
    storedPath: storedPath ?? this.storedPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    createdAt: createdAt ?? this.createdAt,
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  YearFile copyWithCompanion(YearFilesCompanion data) {
    return YearFile(
      id: data.id.present ? data.id.value : this.id,
      yearId: data.yearId.present ? data.yearId.value : this.yearId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      storedPath: data.storedPath.present
          ? data.storedPath.value
          : this.storedPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YearFile(')
          ..write('id: $id, ')
          ..write('yearId: $yearId, ')
          ..write('fileName: $fileName, ')
          ..write('storedPath: $storedPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    yearId,
    fileName,
    storedPath,
    sizeBytes,
    mimeType,
    createdAt,
    uuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YearFile &&
          other.id == this.id &&
          other.yearId == this.yearId &&
          other.fileName == this.fileName &&
          other.storedPath == this.storedPath &&
          other.sizeBytes == this.sizeBytes &&
          other.mimeType == this.mimeType &&
          other.createdAt == this.createdAt &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt);
}

class YearFilesCompanion extends UpdateCompanion<YearFile> {
  final Value<int> id;
  final Value<int> yearId;
  final Value<String> fileName;
  final Value<String> storedPath;
  final Value<int> sizeBytes;
  final Value<String?> mimeType;
  final Value<DateTime> createdAt;
  final Value<String> uuid;
  final Value<int> updatedAt;
  const YearFilesCompanion({
    this.id = const Value.absent(),
    this.yearId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.storedPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  YearFilesCompanion.insert({
    this.id = const Value.absent(),
    required int yearId,
    required String fileName,
    required String storedPath,
    this.sizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : yearId = Value(yearId),
       fileName = Value(fileName),
       storedPath = Value(storedPath);
  static Insertable<YearFile> custom({
    Expression<int>? id,
    Expression<int>? yearId,
    Expression<String>? fileName,
    Expression<String>? storedPath,
    Expression<int>? sizeBytes,
    Expression<String>? mimeType,
    Expression<DateTime>? createdAt,
    Expression<String>? uuid,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (yearId != null) 'year_id': yearId,
      if (fileName != null) 'file_name': fileName,
      if (storedPath != null) 'stored_path': storedPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (createdAt != null) 'created_at': createdAt,
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  YearFilesCompanion copyWith({
    Value<int>? id,
    Value<int>? yearId,
    Value<String>? fileName,
    Value<String>? storedPath,
    Value<int>? sizeBytes,
    Value<String?>? mimeType,
    Value<DateTime>? createdAt,
    Value<String>? uuid,
    Value<int>? updatedAt,
  }) {
    return YearFilesCompanion(
      id: id ?? this.id,
      yearId: yearId ?? this.yearId,
      fileName: fileName ?? this.fileName,
      storedPath: storedPath ?? this.storedPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (yearId.present) {
      map['year_id'] = Variable<int>(yearId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (storedPath.present) {
      map['stored_path'] = Variable<String>(storedPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YearFilesCompanion(')
          ..write('id: $id, ')
          ..write('yearId: $yearId, ')
          ..write('fileName: $fileName, ')
          ..write('storedPath: $storedPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AcademicYearsTable academicYears = $AcademicYearsTable(this);
  late final $ClassesTable classes = $ClassesTable(this);
  late final $ScheduleItemsTable scheduleItems = $ScheduleItemsTable(this);
  late final $ScheduleExceptionsTable scheduleExceptions =
      $ScheduleExceptionsTable(this);
  late final $HolidaysTable holidays = $HolidaysTable(this);
  late final $AbsencesTable absences = $AbsencesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $TaskRemindersTable taskReminders = $TaskRemindersTable(this);
  late final $GradesTable grades = $GradesTable(this);
  late final $PomodoroSessionsTable pomodoroSessions = $PomodoroSessionsTable(
    this,
  );
  late final $XtraEventsTable xtraEvents = $XtraEventsTable(this);
  late final $SyncTombstonesTable syncTombstones = $SyncTombstonesTable(this);
  late final $MenuCacheTable menuCache = $MenuCacheTable(this);
  late final $ClassFilesTable classFiles = $ClassFilesTable(this);
  late final $YearFilesTable yearFiles = $YearFilesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    academicYears,
    classes,
    scheduleItems,
    scheduleExceptions,
    holidays,
    absences,
    tasks,
    subtasks,
    taskReminders,
    grades,
    pomodoroSessions,
    xtraEvents,
    syncTombstones,
    menuCache,
    classFiles,
    yearFiles,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'academic_years',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('classes', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'classes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedule_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_exceptions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'classes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('absences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'classes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subtasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_reminders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('grades', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pomodoro_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'classes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('class_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'academic_years',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('year_files', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AcademicYearsTableCreateCompanionBuilder =
    AcademicYearsCompanion Function({
      Value<int> id,
      required String name,
      required String startDate,
      required String endDate,
      Value<int?> rotationLength,
      Value<String?> rotationSchoolDays,
      Value<String?> rotationLabels,
      Value<String> uuid,
      Value<int> updatedAt,
    });
typedef $$AcademicYearsTableUpdateCompanionBuilder =
    AcademicYearsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> startDate,
      Value<String> endDate,
      Value<int?> rotationLength,
      Value<String?> rotationSchoolDays,
      Value<String?> rotationLabels,
      Value<String> uuid,
      Value<int> updatedAt,
    });

final class $$AcademicYearsTableReferences
    extends BaseReferences<_$AppDatabase, $AcademicYearsTable, AcademicYear> {
  $$AcademicYearsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ClassesTable, List<ClassesData>>
  _classesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.classes,
    aliasName: 'academic_years__id__classes__year_id',
  );

  $$ClassesTableProcessedTableManager get classesRefs {
    final manager = $$ClassesTableTableManager(
      $_db,
      $_db.classes,
    ).filter((f) => f.yearId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_classesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$YearFilesTable, List<YearFile>>
  _yearFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.yearFiles,
    aliasName: 'academic_years__id__year_files__year_id',
  );

  $$YearFilesTableProcessedTableManager get yearFilesRefs {
    final manager = $$YearFilesTableTableManager(
      $_db,
      $_db.yearFiles,
    ).filter((f) => f.yearId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_yearFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AcademicYearsTableFilterComposer
    extends Composer<_$AppDatabase, $AcademicYearsTable> {
  $$AcademicYearsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rotationLength => $composableBuilder(
    column: $table.rotationLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rotationSchoolDays => $composableBuilder(
    column: $table.rotationSchoolDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rotationLabels => $composableBuilder(
    column: $table.rotationLabels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> classesRefs(
    Expression<bool> Function($$ClassesTableFilterComposer f) f,
  ) {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.yearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableFilterComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> yearFilesRefs(
    Expression<bool> Function($$YearFilesTableFilterComposer f) f,
  ) {
    final $$YearFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.yearFiles,
      getReferencedColumn: (t) => t.yearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YearFilesTableFilterComposer(
            $db: $db,
            $table: $db.yearFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AcademicYearsTableOrderingComposer
    extends Composer<_$AppDatabase, $AcademicYearsTable> {
  $$AcademicYearsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotationLength => $composableBuilder(
    column: $table.rotationLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rotationSchoolDays => $composableBuilder(
    column: $table.rotationSchoolDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rotationLabels => $composableBuilder(
    column: $table.rotationLabels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AcademicYearsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcademicYearsTable> {
  $$AcademicYearsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get rotationLength => $composableBuilder(
    column: $table.rotationLength,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rotationSchoolDays => $composableBuilder(
    column: $table.rotationSchoolDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rotationLabels => $composableBuilder(
    column: $table.rotationLabels,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> classesRefs<T extends Object>(
    Expression<T> Function($$ClassesTableAnnotationComposer a) f,
  ) {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.yearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> yearFilesRefs<T extends Object>(
    Expression<T> Function($$YearFilesTableAnnotationComposer a) f,
  ) {
    final $$YearFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.yearFiles,
      getReferencedColumn: (t) => t.yearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YearFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.yearFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AcademicYearsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AcademicYearsTable,
          AcademicYear,
          $$AcademicYearsTableFilterComposer,
          $$AcademicYearsTableOrderingComposer,
          $$AcademicYearsTableAnnotationComposer,
          $$AcademicYearsTableCreateCompanionBuilder,
          $$AcademicYearsTableUpdateCompanionBuilder,
          (AcademicYear, $$AcademicYearsTableReferences),
          AcademicYear,
          PrefetchHooks Function({bool classesRefs, bool yearFilesRefs})
        > {
  $$AcademicYearsTableTableManager(_$AppDatabase db, $AcademicYearsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcademicYearsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AcademicYearsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AcademicYearsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<int?> rotationLength = const Value.absent(),
                Value<String?> rotationSchoolDays = const Value.absent(),
                Value<String?> rotationLabels = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AcademicYearsCompanion(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                rotationLength: rotationLength,
                rotationSchoolDays: rotationSchoolDays,
                rotationLabels: rotationLabels,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String startDate,
                required String endDate,
                Value<int?> rotationLength = const Value.absent(),
                Value<String?> rotationSchoolDays = const Value.absent(),
                Value<String?> rotationLabels = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AcademicYearsCompanion.insert(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                rotationLength: rotationLength,
                rotationSchoolDays: rotationSchoolDays,
                rotationLabels: rotationLabels,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AcademicYearsTable, AcademicYear>(table),
                  $$AcademicYearsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({classesRefs = false, yearFilesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (classesRefs) db.classes,
                    if (yearFilesRefs) db.yearFiles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (classesRefs)
                        await $_getPrefetchedData<
                          AcademicYear,
                          $AcademicYearsTable,
                          ClassesData
                        >(
                          currentTable: table,
                          referencedTable: $$AcademicYearsTableReferences
                              ._classesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AcademicYearsTableReferences(
                                db,
                                table,
                                p0,
                              ).classesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.yearId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (yearFilesRefs)
                        await $_getPrefetchedData<
                          AcademicYear,
                          $AcademicYearsTable,
                          YearFile
                        >(
                          currentTable: table,
                          referencedTable: $$AcademicYearsTableReferences
                              ._yearFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AcademicYearsTableReferences(
                                db,
                                table,
                                p0,
                              ).yearFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.yearId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AcademicYearsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AcademicYearsTable,
      AcademicYear,
      $$AcademicYearsTableFilterComposer,
      $$AcademicYearsTableOrderingComposer,
      $$AcademicYearsTableAnnotationComposer,
      $$AcademicYearsTableCreateCompanionBuilder,
      $$AcademicYearsTableUpdateCompanionBuilder,
      (AcademicYear, $$AcademicYearsTableReferences),
      AcademicYear,
      PrefetchHooks Function({bool classesRefs, bool yearFilesRefs})
    >;
typedef $$ClassesTableCreateCompanionBuilder = ClassesCompanion Function({
  Value<int> id,
  required String name,
  required int colorValue,
  Value<int?> yearId,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String?> teacher,
  Value<String?> teacherEmail,
  Value<String?> room,
  Value<String?> building,
  Value<String?> module,
  Value<String?> onlineLink,
  Value<String?> notes,
  Value<int?> maxAbsences,
  Value<int?> maxAbsencesTheory,
  Value<int?> maxAbsencesPractical,
  Value<int?> reminderMinutes,
  Value<bool> active,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$ClassesTableUpdateCompanionBuilder = ClassesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> colorValue,
  Value<int?> yearId,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String?> teacher,
  Value<String?> teacherEmail,
  Value<String?> room,
  Value<String?> building,
  Value<String?> module,
  Value<String?> onlineLink,
  Value<String?> notes,
  Value<int?> maxAbsences,
  Value<int?> maxAbsencesTheory,
  Value<int?> maxAbsencesPractical,
  Value<int?> reminderMinutes,
  Value<bool> active,
  Value<String> uuid,
  Value<int> updatedAt,
});

final class $$ClassesTableReferences
    extends BaseReferences<_$AppDatabase, $ClassesTable, ClassesData> {
  $$ClassesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AcademicYearsTable _yearIdTable(_$AppDatabase db) =>
      db.academicYears.createAlias('classes__year_id__academic_years__id');

  $$AcademicYearsTableProcessedTableManager? get yearId {
    final $_column = $_itemColumn<int>('year_id');
    if ($_column == null) return null;
    final manager = $$AcademicYearsTableTableManager(
      $_db,
      $_db.academicYears,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_yearIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScheduleItemsTable, List<ScheduleItem>>
  _scheduleItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scheduleItems,
    aliasName: 'classes__id__schedule_items__class_id',
  );

  $$ScheduleItemsTableProcessedTableManager get scheduleItemsRefs {
    final manager = $$ScheduleItemsTableTableManager(
      $_db,
      $_db.scheduleItems,
    ).filter((f) => f.classId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scheduleItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AbsencesTable, List<Absence>> _absencesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.absences,
    aliasName: 'classes__id__absences__class_id',
  );

  $$AbsencesTableProcessedTableManager get absencesRefs {
    final manager = $$AbsencesTableTableManager(
      $_db,
      $_db.absences,
    ).filter((f) => f.classId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_absencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'classes__id__tasks__class_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.classId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ClassFilesTable, List<ClassFile>>
  _classFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.classFiles,
    aliasName: 'classes__id__class_files__class_id',
  );

  $$ClassFilesTableProcessedTableManager get classFilesRefs {
    final manager = $$ClassFilesTableTableManager(
      $_db,
      $_db.classFiles,
    ).filter((f) => f.classId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_classFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClassesTableFilterComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherEmail => $composableBuilder(
    column: $table.teacherEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get building => $composableBuilder(
    column: $table.building,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get onlineLink => $composableBuilder(
    column: $table.onlineLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAbsences => $composableBuilder(
    column: $table.maxAbsences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAbsencesTheory => $composableBuilder(
    column: $table.maxAbsencesTheory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAbsencesPractical => $composableBuilder(
    column: $table.maxAbsencesPractical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AcademicYearsTableFilterComposer get yearId {
    final $$AcademicYearsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.yearId,
      referencedTable: $db.academicYears,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableFilterComposer(
            $db: $db,
            $table: $db.academicYears,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scheduleItemsRefs(
    Expression<bool> Function($$ScheduleItemsTableFilterComposer f) f,
  ) {
    final $$ScheduleItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleItems,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleItemsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> absencesRefs(
    Expression<bool> Function($$AbsencesTableFilterComposer f) f,
  ) {
    final $$AbsencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.absences,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AbsencesTableFilterComposer(
            $db: $db,
            $table: $db.absences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> classFilesRefs(
    Expression<bool> Function($$ClassFilesTableFilterComposer f) f,
  ) {
    final $$ClassFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classFiles,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassFilesTableFilterComposer(
            $db: $db,
            $table: $db.classFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherEmail => $composableBuilder(
    column: $table.teacherEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get building => $composableBuilder(
    column: $table.building,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get onlineLink => $composableBuilder(
    column: $table.onlineLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAbsences => $composableBuilder(
    column: $table.maxAbsences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAbsencesTheory => $composableBuilder(
    column: $table.maxAbsencesTheory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAbsencesPractical => $composableBuilder(
    column: $table.maxAbsencesPractical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AcademicYearsTableOrderingComposer get yearId {
    final $$AcademicYearsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.yearId,
      referencedTable: $db.academicYears,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableOrderingComposer(
            $db: $db,
            $table: $db.academicYears,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<String> get teacherEmail => $composableBuilder(
    column: $table.teacherEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get building =>
      $composableBuilder(column: $table.building, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get onlineLink => $composableBuilder(
    column: $table.onlineLink,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get maxAbsences => $composableBuilder(
    column: $table.maxAbsences,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxAbsencesTheory => $composableBuilder(
    column: $table.maxAbsencesTheory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxAbsencesPractical => $composableBuilder(
    column: $table.maxAbsencesPractical,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AcademicYearsTableAnnotationComposer get yearId {
    final $$AcademicYearsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.yearId,
      referencedTable: $db.academicYears,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableAnnotationComposer(
            $db: $db,
            $table: $db.academicYears,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scheduleItemsRefs<T extends Object>(
    Expression<T> Function($$ScheduleItemsTableAnnotationComposer a) f,
  ) {
    final $$ScheduleItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleItems,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.scheduleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> absencesRefs<T extends Object>(
    Expression<T> Function($$AbsencesTableAnnotationComposer a) f,
  ) {
    final $$AbsencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.absences,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AbsencesTableAnnotationComposer(
            $db: $db,
            $table: $db.absences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> classFilesRefs<T extends Object>(
    Expression<T> Function($$ClassFilesTableAnnotationComposer a) f,
  ) {
    final $$ClassFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classFiles,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.classFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClassesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassesTable,
          ClassesData,
          $$ClassesTableFilterComposer,
          $$ClassesTableOrderingComposer,
          $$ClassesTableAnnotationComposer,
          $$ClassesTableCreateCompanionBuilder,
          $$ClassesTableUpdateCompanionBuilder,
          (ClassesData, $$ClassesTableReferences),
          ClassesData,
          PrefetchHooks Function({
            bool yearId,
            bool scheduleItemsRefs,
            bool absencesRefs,
            bool tasksRefs,
            bool classFilesRefs,
          })
        > {
  $$ClassesTableTableManager(_$AppDatabase db, $ClassesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int?> yearId = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<String?> teacherEmail = const Value.absent(),
                Value<String?> room = const Value.absent(),
                Value<String?> building = const Value.absent(),
                Value<String?> module = const Value.absent(),
                Value<String?> onlineLink = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> maxAbsences = const Value.absent(),
                Value<int?> maxAbsencesTheory = const Value.absent(),
                Value<int?> maxAbsencesPractical = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ClassesCompanion(
                id: id,
                name: name,
                colorValue: colorValue,
                yearId: yearId,
                startDate: startDate,
                endDate: endDate,
                teacher: teacher,
                teacherEmail: teacherEmail,
                room: room,
                building: building,
                module: module,
                onlineLink: onlineLink,
                notes: notes,
                maxAbsences: maxAbsences,
                maxAbsencesTheory: maxAbsencesTheory,
                maxAbsencesPractical: maxAbsencesPractical,
                reminderMinutes: reminderMinutes,
                active: active,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int colorValue,
                Value<int?> yearId = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<String?> teacherEmail = const Value.absent(),
                Value<String?> room = const Value.absent(),
                Value<String?> building = const Value.absent(),
                Value<String?> module = const Value.absent(),
                Value<String?> onlineLink = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> maxAbsences = const Value.absent(),
                Value<int?> maxAbsencesTheory = const Value.absent(),
                Value<int?> maxAbsencesPractical = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ClassesCompanion.insert(
                id: id,
                name: name,
                colorValue: colorValue,
                yearId: yearId,
                startDate: startDate,
                endDate: endDate,
                teacher: teacher,
                teacherEmail: teacherEmail,
                room: room,
                building: building,
                module: module,
                onlineLink: onlineLink,
                notes: notes,
                maxAbsences: maxAbsences,
                maxAbsencesTheory: maxAbsencesTheory,
                maxAbsencesPractical: maxAbsencesPractical,
                reminderMinutes: reminderMinutes,
                active: active,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassesTable, ClassesData>(table),
                  $$ClassesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                yearId = false,
                scheduleItemsRefs = false,
                absencesRefs = false,
                tasksRefs = false,
                classFilesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scheduleItemsRefs) db.scheduleItems,
                    if (absencesRefs) db.absences,
                    if (tasksRefs) db.tasks,
                    if (classFilesRefs) db.classFiles,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (yearId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.yearId,
                            referencedTable: $$ClassesTableReferences
                                ._yearIdTable(db),
                            referencedColumn: $$ClassesTableReferences
                                ._yearIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scheduleItemsRefs)
                        await $_getPrefetchedData<
                          ClassesData,
                          $ClassesTable,
                          ScheduleItem
                        >(
                          currentTable: table,
                          referencedTable: $$ClassesTableReferences
                              ._scheduleItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (absencesRefs)
                        await $_getPrefetchedData<
                          ClassesData,
                          $ClassesTable,
                          Absence
                        >(
                          currentTable: table,
                          referencedTable: $$ClassesTableReferences
                              ._absencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).absencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          ClassesData,
                          $ClassesTable,
                          Task
                        >(
                          currentTable: table,
                          referencedTable: $$ClassesTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassesTableReferences(db, table, p0).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (classFilesRefs)
                        await $_getPrefetchedData<
                          ClassesData,
                          $ClassesTable,
                          ClassFile
                        >(
                          currentTable: table,
                          referencedTable: $$ClassesTableReferences
                              ._classFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).classFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassesTable,
      ClassesData,
      $$ClassesTableFilterComposer,
      $$ClassesTableOrderingComposer,
      $$ClassesTableAnnotationComposer,
      $$ClassesTableCreateCompanionBuilder,
      $$ClassesTableUpdateCompanionBuilder,
      (ClassesData, $$ClassesTableReferences),
      ClassesData,
      PrefetchHooks Function({
        bool yearId,
        bool scheduleItemsRefs,
        bool absencesRefs,
        bool tasksRefs,
        bool classFilesRefs,
      })
    >;
typedef $$ScheduleItemsTableCreateCompanionBuilder =
    ScheduleItemsCompanion Function({
      Value<int> id,
      required int classId,
      required int dayOfWeek,
      required int startMinutes,
      required int endMinutes,
      Value<String?> room,
      required RotationKind rotation,
      Value<WeekParity?> weekParity,
      Value<int?> cycleLength,
      Value<String?> cycleWeeks,
      Value<String?> rotationDays,
      Value<String?> validFrom,
      Value<String?> validTo,
      Value<String> uuid,
      Value<int> updatedAt,
    });
typedef $$ScheduleItemsTableUpdateCompanionBuilder =
    ScheduleItemsCompanion Function({
      Value<int> id,
      Value<int> classId,
      Value<int> dayOfWeek,
      Value<int> startMinutes,
      Value<int> endMinutes,
      Value<String?> room,
      Value<RotationKind> rotation,
      Value<WeekParity?> weekParity,
      Value<int?> cycleLength,
      Value<String?> cycleWeeks,
      Value<String?> rotationDays,
      Value<String?> validFrom,
      Value<String?> validTo,
      Value<String> uuid,
      Value<int> updatedAt,
    });

final class $$ScheduleItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ScheduleItemsTable, ScheduleItem> {
  $$ScheduleItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClassesTable _classIdTable(_$AppDatabase db) =>
      db.classes.createAlias('schedule_items__class_id__classes__id');

  $$ClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<int>('class_id')!;

    final manager = $$ClassesTableTableManager(
      $_db,
      $_db.classes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScheduleExceptionsTable, List<ScheduleException>>
  _scheduleExceptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.scheduleExceptions,
        aliasName: 'schedule_items__id__schedule_exceptions__schedule_item_id',
      );

  $$ScheduleExceptionsTableProcessedTableManager get scheduleExceptionsRefs {
    final manager = $$ScheduleExceptionsTableTableManager(
      $_db,
      $_db.scheduleExceptions,
    ).filter((f) => f.scheduleItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduleExceptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScheduleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleItemsTable> {
  $$ScheduleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RotationKind, RotationKind, String>
  get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<WeekParity?, WeekParity, int> get weekParity =>
      $composableBuilder(
        column: $table.weekParity,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get cycleLength => $composableBuilder(
    column: $table.cycleLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleWeeks => $composableBuilder(
    column: $table.cycleWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rotationDays => $composableBuilder(
    column: $table.rotationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClassesTableFilterComposer get classId {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableFilterComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scheduleExceptionsRefs(
    Expression<bool> Function($$ScheduleExceptionsTableFilterComposer f) f,
  ) {
    final $$ScheduleExceptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleExceptions,
      getReferencedColumn: (t) => t.scheduleItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleExceptionsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleExceptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScheduleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleItemsTable> {
  $$ScheduleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekParity => $composableBuilder(
    column: $table.weekParity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleLength => $composableBuilder(
    column: $table.cycleLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleWeeks => $composableBuilder(
    column: $table.cycleWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rotationDays => $composableBuilder(
    column: $table.rotationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassesTableOrderingComposer get classId {
    final $$ClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableOrderingComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleItemsTable> {
  $$ScheduleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RotationKind, String> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WeekParity?, int> get weekParity =>
      $composableBuilder(
        column: $table.weekParity,
        builder: (column) => column,
      );

  GeneratedColumn<int> get cycleLength => $composableBuilder(
    column: $table.cycleLength,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cycleWeeks => $composableBuilder(
    column: $table.cycleWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rotationDays => $composableBuilder(
    column: $table.rotationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<String> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ClassesTableAnnotationComposer get classId {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scheduleExceptionsRefs<T extends Object>(
    Expression<T> Function($$ScheduleExceptionsTableAnnotationComposer a) f,
  ) {
    final $$ScheduleExceptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduleExceptions,
          getReferencedColumn: (t) => t.scheduleItemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleExceptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleExceptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ScheduleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleItemsTable,
          ScheduleItem,
          $$ScheduleItemsTableFilterComposer,
          $$ScheduleItemsTableOrderingComposer,
          $$ScheduleItemsTableAnnotationComposer,
          $$ScheduleItemsTableCreateCompanionBuilder,
          $$ScheduleItemsTableUpdateCompanionBuilder,
          (ScheduleItem, $$ScheduleItemsTableReferences),
          ScheduleItem,
          PrefetchHooks Function({bool classId, bool scheduleExceptionsRefs})
        > {
  $$ScheduleItemsTableTableManager(_$AppDatabase db, $ScheduleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> classId = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int> endMinutes = const Value.absent(),
                Value<String?> room = const Value.absent(),
                Value<RotationKind> rotation = const Value.absent(),
                Value<WeekParity?> weekParity = const Value.absent(),
                Value<int?> cycleLength = const Value.absent(),
                Value<String?> cycleWeeks = const Value.absent(),
                Value<String?> rotationDays = const Value.absent(),
                Value<String?> validFrom = const Value.absent(),
                Value<String?> validTo = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ScheduleItemsCompanion(
                id: id,
                classId: classId,
                dayOfWeek: dayOfWeek,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                room: room,
                rotation: rotation,
                weekParity: weekParity,
                cycleLength: cycleLength,
                cycleWeeks: cycleWeeks,
                rotationDays: rotationDays,
                validFrom: validFrom,
                validTo: validTo,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int classId,
                required int dayOfWeek,
                required int startMinutes,
                required int endMinutes,
                Value<String?> room = const Value.absent(),
                required RotationKind rotation,
                Value<WeekParity?> weekParity = const Value.absent(),
                Value<int?> cycleLength = const Value.absent(),
                Value<String?> cycleWeeks = const Value.absent(),
                Value<String?> rotationDays = const Value.absent(),
                Value<String?> validFrom = const Value.absent(),
                Value<String?> validTo = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ScheduleItemsCompanion.insert(
                id: id,
                classId: classId,
                dayOfWeek: dayOfWeek,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                room: room,
                rotation: rotation,
                weekParity: weekParity,
                cycleLength: cycleLength,
                cycleWeeks: cycleWeeks,
                rotationDays: rotationDays,
                validFrom: validFrom,
                validTo: validTo,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleItemsTable, ScheduleItem>(table),
                  $$ScheduleItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({classId = false, scheduleExceptionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scheduleExceptionsRefs) db.scheduleExceptions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (classId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.classId,
                            referencedTable: $$ScheduleItemsTableReferences
                                ._classIdTable(db),
                            referencedColumn: $$ScheduleItemsTableReferences
                                ._classIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scheduleExceptionsRefs)
                        await $_getPrefetchedData<
                          ScheduleItem,
                          $ScheduleItemsTable,
                          ScheduleException
                        >(
                          currentTable: table,
                          referencedTable: $$ScheduleItemsTableReferences
                              ._scheduleExceptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScheduleItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleExceptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scheduleItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScheduleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleItemsTable,
      ScheduleItem,
      $$ScheduleItemsTableFilterComposer,
      $$ScheduleItemsTableOrderingComposer,
      $$ScheduleItemsTableAnnotationComposer,
      $$ScheduleItemsTableCreateCompanionBuilder,
      $$ScheduleItemsTableUpdateCompanionBuilder,
      (ScheduleItem, $$ScheduleItemsTableReferences),
      ScheduleItem,
      PrefetchHooks Function({bool classId, bool scheduleExceptionsRefs})
    >;
typedef $$ScheduleExceptionsTableCreateCompanionBuilder =
    ScheduleExceptionsCompanion Function({
      Value<int> id,
      required int scheduleItemId,
      required String date,
      required ExceptionKind status,
      Value<int?> newStartMinutes,
      Value<int?> newEndMinutes,
      Value<String?> newRoom,
      Value<String> uuid,
      Value<int> updatedAt,
    });
typedef $$ScheduleExceptionsTableUpdateCompanionBuilder =
    ScheduleExceptionsCompanion Function({
      Value<int> id,
      Value<int> scheduleItemId,
      Value<String> date,
      Value<ExceptionKind> status,
      Value<int?> newStartMinutes,
      Value<int?> newEndMinutes,
      Value<String?> newRoom,
      Value<String> uuid,
      Value<int> updatedAt,
    });

final class $$ScheduleExceptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ScheduleExceptionsTable,
          ScheduleException
        > {
  $$ScheduleExceptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScheduleItemsTable _scheduleItemIdTable(_$AppDatabase db) => db
      .scheduleItems
      .createAlias('schedule_exceptions__schedule_item_id__schedule_items__id');

  $$ScheduleItemsTableProcessedTableManager get scheduleItemId {
    final $_column = $_itemColumn<int>('schedule_item_id')!;

    final manager = $$ScheduleItemsTableTableManager(
      $_db,
      $_db.scheduleItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScheduleExceptionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleExceptionsTable> {
  $$ScheduleExceptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExceptionKind, ExceptionKind, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get newStartMinutes => $composableBuilder(
    column: $table.newStartMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newEndMinutes => $composableBuilder(
    column: $table.newEndMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newRoom => $composableBuilder(
    column: $table.newRoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScheduleItemsTableFilterComposer get scheduleItemId {
    final $$ScheduleItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleItemId,
      referencedTable: $db.scheduleItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleItemsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleExceptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleExceptionsTable> {
  $$ScheduleExceptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newStartMinutes => $composableBuilder(
    column: $table.newStartMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newEndMinutes => $composableBuilder(
    column: $table.newEndMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newRoom => $composableBuilder(
    column: $table.newRoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScheduleItemsTableOrderingComposer get scheduleItemId {
    final $$ScheduleItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleItemId,
      referencedTable: $db.scheduleItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleItemsTableOrderingComposer(
            $db: $db,
            $table: $db.scheduleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleExceptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleExceptionsTable> {
  $$ScheduleExceptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExceptionKind, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get newStartMinutes => $composableBuilder(
    column: $table.newStartMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newEndMinutes => $composableBuilder(
    column: $table.newEndMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get newRoom =>
      $composableBuilder(column: $table.newRoom, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ScheduleItemsTableAnnotationComposer get scheduleItemId {
    final $$ScheduleItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleItemId,
      referencedTable: $db.scheduleItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.scheduleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleExceptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleExceptionsTable,
          ScheduleException,
          $$ScheduleExceptionsTableFilterComposer,
          $$ScheduleExceptionsTableOrderingComposer,
          $$ScheduleExceptionsTableAnnotationComposer,
          $$ScheduleExceptionsTableCreateCompanionBuilder,
          $$ScheduleExceptionsTableUpdateCompanionBuilder,
          (ScheduleException, $$ScheduleExceptionsTableReferences),
          ScheduleException,
          PrefetchHooks Function({bool scheduleItemId})
        > {
  $$ScheduleExceptionsTableTableManager(
    _$AppDatabase db,
    $ScheduleExceptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleExceptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleExceptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleExceptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scheduleItemId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<ExceptionKind> status = const Value.absent(),
                Value<int?> newStartMinutes = const Value.absent(),
                Value<int?> newEndMinutes = const Value.absent(),
                Value<String?> newRoom = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ScheduleExceptionsCompanion(
                id: id,
                scheduleItemId: scheduleItemId,
                date: date,
                status: status,
                newStartMinutes: newStartMinutes,
                newEndMinutes: newEndMinutes,
                newRoom: newRoom,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scheduleItemId,
                required String date,
                required ExceptionKind status,
                Value<int?> newStartMinutes = const Value.absent(),
                Value<int?> newEndMinutes = const Value.absent(),
                Value<String?> newRoom = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ScheduleExceptionsCompanion.insert(
                id: id,
                scheduleItemId: scheduleItemId,
                date: date,
                status: status,
                newStartMinutes: newStartMinutes,
                newEndMinutes: newEndMinutes,
                newRoom: newRoom,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleExceptionsTable, ScheduleException>(
                    table,
                  ),
                  $$ScheduleExceptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scheduleItemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scheduleItemId,
                        referencedTable: $$ScheduleExceptionsTableReferences
                            ._scheduleItemIdTable(db),
                        referencedColumn: $$ScheduleExceptionsTableReferences
                            ._scheduleItemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScheduleExceptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleExceptionsTable,
      ScheduleException,
      $$ScheduleExceptionsTableFilterComposer,
      $$ScheduleExceptionsTableOrderingComposer,
      $$ScheduleExceptionsTableAnnotationComposer,
      $$ScheduleExceptionsTableCreateCompanionBuilder,
      $$ScheduleExceptionsTableUpdateCompanionBuilder,
      (ScheduleException, $$ScheduleExceptionsTableReferences),
      ScheduleException,
      PrefetchHooks Function({bool scheduleItemId})
    >;
typedef $$HolidaysTableCreateCompanionBuilder = HolidaysCompanion Function({
  Value<int> id,
  required String name,
  required String startDate,
  required String endDate,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$HolidaysTableUpdateCompanionBuilder = HolidaysCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> startDate,
  Value<String> endDate,
  Value<String> uuid,
  Value<int> updatedAt,
});

class $$HolidaysTableFilterComposer
    extends Composer<_$AppDatabase, $HolidaysTable> {
  $$HolidaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HolidaysTableOrderingComposer
    extends Composer<_$AppDatabase, $HolidaysTable> {
  $$HolidaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HolidaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $HolidaysTable> {
  $$HolidaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HolidaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HolidaysTable,
          Holiday,
          $$HolidaysTableFilterComposer,
          $$HolidaysTableOrderingComposer,
          $$HolidaysTableAnnotationComposer,
          $$HolidaysTableCreateCompanionBuilder,
          $$HolidaysTableUpdateCompanionBuilder,
          (Holiday, BaseReferences<_$AppDatabase, $HolidaysTable, Holiday>),
          Holiday,
          PrefetchHooks Function()
        > {
  $$HolidaysTableTableManager(_$AppDatabase db, $HolidaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HolidaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HolidaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HolidaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => HolidaysCompanion(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String startDate,
                required String endDate,
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => HolidaysCompanion.insert(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HolidaysTable, Holiday>(table),
                  BaseReferences<_$AppDatabase, $HolidaysTable, Holiday>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HolidaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HolidaysTable,
      Holiday,
      $$HolidaysTableFilterComposer,
      $$HolidaysTableOrderingComposer,
      $$HolidaysTableAnnotationComposer,
      $$HolidaysTableCreateCompanionBuilder,
      $$HolidaysTableUpdateCompanionBuilder,
      (Holiday, BaseReferences<_$AppDatabase, $HolidaysTable, Holiday>),
      Holiday,
      PrefetchHooks Function()
    >;
typedef $$AbsencesTableCreateCompanionBuilder = AbsencesCompanion Function({
  Value<int> id,
  required int classId,
  required String date,
  required int startMinutes,
  required int endMinutes,
  Value<String?> reason,
  Value<bool> isExcused,
  Value<AbsenceKind?> kind,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$AbsencesTableUpdateCompanionBuilder = AbsencesCompanion Function({
  Value<int> id,
  Value<int> classId,
  Value<String> date,
  Value<int> startMinutes,
  Value<int> endMinutes,
  Value<String?> reason,
  Value<bool> isExcused,
  Value<AbsenceKind?> kind,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<String> uuid,
  Value<int> updatedAt,
});

final class $$AbsencesTableReferences
    extends BaseReferences<_$AppDatabase, $AbsencesTable, Absence> {
  $$AbsencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClassesTable _classIdTable(_$AppDatabase db) =>
      db.classes.createAlias('absences__class_id__classes__id');

  $$ClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<int>('class_id')!;

    final manager = $$ClassesTableTableManager(
      $_db,
      $_db.classes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AbsencesTableFilterComposer
    extends Composer<_$AppDatabase, $AbsencesTable> {
  $$AbsencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExcused => $composableBuilder(
    column: $table.isExcused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AbsenceKind?, AbsenceKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClassesTableFilterComposer get classId {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableFilterComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AbsencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AbsencesTable> {
  $$AbsencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExcused => $composableBuilder(
    column: $table.isExcused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassesTableOrderingComposer get classId {
    final $$ClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableOrderingComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AbsencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AbsencesTable> {
  $$AbsencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get isExcused =>
      $composableBuilder(column: $table.isExcused, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AbsenceKind?, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ClassesTableAnnotationComposer get classId {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AbsencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AbsencesTable,
          Absence,
          $$AbsencesTableFilterComposer,
          $$AbsencesTableOrderingComposer,
          $$AbsencesTableAnnotationComposer,
          $$AbsencesTableCreateCompanionBuilder,
          $$AbsencesTableUpdateCompanionBuilder,
          (Absence, $$AbsencesTableReferences),
          Absence,
          PrefetchHooks Function({bool classId})
        > {
  $$AbsencesTableTableManager(_$AppDatabase db, $AbsencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbsencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbsencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbsencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> classId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int> endMinutes = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<bool> isExcused = const Value.absent(),
                Value<AbsenceKind?> kind = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AbsencesCompanion(
                id: id,
                classId: classId,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                reason: reason,
                isExcused: isExcused,
                kind: kind,
                notes: notes,
                createdAt: createdAt,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int classId,
                required String date,
                required int startMinutes,
                required int endMinutes,
                Value<String?> reason = const Value.absent(),
                Value<bool> isExcused = const Value.absent(),
                Value<AbsenceKind?> kind = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AbsencesCompanion.insert(
                id: id,
                classId: classId,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                reason: reason,
                isExcused: isExcused,
                kind: kind,
                notes: notes,
                createdAt: createdAt,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AbsencesTable, Absence>(table),
                  $$AbsencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (classId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.classId,
                        referencedTable: $$AbsencesTableReferences
                            ._classIdTable(db),
                        referencedColumn: $$AbsencesTableReferences
                            ._classIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AbsencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AbsencesTable,
      Absence,
      $$AbsencesTableFilterComposer,
      $$AbsencesTableOrderingComposer,
      $$AbsencesTableAnnotationComposer,
      $$AbsencesTableCreateCompanionBuilder,
      $$AbsencesTableUpdateCompanionBuilder,
      (Absence, $$AbsencesTableReferences),
      Absence,
      PrefetchHooks Function({bool classId})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int?> classId,
  required String title,
  Value<String?> notes,
  Value<TaskKind> type,
  Value<String?> dueDate,
  Value<int?> dueMinutes,
  Value<TaskPriority> priority,
  Value<bool> isDone,
  Value<DateTime?> doneAt,
  Value<DateTime> createdAt,
  Value<int?> progressPercent,
  Value<RepeatKind?> repeatKind,
  Value<String?> repeatUntil,
  Value<int?> linkedExamId,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int?> classId,
  Value<String> title,
  Value<String?> notes,
  Value<TaskKind> type,
  Value<String?> dueDate,
  Value<int?> dueMinutes,
  Value<TaskPriority> priority,
  Value<bool> isDone,
  Value<DateTime?> doneAt,
  Value<DateTime> createdAt,
  Value<int?> progressPercent,
  Value<RepeatKind?> repeatKind,
  Value<String?> repeatUntil,
  Value<int?> linkedExamId,
  Value<String> uuid,
  Value<int> updatedAt,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClassesTable _classIdTable(_$AppDatabase db) =>
      db.classes.createAlias('tasks__class_id__classes__id');

  $$ClassesTableProcessedTableManager? get classId {
    final $_column = $_itemColumn<int>('class_id');
    if ($_column == null) return null;
    final manager = $$ClassesTableTableManager(
      $_db,
      $_db.classes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _linkedExamIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('tasks__linked_exam_id__tasks__id');

  $$TasksTableProcessedTableManager? get linkedExamId {
    final $_column = $_itemColumn<int>('linked_exam_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkedExamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SubtasksTable, List<Subtask>> _subtasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.subtasks,
    aliasName: 'tasks__id__subtasks__task_id',
  );

  $$SubtasksTableProcessedTableManager get subtasksRefs {
    final manager = $$SubtasksTableTableManager(
      $_db,
      $_db.subtasks,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subtasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskRemindersTable, List<TaskReminder>>
  _taskRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskReminders,
    aliasName: 'tasks__id__task_reminders__task_id',
  );

  $$TaskRemindersTableProcessedTableManager get taskRemindersRefs {
    final manager = $$TaskRemindersTableTableManager(
      $_db,
      $_db.taskReminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRemindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GradesTable, List<Grade>> _gradesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.grades,
    aliasName: 'tasks__id__grades__exam_task_id',
  );

  $$GradesTableProcessedTableManager get gradesRefs {
    final manager = $$GradesTableTableManager(
      $_db,
      $_db.grades,
    ).filter((f) => f.examTaskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gradesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PomodoroSessionsTable, List<PomodoroSession>>
  _pomodoroSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pomodoroSessions,
    aliasName: 'tasks__id__pomodoro_sessions__task_id',
  );

  $$PomodoroSessionsTableProcessedTableManager get pomodoroSessionsRefs {
    final manager = $$PomodoroSessionsTableTableManager(
      $_db,
      $_db.pomodoroSessions,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pomodoroSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskKind, TaskKind, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueMinutes => $composableBuilder(
    column: $table.dueMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskPriority, TaskPriority, int>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RepeatKind?, RepeatKind, String>
  get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get repeatUntil => $composableBuilder(
    column: $table.repeatUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClassesTableFilterComposer get classId {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableFilterComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get linkedExamId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedExamId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> subtasksRefs(
    Expression<bool> Function($$SubtasksTableFilterComposer f) f,
  ) {
    final $$SubtasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableFilterComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskRemindersRefs(
    Expression<bool> Function($$TaskRemindersTableFilterComposer f) f,
  ) {
    final $$TaskRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableFilterComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gradesRefs(
    Expression<bool> Function($$GradesTableFilterComposer f) f,
  ) {
    final $$GradesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grades,
      getReferencedColumn: (t) => t.examTaskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GradesTableFilterComposer(
            $db: $db,
            $table: $db.grades,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pomodoroSessionsRefs(
    Expression<bool> Function($$PomodoroSessionsTableFilterComposer f) f,
  ) {
    final $$PomodoroSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pomodoroSessions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PomodoroSessionsTableFilterComposer(
            $db: $db,
            $table: $db.pomodoroSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueMinutes => $composableBuilder(
    column: $table.dueMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatUntil => $composableBuilder(
    column: $table.repeatUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassesTableOrderingComposer get classId {
    final $$ClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableOrderingComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get linkedExamId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedExamId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueMinutes => $composableBuilder(
    column: $table.dueMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskPriority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RepeatKind?, String> get repeatKind =>
      $composableBuilder(
        column: $table.repeatKind,
        builder: (column) => column,
      );

  GeneratedColumn<String> get repeatUntil => $composableBuilder(
    column: $table.repeatUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ClassesTableAnnotationComposer get classId {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get linkedExamId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedExamId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> subtasksRefs<T extends Object>(
    Expression<T> Function($$SubtasksTableAnnotationComposer a) f,
  ) {
    final $$SubtasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableAnnotationComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskRemindersRefs<T extends Object>(
    Expression<T> Function($$TaskRemindersTableAnnotationComposer a) f,
  ) {
    final $$TaskRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gradesRefs<T extends Object>(
    Expression<T> Function($$GradesTableAnnotationComposer a) f,
  ) {
    final $$GradesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grades,
      getReferencedColumn: (t) => t.examTaskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GradesTableAnnotationComposer(
            $db: $db,
            $table: $db.grades,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pomodoroSessionsRefs<T extends Object>(
    Expression<T> Function($$PomodoroSessionsTableAnnotationComposer a) f,
  ) {
    final $$PomodoroSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pomodoroSessions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PomodoroSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.pomodoroSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool classId,
            bool linkedExamId,
            bool subtasksRefs,
            bool taskRemindersRefs,
            bool gradesRefs,
            bool pomodoroSessionsRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> classId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<TaskKind> type = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> dueMinutes = const Value.absent(),
                Value<TaskPriority> priority = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> progressPercent = const Value.absent(),
                Value<RepeatKind?> repeatKind = const Value.absent(),
                Value<String?> repeatUntil = const Value.absent(),
                Value<int?> linkedExamId = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                classId: classId,
                title: title,
                notes: notes,
                type: type,
                dueDate: dueDate,
                dueMinutes: dueMinutes,
                priority: priority,
                isDone: isDone,
                doneAt: doneAt,
                createdAt: createdAt,
                progressPercent: progressPercent,
                repeatKind: repeatKind,
                repeatUntil: repeatUntil,
                linkedExamId: linkedExamId,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> classId = const Value.absent(),
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<TaskKind> type = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> dueMinutes = const Value.absent(),
                Value<TaskPriority> priority = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> progressPercent = const Value.absent(),
                Value<RepeatKind?> repeatKind = const Value.absent(),
                Value<String?> repeatUntil = const Value.absent(),
                Value<int?> linkedExamId = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                classId: classId,
                title: title,
                notes: notes,
                type: type,
                dueDate: dueDate,
                dueMinutes: dueMinutes,
                priority: priority,
                isDone: isDone,
                doneAt: doneAt,
                createdAt: createdAt,
                progressPercent: progressPercent,
                repeatKind: repeatKind,
                repeatUntil: repeatUntil,
                linkedExamId: linkedExamId,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                classId = false,
                linkedExamId = false,
                subtasksRefs = false,
                taskRemindersRefs = false,
                gradesRefs = false,
                pomodoroSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subtasksRefs) db.subtasks,
                    if (taskRemindersRefs) db.taskReminders,
                    if (gradesRefs) db.grades,
                    if (pomodoroSessionsRefs) db.pomodoroSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (classId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.classId,
                            referencedTable: $$TasksTableReferences
                                ._classIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._classIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (linkedExamId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.linkedExamId,
                            referencedTable: $$TasksTableReferences
                                ._linkedExamIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._linkedExamIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subtasksRefs)
                        await $_getPrefetchedData<Task, $TasksTable, Subtask>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._subtasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).subtasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskRemindersRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskReminder
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gradesRefs)
                        await $_getPrefetchedData<Task, $TasksTable, Grade>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._gradesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(db, table, p0).gradesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examTaskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pomodoroSessionsRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          PomodoroSession
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._pomodoroSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).pomodoroSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool classId,
        bool linkedExamId,
        bool subtasksRefs,
        bool taskRemindersRefs,
        bool gradesRefs,
        bool pomodoroSessionsRefs,
      })
    >;
typedef $$SubtasksTableCreateCompanionBuilder = SubtasksCompanion Function({
  Value<int> id,
  required int taskId,
  required String title,
  Value<bool> isDone,
  Value<int> position,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$SubtasksTableUpdateCompanionBuilder = SubtasksCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<String> title,
  Value<bool> isDone,
  Value<int> position,
  Value<String> uuid,
  Value<int> updatedAt,
});

final class $$SubtasksTableReferences
    extends BaseReferences<_$AppDatabase, $SubtasksTable, Subtask> {
  $$SubtasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('subtasks__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubtasksTable,
          Subtask,
          $$SubtasksTableFilterComposer,
          $$SubtasksTableOrderingComposer,
          $$SubtasksTableAnnotationComposer,
          $$SubtasksTableCreateCompanionBuilder,
          $$SubtasksTableUpdateCompanionBuilder,
          (Subtask, $$SubtasksTableReferences),
          Subtask,
          PrefetchHooks Function({bool taskId})
        > {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => SubtasksCompanion(
                id: id,
                taskId: taskId,
                title: title,
                isDone: isDone,
                position: position,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required String title,
                Value<bool> isDone = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => SubtasksCompanion.insert(
                id: id,
                taskId: taskId,
                title: title,
                isDone: isDone,
                position: position,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubtasksTable, Subtask>(table),
                  $$SubtasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$SubtasksTableReferences._taskIdTable(
                          db,
                        ),
                        referencedColumn: $$SubtasksTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubtasksTable,
      Subtask,
      $$SubtasksTableFilterComposer,
      $$SubtasksTableOrderingComposer,
      $$SubtasksTableAnnotationComposer,
      $$SubtasksTableCreateCompanionBuilder,
      $$SubtasksTableUpdateCompanionBuilder,
      (Subtask, $$SubtasksTableReferences),
      Subtask,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskRemindersTableCreateCompanionBuilder =
    TaskRemindersCompanion Function({
      Value<int> id,
      required int taskId,
      Value<int> offsetMinutes,
      Value<String> uuid,
      Value<int> updatedAt,
    });
typedef $$TaskRemindersTableUpdateCompanionBuilder =
    TaskRemindersCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<int> offsetMinutes,
      Value<String> uuid,
      Value<int> updatedAt,
    });

final class $$TaskRemindersTableReferences
    extends BaseReferences<_$AppDatabase, $TaskRemindersTable, TaskReminder> {
  $$TaskRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRemindersTable,
          TaskReminder,
          $$TaskRemindersTableFilterComposer,
          $$TaskRemindersTableOrderingComposer,
          $$TaskRemindersTableAnnotationComposer,
          $$TaskRemindersTableCreateCompanionBuilder,
          $$TaskRemindersTableUpdateCompanionBuilder,
          (TaskReminder, $$TaskRemindersTableReferences),
          TaskReminder,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRemindersTableTableManager(_$AppDatabase db, $TaskRemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TaskRemindersCompanion(
                id: id,
                taskId: taskId,
                offsetMinutes: offsetMinutes,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                Value<int> offsetMinutes = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TaskRemindersCompanion.insert(
                id: id,
                taskId: taskId,
                offsetMinutes: offsetMinutes,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskRemindersTable, TaskReminder>(table),
                  $$TaskRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskRemindersTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$TaskRemindersTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRemindersTable,
      TaskReminder,
      $$TaskRemindersTableFilterComposer,
      $$TaskRemindersTableOrderingComposer,
      $$TaskRemindersTableAnnotationComposer,
      $$TaskRemindersTableCreateCompanionBuilder,
      $$TaskRemindersTableUpdateCompanionBuilder,
      (TaskReminder, $$TaskRemindersTableReferences),
      TaskReminder,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$GradesTableCreateCompanionBuilder = GradesCompanion Function({
  Value<int> id,
  required int examTaskId,
  required double score,
  Value<double> maxScore,
  required String date,
  Value<String?> notes,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$GradesTableUpdateCompanionBuilder = GradesCompanion Function({
  Value<int> id,
  Value<int> examTaskId,
  Value<double> score,
  Value<double> maxScore,
  Value<String> date,
  Value<String?> notes,
  Value<String> uuid,
  Value<int> updatedAt,
});

final class $$GradesTableReferences
    extends BaseReferences<_$AppDatabase, $GradesTable, Grade> {
  $$GradesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _examTaskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('grades__exam_task_id__tasks__id');

  $$TasksTableProcessedTableManager get examTaskId {
    final $_column = $_itemColumn<int>('exam_task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examTaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GradesTableFilterComposer
    extends Composer<_$AppDatabase, $GradesTable> {
  $$GradesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get examTaskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradesTableOrderingComposer
    extends Composer<_$AppDatabase, $GradesTable> {
  $$GradesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get examTaskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradesTable> {
  $$GradesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get examTaskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GradesTable,
          Grade,
          $$GradesTableFilterComposer,
          $$GradesTableOrderingComposer,
          $$GradesTableAnnotationComposer,
          $$GradesTableCreateCompanionBuilder,
          $$GradesTableUpdateCompanionBuilder,
          (Grade, $$GradesTableReferences),
          Grade,
          PrefetchHooks Function({bool examTaskId})
        > {
  $$GradesTableTableManager(_$AppDatabase db, $GradesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> examTaskId = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> maxScore = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => GradesCompanion(
                id: id,
                examTaskId: examTaskId,
                score: score,
                maxScore: maxScore,
                date: date,
                notes: notes,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int examTaskId,
                required double score,
                Value<double> maxScore = const Value.absent(),
                required String date,
                Value<String?> notes = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => GradesCompanion.insert(
                id: id,
                examTaskId: examTaskId,
                score: score,
                maxScore: maxScore,
                date: date,
                notes: notes,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GradesTable, Grade>(table),
                  $$GradesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examTaskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (examTaskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.examTaskId,
                        referencedTable: $$GradesTableReferences
                            ._examTaskIdTable(db),
                        referencedColumn: $$GradesTableReferences
                            ._examTaskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GradesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GradesTable,
      Grade,
      $$GradesTableFilterComposer,
      $$GradesTableOrderingComposer,
      $$GradesTableAnnotationComposer,
      $$GradesTableCreateCompanionBuilder,
      $$GradesTableUpdateCompanionBuilder,
      (Grade, $$GradesTableReferences),
      Grade,
      PrefetchHooks Function({bool examTaskId})
    >;
typedef $$PomodoroSessionsTableCreateCompanionBuilder =
    PomodoroSessionsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      required int workMinutes,
      Value<int?> taskId,
      Value<String> uuid,
      Value<int> updatedAt,
    });
typedef $$PomodoroSessionsTableUpdateCompanionBuilder =
    PomodoroSessionsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<int> workMinutes,
      Value<int?> taskId,
      Value<String> uuid,
      Value<int> updatedAt,
    });

final class $$PomodoroSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PomodoroSessionsTable, PomodoroSession> {
  $$PomodoroSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('pomodoro_sessions__task_id__tasks__id');

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<int>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PomodoroSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTable> {
  $$PomodoroSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workMinutes => $composableBuilder(
    column: $table.workMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PomodoroSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTable> {
  $$PomodoroSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workMinutes => $composableBuilder(
    column: $table.workMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PomodoroSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTable> {
  $$PomodoroSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get workMinutes => $composableBuilder(
    column: $table.workMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PomodoroSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PomodoroSessionsTable,
          PomodoroSession,
          $$PomodoroSessionsTableFilterComposer,
          $$PomodoroSessionsTableOrderingComposer,
          $$PomodoroSessionsTableAnnotationComposer,
          $$PomodoroSessionsTableCreateCompanionBuilder,
          $$PomodoroSessionsTableUpdateCompanionBuilder,
          (PomodoroSession, $$PomodoroSessionsTableReferences),
          PomodoroSession,
          PrefetchHooks Function({bool taskId})
        > {
  $$PomodoroSessionsTableTableManager(
    _$AppDatabase db,
    $PomodoroSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PomodoroSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PomodoroSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PomodoroSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> workMinutes = const Value.absent(),
                Value<int?> taskId = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PomodoroSessionsCompanion(
                id: id,
                startedAt: startedAt,
                workMinutes: workMinutes,
                taskId: taskId,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                required int workMinutes,
                Value<int?> taskId = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PomodoroSessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                workMinutes: workMinutes,
                taskId: taskId,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PomodoroSessionsTable, PomodoroSession>(table),
                  $$PomodoroSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$PomodoroSessionsTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$PomodoroSessionsTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PomodoroSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PomodoroSessionsTable,
      PomodoroSession,
      $$PomodoroSessionsTableFilterComposer,
      $$PomodoroSessionsTableOrderingComposer,
      $$PomodoroSessionsTableAnnotationComposer,
      $$PomodoroSessionsTableCreateCompanionBuilder,
      $$PomodoroSessionsTableUpdateCompanionBuilder,
      (PomodoroSession, $$PomodoroSessionsTableReferences),
      PomodoroSession,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$XtraEventsTableCreateCompanionBuilder = XtraEventsCompanion Function({
  Value<int> id,
  required String title,
  required String date,
  Value<int?> startMinutes,
  Value<int?> endMinutes,
  Value<String?> location,
  Value<String?> notes,
  Value<int> colorValue,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$XtraEventsTableUpdateCompanionBuilder = XtraEventsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> date,
  Value<int?> startMinutes,
  Value<int?> endMinutes,
  Value<String?> location,
  Value<String?> notes,
  Value<int> colorValue,
  Value<String> uuid,
  Value<int> updatedAt,
});

class $$XtraEventsTableFilterComposer
    extends Composer<_$AppDatabase, $XtraEventsTable> {
  $$XtraEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$XtraEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $XtraEventsTable> {
  $$XtraEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$XtraEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $XtraEventsTable> {
  $$XtraEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$XtraEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $XtraEventsTable,
          XtraEvent,
          $$XtraEventsTableFilterComposer,
          $$XtraEventsTableOrderingComposer,
          $$XtraEventsTableAnnotationComposer,
          $$XtraEventsTableCreateCompanionBuilder,
          $$XtraEventsTableUpdateCompanionBuilder,
          (
            XtraEvent,
            BaseReferences<_$AppDatabase, $XtraEventsTable, XtraEvent>,
          ),
          XtraEvent,
          PrefetchHooks Function()
        > {
  $$XtraEventsTableTableManager(_$AppDatabase db, $XtraEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$XtraEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$XtraEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$XtraEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int?> startMinutes = const Value.absent(),
                Value<int?> endMinutes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => XtraEventsCompanion(
                id: id,
                title: title,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
                notes: notes,
                colorValue: colorValue,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String date,
                Value<int?> startMinutes = const Value.absent(),
                Value<int?> endMinutes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => XtraEventsCompanion.insert(
                id: id,
                title: title,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
                notes: notes,
                colorValue: colorValue,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$XtraEventsTable, XtraEvent>(table),
                  BaseReferences<_$AppDatabase, $XtraEventsTable, XtraEvent>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$XtraEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $XtraEventsTable,
      XtraEvent,
      $$XtraEventsTableFilterComposer,
      $$XtraEventsTableOrderingComposer,
      $$XtraEventsTableAnnotationComposer,
      $$XtraEventsTableCreateCompanionBuilder,
      $$XtraEventsTableUpdateCompanionBuilder,
      (XtraEvent, BaseReferences<_$AppDatabase, $XtraEventsTable, XtraEvent>),
      XtraEvent,
      PrefetchHooks Function()
    >;
typedef $$SyncTombstonesTableCreateCompanionBuilder =
    SyncTombstonesCompanion Function({
      required String tableKey,
      required String uuid,
      Value<int> deletedAt,
      Value<int> rowid,
    });
typedef $$SyncTombstonesTableUpdateCompanionBuilder =
    SyncTombstonesCompanion Function({
      Value<String> tableKey,
      Value<String> uuid,
      Value<int> deletedAt,
      Value<int> rowid,
    });

class $$SyncTombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tableKey => $composableBuilder(
    column: $table.tableKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncTombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tableKey => $composableBuilder(
    column: $table.tableKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncTombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tableKey =>
      $composableBuilder(column: $table.tableKey, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SyncTombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncTombstonesTable,
          SyncTombstone,
          $$SyncTombstonesTableFilterComposer,
          $$SyncTombstonesTableOrderingComposer,
          $$SyncTombstonesTableAnnotationComposer,
          $$SyncTombstonesTableCreateCompanionBuilder,
          $$SyncTombstonesTableUpdateCompanionBuilder,
          (
            SyncTombstone,
            BaseReferences<_$AppDatabase, $SyncTombstonesTable, SyncTombstone>,
          ),
          SyncTombstone,
          PrefetchHooks Function()
        > {
  $$SyncTombstonesTableTableManager(
    _$AppDatabase db,
    $SyncTombstonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tableKey = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion(
                tableKey: tableKey,
                uuid: uuid,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tableKey,
                required String uuid,
                Value<int> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion.insert(
                tableKey: tableKey,
                uuid: uuid,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncTombstonesTable, SyncTombstone>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncTombstonesTable,
                    SyncTombstone
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncTombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncTombstonesTable,
      SyncTombstone,
      $$SyncTombstonesTableFilterComposer,
      $$SyncTombstonesTableOrderingComposer,
      $$SyncTombstonesTableAnnotationComposer,
      $$SyncTombstonesTableCreateCompanionBuilder,
      $$SyncTombstonesTableUpdateCompanionBuilder,
      (
        SyncTombstone,
        BaseReferences<_$AppDatabase, $SyncTombstonesTable, SyncTombstone>,
      ),
      SyncTombstone,
      PrefetchHooks Function()
    >;
typedef $$MenuCacheTableCreateCompanionBuilder = MenuCacheCompanion Function({
  Value<int> id,
  required String providerId,
  required String locationId,
  required String date,
  required String payload,
  Value<int> fetchedAt,
});
typedef $$MenuCacheTableUpdateCompanionBuilder = MenuCacheCompanion Function({
  Value<int> id,
  Value<String> providerId,
  Value<String> locationId,
  Value<String> date,
  Value<String> payload,
  Value<int> fetchedAt,
});

class $$MenuCacheTableFilterComposer
    extends Composer<_$AppDatabase, $MenuCacheTable> {
  $$MenuCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuCacheTable> {
  $$MenuCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuCacheTable> {
  $$MenuCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$MenuCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuCacheTable,
          MenuCacheData,
          $$MenuCacheTableFilterComposer,
          $$MenuCacheTableOrderingComposer,
          $$MenuCacheTableAnnotationComposer,
          $$MenuCacheTableCreateCompanionBuilder,
          $$MenuCacheTableUpdateCompanionBuilder,
          (
            MenuCacheData,
            BaseReferences<_$AppDatabase, $MenuCacheTable, MenuCacheData>,
          ),
          MenuCacheData,
          PrefetchHooks Function()
        > {
  $$MenuCacheTableTableManager(_$AppDatabase db, $MenuCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> locationId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
              }) => MenuCacheCompanion(
                id: id,
                providerId: providerId,
                locationId: locationId,
                date: date,
                payload: payload,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String providerId,
                required String locationId,
                required String date,
                required String payload,
                Value<int> fetchedAt = const Value.absent(),
              }) => MenuCacheCompanion.insert(
                id: id,
                providerId: providerId,
                locationId: locationId,
                date: date,
                payload: payload,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MenuCacheTable, MenuCacheData>(table),
                  BaseReferences<_$AppDatabase, $MenuCacheTable, MenuCacheData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuCacheTable,
      MenuCacheData,
      $$MenuCacheTableFilterComposer,
      $$MenuCacheTableOrderingComposer,
      $$MenuCacheTableAnnotationComposer,
      $$MenuCacheTableCreateCompanionBuilder,
      $$MenuCacheTableUpdateCompanionBuilder,
      (
        MenuCacheData,
        BaseReferences<_$AppDatabase, $MenuCacheTable, MenuCacheData>,
      ),
      MenuCacheData,
      PrefetchHooks Function()
    >;
typedef $$ClassFilesTableCreateCompanionBuilder = ClassFilesCompanion Function({
  Value<int> id,
  required int classId,
  required String fileName,
  required String storedPath,
  Value<int> sizeBytes,
  Value<String?> mimeType,
  Value<DateTime> createdAt,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$ClassFilesTableUpdateCompanionBuilder = ClassFilesCompanion Function({
  Value<int> id,
  Value<int> classId,
  Value<String> fileName,
  Value<String> storedPath,
  Value<int> sizeBytes,
  Value<String?> mimeType,
  Value<DateTime> createdAt,
  Value<String> uuid,
  Value<int> updatedAt,
});

final class $$ClassFilesTableReferences
    extends BaseReferences<_$AppDatabase, $ClassFilesTable, ClassFile> {
  $$ClassFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClassesTable _classIdTable(_$AppDatabase db) =>
      db.classes.createAlias('class_files__class_id__classes__id');

  $$ClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<int>('class_id')!;

    final manager = $$ClassesTableTableManager(
      $_db,
      $_db.classes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClassFilesTableFilterComposer
    extends Composer<_$AppDatabase, $ClassFilesTable> {
  $$ClassFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClassesTableFilterComposer get classId {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableFilterComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassFilesTable> {
  $$ClassFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassesTableOrderingComposer get classId {
    final $$ClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableOrderingComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassFilesTable> {
  $$ClassFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ClassesTableAnnotationComposer get classId {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassFilesTable,
          ClassFile,
          $$ClassFilesTableFilterComposer,
          $$ClassFilesTableOrderingComposer,
          $$ClassFilesTableAnnotationComposer,
          $$ClassFilesTableCreateCompanionBuilder,
          $$ClassFilesTableUpdateCompanionBuilder,
          (ClassFile, $$ClassFilesTableReferences),
          ClassFile,
          PrefetchHooks Function({bool classId})
        > {
  $$ClassFilesTableTableManager(_$AppDatabase db, $ClassFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> classId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> storedPath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ClassFilesCompanion(
                id: id,
                classId: classId,
                fileName: fileName,
                storedPath: storedPath,
                sizeBytes: sizeBytes,
                mimeType: mimeType,
                createdAt: createdAt,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int classId,
                required String fileName,
                required String storedPath,
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ClassFilesCompanion.insert(
                id: id,
                classId: classId,
                fileName: fileName,
                storedPath: storedPath,
                sizeBytes: sizeBytes,
                mimeType: mimeType,
                createdAt: createdAt,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassFilesTable, ClassFile>(table),
                  $$ClassFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (classId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.classId,
                        referencedTable: $$ClassFilesTableReferences
                            ._classIdTable(db),
                        referencedColumn: $$ClassFilesTableReferences
                            ._classIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ClassFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassFilesTable,
      ClassFile,
      $$ClassFilesTableFilterComposer,
      $$ClassFilesTableOrderingComposer,
      $$ClassFilesTableAnnotationComposer,
      $$ClassFilesTableCreateCompanionBuilder,
      $$ClassFilesTableUpdateCompanionBuilder,
      (ClassFile, $$ClassFilesTableReferences),
      ClassFile,
      PrefetchHooks Function({bool classId})
    >;
typedef $$YearFilesTableCreateCompanionBuilder = YearFilesCompanion Function({
  Value<int> id,
  required int yearId,
  required String fileName,
  required String storedPath,
  Value<int> sizeBytes,
  Value<String?> mimeType,
  Value<DateTime> createdAt,
  Value<String> uuid,
  Value<int> updatedAt,
});
typedef $$YearFilesTableUpdateCompanionBuilder = YearFilesCompanion Function({
  Value<int> id,
  Value<int> yearId,
  Value<String> fileName,
  Value<String> storedPath,
  Value<int> sizeBytes,
  Value<String?> mimeType,
  Value<DateTime> createdAt,
  Value<String> uuid,
  Value<int> updatedAt,
});

final class $$YearFilesTableReferences
    extends BaseReferences<_$AppDatabase, $YearFilesTable, YearFile> {
  $$YearFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AcademicYearsTable _yearIdTable(_$AppDatabase db) =>
      db.academicYears.createAlias('year_files__year_id__academic_years__id');

  $$AcademicYearsTableProcessedTableManager get yearId {
    final $_column = $_itemColumn<int>('year_id')!;

    final manager = $$AcademicYearsTableTableManager(
      $_db,
      $_db.academicYears,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_yearIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$YearFilesTableFilterComposer
    extends Composer<_$AppDatabase, $YearFilesTable> {
  $$YearFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AcademicYearsTableFilterComposer get yearId {
    final $$AcademicYearsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.yearId,
      referencedTable: $db.academicYears,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableFilterComposer(
            $db: $db,
            $table: $db.academicYears,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$YearFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $YearFilesTable> {
  $$YearFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AcademicYearsTableOrderingComposer get yearId {
    final $$AcademicYearsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.yearId,
      referencedTable: $db.academicYears,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableOrderingComposer(
            $db: $db,
            $table: $db.academicYears,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$YearFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $YearFilesTable> {
  $$YearFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AcademicYearsTableAnnotationComposer get yearId {
    final $$AcademicYearsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.yearId,
      referencedTable: $db.academicYears,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableAnnotationComposer(
            $db: $db,
            $table: $db.academicYears,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$YearFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $YearFilesTable,
          YearFile,
          $$YearFilesTableFilterComposer,
          $$YearFilesTableOrderingComposer,
          $$YearFilesTableAnnotationComposer,
          $$YearFilesTableCreateCompanionBuilder,
          $$YearFilesTableUpdateCompanionBuilder,
          (YearFile, $$YearFilesTableReferences),
          YearFile,
          PrefetchHooks Function({bool yearId})
        > {
  $$YearFilesTableTableManager(_$AppDatabase db, $YearFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$YearFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$YearFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$YearFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> yearId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> storedPath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => YearFilesCompanion(
                id: id,
                yearId: yearId,
                fileName: fileName,
                storedPath: storedPath,
                sizeBytes: sizeBytes,
                mimeType: mimeType,
                createdAt: createdAt,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int yearId,
                required String fileName,
                required String storedPath,
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => YearFilesCompanion.insert(
                id: id,
                yearId: yearId,
                fileName: fileName,
                storedPath: storedPath,
                sizeBytes: sizeBytes,
                mimeType: mimeType,
                createdAt: createdAt,
                uuid: uuid,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$YearFilesTable, YearFile>(table),
                  $$YearFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({yearId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (yearId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.yearId,
                        referencedTable: $$YearFilesTableReferences
                            ._yearIdTable(db),
                        referencedColumn: $$YearFilesTableReferences
                            ._yearIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$YearFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $YearFilesTable,
      YearFile,
      $$YearFilesTableFilterComposer,
      $$YearFilesTableOrderingComposer,
      $$YearFilesTableAnnotationComposer,
      $$YearFilesTableCreateCompanionBuilder,
      $$YearFilesTableUpdateCompanionBuilder,
      (YearFile, $$YearFilesTableReferences),
      YearFile,
      PrefetchHooks Function({bool yearId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AcademicYearsTableTableManager get academicYears =>
      $$AcademicYearsTableTableManager(_db, _db.academicYears);
  $$ClassesTableTableManager get classes =>
      $$ClassesTableTableManager(_db, _db.classes);
  $$ScheduleItemsTableTableManager get scheduleItems =>
      $$ScheduleItemsTableTableManager(_db, _db.scheduleItems);
  $$ScheduleExceptionsTableTableManager get scheduleExceptions =>
      $$ScheduleExceptionsTableTableManager(_db, _db.scheduleExceptions);
  $$HolidaysTableTableManager get holidays =>
      $$HolidaysTableTableManager(_db, _db.holidays);
  $$AbsencesTableTableManager get absences =>
      $$AbsencesTableTableManager(_db, _db.absences);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$TaskRemindersTableTableManager get taskReminders =>
      $$TaskRemindersTableTableManager(_db, _db.taskReminders);
  $$GradesTableTableManager get grades =>
      $$GradesTableTableManager(_db, _db.grades);
  $$PomodoroSessionsTableTableManager get pomodoroSessions =>
      $$PomodoroSessionsTableTableManager(_db, _db.pomodoroSessions);
  $$XtraEventsTableTableManager get xtraEvents =>
      $$XtraEventsTableTableManager(_db, _db.xtraEvents);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(_db, _db.syncTombstones);
  $$MenuCacheTableTableManager get menuCache =>
      $$MenuCacheTableTableManager(_db, _db.menuCache);
  $$ClassFilesTableTableManager get classFiles =>
      $$ClassFilesTableTableManager(_db, _db.classFiles);
  $$YearFilesTableTableManager get yearFiles =>
      $$YearFilesTableTableManager(_db, _db.yearFiles);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
