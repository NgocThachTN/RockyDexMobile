import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../../core/services/app_version_service.dart';
import '../../../../core/services/update_service.dart';
import '../../../library/data/library_repository.dart';

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
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  backgroundColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey.withValues(alpha: 0.12),
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(libraryRepositoryProvider).syncFavorites();
            await ref.read(libraryRepositoryProvider).syncHistory();
          } catch (_) {}
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header (Gradient Card)
              _buildProfileHeader(context, authState),

              const SizedBox(height: 8),

              // 2. Ứng dụng Section
              _buildSectionHeader('Ứng dụng'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.08 : 0.02,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.menu_book_outlined,
                      title: 'Kệ sách',
                      onTap: () => context.push('/library'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Thống kê',
                      onTap: () => context.push('/stats'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: 'Cài đặt',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Kết nối Section
              _buildSectionHeader('Kết nối'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.08 : 0.02,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.share_outlined,
                      title: 'Mời bạn bè sử dụng',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('RockyDex'),
                            content: const Text(
                              'Cảm ơn bạn đã giới thiệu RockyDex với bạn bè! Link tải app: https://github.com/NgocThachTN/RockyDexMobile',
                            ),
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
                  ],
                ),
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

    Widget headerContent;

    if (user == null) {
      // Guest Profile Header
      headerContent = Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: isDark
                    ? const Color(0xFF2C2C2C)
                    : Colors.grey.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 36,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 10,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
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
      );
    } else {
      // Authenticated Profile Header
      final avatarUrl = user.profile.avatarUrl;
      final hasAvatar = avatarUrl.isNotEmpty;

      headerContent = Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: isDark
                    ? const Color(0xFF2C2C2C)
                    : Colors.grey.withValues(alpha: 0.15),
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: !hasAvatar
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 36,
                        color: isDark ? Colors.white60 : Colors.black54,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    size: 10,
                    color: Colors.white,
                  ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF151515)]
              : [Colors.white, const Color(0xFFF9F9F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: headerContent,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textDarkPrimary
              : AppColors.textLightPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<String>(
            future: AppVersionService.displayVersionLabel(),
            initialData: AppVersionService.fallbackVersionLabel,
            builder: (context, snapshot) {
              return Text(
                'Phiên bản: ${snapshot.data ?? AppVersionService.fallbackVersionLabel}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
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
}
