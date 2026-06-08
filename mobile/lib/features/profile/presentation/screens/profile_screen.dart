import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../../core/services/update_service.dart';

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

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
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
  }

  void _showStatsBottomSheet(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thống kê đọc truyện',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildStatsGrid(context, statsAsync),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(readingStatsProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        titleSpacing: 16,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        actions: [
          if (authState.user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: () => _handleLogout(context, ref),
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.12),
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: () => context.push('/login'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(readingStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header
              _buildProfileHeader(context, authState),

              const SizedBox(height: 16),

              // 2. Ứng dụng Section
              _buildSectionHeader('Ứng dụng'),
              Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.menu_book_outlined,
                    title: 'Lưu trữ',
                    onTap: () => context.push('/library'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Thống kê',
                    onTap: () => _showStatsBottomSheet(context, statsAsync),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Cài đặt',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Kết nối Section
              _buildSectionHeader('Kết nối'),
              _buildMenuItem(
                icon: Icons.share_outlined,
                title: 'Mời bạn bè sử dụng',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('RockyDex'),
                      content: const Text('Cảm ơn bạn đã giới thiệu RockyDex với bạn bè! Link tải app: https://github.com/NgocThachTN/RockyDexMobile'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 4. Footer Version Info
              _buildVersionInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthState authState) {
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      // Guest Profile Header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.15),
                  child: Icon(Icons.person_outline_rounded, size: 40, color: isDark ? Colors.white60 : Colors.black54),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                    ),
                    child: Icon(Icons.add_a_photo_outlined, size: 10, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Độc giả RockyDex (Khách)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Đăng nhập để đồng bộ lịch sử và yêu thích',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Authenticated Profile Header
    final avatarUrl = user.profile.avatarUrl;
    final hasAvatar = avatarUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.15),
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: !hasAvatar
                    ? Icon(Icons.person_outline_rounded, size: 40, color: isDark ? Colors.white60 : Colors.black54)
                    : null,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Phiên bản: 1.1.6',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              UpdateService.checkForUpdates(context);
            },
            child: const Icon(
              Icons.refresh_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ],
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
