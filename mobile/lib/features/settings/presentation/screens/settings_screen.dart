// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/update_service.dart';
import '../../../reader/presentation/reader_providers.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

final autoUpdateNotificationsProvider = FutureProvider<bool>((ref) {
  return UpdateService.isAutoNotificationEnabled();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final themeStr = _prefs.getString('app_theme_mode') ?? 'system';
    switch (themeStr) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> updateTheme(ThemeMode mode) async {
    state = mode;
    String themeStr = 'system';
    if (mode == ThemeMode.light) themeStr = 'light';
    if (mode == ThemeMode.dark) themeStr = 'dark';
    await _prefs.setString('app_theme_mode', themeStr);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final readerSettings = ref.watch(readerSettingsProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final autoUpdateNotificationsAsync = ref.watch(
      autoUpdateNotificationsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Theme Settings
          Text(
            'Giao diện',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Sáng'),
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).updateTheme(mode);
                    }
                  },
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<ThemeMode>(
                  title: const Text('Tối'),
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).updateTheme(mode);
                    }
                  },
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<ThemeMode>(
                  title: const Text('Mặc định hệ thống'),
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).updateTheme(mode);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Reader Settings
          Text(
            'Trình đọc truyện',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Chế độ đọc'),
                  subtitle: Text(
                    readerSettings.layout == 'vertical'
                        ? 'Cuộn dọc liên tục'
                        : 'Lướt ngang từng trang',
                  ),
                  trailing: const Icon(
                    Icons.swap_horiz,
                    color: AppColors.primaryBlue,
                  ),
                  onTap: () {
                    final nextLayout = readerSettings.layout == 'vertical'
                        ? 'horizontal'
                        : 'vertical';
                    ref
                        .read(readerSettingsProvider.notifier)
                        .updateLayout(nextLayout);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Information & Updates
          Text(
            'Thông tin & Cập nhật',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Phiên bản hiện tại'),
                  subtitle: packageInfoAsync.when(
                    data: (info) => Text('${info.version}+${info.buildNumber}'),
                    loading: () => const Text('Đang tải...'),
                    error: (_, __) => const Text('Không rõ'),
                  ),
                ),
                const Divider(height: 1, indent: 16),
                autoUpdateNotificationsAsync.when(
                  data: (enabled) => SwitchListTile(
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    title: const Text('Thông báo cập nhật tự động'),
                    subtitle: const Text('Tự báo khi GitHub có bản APK mới'),
                    value: enabled,
                    activeThumbColor: AppColors.primaryBlue,
                    onChanged: (value) async {
                      await UpdateService.setAutoNotificationEnabled(value);
                      ref.invalidate(autoUpdateNotificationsProvider);
                      if (context.mounted && value) {
                        UpdateService.checkAndNotifyForUpdates(context);
                      }
                    },
                  ),
                  loading: () => const ListTile(
                    leading: Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text('Thông báo cập nhật tự động'),
                    subtitle: Text('Đang tải...'),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.system_update_alt_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Kiểm tra cập nhật'),
                  subtitle: const Text('Kiểm tra phiên bản mới nhất từ GitHub'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    UpdateService.checkForUpdates(
                      context,
                      showNoUpdatePrompt: true,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
