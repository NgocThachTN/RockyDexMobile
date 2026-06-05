import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../home_notifier.dart';
import 'category_grid_sheet.dart';

class HomeFilterSection extends ConsumerWidget {
  final HomeState state;

  const HomeFilterSection({super.key, required this.state});

  void _showCategoriesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryGridSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  onPressed: () => _showCategoriesBottomSheet(context),
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

                // Dynamic Category chips (first 12 categories)
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
}
