import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../home_notifier.dart';
import '../../domain/comic_model.dart';
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
      {'label': 'Nổi Bật', 'type': ApiConstants.listFeatured},
      {'label': 'Mới Nhất', 'type': ApiConstants.listNew},
      {'label': 'Đang Ra', 'type': ApiConstants.listOngoing},
      {'label': 'Hoàn Thành', 'type': ApiConstants.listCompleted},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs and Pinned Category Button
          Row(
            children: [
              // Scrollable Filter Tabs
              Expanded(
                child: SizedBox(
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
                        child: InkWell(
                          onTap: () {
                            ref.read(homeProvider.notifier).selectListType(filter['type']!);
                          },
                          borderRadius: BorderRadius.circular(19),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.18)),
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryBlue.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              filter['label']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Divider
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: isDark ? Colors.white12 : Colors.black12,
              ),

              // Pinned "Thể Loại" Capsule Button
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => _showCategoriesBottomSheet(context),
                  borderRadius: BorderRadius.circular(19),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: state.isCategoryFilterActive
                          ? AppColors.primaryBlue
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: state.isCategoryFilterActive
                            ? AppColors.primaryBlue
                            : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.18)),
                        width: 1,
                      ),
                      boxShadow: state.isCategoryFilterActive
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: state.isCategoryFilterActive
                              ? Colors.white
                              : AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Thể loại',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: state.isCategoryFilterActive
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Active Category Filter Indicator (Only shown when a category filter is active)
          if (state.isCategoryFilterActive)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.label_outline_rounded,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang lọc theo: ',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          state.categories.firstWhere(
                            (c) => c.slug == state.selectedCategorySlug,
                            orElse: () => CategoryModel(id: '', name: state.selectedCategorySlug, slug: ''),
                          ).name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => ref.read(homeProvider.notifier).clearCategory(),
                      child: const Icon(
                        Icons.cancel_rounded,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

