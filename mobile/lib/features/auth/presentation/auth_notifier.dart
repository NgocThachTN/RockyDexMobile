import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/library_providers.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(repo, prefs, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SharedPreferences _prefs;
  final Ref _ref;

  AuthNotifier(this._repository, this._prefs, this._ref) : super(AuthState()) {
    _loadUserFromPrefs();
  }

  void _loadUserFromPrefs() {
    final userJsonStr = _prefs.getString('user_data');
    if (userJsonStr != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userJsonStr) as Map<String, dynamic>);
        state = AuthState(user: user);
      } catch (_) {
        // Corrupted preferences
        _prefs.remove('user_data');
        _prefs.remove('auth_token');
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.login(email, password);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _prefs.setString('auth_token', token);
      await _prefs.setString('user_data', jsonEncode(user.toJson()));

      state = AuthState(user: user);

      // Perform background sync on successful login
      await _ref.read(libraryRepositoryProvider).syncFavorites();
      await _ref.read(libraryRepositoryProvider).syncHistory();

      // Invalidate providers to reload screen grids
      _ref.invalidate(libraryFavoritesProvider);
      _ref.invalidate(libraryHistoryProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.register(email, password, name);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _prefs.setString('auth_token', token);
      await _prefs.setString('user_data', jsonEncode(user.toJson()));

      state = AuthState(user: user);

      // Sync local and remote library data
      await _ref.read(libraryRepositoryProvider).syncFavorites();
      await _ref.read(libraryRepositoryProvider).syncHistory();

      _ref.invalidate(libraryFavoritesProvider);
      _ref.invalidate(libraryHistoryProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> googleLogin(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.googleLogin(idToken);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _prefs.setString('auth_token', token);
      await _prefs.setString('user_data', jsonEncode(user.toJson()));

      state = AuthState(user: user);

      // Sync local and remote library data
      await _ref.read(libraryRepositoryProvider).syncFavorites();
      await _ref.read(libraryRepositoryProvider).syncHistory();

      _ref.invalidate(libraryFavoritesProvider);
      _ref.invalidate(libraryHistoryProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    
    // Clear local SQLite favorites and history on logout
    await LocalStorage.clearHistory();
    await LocalStorage.clearFavorites();
    
    state = AuthState();

    // Rebuild lists to empty state
    _ref.invalidate(libraryFavoritesProvider);
    _ref.invalidate(libraryHistoryProvider);
  }

  Future<void> updateProfile({
    String? avatarUrl,
    String? themePreference,
    String? readingLayout,
    double? readingBrightness,
  }) async {
    if (state.user == null) return;
    try {
      final data = <String, dynamic>{};
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (themePreference != null) data['theme_preference'] = themePreference;
      if (readingLayout != null) data['reading_layout'] = readingLayout;
      if (readingBrightness != null) data['reading_brightness'] = readingBrightness;

      final updatedProfile = await _repository.updateProfile(data);
      final updatedUser = state.user!.copyWith(profile: updatedProfile);

      await _prefs.setString('user_data', jsonEncode(updatedUser.toJson()));
      state = state.copyWith(user: updatedUser);
    } catch (_) {
      // Keep state as is on failure
    }
  }
}
