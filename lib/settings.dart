import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  const Settings({
    this.newPerDay = 10,
    this.reviewCap = 200,
    this.autoPlay = true,
    this.speechRate = 0.45,
    this.reverseCards = false,
    this.reminderEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 20, minute: 0),
    this.themeMode = ThemeMode.system,
  });

  final int newPerDay;
  final int reviewCap;
  final bool autoPlay;
  final double speechRate;
  final bool reverseCards;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;
  final ThemeMode themeMode;

  Settings copyWith({
    int? newPerDay,
    int? reviewCap,
    bool? autoPlay,
    double? speechRate,
    bool? reverseCards,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    ThemeMode? themeMode,
  }) =>
      Settings(
        newPerDay: newPerDay ?? this.newPerDay,
        reviewCap: reviewCap ?? this.reviewCap,
        autoPlay: autoPlay ?? this.autoPlay,
        speechRate: speechRate ?? this.speechRate,
        reverseCards: reverseCards ?? this.reverseCards,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderTime: reminderTime ?? this.reminderTime,
        themeMode: themeMode ?? this.themeMode,
      );

  static Settings load(SharedPreferences p) {
    const d = Settings();
    return Settings(
      newPerDay: p.getInt('newPerDay') ?? d.newPerDay,
      reviewCap: p.getInt('reviewCap') ?? d.reviewCap,
      autoPlay: p.getBool('autoPlay') ?? d.autoPlay,
      speechRate: p.getDouble('speechRate') ?? d.speechRate,
      reverseCards: p.getBool('reverseCards') ?? d.reverseCards,
      reminderEnabled: p.getBool('reminderEnabled') ?? d.reminderEnabled,
      reminderTime: TimeOfDay(
        hour: p.getInt('reminderHour') ?? d.reminderTime.hour,
        minute: p.getInt('reminderMinute') ?? d.reminderTime.minute,
      ),
      themeMode: ThemeMode.values[p.getInt('themeMode') ?? d.themeMode.index],
    );
  }

  Future<void> save(SharedPreferences p) async {
    await p.setInt('newPerDay', newPerDay);
    await p.setInt('reviewCap', reviewCap);
    await p.setBool('autoPlay', autoPlay);
    await p.setDouble('speechRate', speechRate);
    await p.setBool('reverseCards', reverseCards);
    await p.setBool('reminderEnabled', reminderEnabled);
    await p.setInt('reminderHour', reminderTime.hour);
    await p.setInt('reminderMinute', reminderTime.minute);
    await p.setInt('themeMode', themeMode.index);
  }
}

final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main'));

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => Settings.load(ref.read(prefsProvider));

  Future<void> update(Settings Function(Settings s) change) async {
    state = change(state);
    await state.save(ref.read(prefsProvider));
  }
}
