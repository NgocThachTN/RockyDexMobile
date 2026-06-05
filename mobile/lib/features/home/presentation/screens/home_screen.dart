import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/comic_model.dart';
import '../home_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(homeProvider.notifier).loadComics();
    }
  }

  // Opens a beautiful bottom sheet containing a grid of categories/genres
  void _showCategoriesBottomSheet(BuildContext context, HomeState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tất Cả Thể Loại',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final cat = state.categories[index];
                    final isSelected = state.selectedCategorySlug == cat.slug;

                    return InkWell(
                      onTap: () {
                        ref.read(homeProvider.notifier).selectCategory(cat.slug);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue.withOpacity(0.12)
                              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : (isDark ? Colors.white : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_stories, color: AppColors.primaryBlue, size: 28),
            const SizedBox(width: 8),
            const Text(
              'RockyDex',
              style: TextStyle(
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
        onRefresh: () => ref.read(homeProvider.notifier).refresh(),
        child: Column(
          children: [
            // 1. Tag Filters Row
            _buildFiltersSection(state, isDark),
            const Divider(height: 1),

            // 2. Comics Grid List
            Expanded(
              child: _buildGridBody(state),
            ),
          ],
        ),
      ),
    );
  }

  // Build the horizontally scrollable tag filters for both List Types & Genres
  Widget _buildFiltersSection(HomeState state, bool isDark) {
    final listFilters = [
      {'label': 'Truyện Nổi Bật', 'type': ApiConstants.listFeatured},
      {'label': 'Mới Cập Nhật', 'type': ApiConstants.listNew},
      {'label': 'Đang Tiến Hành', 'type': ApiConstants.listOngoing},
      {'label': 'Đã Hoàn Thành', 'type': ApiConstants.listCompleted},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List type tabs
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: listFilters.length,
              itemBuilder: (context, index) {
                final filter = listFilters[index];
                final isSelected = state.selectedListType == filter['type'] && !state.isCategoryFilterActive;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(homeProvider.notifier).selectListType(filter['type']!);
                      }
                    },
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    selectedColor: AppColors.primaryBlue.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : (isDark ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Genre selection tags
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // "All categories" drawer button
                ActionChip(
                  avatar: const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.primaryBlue),
                  label: const Text('Thể loại'),
                  onPressed: () => _showCategoriesBottomSheet(context, state),
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),

                // "All Comics / Clear Category" button if active
                if (state.isCategoryFilterActive) ...[
                  InputChip(
                    label: const Text('Tất cả'),
                    onDeleted: () => ref.read(homeProvider.notifier).clearCategory(),
                    onPressed: () => ref.read(homeProvider.notifier).clearCategory(),
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Dynamic Category chips (first 10 categories)
                ...state.categories.take(12).map((cat) {
                  final isSelected = state.selectedCategorySlug == cat.slug;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(homeProvider.notifier).selectCategory(cat.slug);
                        } else {
                          ref.read(homeProvider.notifier).clearCategory();
                        }
                      },
                      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      selectedColor: AppColors.primaryBlue.withOpacity(0.15),
                      checkmarkColor: AppColors.primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : (isDark ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the comic grid layout body
  Widget _buildGridBody(HomeState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
      );
    }

    if (state.error != null && state.comics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lỗi: ${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(homeProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.comics.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả phù hợp'),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 2x2 Grid Layout
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.61,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final comic = state.comics[index];
                return _buildComicGridCard(context, comic);
              },
              childCount: state.comics.length,
            ),
          ),
        ),

        // Loader at the bottom when loading more
        if (state.isLoadMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
              ),
            ),
          ),
      ],
    );
  }

  // Build a premium card item for the 2-column grid list
  Widget _buildComicGridCard(BuildContext context, ComicModel comic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
