import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
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
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá Nhân'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(readingStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Card (Login / Logout aware)
              _buildProfileCard(context, ref, authState),

              const SizedBox(height: 16),

              // 2. Reading Stats (Always shown)
              Text(
                'Thống kê đọc truyện',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 8),
              _buildStatsGrid(context, statsAsync),
              const SizedBox(height: 16),

              // 3. Settings & Actions List
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, color: AppColors.primaryBlue, size: 20),
                      title: const Text('Lịch sử đọc truyện', style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () => context.push('/history'),
                    ),
                    const Divider(height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.bookmark_outline, color: AppColors.primaryBlue, size: 20),
                      title: const Text('Truyện yêu thích', style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () => context.push('/favorites'),
                    ),
                    const Divider(height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue, size: 20),
                      title: const Text('Cài đặt đọc truyện', style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
                      title: const Text('Về RockyDex', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Phiên bản v1.1.5', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'RockyDex',
                          applicationVersion: '1.1.5',
                          applicationIcon: Image.asset('assets/images/app_icon.png', width: 48, height: 48, errorBuilder: (_, __, ___) => const Icon(Icons.auto_stories, size: 48, color: AppColors.primaryBlue)),
                          children: const [
                            Text('Ứng dụng đọc truyện tranh tối giản, nhanh chóng và mượt mà cho người dùng Việt Nam. Hợp phong thủy Xanh Dương - Xám. Dữ liệu tự động đồng bộ giữa Local DB và Cloud Server.'),
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

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, AuthState authState) {
    final user = authState.user;

    if (user == null) {
      // Guest Profile Card
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.15),
                    child: const Icon(Icons.person, size: 28, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Độc giả RockyDex (Khách)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Đăng nhập để đồng bộ lịch sử và yêu thích',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ĐĂNG NHẬP / ĐĂNG KÝ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Authenticated Profile Card
    final avatarUrl = user.profile.avatarUrl;
    final hasAvatar = avatarUrl.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.15),
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: !hasAvatar ? const Icon(Icons.person, size: 32, color: AppColors.primaryBlue) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                  ref.invalidate(readingStatsProvider);
                }
              },
              icon: const Icon(Icons.logout, size: 16, color: AppColors.error),
              label: const Text(
                'ĐĂNG XUẤT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(context, 'Yêu thích', '$favoritesCount', 'bộ truyện')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(context, 'Chương', '$chaptersRead', 'đã đọc')),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, String unit) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
