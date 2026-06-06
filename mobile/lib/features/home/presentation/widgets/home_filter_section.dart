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
      {'label': 'Nổi Bật', 'type': ApiConstants.listFeatured},
      {'label': 'Mới Nhất', 'type': ApiConstants.listNew},
      {'label': 'Đang Ra', 'type': ApiConstants.listOngoing},
      {'label': 'Hoàn Thành', 'type': ApiConstants.listCompleted},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      child: Row(
        children: listFilters.map((filter) {
          final isSelected = state.selectedListType == filter['type'];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  ref.read(homeProvider.notifier).selectListType(filter['type']!);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
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
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
