import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/presentation/auth_notifier.dart';

final readingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final favorites = await LocalStorage.getFavorites();
  final history = await LocalStorage.getHistoryList();
  
  final uniqueComicsRead = history.map((e) => e['comic_slug']).toSet().length;
  final totalChaptersRead = history.length;

  return {
    'total_comics_read': uniqueComicsRead,
    'total_favorites': favorites.length,
    'chapters_read': totalChaptersRead,
  };
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(readingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá Nhân'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(readingStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Local Profile Card (No login required)
              _buildLocalProfileCard(context),

              const SizedBox(height: 24),

              // 2. Reading Stats (Always shown)
              Text(
                'Thống kê đọc truyện',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(context, statsAsync),
              const SizedBox(height: 24),

              // 3. Settings & Actions List
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
                      title: const Text('Cài đặt đọc truyện'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                      title: const Text('Về RockyDex'),
                      subtitle: const Text('Phiên bản 1.0.0'),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'RockyDex',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(Icons.auto_stories, color: AppColors.primaryBlue, size: 40),
                          children: const [
                            Text('Ứng dụng đọc truyện tranh tối giản, nhanh chóng và mượt mà cho người dùng Việt Nam. Hợp phong thủy Xanh Dương - Xám. Dữ liệu lưu offline hoàn toàn.'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
              child: const Icon(Icons.person, size: 36, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Độc giả RockyDex',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dữ liệu lưu offline trên thiết bị',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AsyncValue<Map<String, dynamic>> asyncStats) {
    return asyncStats.when(
      data: (stats) {
        final comicsRead = stats['total_comics_read'] ?? 0;
        final favoritesCount = stats['total_favorites'] ?? 0;
        final chaptersRead = stats['chapters_read'] ?? 0;

        return Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Đã đọc', '$comicsRead', 'bộ truyện')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Yêu thích', '$favoritesCount', 'bộ truyện')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Chương', '$chaptersRead', 'đã hoàn thành')),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, String unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
