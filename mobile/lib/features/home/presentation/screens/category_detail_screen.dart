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

  void _showFilterPicker(BuildContext context, CategoryComicsState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final notifier = ref.read(categoryComicsProvider(widget.categorySlug).notifier);

            final statuses = [
              {'name': 'Tất cả trạng thái', 'value': 'all'},
              {'name': 'Đang tiến hành', 'value': 'ongoing'},
              {'name': 'Hoàn thành', 'value': 'completed'},
            ];

            final years = [
              {'name': 'Tất cả năm', 'value': 'all'},
              {'name': 'Năm 2026', 'value': '2026'},
              {'name': 'Năm 2025', 'value': '2025'},
              {'name': 'Năm 2024', 'value': '2024'},
              {'name': 'Năm 2023', 'value': '2023'},
              {'name': 'Năm 2022', 'value': '2022'},
              {'name': 'Năm 2021', 'value': '2021'},
              {'name': 'Trước 2021', 'value': 'before_2021'},
            ];

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ Lọc Truyện',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextButton(
                        onPressed: () {
                          notifier.resetFilters();
                          setModalState(() {});
                          setState(() {});
                        },
                        child: const Text('Đặt lại', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Status Section
                  const Text(
                    'Trạng thái',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((status) {
                      final isSelected = state.selectedStatus == status['value'];
                      return ChoiceChip(
                        label: Text(status['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          notifier.updateStatus(status['value']!);
                          setModalState(() {});
                          setState(() {});
                        },
                        selectedColor: AppColors.primaryBlue.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Year Section
                  const Text(
                    'Năm phát hành',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: years.map((year) {
                      final isSelected = state.selectedYear == year['value'];
                      return ChoiceChip(
                        label: Text(year['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          notifier.updateYear(year['value']!);
                          setModalState(() {});
                          setState(() {});
                        },
                        selectedColor: AppColors.primaryBlue.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveFiltersBar(CategoryComicsState state) {
    final notifier = ref.read(categoryComicsProvider(widget.categorySlug).notifier);

    final statusLabel = {
      'all': '',
      'ongoing': 'Đang ra',
      'completed': 'Hoàn thành',
    }[state.selectedStatus]!;

    final yearLabel = {
      'all': '',
      '2026': 'Năm 2026',
      '2025': 'Năm 2025',
      '2024': 'Năm 2024',
      '2023': 'Năm 2023',
      '2022': 'Năm 2022',
      '2021': 'Năm 2021',
      'before_2021': 'Trước 2021',
    }[state.selectedYear]!;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (state.selectedStatus != 'all')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text(statusLabel, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                side: const BorderSide(color: AppColors.primaryBlue, width: 0.5),
                onDeleted: () {
                  notifier.updateStatus('all');
                  setState(() {});
                },
              ),
            ),
          if (state.selectedYear != 'all')
            InputChip(
              label: Text(yearLabel, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
              side: const BorderSide(color: AppColors.primaryBlue, width: 0.5),
              onDeleted: () {
                notifier.updateYear('all');
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryComicsProvider(widget.categorySlug));
    final hasActiveFilter = state.selectedStatus != 'all' || state.selectedYear != 'all';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasActiveFilter ? AppColors.primaryBlue : null,
            ),
            onPressed: () => _showFilterPicker(context, state),
          ),
        ],
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

    final filteredList = state.filteredComics;

    if (filteredList.isEmpty) {
      return Column(
        children: [
          if (state.selectedStatus != 'all' || state.selectedYear != 'all')
            _buildActiveFiltersBar(state),
          const Expanded(
            child: Center(
              child: Text('Không tìm thấy kết quả phù hợp'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (state.selectedStatus != 'all' || state.selectedYear != 'all')
          _buildActiveFiltersBar(state),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
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
                      final comic = filteredList[index];
                      return ComicGridCard(comic: comic);
                    },
                    childCount: filteredList.length,
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
          ),
        ),
      ],
    );
  }
}
