// dart format off
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:home_widget/home_widget.dart';

class DueTasksCompactHomeWidget {
  const DueTasksCompactHomeWidget._();

  static const String _$paramPrefix = 'home_widget.DueTasksCompact';

  static Future<void> saveData({
    int? themeBg,
    int? themeFg,
    int? themeAccent,
    String? headerLine,
    List<DueTasksCompactTasksItem>? tasks,
  }) {
    return Future.wait([
      if (themeBg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeBg', themeBg),
      if (themeFg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeFg', themeFg),
      if (themeAccent != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeAccent', themeAccent),
      if (headerLine != null) HomeWidget.saveWidgetData<String>('${_$paramPrefix}.headerLine', headerLine),
      if (tasks != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.tasks', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in tasks) _item.toJson()]))), extension: 'json');
      }(),
    ]);
  }

  static Future<void> deleteData({
    bool themeBg = false,
    bool themeFg = false,
    bool themeAccent = false,
    bool headerLine = false,
    bool tasks = false,
  }) {
    return Future.wait([
      if (themeBg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeBg', null),
      if (themeFg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeFg', null),
      if (themeAccent) HomeWidget.saveWidgetData('${_$paramPrefix}.themeAccent', null),
      if (headerLine) HomeWidget.saveWidgetData('${_$paramPrefix}.headerLine', null),
      if (tasks) HomeWidget.saveWidgetData('${_$paramPrefix}.tasks', null),
    ]);
  }

  static Future<({int? themeBg, int? themeFg, int? themeAccent, String? headerLine, List<DueTasksCompactTasksItem>? tasks})> getData() async {
    final _tasksPath = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.tasks');
    List<DueTasksCompactTasksItem>? tasks;
    if (_tasksPath != null) {
      try {
        final _tasksJson = jsonDecode(await File(_tasksPath).readAsString());
        if (_tasksJson is List) tasks = [for (final _item in _tasksJson) DueTasksCompactTasksItem.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        tasks = null;
      }
    }
    return (
      themeBg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeBg', defaultValue: 0),
      themeFg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeFg', defaultValue: 0),
      themeAccent: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeAccent', defaultValue: 0),
      headerLine: await HomeWidget.getWidgetData<String>('${_$paramPrefix}.headerLine', defaultValue: 'Due tasks'),
      tasks: tasks,
    );
  }


  static Future<bool?> updateWidget() {
    return HomeWidget.updateWidget(
      androidName: 'DueTasksCompactHomeWidgetReceiver',
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
      androidName: 'DueTasksCompactHomeWidgetReceiver',
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
      androidName: 'DueTasksCompactHomeWidgetReceiver',
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
      return androidClassName.endsWith('.DueTasksCompactHomeWidgetReceiver');
    }
    return false;
  }
}

class DueTasksCompactTasksItem {
  final String? title;
  final String? date;

  const DueTasksCompactTasksItem({
    this.title,
    this.date,
  });

  factory DueTasksCompactTasksItem.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return DueTasksCompactTasksItem(
      title: _readString(json['title']),
      date: _readString(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (date != null) 'date': date,
    };
  }
}

String? _readString(Object? value) => value is String ? value : null;
