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
      if (!mounted) return;
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
      // Hide the filter bar completely when no filters are active (no blank spaces/dividers)
      return const SizedBox.shrink();
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: activeChips,
            ),
          ),
          const SizedBox(width: 8),
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
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
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
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
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
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
          // Divider has been removed completely to eliminate the white/gray line
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.map((query) {
              return InkWell(
                onTap: () {
                  _searchController.text = query;
                  ref.read(searchProvider.notifier).search(query, saveToHistory: true);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    query,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textDarkPrimary
                          : AppColors.textLightPrimary,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 20, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Bộ lọc nâng cao',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      notifier.resetFilters();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            
            // Body (Scrollable cards)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sort (MangaDex only)
                    if (state.isMangaDex)
                      _buildSectionCard(
                        context: context,
                        icon: Icons.sort_rounded,
                        title: 'Sắp xếp theo',
                        child: _buildSortSection(state, notifier, context),
                      ),

                    // Country (OTruyen only)
                    if (!state.isMangaDex)
                      _buildSectionCard(
                        context: context,
                        icon: Icons.public_rounded,
                        title: 'Quốc gia',
                        child: _buildCountrySection(state, notifier, context),
                      ),

                    // Status
                    _buildSectionCard(
                      context: context,
                      icon: Icons.hourglass_empty_rounded,
                      title: 'Tình trạng',
                      child: _buildStatusSection(state, notifier, context),
                    ),

                    // Publication Year
                    _buildSectionCard(
                      context: context,
                      icon: Icons.calendar_today_rounded,
                      title: 'Năm phát hành',
                      child: _buildYearSection(state, notifier, context),
                    ),

                    // Genres (MangaDex only)
                    if (state.isMangaDex)
                      _buildSectionCard(
                        context: context,
                        icon: Icons.style_rounded,
                        title: 'Thể loại',
                        child: _buildGenresSection(state, notifier, context),
                      ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),

            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        notifier.resetFilters();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Đặt lại',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close Drawer
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'ÁP DỤNG',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildSortSection(SearchState state, SearchNotifier notifier, BuildContext context) {
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
        return _buildCustomChip(
          label: opt['name']!,
          isSelected: isSelected,
          onTap: () => notifier.updateSortBy(opt['value']!),
          context: context,
        );
      }).toList(),
    );
  }

  Widget _buildCountrySection(SearchState state, SearchNotifier notifier, BuildContext context) {
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
        return _buildCustomChip(
          label: opt['name']!,
          isSelected: isSelected,
          onTap: () => notifier.updateCountry(opt['value']!),
          context: context,
        );
      }).toList(),
    );
  }

  Widget _buildStatusSection(SearchState state, SearchNotifier notifier, BuildContext context) {
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
        return _buildCustomChip(
          label: opt['name']!,
          isSelected: isSelected,
          onTap: () => notifier.updateStatus(opt['value']!),
          context: context,
        );
      }).toList(),
    );
  }

  Widget _buildYearSection(SearchState state, SearchNotifier notifier, BuildContext context) {
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickYears.map((opt) {
            final isSelected = state.selectedYear == opt['value'];
            return _buildCustomChip(
              label: opt['name']!,
              isSelected: isSelected,
              onTap: () => notifier.updateYear(opt['value']!),
              context: context,
            );
          }).toList(),
        ),
        if (state.isMangaDex) ...[
          const SizedBox(height: 12),
          _buildOlderYearDropdown(state, notifier, context),
        ],
      ],
    );
  }

  Widget _buildOlderYearDropdown(SearchState state, SearchNotifier notifier, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 8;
    final List<String> olderYears = [];
    for (int y = startYear; y >= 1970; y--) {
      olderYears.add(y.toString());
    }

    final isSelectedValueInOlder = olderYears.contains(state.selectedYear);
    final String dropdownValue = isSelectedValueInOlder ? state.selectedYear : 'Năm khác...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
          items: [
            const DropdownMenuItem(
              value: 'Năm khác...',
              child: Text('Năm phát hành khác...', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            ...olderYears.map((y) => DropdownMenuItem(
              value: y,
              child: Text('Năm $y', style: const TextStyle(fontSize: 13)),
            )),
          ],
          onChanged: (val) {
            if (val != null && val != 'Năm khác...') {
              notifier.updateYear(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildGenresSection(SearchState state, SearchNotifier notifier, BuildContext context) {
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
      spacing: 8,
      runSpacing: 8,
      children: mangaDexGenres.entries.map((entry) {
        final isSelected = state.selectedGenres.contains(entry.key);
        return _buildCustomChip(
          label: entry.value,
          isSelected: isSelected,
          onTap: () => notifier.toggleGenre(entry.key),
          context: context,
        );
      }).toList(),
    );
  }
}
