import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';

// Local provider to retrieve favorites list
final libraryFavoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return LocalStorage.getFavorites();
});

// Local provider to retrieve history list
final libraryHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return LocalStorage.getHistoryList();
});

