import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/constants/colors.dart';
import 'package:mobile/core/storage/local_storage.dart';
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
                        child: Stack(
                          children: [
                            Positioned.fill(
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
                            // Floating Unfavorite Button
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Bỏ yêu thích'),
                                      content: Text('Bạn có chắc chắn muốn bỏ yêu thích truyện "$name" không?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Hủy'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                          child: const Text('Bỏ thích'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await LocalStorage.deleteFavorite(slug);
                                    ref.invalidate(libraryFavoritesProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã bỏ yêu thích "$name"'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
