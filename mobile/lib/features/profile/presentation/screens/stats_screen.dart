import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../library/presentation/library_providers.dart';
import '../../../library/data/library_repository.dart';

final readingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  try {
    await repo.syncFavorites();
    await repo.syncHistory();
  } catch (_) {}

  final favorites = await LocalStorage.getFavorites();
  final history = await LocalStorage.getHistoryList();
  
  final uniqueComicsRead = history.map((e) => e['comic_slug']).toSet().length;
  
  final totalChaptersRead = history.fold<int>(0, (sum, item) {
    final progress = item['progress_percent'] as int? ?? 0;
    return sum + (progress / 10).floor() + 1;
  });

  return {
    'total_comics_read': uniqueComicsRead,
    'total_favorites': favorites.length,
    'chapters_read': totalChaptersRead,
  };
});

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(libraryHistoryProvider);
    ref.invalidate(libraryFavoritesProvider);
    ref.invalidate(readingStatsProvider);
    await ref.read(readingStatsProvider.future);
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Vừa xong';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inSeconds < 60) {
        return 'Vừa xong';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} phút trước';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} giờ trước';
      } else if (diff.inDays == 1) {
        return 'Hôm qua';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      } else {
        return DateFormat('dd/MM/yyyy').format(dt);
      }
    } catch (_) {
      return 'Chưa rõ';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(readingStatsProvider);
    final historyAsync = ref.watch(libraryHistoryProvider);
    final favoritesAsync = ref.watch(libraryFavoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Thống kê đọc truyện',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryBlue,
        child: Column(
          children: [
            // 1. Dashboard card (Overview metrics)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildDashboardCard(isDark, statsAsync),
            ),
            const SizedBox(height: 12),

            // 2. Custom Styled TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primaryBlue,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Lịch sử đọc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Yêu thích', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. TabBarView for Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Lịch sử đọc
                  _buildHistoryTab(historyAsync),

                  // Tab 2: Yêu thích
                  _buildFavoritesTab(favoritesAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(bool isDark, AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: statsAsync.when(
        data: (stats) {
          final comicsRead = stats['total_comics_read'] ?? 0;
          final favoritesCount = stats['total_favorites'] ?? 0;
          final chaptersRead = stats['chapters_read'] ?? 0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.menu_book_rounded,
                value: '$comicsRead',
                label: 'Truyện đã đọc',
                color: AppColors.primaryBlue,
              ),
              _buildVerticalDivider(isDark),
              _buildStatItem(
                icon: Icons.favorite_rounded,
                value: '$favoritesCount',
                label: 'Yêu thích',
                color: Colors.redAccent,
              ),
              _buildVerticalDivider(isDark),
              _buildStatItem(
                icon: Icons.auto_stories_rounded,
                value: '$chaptersRead',
                label: 'Chương đã đọc',
                color: Colors.orangeAccent,
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
          ),
        ),
        error: (err, _) => Center(
          child: Text('Lỗi tải dữ liệu: $err', style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 45,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
    );
  }

  Widget _buildHistoryTab(AsyncValue<List<Map<String, dynamic>>> historyAsync) {
    return historyAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Chưa có lịch sử đọc truyện', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.52,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final slug = item['comic_slug'] ?? '';
            final name = item['comic_name'] ?? '';
            final thumb = item['comic_thumb'] ?? '';
            final chapName = item['chapter_name'] ?? '';
            final progress = item['progress_percent'] as int? ?? 0;
            final lastRead = item['last_read_at'] as String?;

            return GestureDetector(
              onTap: () => context.push('/comic/$slug'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image with overlay
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                    width: 0.8,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: CachedNetworkImage(
                                    imageUrl: thumb,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fadeInDuration: const Duration(milliseconds: 250),
                                    placeholder: (context, url) => Container(
                                      color: Theme.of(context).cardColor,
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Theme.of(context).cardColor,
                                      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Progress Bar overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Tiến độ: $progress%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progress / 100.0,
                                    backgroundColor: Colors.transparent,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                    minHeight: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Fast Read overlay Button
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                final chapterSlug = item['chapter_slug'] as String? ?? '';
                                if (chapterSlug.isNotEmpty) {
                                  context.push(
                                    '/reader/$slug/$chapterSlug',
                                    extra: {
                                      'comic_name': name,
                                      'comic_thumb': thumb,
                                      'chapter_name': chapName,
                                    },
                                  );
                                } else {
                                  context.push('/comic/$slug');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    // Chapter Name
                    Text(
                      'Chương $chapName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(height: 1),
                    // Relative Time
                    Text(
                      _formatRelativeTime(lastRead),
                      style: const TextStyle(color: Colors.grey, fontSize: 8),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
      ),
      error: (err, _) => Center(child: Text('Lỗi: $err')),
    );
  }

  Widget _buildFavoritesTab(AsyncValue<List<Map<String, dynamic>>> favoritesAsync) {
    return favoritesAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Chưa có truyện yêu thích', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.52,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final slug = item['slug'] ?? item['comic_slug'] ?? '';
            final name = item['name'] ?? item['comic_name'] ?? '';
            final thumb = item['thumb_url'] ?? item['comic_thumb'] ?? '';
            final createdAt = item['created_at'] as String?;

            return GestureDetector(
              onTap: () => context.push('/comic/$slug'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 0.8,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: CachedNetworkImage(
                              imageUrl: thumb,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              fadeInDuration: const Duration(milliseconds: 250),
                              placeholder: (context, url) => Container(
                                color: Theme.of(context).cardColor,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Theme.of(context).cardColor,
                                child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    // Favorite date
                    Text(
                      createdAt != null && createdAt.isNotEmpty
                          ? 'Thích từ: ${_formatDate(createdAt)}'
                          : 'Yêu thích',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 9),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
      ),
      error: (err, _) => Center(child: Text('Lỗi: $err')),
    );
  }
}
