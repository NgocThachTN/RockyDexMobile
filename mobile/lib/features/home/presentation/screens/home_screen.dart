import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/update_service.dart';
import '../home_notifier.dart';
import '../widgets/comic_grid_card.dart';
import '../widgets/home_banner_carousel.dart';
import '../../../library/presentation/library_providers.dart';
import '../../domain/comic_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Default to "Mới cập nhật" (listNew) on startup
      ref.read(homeProvider.notifier).selectListType(ApiConstants.listNew);
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    // Trigger rebuild to update tab body
    setState(() {});

    if (_tabController.index == 0) {
      ref.read(homeProvider.notifier).selectListType(ApiConstants.listNew);
    } else if (_tabController.index == 1) {
      ref.read(homeProvider.notifier).selectListType(ApiConstants.listFeatured);
    } else if (_tabController.index == 2) {
      ref.invalidate(libraryFavoritesProvider);
    }
  }

  void _onScroll() {
    if (_tabController.index == 2) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(homeProvider.notifier).loadComics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 8),
            const Text(
              'RockyDex',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () => context.go('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Mới cập nhật'),
            Tab(text: 'Truyện mới'),
            Tab(text: 'Theo dõi'),
          ],
          indicatorColor: AppColors.primaryBlue,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_tabController.index == 2) {
            ref.invalidate(libraryFavoritesProvider);
          } else {
            await ref.read(homeProvider.notifier).refresh();
          }
        },
        child: Column(
          children: [
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
    if (_tabController.index == 2) {
      return _buildFavoritesGrid();
    }

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
                        : 'Mới Cập Nhật',
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

  // Build the local favorites/following list grid
  Widget _buildFavoritesGrid() {
    final favoritesAsync = ref.watch(libraryFavoritesProvider);

    return favoritesAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('Chưa có truyện theo dõi'),
          );
        }

        return GridView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final slug = item['comic_slug'] ?? item['slug'] ?? '';
            final name = item['comic_name'] ?? item['name'] ?? '';
            final thumb = item['comic_thumb'] ?? item['thumb_url'] ?? '';
            final status = item['status'] ?? 'ongoing';

            final comic = ComicModel(
              id: item['comic_id'] ?? slug,
              name: name,
              slug: slug,
              originName: const [],
              status: status,
              thumbUrl: thumb,
              category: const [],
              updatedAt: '',
              chaptersLatest: const [],
            );

            return ComicGridCard(comic: comic);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
      ),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
    );
  }
}
