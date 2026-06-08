import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/providers/server_source_provider.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSource = ref.watch(serverSourceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final isMangaDex = activeSource == ServerSource.mangadex;
    final tabCount = isMangaDex ? 4 : 3;

    return DefaultTabController(
      key: ValueKey(activeSource), // Recreates TabController and resets index when source changes
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          title: PopupMenuButton<ServerSource>(
            offset: const Offset(0, 40),
            position: PopupMenuPosition.under,
            tooltip: 'Chọn nguồn truyện',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (source) {
              ref.read(serverSourceProvider.notifier).setSource(source);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ServerSource.otruyen,
                child: Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 18, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text('OTruyen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ServerSource.mangadex,
                child: Row(
                  children: [
                    Icon(Icons.dns_outlined, size: 18, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text('MangaDex', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories, color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 8),
                Text(
                  activeSource == ServerSource.otruyen ? 'RockyDex (OTruyen)' : 'RockyDex (MangaDex)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.1,
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
            dividerColor: Colors.transparent,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'Cập nhật'),
              const Tab(text: 'Truyện mới'),
              if (isMangaDex) const Tab(text: 'Đánh giá cao'),
              const Tab(text: 'Theo dõi'),
            ],
            indicatorColor: AppColors.primaryBlue,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 0: Cập nhật
            const HomeTabList(listType: ApiConstants.listNew),
            // Tab 1: Truyện mới
            const HomeTabList(listType: ApiConstants.listFeatured),
            // Tab 2 (MangaDex only): Đánh giá cao
            if (isMangaDex)
              const HomeTabList(listType: ApiConstants.listMangaDexTopRated),
            // Tab 2 (OTruyen) / Tab 3 (MangaDex): Theo dõi
            const HomeFavoritesTab(),
          ],
        ),
      ),
    );
  }
}

class HomeTabList extends ConsumerStatefulWidget {
  final String listType;

  const HomeTabList({super.key, required this.listType});

  @override
  ConsumerState<HomeTabList> createState() => _HomeTabListState();
}

class _HomeTabListState extends ConsumerState<HomeTabList> {
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
    // Featured list doesn't paginate, so skip pagination for it
    if (widget.listType == ApiConstants.listFeatured) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(homeListProvider(widget.listType).notifier).loadComics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeListProvider(widget.listType));

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
                onPressed: () => ref.read(homeListProvider(widget.listType).notifier).refresh(),
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

    return RefreshIndicator(
      onRefresh: () => ref.read(homeListProvider(widget.listType).notifier).refresh(),
      color: AppColors.primaryBlue,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Banner Carousel (only visible at top of screen)
          if (state.comics.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  HomeBannerCarousel(featuredComics: state.comics),
                  const SizedBox(height: 12),
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
      ),
    );
  }
}

class HomeFavoritesTab extends ConsumerStatefulWidget {
  const HomeFavoritesTab({super.key});

  @override
  ConsumerState<HomeFavoritesTab> createState() => _HomeFavoritesTabState();
}

class _HomeFavoritesTabState extends ConsumerState<HomeFavoritesTab> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(libraryFavoritesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(libraryFavoritesProvider),
      color: AppColors.primaryBlue,
      child: favoritesAsync.when(
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
      ),
    );
  }
}
