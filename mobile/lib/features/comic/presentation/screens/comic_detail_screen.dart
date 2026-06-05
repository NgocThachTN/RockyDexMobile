import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/comic_detail_model.dart';
import '../comic_detail_providers.dart';

class ComicDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const ComicDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends ConsumerState<ComicDetailScreen> {
  bool _isDescriptionExpanded = false;
  bool _isChapterAscending = false; // default descending

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(comicDetailProvider(widget.slug));
    final historyAsync = ref.watch(comicHistoryProvider(widget.slug));
    final favState = ref.watch(favoriteNotifierProvider(widget.slug));


    return Scaffold(
      body: detailAsync.when(
        data: (comic) {
          // Flatten chapters list
          final chaptersList = comic.chapters.isNotEmpty
              ? comic.chapters.first.serverData
              : <ChapterModel>[];

          final sortedChapters = _isChapterAscending
              ? chaptersList.reversed.toList()
              : chaptersList.toList();

          return CustomScrollView(
            slivers: [
              // 1. Sleek Flat Header (Banner & Back)
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blur/Dark Cover Banner
                      CachedNetworkImage(
                        imageUrl: comic.thumbUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(color: Colors.black.withOpacity(0.65)),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: favState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            favState.isFav ? Icons.bookmark : Icons.bookmark_border,
                            color: favState.isFav ? AppColors.primaryBlue : Colors.white,
                          ),
                    onPressed: () {
                      ref.read(favoriteNotifierProvider(widget.slug).notifier).toggleFavorite(comic);
                    },
                  ),
                ],
              ),

              // 2. Comic Info Detail
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overlaid Cover
                          Container(
                            width: 100,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: CachedNetworkImage(
                                imageUrl: comic.thumbUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comic.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  comic.author.isNotEmpty ? comic.author.join(', ') : 'Chưa cập nhật tác giả',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: comic.status == 'ongoing'
                                        ? AppColors.primaryBlue.withOpacity(0.15)
                                        : AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    comic.status == 'ongoing' ? 'Đang ra' : 'Hoàn thành',
                                    style: TextStyle(
                                      color: comic.status == 'ongoing'
                                          ? AppColors.primaryBlue
                                          : AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Genres
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: comic.category.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),

                      // Actions: Read Buttons
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: historyAsync.when(
                              data: (history) {
                                final hasHistory = history != null;
                                final label = hasHistory
                                    ? 'ĐỌC TIẾP (Ch. ${history['chapter_name']})'
                                    : 'ĐỌC TỪ ĐẦU';
                                return ElevatedButton(
                                  onPressed: () {
                                    if (chaptersList.isEmpty) return;
                                    if (hasHistory) {
                                      // Resume
                                      final targetChapter = chaptersList.firstWhere(
                                        (element) => element.chapterSlug == history['chapter_slug'],
                                        orElse: () => chaptersList.last,
                                      );
                                      context.push(
                                        '/reader/${widget.slug}/${targetChapter.chapterSlug}',
                                        extra: targetChapter.chapterApiData,
                                      );
                                    } else {
                                      // Read First (which is usually the last element in standard order, wait, OTruyen API list order: usually index 0 is chap 1, or last is chap 1. In details response, index 0 is typically Chapter 1, but we should make sure. Let's see: in Kingdom response we saw server_data had index 0 as chap 1, index 1 as chap 2. Yes! So chaptersList.first is chapter 1, chaptersList.last is latest.)
                                      final firstChapter = chaptersList.first;
                                      context.push(
                                        '/reader/${widget.slug}/${firstChapter.chapterSlug}',
                                        extra: firstChapter.chapterApiData,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                              loading: () => const SizedBox(
                                height: 48,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              error: (e, s) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),

                      // Description
                      const SizedBox(height: 20),
                      Text(
                        'Nội dung',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stripe HTML tags from content or show standard Text
                            Text(
                              comic.content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim(),
                              maxLines: _isDescriptionExpanded ? null : 3,
                              overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chapter List Header
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách chương (${chaptersList.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: Icon(_isChapterAscending ? Icons.arrow_upward : Icons.arrow_downward),
                            onPressed: () {
                              setState(() {
                                _isChapterAscending = !_isChapterAscending;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Chapters list
              sortedChapters.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: Text('Đang cập nhật chương')),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final chap = sortedChapters[index];
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(
                                  'Chương ${chap.chapterName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: chap.chapterTitle.isNotEmpty
                                    ? Text(
                                        chap.chapterTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                trailing: const Icon(Icons.chevron_right, size: 18),
                                onTap: () {
                                  context.push(
                                    '/reader/${widget.slug}/${chap.chapterSlug}',
                                    extra: chap.chapterApiData,
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(color: Theme.of(context).dividerColor, height: 1),
                              ),
                            ],
                          );
                        },
                        childCount: sortedChapters.length,
                      ),
                    ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Đã có lỗi xảy ra: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(comicDetailProvider(widget.slug));
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
