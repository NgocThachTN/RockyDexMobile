import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../category_screen_providers.dart';
import '../widgets/comic_grid_card.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categorySlug;
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.categorySlug,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
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
      ref.read(categoryComicsProvider(widget.categorySlug).notifier).loadComics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryComicsProvider(widget.categorySlug));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(categoryComicsProvider(widget.categorySlug).notifier).loadComics(reset: true),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(CategoryComicsState state) {
    if (state.isLoading && state.comics.isEmpty) {
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
                onPressed: () => ref.read(categoryComicsProvider(widget.categorySlug).notifier).loadComics(reset: true),
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
        child: Text('Không có truyện nào thuộc thể loại này'),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
