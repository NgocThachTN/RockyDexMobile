import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../home_notifier.dart';
import '../widgets/home_filter_section.dart';
import '../widgets/comic_grid_card.dart';
import '../widgets/home_banner_carousel.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_stories, color: AppColors.primaryBlue, size: 28),
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
            // 1. Tag Filters Section (Extracted Component)
            HomeFilterSection(state: state),
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

  // Build the comic grid layout body
  Widget _buildGridBody(HomeState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        // Banner Carousel (only visible when not filtering by category and at page 1)
        if (state.selectedCategorySlug.isEmpty && state.comics.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                HomeBannerCarousel(featuredComics: state.comics),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    state.selectedListType == ApiConstants.listFeatured
                        ? 'Truyện Đề Xuất'
                        : (state.selectedListType == ApiConstants.listNew
                            ? 'Mới Cập Nhật'
                            : (state.selectedListType == ApiConstants.listOngoing
                                ? 'Đang Tiến Hành'
                                : 'Đã Hoàn Thành')),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

        // 2x2 Grid Layout
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final comic = state.comics[index];
                // Reuse ComicGridCard component
                return ComicGridCard(comic: comic);
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
}
