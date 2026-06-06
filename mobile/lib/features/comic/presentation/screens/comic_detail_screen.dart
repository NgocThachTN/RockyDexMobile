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
                          // Overlaid Cover with Shadow
                          Container(
                            width: 105,
                            height: 145,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.5),
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
                                        height: 1.2,
                                      ),
                                ),
                                if (comic.originName.isNotEmpty && comic.originName.first.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    comic.originName.join(', '),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 15,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        comic.author.isNotEmpty ? comic.author.join(', ') : 'Chưa cập nhật tác giả',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Square-cornered Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: comic.status == 'ongoing'
                                        ? AppColors.primaryBlue.withOpacity(0.12)
                                        : AppColors.success.withOpacity(0.12),
                                    border: Border.all(
                                      color: comic.status == 'ongoing'
                                          ? AppColors.primaryBlue.withOpacity(0.5)
                                          : AppColors.success.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    comic.status == 'ongoing' ? 'ĐANG RA' : 'HOÀN THÀNH',
                                    style: TextStyle(
                                      color: comic.status == 'ongoing'
                                          ? AppColors.primaryBlue
                                          : AppColors.success,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Genres (Clickable tags that navigate to the Category Details)
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: comic.category.map((cat) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.push('/categories/${cat.slug}', extra: cat.name);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor.withOpacity(0.8),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Actions: Read Buttons with Icons
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
                                return ElevatedButton.icon(
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
                                      // Read First
                                      final firstChapter = chaptersList.first;
                                      context.push(
                                        '/reader/${widget.slug}/${firstChapter.chapterSlug}',
                                        extra: firstChapter.chapterApiData,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    hasHistory ? Icons.shortcut_rounded : Icons.play_arrow_rounded,
                                    size: 20,
                                  ),
                                  label: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                    shadowColor: AppColors.primaryBlue.withOpacity(0.3),
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

                      // Beautiful Description Box
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nội dung',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
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
                                  Text(
                                    comic.content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim(),
                                    maxLines: _isDescriptionExpanded ? null : 3,
                                    overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          height: 1.5,
                                          fontSize: 13.5,
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                                        style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        _isDescriptionExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ],
                                  ),
                                ],
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
                          final history = historyAsync.valueOrNull;
                          final isLastRead = history != null && history['chapter_slug'] == chap.chapterSlug;

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(
                                  'Chương ${chap.chapterName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isLastRead ? AppColors.primaryBlue : null,
                                  ),
                                ),
                                subtitle: chap.chapterTitle.isNotEmpty
                                    ? Text(
                                        chap.chapterTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isLastRead ? AppColors.primaryBlue.withOpacity(0.7) : null,
                                        ),
                                      )
                                    : null,
                                trailing: isLastRead
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.primaryBlue, width: 1),
                                        ),
                                        child: const Text(
                                          'Đang đọc',
                                          style: TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right, size: 18),
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
