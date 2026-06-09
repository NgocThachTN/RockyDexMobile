import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../data/reader_repository.dart';
import '../domain/chapter_detail_model.dart';

final readerChapterDetailProvider =
    FutureProvider.family<ChapterDetailInfoModel, String>((
      ref,
      apiDataUrl,
    ) async {
      final repo = ref.watch(readerRepositoryProvider);
      return repo.getChapterDetail(apiDataUrl);
    });

// Reading Preferences (Layout Mode, brightness, theme)
class ReaderSettings {
  final String layout; // vertical, horizontal, continuous
  final double brightness;

  ReaderSettings({this.layout = 'vertical', this.brightness = 1.0});

  ReaderSettings copyWith({String? layout, double? brightness}) {
    return ReaderSettings(
      layout: layout ?? this.layout,
      brightness: brightness ?? this.brightness,
    );
  }
}

final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ReaderSettingsNotifier(prefs);
    });

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  final SharedPreferences _prefs;
  Timer? _brightnessPersistTimer;

  ReaderSettingsNotifier(this._prefs) : super(ReaderSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final layout = _prefs.getString('reader_layout') ?? 'vertical';
    final brightness = _prefs.getDouble('reader_brightness') ?? 1.0;
    state = ReaderSettings(layout: layout, brightness: brightness);
  }

  Future<void> updateLayout(String layout) async {
    if (state.layout == layout) return;
    state = state.copyWith(layout: layout);
    await _prefs.setString('reader_layout', layout);
  }

  void updateBrightness(double brightness) {
    final nextBrightness = brightness.clamp(0.1, 1.0).toDouble();
    if ((state.brightness - nextBrightness).abs() < 0.001) return;

    state = state.copyWith(brightness: nextBrightness);
    _brightnessPersistTimer?.cancel();
    _brightnessPersistTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_prefs.setDouble('reader_brightness', state.brightness));
    });
  }

  @override
  void dispose() {
    _brightnessPersistTimer?.cancel();
    unawaited(_prefs.setDouble('reader_brightness', state.brightness));
    super.dispose();
  }
}
