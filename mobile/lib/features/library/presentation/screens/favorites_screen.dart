import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../library_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(libraryFavoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Truyện Yêu Thích'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(libraryFavoritesProvider),
        child: favoritesAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: Text('Chưa có truyện yêu thích'),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final slug = item['comic_slug'] ?? item['slug'];
                final name = item['comic_name'] ?? item['name'];
                final thumb = item['comic_thumb'] ?? item['thumb_url'];

                return GestureDetector(
                  onTap: () => context.push('/comic/$slug'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: CachedNetworkImage(
                              imageUrl: thumb,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              fadeInDuration: const Duration(milliseconds: 250),
                              placeholder: (context, url) => Container(
                                color: Theme.of(context).cardColor,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Theme.of(context).cardColor,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
        ),
      ),
    );
  }
}
