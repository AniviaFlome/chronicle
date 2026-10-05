// dart format off
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:home_widget/home_widget.dart';

class TodayAgendaHomeWidget {
  const TodayAgendaHomeWidget._();

  static const String _$paramPrefix = 'home_widget.TodayAgenda';

  static Future<void> saveData({
    int? themeBg,
    int? themeFg,
    int? themeAccent,
    List<TodayAgendaClassesItem>? classes,
    List<TodayAgendaLaterItem>? later,
    List<TodayAgendaWeekItem>? week,
  }) {
    return Future.wait([
      if (themeBg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeBg', themeBg),
      if (themeFg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeFg', themeFg),
      if (themeAccent != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeAccent', themeAccent),
      if (classes != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.classes', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in classes) _item.toJson()]))), extension: 'json');
      }(),
      if (later != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.later', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in later) _item.toJson()]))), extension: 'json');
      }(),
      if (week != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.week', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in week) _item.toJson()]))), extension: 'json');
      }(),
    ]);
  }

  static Future<void> deleteData({
    bool themeBg = false,
    bool themeFg = false,
    bool themeAccent = false,
    bool classes = false,
    bool later = false,
    bool week = false,
  }) {
    return Future.wait([
      if (themeBg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeBg', null),
      if (themeFg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeFg', null),
      if (themeAccent) HomeWidget.saveWidgetData('${_$paramPrefix}.themeAccent', null),
      if (classes) HomeWidget.saveWidgetData('${_$paramPrefix}.classes', null),
      if (later) HomeWidget.saveWidgetData('${_$paramPrefix}.later', null),
      if (week) HomeWidget.saveWidgetData('${_$paramPrefix}.week', null),
    ]);
  }

  static Future<({int? themeBg, int? themeFg, int? themeAccent, List<TodayAgendaClassesItem>? classes, List<TodayAgendaLaterItem>? later, List<TodayAgendaWeekItem>? week})> getData() async {
    final _classesPath = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.classes');
    List<TodayAgendaClassesItem>? classes;
    if (_classesPath != null) {
      try {
        final _classesJson = jsonDecode(await File(_classesPath).readAsString());
        if (_classesJson is List) classes = [for (final _item in _classesJson) TodayAgendaClassesItem.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        classes = null;
      }
    }
    final _laterPath = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.later');
    List<TodayAgendaLaterItem>? later;
    if (_laterPath != null) {
      try {
        final _laterJson = jsonDecode(await File(_laterPath).readAsString());
        if (_laterJson is List) later = [for (final _item in _laterJson) TodayAgendaLaterItem.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        later = null;
      }
    }
    final _weekPath = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.week');
    List<TodayAgendaWeekItem>? week;
    if (_weekPath != null) {
      try {
        final _weekJson = jsonDecode(await File(_weekPath).readAsString());
        if (_weekJson is List) week = [for (final _item in _weekJson) TodayAgendaWeekItem.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        week = null;
      }
    }
    return (
      themeBg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeBg', defaultValue: 0),
      themeFg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeFg', defaultValue: 0),
      themeAccent: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeAccent', defaultValue: 0),
      classes: classes,
      later: later,
      week: week,
    );
  }


  static Future<bool?> updateWidget() {
    return HomeWidget.updateWidget(
      androidName: 'TodayAgendaHomeWidgetReceiver',
    );
  }

  /// Asks the launcher to re-render this widget's gallery preview.
  ///
  /// Android 15 and newer only; returns false elsewhere and when the system
  /// rate limit (about two updates per hour and widget) was hit. The plugin
  /// registers the preview automatically when the app starts, so this is only
  /// needed after data changes that should show in the gallery right away.
  static Future<bool> updatePreview() async {
    return await HomeWidget.updateWidgetPreview(
      androidName: 'TodayAgendaHomeWidgetReceiver',
    ) ?? false;
  }

  /// Whether the launcher lets the app ask to add this widget to the home
  /// screen: Android 8 or newer with a launcher that supports pinning. Always
  /// false on iOS.
  static Future<bool> isRequestPinWidgetSupported() async {
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  }

  /// Asks the launcher to add this widget to the home screen.
  ///
  /// Shows the system pin dialog where [isRequestPinWidgetSupported] is true
  /// and does nothing anywhere else.
  static Future<void> requestPinWidget() {
    return HomeWidget.requestPinWidget(
      androidName: 'TodayAgendaHomeWidgetReceiver',
    );
  }

  /// Every instance of this widget currently placed on a home screen.
  ///
  /// Android reports one entry per placed instance, iOS one entry per family
  /// the widget is placed in.
  static Future<List<HomeWidgetInfo>> getInstalledWidgets() async {
    final widgets = await HomeWidget.getInstalledWidgets();
    return widgets.where(_$isThisWidget).toList();
  }

  /// Whether at least one instance of this widget is on a home screen.
  static Future<bool> isInstalled() async {
    return (await getInstalledWidgets()).isNotEmpty;
  }

  /// Whether [info] describes this widget.
  ///
  /// Android reports the provider's short class name — `.Receiver` when it
  /// lives in the package of the application id, and the qualified name
  /// otherwise — which is why the suffix is matched.
  static bool _$isThisWidget(HomeWidgetInfo info) {
    final androidClassName = info.androidClassName;
    if (androidClassName != null) {
      return androidClassName.endsWith('.TodayAgendaHomeWidgetReceiver');
    }
    return false;
  }
}

class TodayAgendaClassesItem {
  final String? time;
  final String? name;

  const TodayAgendaClassesItem({
    this.time,
    this.name,
  });

  factory TodayAgendaClassesItem.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaClassesItem(
      time: _readString(json['time']),
      name: _readString(json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (time != null) 'time': time,
      if (name != null) 'name': name,
    };
  }
}

class TodayAgendaLaterItem {
  final String? label;
  final String? name;

  const TodayAgendaLaterItem({
    this.label,
    this.name,
  });

  factory TodayAgendaLaterItem.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaLaterItem(
      label: _readString(json['label']),
      name: _readString(json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
      if (name != null) 'name': name,
    };
  }
}

class TodayAgendaWeekItem {
  final bool? isToday;
  final String? initial;
  final String? date;

  const TodayAgendaWeekItem({
    this.isToday,
    this.initial,
    this.date,
  });

  factory TodayAgendaWeekItem.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaWeekItem(
      isToday: _readBool(json['isToday']) ?? false,
      initial: _readString(json['initial']),
      date: _readString(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (isToday != null) 'isToday': isToday,
      if (initial != null) 'initial': initial,
      if (date != null) 'date': date,
    };
  }
}

String? _readString(Object? value) => value is String ? value : null;
bool? _readBool(Object? value) => value is bool ? value : null;
