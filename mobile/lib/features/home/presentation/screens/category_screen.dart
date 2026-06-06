import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../home_notifier.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Predefined cohesive, modern accent colors for category indicator bars
  final List<Color> _accentColors = [
    const Color(0xFFE57373), // Soft Red
    const Color(0xFFF06292), // Soft Pink
    const Color(0xFFBA68C8), // Soft Purple
    const Color(0xFF9575CD), // Soft Deep Purple
    const Color(0xFF7986CB), // Soft Indigo
    const Color(0xFF64B5F6), // Soft Blue
    const Color(0xFF4FC3F7), // Soft Light Blue
    const Color(0xFF4DD0E1), // Soft Cyan
    const Color(0xFF4DB6AC), // Soft Teal
    const Color(0xFF81C784), // Soft Green
    const Color(0xFFAED581), // Soft Light Green
    const Color(0xFFD4E157), // Soft Lime
    const Color(0xFFFFD54F), // Soft Amber
    const Color(0xFFFFB74D), // Soft Orange
    const Color(0xFFFF8A65), // Soft Deep Orange
  ];

  Color _getAccentColor(String name) {
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return _accentColors[hash % _accentColors.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thể Loại'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).init(force: true),
        color: AppColors.primaryBlue,
        child: _buildBody(context, state, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state, bool isDark) {
    if (state.isCategoriesLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryBlue,
        ),
      );
    }

    if (state.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.categoriesError ?? 'Không thể tải danh sách thể loại',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(homeProvider.notifier).reloadCategories(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter categories locally
    final filteredCategories = state.categories.where((cat) {
      final nameLower = cat.name.toLowerCase();
      final slugLower = cat.slug.toLowerCase();
      return nameLower.contains(_searchQuery) || slugLower.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        // Clean Search Field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm nhanh thể loại...',
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
        ),

        // Grid of Categories
        Expanded(
          child: filteredCategories.isEmpty
              ? const Center(
                  child: Text('Không tìm thấy thể loại nào phù hợp'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final cat = filteredCategories[index];
                    final color = _getAccentColor(cat.name);

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push(
                            '/categories/${cat.slug}',
                            extra: cat.name,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              // Accent indicator
                              Container(
                                width: 5,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
