import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../data/reader_repository.dart';
import '../domain/chapter_detail_model.dart';

final readerChapterDetailProvider = FutureProvider.family<ChapterDetailInfoModel, String>((ref, apiDataUrl) async {
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

final readerSettingsProvider = StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReaderSettingsNotifier(prefs);
});

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  final SharedPreferences _prefs;

  ReaderSettingsNotifier(this._prefs) : super(ReaderSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final layout = _prefs.getString('reader_layout') ?? 'vertical';
    final brightness = _prefs.getDouble('reader_brightness') ?? 1.0;
    state = ReaderSettings(layout: layout, brightness: brightness);
  }

  Future<void> updateLayout(String layout) async {
    await _prefs.setString('reader_layout', layout);
    state = state.copyWith(layout: layout);
  }

  Future<void> updateBrightness(double brightness) async {
    await _prefs.setDouble('reader_brightness', brightness);
    state = state.copyWith(brightness: brightness);
  }
}
