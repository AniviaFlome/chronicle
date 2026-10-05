// dart format off
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class NextClassHomeWidget {
  const NextClassHomeWidget._();

  static const String _$paramPrefix = 'home_widget.NextClass';

  static Future<void> saveData({
    int? themeBg,
    int? themeFg,
    int? themeAccent,
    Map<DateTime, NextClassTimedData>? timedData,
  }) {
    return Future.wait([
      if (themeBg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeBg', themeBg),
      if (themeFg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeFg', themeFg),
      if (themeAccent != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeAccent', themeAccent),
      if (timedData != null) () async {
        final _timedTimes = timedData.keys.toList()..sort();
        if (_timedTimes.isEmpty) {
          await HomeWidget.saveWidgetData('${_$paramPrefix}.timedData', null);
          try {
            await HomeWidget.cancelScheduledWidgetUpdates(androidName: 'NextClassHomeWidgetReceiver');
          } catch (error, stackTrace) {
            // Cancelling is best effort; the data was deleted.
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stackTrace,
                library: 'home_widget',
                context: ErrorDescription('cancelling scheduled updates for the NextClass widget'),
              ),
            );
          }
          return;
        }
        final _timedJson = <String, dynamic>{
          for (final _time in _timedTimes)
            _time.toUtc().millisecondsSinceEpoch.toString(): timedData[_time]!.toJson(),
        };
        await HomeWidget.saveFile('${_$paramPrefix}.timedData', Uint8List.fromList(utf8.encode(jsonEncode(_timedJson))), extension: 'json');
        try {
          await HomeWidget.scheduleWidgetUpdates(_timedTimes, androidName: 'NextClassHomeWidgetReceiver');
        } catch (error, stackTrace) {
          // Scheduling is best effort; the data was saved.
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'home_widget',
              context: ErrorDescription('scheduling updates for the NextClass widget'),
            ),
          );
        }
      }(),
    ]);
  }

  static Future<void> deleteData({
    bool themeBg = false,
    bool themeFg = false,
    bool themeAccent = false,
    bool timedData = false,
  }) {
    return Future.wait([
      if (themeBg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeBg', null),
      if (themeFg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeFg', null),
      if (themeAccent) HomeWidget.saveWidgetData('${_$paramPrefix}.themeAccent', null),
      if (timedData) () async {
        await HomeWidget.saveWidgetData('${_$paramPrefix}.timedData', null);
        try {
          await HomeWidget.cancelScheduledWidgetUpdates(androidName: 'NextClassHomeWidgetReceiver');
        } catch (error, stackTrace) {
          // Cancelling is best effort; the data was deleted.
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'home_widget',
              context: ErrorDescription('cancelling scheduled updates for the NextClass widget'),
            ),
          );
        }
      }(),
    ]);
  }

  /// Reads every stored value back.
  ///
  /// The keys of [timedData] are local-time [DateTime]s, so they compare equal to a
  /// local [DateTime] for the same instant. Timestamps are stored as epoch
  /// milliseconds: sub-millisecond precision of the saved keys is not preserved.
  /// Keys are compared by instant, so a local [DateTime] and its `toUtc()` twin
  /// denote the same entry and only one of them survives a save.
  static Future<({int? themeBg, int? themeFg, int? themeAccent, Map<DateTime, NextClassTimedData>? timedData})> getData() async {
    final _timedDataPath = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.timedData');
    Map<DateTime, NextClassTimedData>? timedData;
    if (_timedDataPath != null) {
      try {
        final raw = await File(_timedDataPath).readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final entries = <DateTime, NextClassTimedData>{};
          for (final entry in decoded.entries) {
            final millis = int.tryParse(entry.key);
            if (millis == null) continue;
            final value = entry.value;
            entries[DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal()] = NextClassTimedData.fromJson(value is Map<String, dynamic> ? value : null);
          }
          timedData = entries;
        }
      } on Exception {
        timedData = null;
      }
    }
    return (
      themeBg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeBg', defaultValue: 0),
      themeFg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeFg', defaultValue: 0),
      themeAccent: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeAccent', defaultValue: 0),
      timedData: timedData,
    );
  }


  static Future<bool?> updateWidget() {
    return HomeWidget.updateWidget(
      androidName: 'NextClassHomeWidgetReceiver',
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
      androidName: 'NextClassHomeWidgetReceiver',
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
      androidName: 'NextClassHomeWidgetReceiver',
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
      return androidClassName.endsWith('.NextClassHomeWidgetReceiver');
    }
    return false;
  }
}

class NextClassTimedData {
  final String? className;
  final String? detailLine;
  final String? thenLine;

  const NextClassTimedData({
    this.className,
    this.detailLine,
    this.thenLine,
  });

  factory NextClassTimedData.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return NextClassTimedData(
      className: _readString(json['className']) ?? '—',
      detailLine: _readString(json['detailLine']) ?? '',
      thenLine: _readString(json['thenLine']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (className != null) 'className': className,
      if (detailLine != null) 'detailLine': detailLine,
      if (thenLine != null) 'thenLine': thenLine,
    };
  }
}

String? _readString(Object? value) => value is String ? value : null;
