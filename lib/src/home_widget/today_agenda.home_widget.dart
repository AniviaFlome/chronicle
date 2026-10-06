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
    int? selectedDay,
    List<TodayAgendaWeekItem>? week,
    List<TodayAgendaDay0Item>? day0,
    List<TodayAgendaDay1Item>? day1,
    List<TodayAgendaDay2Item>? day2,
    List<TodayAgendaDay3Item>? day3,
    List<TodayAgendaDay4Item>? day4,
    List<TodayAgendaDay5Item>? day5,
    List<TodayAgendaDay6Item>? day6,
  }) {
    return Future.wait([
      if (themeBg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeBg', themeBg),
      if (themeFg != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeFg', themeFg),
      if (themeAccent != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.themeAccent', themeAccent),
      if (selectedDay != null) HomeWidget.saveWidgetData<int>('${_$paramPrefix}.selectedDay', selectedDay),
      if (week != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.week', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in week) _item.toJson()]))), extension: 'json');
      }(),
      if (day0 != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.day0', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in day0) _item.toJson()]))), extension: 'json');
      }(),
      if (day1 != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.day1', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in day1) _item.toJson()]))), extension: 'json');
      }(),
      if (day2 != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.day2', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in day2) _item.toJson()]))), extension: 'json');
      }(),
      if (day3 != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.day3', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in day3) _item.toJson()]))), extension: 'json');
      }(),
      if (day4 != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.day4', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in day4) _item.toJson()]))), extension: 'json');
      }(),
      if (day5 != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.day5', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in day5) _item.toJson()]))), extension: 'json');
      }(),
      if (day6 != null) () async {
        await HomeWidget.saveFile('${_$paramPrefix}.day6', Uint8List.fromList(utf8.encode(jsonEncode([for (final _item in day6) _item.toJson()]))), extension: 'json');
      }(),
    ]);
  }

  static Future<void> deleteData({
    bool themeBg = false,
    bool themeFg = false,
    bool themeAccent = false,
    bool selectedDay = false,
    bool week = false,
    bool day0 = false,
    bool day1 = false,
    bool day2 = false,
    bool day3 = false,
    bool day4 = false,
    bool day5 = false,
    bool day6 = false,
  }) {
    return Future.wait([
      if (themeBg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeBg', null),
      if (themeFg) HomeWidget.saveWidgetData('${_$paramPrefix}.themeFg', null),
      if (themeAccent) HomeWidget.saveWidgetData('${_$paramPrefix}.themeAccent', null),
      if (selectedDay) HomeWidget.saveWidgetData('${_$paramPrefix}.selectedDay', null),
      if (week) HomeWidget.saveWidgetData('${_$paramPrefix}.week', null),
      if (day0) HomeWidget.saveWidgetData('${_$paramPrefix}.day0', null),
      if (day1) HomeWidget.saveWidgetData('${_$paramPrefix}.day1', null),
      if (day2) HomeWidget.saveWidgetData('${_$paramPrefix}.day2', null),
      if (day3) HomeWidget.saveWidgetData('${_$paramPrefix}.day3', null),
      if (day4) HomeWidget.saveWidgetData('${_$paramPrefix}.day4', null),
      if (day5) HomeWidget.saveWidgetData('${_$paramPrefix}.day5', null),
      if (day6) HomeWidget.saveWidgetData('${_$paramPrefix}.day6', null),
    ]);
  }

  static Future<({int? themeBg, int? themeFg, int? themeAccent, int? selectedDay, List<TodayAgendaWeekItem>? week, List<TodayAgendaDay0Item>? day0, List<TodayAgendaDay1Item>? day1, List<TodayAgendaDay2Item>? day2, List<TodayAgendaDay3Item>? day3, List<TodayAgendaDay4Item>? day4, List<TodayAgendaDay5Item>? day5, List<TodayAgendaDay6Item>? day6})> getData() async {
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
    final _day0Path = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.day0');
    List<TodayAgendaDay0Item>? day0;
    if (_day0Path != null) {
      try {
        final _day0Json = jsonDecode(await File(_day0Path).readAsString());
        if (_day0Json is List) day0 = [for (final _item in _day0Json) TodayAgendaDay0Item.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        day0 = null;
      }
    }
    final _day1Path = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.day1');
    List<TodayAgendaDay1Item>? day1;
    if (_day1Path != null) {
      try {
        final _day1Json = jsonDecode(await File(_day1Path).readAsString());
        if (_day1Json is List) day1 = [for (final _item in _day1Json) TodayAgendaDay1Item.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        day1 = null;
      }
    }
    final _day2Path = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.day2');
    List<TodayAgendaDay2Item>? day2;
    if (_day2Path != null) {
      try {
        final _day2Json = jsonDecode(await File(_day2Path).readAsString());
        if (_day2Json is List) day2 = [for (final _item in _day2Json) TodayAgendaDay2Item.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        day2 = null;
      }
    }
    final _day3Path = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.day3');
    List<TodayAgendaDay3Item>? day3;
    if (_day3Path != null) {
      try {
        final _day3Json = jsonDecode(await File(_day3Path).readAsString());
        if (_day3Json is List) day3 = [for (final _item in _day3Json) TodayAgendaDay3Item.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        day3 = null;
      }
    }
    final _day4Path = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.day4');
    List<TodayAgendaDay4Item>? day4;
    if (_day4Path != null) {
      try {
        final _day4Json = jsonDecode(await File(_day4Path).readAsString());
        if (_day4Json is List) day4 = [for (final _item in _day4Json) TodayAgendaDay4Item.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        day4 = null;
      }
    }
    final _day5Path = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.day5');
    List<TodayAgendaDay5Item>? day5;
    if (_day5Path != null) {
      try {
        final _day5Json = jsonDecode(await File(_day5Path).readAsString());
        if (_day5Json is List) day5 = [for (final _item in _day5Json) TodayAgendaDay5Item.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        day5 = null;
      }
    }
    final _day6Path = await HomeWidget.getWidgetData<String>('${_$paramPrefix}.day6');
    List<TodayAgendaDay6Item>? day6;
    if (_day6Path != null) {
      try {
        final _day6Json = jsonDecode(await File(_day6Path).readAsString());
        if (_day6Json is List) day6 = [for (final _item in _day6Json) TodayAgendaDay6Item.fromJson(_item is Map<String, dynamic> ? _item : null)];
      } on Exception {
        day6 = null;
      }
    }
    return (
      themeBg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeBg', defaultValue: 0),
      themeFg: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeFg', defaultValue: 0),
      themeAccent: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.themeAccent', defaultValue: 0),
      selectedDay: await HomeWidget.getWidgetData<int>('${_$paramPrefix}.selectedDay', defaultValue: 0),
      week: week,
      day0: day0,
      day1: day1,
      day2: day2,
      day3: day3,
      day4: day4,
      day5: day5,
      day6: day6,
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

class TodayAgendaWeekItem {
  final String? label;

  const TodayAgendaWeekItem({
    this.label,
  });

  factory TodayAgendaWeekItem.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaWeekItem(
      label: _readString(json['label']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
    };
  }
}

class TodayAgendaDay0Item {
  final String? time;
  final String? name;

  const TodayAgendaDay0Item({
    this.time,
    this.name,
  });

  factory TodayAgendaDay0Item.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaDay0Item(
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

class TodayAgendaDay1Item {
  final String? time;
  final String? name;

  const TodayAgendaDay1Item({
    this.time,
    this.name,
  });

  factory TodayAgendaDay1Item.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaDay1Item(
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

class TodayAgendaDay2Item {
  final String? time;
  final String? name;

  const TodayAgendaDay2Item({
    this.time,
    this.name,
  });

  factory TodayAgendaDay2Item.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaDay2Item(
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

class TodayAgendaDay3Item {
  final String? time;
  final String? name;

  const TodayAgendaDay3Item({
    this.time,
    this.name,
  });

  factory TodayAgendaDay3Item.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaDay3Item(
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

class TodayAgendaDay4Item {
  final String? time;
  final String? name;

  const TodayAgendaDay4Item({
    this.time,
    this.name,
  });

  factory TodayAgendaDay4Item.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaDay4Item(
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

class TodayAgendaDay5Item {
  final String? time;
  final String? name;

  const TodayAgendaDay5Item({
    this.time,
    this.name,
  });

  factory TodayAgendaDay5Item.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaDay5Item(
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

class TodayAgendaDay6Item {
  final String? time;
  final String? name;

  const TodayAgendaDay6Item({
    this.time,
    this.name,
  });

  factory TodayAgendaDay6Item.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return TodayAgendaDay6Item(
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

String? _readString(Object? value) => value is String ? value : null;
