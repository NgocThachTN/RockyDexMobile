import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../../home/domain/comic_model.dart';
import '../search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial query passed from home page genre filter if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extraGenre = GoRouterState.of(context).extra as String?;
      if (extraGenre != null) {
        _searchController.text = extraGenre;
        ref.read(searchProvider.notifier).search(extraGenre);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchProvider.notifier).search(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm truyện...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).search('');
                    },
                  )
                : null,
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {}); // refresh to show/hide clear button
          },
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: _searchController.text.isEmpty && searchState.history.isNotEmpty
                ? _buildSearchHistory(searchState.history)
                : _buildSearchResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory(List<String> history) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch sử tìm kiếm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  ref.read(searchProvider.notifier).clearHistory();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.map((query) {
              return ActionChip(
                label: Text(query),
                onPressed: () {
                  _searchController.text = query;
                  _submitSearch(query);
                },
                backgroundColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            state.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    if (state.results.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả phù hợp'),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.61,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: state.results.length + (state.isLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.results.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
            ),
          );
        }

        final comic = state.results[index];
        return _buildSearchGridCard(context, comic, isDark);
      },
    );
  }

  Widget _buildSearchGridCard(BuildContext context, ComicModel comic, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/comic/${comic.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image block
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: comic.thumbUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
                        child: const Icon(Icons.broken_image, size: 28),
                      ),
                    ),
                    // Status Badge overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: (comic.status == 'ongoing'
                                  ? AppColors.primaryBlue
                                  : AppColors.success)
                              .withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comic.status == 'ongoing' ? 'Đang ra' : 'Xong',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Metadata content block
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Latest Chapter Badge
                      if (comic.chaptersLatest != null && comic.chaptersLatest!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ch. ${comic.chaptersLatest!.first.chapterName}',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Action button indicator
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
