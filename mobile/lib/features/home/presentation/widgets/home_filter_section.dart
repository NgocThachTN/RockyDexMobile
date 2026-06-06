import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../home_notifier.dart';

class HomeFilterSection extends ConsumerWidget {
  final HomeState state;

  const HomeFilterSection({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final listFilters = [
      {'label': 'Cập nhật', 'type': ApiConstants.listNew},
      {'label': 'Đề xuất', 'type': ApiConstants.listFeatured},
      {'label': 'Đang phát hành', 'type': ApiConstants.listOngoing},
      {'label': 'Hoàn thành', 'type': ApiConstants.listCompleted},
      {'label': 'Sắp ra mắt', 'type': ApiConstants.listComingSoon},
    ];

    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: listFilters.map((filter) {
            final isSelected = state.selectedListType == filter['type'];

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(homeProvider.notifier).selectListType(filter['type']!);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.18)),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.2),
                                blurRadius: 4,
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
