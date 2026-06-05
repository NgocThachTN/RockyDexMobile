import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/home/data/home_repository.dart';
import 'package:mobile/features/home/domain/comic_model.dart';
import 'package:mobile/features/home/presentation/home_notifier.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('RockyDex app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          homeProvider.overrideWith(
            (ref) => HomeNotifier(_FakeHomeRepository()),
          ),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<List<ComicModel>> getHomeComics() async => [];

  @override
  Future<List<ComicModel>> getComicsList(String type, {int page = 1}) async => [];

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ComicModel>> getComicsByCategory(
    String categorySlug, {
    int page = 1,
  }) async =>
      [];
}
