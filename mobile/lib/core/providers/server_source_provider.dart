import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';

enum ServerSource { otruyen, mangadex }

final serverSourceProvider = StateNotifierProvider<ServerSourceNotifier, ServerSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ServerSourceNotifier(prefs);
});

class ServerSourceNotifier extends StateNotifier<ServerSource> {
  static const String _key = 'selected_server_source';
  final SharedPreferences _prefs;

  ServerSourceNotifier(this._prefs) : super(ServerSource.otruyen) {
    _loadSource();
  }

  void _loadSource() {
    final stored = _prefs.getString(_key);
    if (stored == 'mangadex') {
      state = ServerSource.mangadex;
    } else {
      state = ServerSource.otruyen;
    }
  }

  Future<void> setSource(ServerSource source) async {
    state = source;
    await _prefs.setString(_key, source.name);
  }
}
