import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/auth_notifier.dart';

final readingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final authState = ref.watch(authProvider);

  if (authState.user == null) {
    return {'total_comics_read': 0, 'total_favorites': 0, 'chapters_read': 0};
  }

  try {
    final response = await dio.get('/user/stats');
    return response.data as Map<String, dynamic>;
  } catch (_) {
    return {'total_comics_read': 0, 'total_favorites': 0, 'chapters_read': 0};
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(readingStatsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá Nhân'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Card (Logged In vs. Logged Out)
            authState.user != null
                ? _buildLoggedInCard(context, ref, authState.user!)
                : _buildLoggedOutCard(context),

            const SizedBox(height: 24),

            // 2. Reading Stats
            if (authState.user != null) ...[
              Text(
                'Thống kê đọc truyện',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(context, statsAsync),
              const SizedBox(height: 24),
            ],

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
                        applicationIcon: Icon(Icons.auto_stories, color: AppColors.primaryBlue, size: 40),
                        children: const [
                          Text('Ứng dụng đọc truyện tranh tối giản, nhanh chóng và mượt mà cho người dùng Việt Nam. Hợp phong thủy Xanh Dương - Xám.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Logout Button (If logged in)
            if (authState.user != null)
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  ref.invalidate(readingStatsProvider);
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('ĐĂNG XUẤT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInCard(BuildContext context, WidgetRef ref, dynamic user) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle_outlined, size: 60, color: AppColors.primaryBlue),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để đồng bộ tủ sách',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lưu lại lịch sử đọc và các bộ truyện yêu thích của bạn giữa các thiết bị.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('ĐĂNG NHẬP / ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
