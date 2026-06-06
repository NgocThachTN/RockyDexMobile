import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../home/presentation/widgets/comic_grid_card.dart';
import '../search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial query passed from home page genre filter if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extraGenre = GoRouterState.of(context).extra as String?;
      if (extraGenre != null) {
        _searchController.text = extraGenre;
        ref.read(searchProvider.notifier).search(extraGenre, saveToHistory: true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
      ref.read(searchProvider.notifier).search(query.trim(), saveToHistory: true);
    }
  }

  void _showCountryFilterPicker(BuildContext context, SearchState state) {
    final countries = [
      {'name': 'Tất cả quốc gia', 'value': 'all'},
      {'name': 'Nhật Bản (Manga)', 'value': 'japan'},
      {'name': 'Trung Quốc (Manhua)', 'value': 'china'},
      {'name': 'Hàn Quốc (Manhwa)', 'value': 'korea'},
      {'name': 'Việt Nam', 'value': 'vietnam'},
    ];

    _showPicker(
      context,
      title: 'Chọn Quốc Gia',
      options: countries,
      selectedValue: state.selectedCountry,
      onSelected: (val) {
        ref.read(searchProvider.notifier).updateCountry(val);
      },
    );
  }

  void _showStatusFilterPicker(BuildContext context, SearchState state) {
    final statuses = [
      {'name': 'Mọi tình trạng', 'value': 'all'},
      {'name': 'Đang phát hành', 'value': 'ongoing'},
      {'name': 'Hoàn thành', 'value': 'completed'},
      {'name': 'Sắp ra mắt', 'value': 'coming_soon'},
    ];

    _showPicker(
      context,
      title: 'Chọn Tình Trạng',
      options: statuses,
      selectedValue: state.selectedStatus,
      onSelected: (val) {
        ref.read(searchProvider.notifier).updateStatus(val);
      },
    );
  }

  void _showYearFilterPicker(BuildContext context, SearchState state) {
    final years = [
      {'name': 'Mọi năm', 'value': 'all'},
      {'name': 'Năm 2026', 'value': '2026'},
      {'name': 'Năm 2025', 'value': '2025'},
      {'name': 'Năm 2024', 'value': '2024'},
      {'name': 'Năm 2023', 'value': '2023'},
      {'name': 'Năm 2022', 'value': '2022'},
      {'name': 'Năm 2021', 'value': '2021'},
      {'name': 'Trước 2021', 'value': 'before_2021'},
    ];

    _showPicker(
      context,
      title: 'Chọn Năm Phát Hành',
      options: years,
      selectedValue: state.selectedYear,
      onSelected: (val) {
        ref.read(searchProvider.notifier).updateYear(val);
      },
    );
  }

  void _showPicker(
    BuildContext context, {
    required String title,
    required List<Map<String, String>> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((opt) {
                    final isSelected = opt['value'] == selectedValue;
                    return ListTile(
                      title: Text(
                        opt['name']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryBlue : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                          : null,
                      onTap: () {
                        onSelected(opt['value']!);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(SearchState state) {
    final hasActiveFilter = state.selectedCountry != 'all' ||
        state.selectedStatus != 'all' ||
        state.selectedYear != 'all';

    final countryLabel = {
      'all': 'Tất cả quốc gia',
      'japan': 'Nhật Bản (Manga)',
      'china': 'Trung Quốc (Manhua)',
      'korea': 'Hàn Quốc (Manhwa)',
      'vietnam': 'Việt Nam',
    }[state.selectedCountry]!;

    final statusLabel = {
      'all': 'Mọi tình trạng',
      'ongoing': 'Đang phát hành',
      'completed': 'Hoàn thành',
      'coming_soon': 'Sắp ra mắt',
    }[state.selectedStatus]!;

    final yearLabel = {
      'all': 'Mọi năm',
      '2026': 'Năm 2026',
      '2025': 'Năm 2025',
      '2024': 'Năm 2024',
      '2023': 'Năm 2023',
      '2022': 'Năm 2022',
      '2021': 'Năm 2021',
      'before_2021': 'Trước 2021',
    }[state.selectedYear]!;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  context,
                  label: countryLabel,
                  isActive: state.selectedCountry != 'all',
                  onTap: () => _showCountryFilterPicker(context, state),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: statusLabel,
                  isActive: state.selectedStatus != 'all',
                  onTap: () => _showStatusFilterPicker(context, state),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: yearLabel,
                  isActive: state.selectedYear != 'all',
                  onTap: () => _showYearFilterPicker(context, state),
                ),
              ],
            ),
          ),
          if (hasActiveFilter) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryBlue),
              tooltip: 'Đặt lại bộ lọc',
              onPressed: () {
                ref.read(searchProvider.notifier).resetFilters();
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withOpacity(0.12)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primaryBlue
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.18)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? AppColors.primaryBlue : Colors.grey,
            ),
          ],
        ),
      ),
    );
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
                      ref.read(searchProvider.notifier).search('', saveToHistory: false);
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {}); // refresh clear button
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              ref.read(searchProvider.notifier).search(val, saveToHistory: false);
            });
          },
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Column(
        children: [
          if (_searchController.text.isNotEmpty) _buildFilterBar(searchState),
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
                  ref.read(searchProvider.notifier).search(query, saveToHistory: true);
                  setState(() {});
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
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue));
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

    final filteredList = state.filteredResults;

    if (filteredList.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả phù hợp'),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredList.length + (state.isLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredList.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
            ),
          );
        }

        final comic = filteredList[index];
        return ComicGridCard(comic: comic);
      },
    );
  }
}
