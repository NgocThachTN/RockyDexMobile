import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/comic_model.dart';
import '../home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredComicsProvider);
    final newAsync = ref.watch(newComicsProvider);
    final ongoingAsync = ref.watch(ongoingComicsProvider);
    final completedAsync = ref.watch(completedComicsProvider);
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_stories, color: AppColors.primaryBlue, size: 28),
            const SizedBox(width: 8),
            Text(
              'RockyDex',
              style: TextStyle(
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredComicsProvider);
          ref.invalidate(newComicsProvider);
          ref.invalidate(ongoingComicsProvider);
          ref.invalidate(completedComicsProvider);
          ref.invalidate(homeCategoriesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Featured Slider
              const SizedBox(height: 12),
              _buildSectionTitle(context, 'Truyện Nổi Bật', () {}),
              _buildFeaturedSection(context, featuredAsync),

              // 2. Categories
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Thể Loại', null),
              _buildCategoriesSection(categoriesAsync),

              // 3. New Updates
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Mới Cập Nhật', () {
                // Navigate to list view
              }),
              _buildHorizontalComicList(context, newAsync),

              // 4. Ongoing
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Truyện Đang Tiến Hành', () {}),
              _buildHorizontalComicList(context, ongoingAsync),

              // 5. Completed
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Truyện Đã Hoàn Thành', () {}),
              _buildHorizontalComicList(context, completedAsync),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context, AsyncValue<List<ComicModel>> asyncVal) {
    return asyncVal.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final featured = list.take(5).toList();

        return SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: featured.length,
            itemBuilder: (context, index) {
              final comic = featured[index];
              return GestureDetector(
                onTap: () => context.push('/comic/${comic.slug}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Cover
                        CachedNetworkImage(
                          imageUrl: comic.thumbUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).cardColor,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).cardColor,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                        // Dark overlay for readability
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        // Content overlay
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                comic.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (comic.category.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  comic.category.map((e) => e.name).join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => SizedBox(
        height: 100,
        child: Center(child: Text('Lỗi tải truyện nổi bật: $err')),
      ),
    );
  }

  Widget _buildCategoriesSection(AsyncValue<List<CategoryModel>> asyncVal) {
    return asyncVal.when(
      data: (list) {
        return SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length > 15 ? 15 : list.length, // show top 15
            itemBuilder: (context, index) {
              final cat = list[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.name),
                  onSelected: (selected) {
                    // Navigate to search with category filter
                    context.go('/search', extra: cat.slug);
                  },
                  backgroundColor: Theme.of(context).cardColor,
                  selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildHorizontalComicList(BuildContext context, AsyncValue<List<ComicModel>> asyncVal) {
    return asyncVal.when(
      data: (list) {
        if (list.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('Không có truyện')),
          );
        }

        return SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final comic = list[index];
              return _buildComicItem(context, comic);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 230,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => SizedBox(
        height: 100,
        child: Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildComicItem(BuildContext context, ComicModel comic) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => context.push('/comic/${comic.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CachedNetworkImage(
                    imageUrl: comic.thumbUrl,
                    fit: BoxFit.cover,
                    width: 120,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).cardColor,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
            // Title
            Text(
              comic.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            // Latest Chapter
            if (comic.chaptersLatest != null && comic.chaptersLatest!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Ch. ${comic.chaptersLatest!.first.chapterName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
