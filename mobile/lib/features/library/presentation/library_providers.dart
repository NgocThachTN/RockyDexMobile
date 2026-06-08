import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';
import '../data/library_repository.dart';

// Local provider to retrieve favorites list
final libraryFavoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  await repo.syncFavorites();
  return LocalStorage.getFavorites();
});

// Local provider to retrieve history list
final libraryHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  await repo.syncHistory();
  return LocalStorage.getHistoryList();
});

