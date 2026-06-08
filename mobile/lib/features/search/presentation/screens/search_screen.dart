import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/providers/server_source_provider.dart';
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

  Widget _buildFilterBar(SearchState state) {
    final notifier = ref.read(searchProvider.notifier);
    final isMangaDex = state.isMangaDex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> activeChips = [];

    // Country (OTruyen only)
    if (!isMangaDex && state.selectedCountry != 'all') {
      final label = {
        'japan': 'Nhật Bản',
        'china': 'Trung Quốc',
        'korea': 'Hàn Quốc',
        'vietnam': 'Việt Nam',
      }[state.selectedCountry] ?? state.selectedCountry;
      activeChips.add(_buildActiveChip('Quốc gia: $label', () => notifier.updateCountry('all'), isDark));
    }

    // Status
    if (state.selectedStatus != 'all') {
      final label = isMangaDex
          ? {
              'ongoing': 'Đang tiến hành',
              'completed': 'Đã hoàn thành',
              'hiatus': 'Tạm ngưng',
              'cancelled': 'Đã hủy',
            }[state.selectedStatus]
          : {
              'ongoing': 'Đang phát hành',
              'completed': 'Hoàn thành',
              'coming_soon': 'Sắp ra mắt',
            }[state.selectedStatus];
      activeChips.add(_buildActiveChip('Trạng thái: $label', () => notifier.updateStatus('all'), isDark));
    }

    // Year
    if (state.selectedYear != 'all') {
      final label = state.selectedYear == 'before_2021' ? 'Trước 2021' : 'Năm ${state.selectedYear}';
      activeChips.add(_buildActiveChip(label, () => notifier.updateYear('all'), isDark));
    }

    // Sort (MangaDex only)
    if (isMangaDex && state.selectedSortBy != 'latestUploadedChapter') {
      final label = {
        'relevance': 'Nổi bật',
        'rating': 'Đánh giá cao',
        'followedCount': 'Theo dõi nhiều',
      }[state.selectedSortBy] ?? state.selectedSortBy;
      activeChips.add(_buildActiveChip('Sắp xếp: $label', () => notifier.updateSortBy('latestUploadedChapter'), isDark));
    }

    // Genres (MangaDex only)
    if (isMangaDex && state.selectedGenres.isNotEmpty) {
      final Map<String, String> mangaDexGenres = {
        '391b0423-d847-456f-aff0-8b0cfc03066b': 'Hành động',
        '87cc8738-c691-4e19-b903-94c5cdad9c15': 'Phiêu lưu',
        '4d32cc48-9f00-4cca-9b5a-a839f0764984': 'Hài hước',
        'b9cafd37-9a11-4fa3-b78a-c778e521955b': 'Kịch tính',
        'cdc58593-abb3-4ddc-8d40-6aab3f661725': 'Giả tưởng',
        'cdad7e68-1419-41ed-bd5e-4b2073d81b9b': 'Kinh dị',
        'ee968100-4191-4968-93d3-f57e75581a31': 'Bí ẩn',
        '423e2eae-977e-4c4b-98ee-99d613c2e787': 'Lãng mạn',
        '256c8064-7c37-4b30-be3f-2735d4d97c6c': 'Sci-Fi',
        'e5301a23-ebd9-49dd-a0cb-2add944c7fe9': 'Đời thường',
        '6997739f-d546-4178-831d-21d0f140bacb': 'Thể thao',
        'eabc5477-179c-48b0-986d-96a87f4d482a': 'Siêu nhiên',
        '5ca13ee5-ae6c-490f-89b2-ed2f8012ccb6': 'Giật gân',
        'f8f62933-140f-4dd3-a2d3-685c2e311cd0': 'Isekai',
        'e197df38-d0e7-43b5-9b09-2842d0c326dd': 'Webtoon',
      };
      for (final gid in state.selectedGenres) {
        final name = mangaDexGenres[gid] ?? 'Thể loại';
        activeChips.add(_buildActiveChip(name, () => notifier.toggleGenre(gid), isDark));
      }
    }

    if (activeChips.isEmpty) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
            const SizedBox(width: 6),
            Text(
              'Chưa áp dụng bộ lọc nào. Chạm vào nút bộ lọc ở góc trên để lọc truyện.',
              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: activeChips,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryBlue),
            tooltip: 'Đặt lại bộ lọc',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              notifier.resetFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onClear, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryBlue, width: 0.8),
        ),
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.only(left: 10, right: 2),
        onDeleted: onClear,
        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.primaryBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final activeSource = ref.watch(serverSourceProvider);
    final sourceName = activeSource == ServerSource.otruyen ? 'OTruyen' : 'MangaDex';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 14, height: 1.2),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm truyện trong $sourceName...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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
              if (_searchController.text.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).search('', saveToHistory: false);
                    setState(() {});
                  },
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: AppColors.primaryBlue),
              tooltip: 'Bộ lọc nâng cao',
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: const FilterDrawer(),
      body: Column(
        children: [
          _buildFilterBar(searchState),
          const Divider(height: 1),
          Expanded(
            child: (searchState.query.isEmpty && !searchState.hasActiveFilter && !searchState.isLoading && searchState.results.isEmpty && searchState.history.isNotEmpty)
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

    if (filteredList.isEmpty) {
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

class FilterDrawer extends ConsumerWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bộ lọc nâng cao',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      notifier.resetFilters();
                    },
                    child: const Text('Đặt lại', style: TextStyle(color: AppColors.primaryBlue, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort (MangaDex only)
                    if (state.isMangaDex) ...[
                      _buildSectionHeader('Sắp xếp theo'),
                      const SizedBox(height: 8),
                      _buildSortSection(state, notifier),
                      const SizedBox(height: 20),
                    ],

                    // Country (OTruyen only)
                    if (!state.isMangaDex) ...[
                      _buildSectionHeader('Quốc gia'),
                      const SizedBox(height: 8),
                      _buildCountrySection(state, notifier),
                      const SizedBox(height: 20),
                    ],

                    // Status
                    _buildSectionHeader('Tình trạng'),
                    const SizedBox(height: 8),
                    _buildStatusSection(state, notifier),
                    const SizedBox(height: 20),

                    // Publication Year
                    _buildSectionHeader('Năm phát hành'),
                    const SizedBox(height: 8),
                    _buildYearSection(state, notifier),
                    const SizedBox(height: 20),

                    // Genres (MangaDex only)
                    if (state.isMangaDex) ...[
                      _buildSectionHeader('Thể loại'),
                      const SizedBox(height: 8),
                      _buildGenresSection(state, notifier),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Apply Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Drawer
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildSortSection(SearchState state, SearchNotifier notifier) {
    final options = [
      {'name': 'Mới cập nhật', 'value': 'latestUploadedChapter'},
      {'name': 'Nổi bật', 'value': 'relevance'},
      {'name': 'Đánh giá cao', 'value': 'rating'},
      {'name': 'Theo dõi nhiều', 'value': 'followedCount'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = state.selectedSortBy == opt['value'];
        return ChoiceChip(
          showCheckmark: false,
          label: Text(opt['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) notifier.updateSortBy(opt['value']!);
          },
          selectedColor: AppColors.primaryBlue.withOpacity(0.12),
          labelStyle: TextStyle(color: isSelected ? AppColors.primaryBlue : null),
        );
      }).toList(),
    );
  }

  Widget _buildCountrySection(SearchState state, SearchNotifier notifier) {
    final options = [
      {'name': 'Tất cả', 'value': 'all'},
      {'name': 'Nhật Bản', 'value': 'japan'},
      {'name': 'Trung Quốc', 'value': 'china'},
      {'name': 'Hàn Quốc', 'value': 'korea'},
      {'name': 'Việt Nam', 'value': 'vietnam'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = state.selectedCountry == opt['value'];
        return ChoiceChip(
          showCheckmark: false,
          label: Text(opt['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) notifier.updateCountry(opt['value']!);
          },
          selectedColor: AppColors.primaryBlue.withOpacity(0.12),
          labelStyle: TextStyle(color: isSelected ? AppColors.primaryBlue : null),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSection(SearchState state, SearchNotifier notifier) {
    final options = state.isMangaDex
        ? [
            {'name': 'Tất cả', 'value': 'all'},
            {'name': 'Đang tiến hành', 'value': 'ongoing'},
            {'name': 'Hoàn thành', 'value': 'completed'},
            {'name': 'Tạm ngưng', 'value': 'hiatus'},
            {'name': 'Đã hủy', 'value': 'cancelled'},
          ]
        : [
            {'name': 'Tất cả', 'value': 'all'},
            {'name': 'Đang phát hành', 'value': 'ongoing'},
            {'name': 'Hoàn thành', 'value': 'completed'},
            {'name': 'Sắp ra mắt', 'value': 'coming_soon'},
          ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = state.selectedStatus == opt['value'];
        return ChoiceChip(
          showCheckmark: false,
          label: Text(opt['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) notifier.updateStatus(opt['value']!);
          },
          selectedColor: AppColors.primaryBlue.withOpacity(0.12),
          labelStyle: TextStyle(color: isSelected ? AppColors.primaryBlue : null),
        );
      }).toList(),
    );
  }

  Widget _buildYearSection(SearchState state, SearchNotifier notifier) {
    final List<Map<String, String>> quickYears = [
      {'name': 'Mọi năm', 'value': 'all'},
    ];
    if (state.isMangaDex) {
      final currentYear = DateTime.now().year;
      for (int y = currentYear; y >= currentYear - 7; y--) {
        quickYears.add({'name': '$y', 'value': y.toString()});
      }
    } else {
      quickYears.addAll([
        {'name': '2026', 'value': '2026'},
        {'name': '2025', 'value': '2025'},
        {'name': '2024', 'value': '2024'},
        {'name': '2023', 'value': '2023'},
        {'name': '2022', 'value': '2022'},
        {'name': '2021', 'value': '2021'},
        {'name': 'Trước 2021', 'value': 'before_2021'},
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickYears.map((opt) {
            final isSelected = state.selectedYear == opt['value'];
            return ChoiceChip(
              showCheckmark: false,
              label: Text(opt['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) notifier.updateYear(opt['value']!);
              },
              selectedColor: AppColors.primaryBlue.withOpacity(0.12),
              labelStyle: TextStyle(color: isSelected ? AppColors.primaryBlue : null),
            );
          }).toList(),
        ),
        if (state.isMangaDex) ...[
          const SizedBox(height: 8),
          _buildOlderYearDropdown(state, notifier),
        ],
      ],
    );
  }

  Widget _buildOlderYearDropdown(SearchState state, SearchNotifier notifier) {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 8;
    final List<String> olderYears = [];
    for (int y = startYear; y >= 1970; y--) {
      olderYears.add(y.toString());
    }

    final isSelectedValueInOlder = olderYears.contains(state.selectedYear);
    final String dropdownValue = isSelectedValueInOlder ? state.selectedYear : 'Năm khác...';

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        isDense: true,
      ),
      value: dropdownValue,
      style: const TextStyle(fontSize: 13, color: AppColors.primaryBlue),
      items: [
        const DropdownMenuItem(value: 'Năm khác...', child: Text('Năm phát hành khác...', style: TextStyle(color: Colors.grey))),
        ...olderYears.map((y) => DropdownMenuItem(value: y, child: Text('Năm $y'))),
      ],
      onChanged: (val) {
        if (val != null && val != 'Năm khác...') {
          notifier.updateYear(val);
        }
      },
    );
  }

  Widget _buildGenresSection(SearchState state, SearchNotifier notifier) {
    final Map<String, String> mangaDexGenres = {
      '391b0423-d847-456f-aff0-8b0cfc03066b': 'Hành động',
      '87cc8738-c691-4e19-b903-94c5cdad9c15': 'Phiêu lưu',
      '4d32cc48-9f00-4cca-9b5a-a839f0764984': 'Hài hước',
      'b9cafd37-9a11-4fa3-b78a-c778e521955b': 'Kịch tính',
      'cdc58593-abb3-4ddc-8d40-6aab3f661725': 'Giả tưởng',
      'cdad7e68-1419-41ed-bd5e-4b2073d81b9b': 'Kinh dị',
      'ee968100-4191-4968-93d3-f57e75581a31': 'Bí ẩn',
      '423e2eae-977e-4c4b-98ee-99d613c2e787': 'Lãng mạn',
      '256c8064-7c37-4b30-be3f-2735d4d97c6c': 'Sci-Fi',
      'e5301a23-ebd9-49dd-a0cb-2add944c7fe9': 'Đời thường',
      '6997739f-d546-4178-831d-21d0f140bacb': 'Thể thao',
      'eabc5477-179c-48b0-986d-96a87f4d482a': 'Siêu nhiên',
      '5ca13ee5-ae6c-490f-89b2-ed2f8012ccb6': 'Giật gân',
      'f8f62933-140f-4dd3-a2d3-685c2e311cd0': 'Isekai',
      'e197df38-d0e7-43b5-9b09-2842d0c326dd': 'Webtoon',
    };

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: mangaDexGenres.entries.map((entry) {
        final isSelected = state.selectedGenres.contains(entry.key);
        return FilterChip(
          showCheckmark: false,
          label: Text(entry.value, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          selected: isSelected,
          onSelected: (selected) {
            notifier.toggleGenre(entry.key);
          },
          selectedColor: AppColors.primaryBlue.withOpacity(0.12),
          labelStyle: TextStyle(color: isSelected ? AppColors.primaryBlue : null),
        );
      }).toList(),
    );
  }
}
