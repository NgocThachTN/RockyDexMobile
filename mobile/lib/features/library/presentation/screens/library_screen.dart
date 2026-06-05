import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../../comic/data/comic_repository.dart';
import '../library_providers.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(libraryFavoritesProvider);
    final historyAsync = ref.watch(libraryHistoryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tủ Sách'),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryBlue,
            labelColor: AppColors.primaryBlue,
            tabs: [
              Tab(text: 'Yêu thích'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Favorites Grid
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(libraryFavoritesProvider),
              child: _buildFavoritesTab(context, ref, favoritesAsync),
            ),
            // Tab 2: History List
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(libraryHistoryProvider),
              child: _buildHistoryTab(context, ref, historyAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> asyncVal,
  ) {
    return asyncVal.when(
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
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).cardColor,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> asyncVal,
  ) {
    return asyncVal.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('Chưa có lịch sử đọc truyện'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final slug = item['comic_slug'];
            final name = item['comic_name'];
            final thumb = item['comic_thumb'] ?? '';
            final chapName = item['chapter_name'];
            final progress = item['progress_percent'] as int? ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Thumb
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: thumb,
                        width: 55,
                        height: 75,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 55,
                          height: 75,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã đọc: Chương $chapName',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100.0,
                              backgroundColor: Theme.of(context).dividerColor,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Play / Resume Button
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline, color: AppColors.primaryBlue, size: 30),
                      onPressed: () {
                        // Open details screen to load full server configurations
                        context.push('/comic/$slug');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
    );
  }
}
