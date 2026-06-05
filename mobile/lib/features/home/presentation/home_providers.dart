import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/comic_model.dart';
import '../data/home_repository.dart';
import '../../../core/constants/api_constants.dart';

final featuredComicsProvider = FutureProvider<List<ComicModel>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getHomeComics();
});

final newComicsProvider = FutureProvider<List<ComicModel>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getComicsList(ApiConstants.listNew);
});

final ongoingComicsProvider = FutureProvider<List<ComicModel>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getComicsList(ApiConstants.listOngoing);
});

final completedComicsProvider = FutureProvider<List<ComicModel>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getComicsList(ApiConstants.listCompleted);
});

final homeCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getCategories();
});
