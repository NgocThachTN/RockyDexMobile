import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String changelog;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
  });
}

class UpdateService {
  static const String _repoUrl =
      'https://api.github.com/repos/NgocThachTN/RockyDexMobile/releases/latest';
  static const MethodChannel _channel = MethodChannel(
    'com.rockydex.mobile/install_permission',
  );
  static const String _autoNotifyKey = 'auto_update_notifications_enabled';
  static const String _lastNotifiedTagKey = 'last_notified_update_tag';

  // Check for updates and redirect to the update screen if a new version is available
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showNoUpdatePrompt = false,
  }) async {
    // Only support Android auto-update
    if (!Platform.isAndroid) return;

    debugPrint('UpdateService: Starting update check against: $_repoUrl');
    try {
      final update = await fetchAvailableUpdate();

      if (update != null) {
        debugPrint(
          'UpdateService: Found newer version. Redirecting to UpdateScreen. Download URL: ${update.downloadUrl}',
        );
        if (context.mounted) {
          openUpdateScreen(context, update);
        }
      } else {
        debugPrint(
          'UpdateService: App is up-to-date (Latest tag is not newer than current version)',
        );
        if (showNoUpdatePrompt && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ứng dụng đã ở phiên bản mới nhất!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Exception during update check: $e');
      if (showNoUpdatePrompt && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kiểm tra cập nhật: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static Future<UpdateInfo?> fetchAvailableUpdate() async {
    if (!Platform.isAndroid) return null;

    final dio = Dio();
    final response = await dio.get(
      _repoUrl,
      options: Options(headers: {'User-Agent': 'RockyDexMobile'}),
    );

    if (response.statusCode != 200) {
      debugPrint(
        'UpdateService: Failed to get latest release. HTTP Status: ${response.statusCode}',
      );
      return null;
    }

    final data = response.data as Map<String, dynamic>;
    final latestTag = data['tag_name'] as String? ?? '';
    final changelog = data['body'] as String? ?? '';

    if (latestTag.isEmpty) {
      debugPrint('UpdateService: Latest release tag name is empty');
      return null;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    debugPrint(
      'UpdateService: Current version = $currentVersion, Latest tag on GitHub = $latestTag',
    );

    if (!_isNewerVersion(currentVersion, latestTag)) {
      return null;
    }

    final assets = data['assets'] as List? ?? [];
    String downloadUrl = '';
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.apk')) {
        downloadUrl = asset['browser_download_url'] as String? ?? '';
        break;
      }
    }

    if (downloadUrl.isEmpty) {
      debugPrint(
        'UpdateService: Newer version tag exists, but no APK asset found in the release',
      );
      return null;
    }

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestTag,
      downloadUrl: downloadUrl,
      changelog: changelog,
    );
  }

  static void openUpdateScreen(BuildContext context, UpdateInfo update) {
    context.push(
      '/update',
      extra: {
        'currentVersion': update.currentVersion,
        'latestVersion': update.latestVersion,
        'downloadUrl': update.downloadUrl,
        'changelog': update.changelog,
      },
    );
  }

  static Future<bool> isAutoNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoNotifyKey) ?? true;
  }

  static Future<void> setAutoNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoNotifyKey, enabled);
  }

  static Future<void> checkAndNotifyForUpdates(BuildContext context) async {
    if (!Platform.isAndroid || !await isAutoNotificationEnabled()) return;

    try {
      final update = await fetchAvailableUpdate();
      if (update == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedTag = prefs.getString(_lastNotifiedTagKey);
      if (lastNotifiedTag == update.latestVersion) return;

      await prefs.setString(_lastNotifiedTagKey, update.latestVersion);
      await _showNativeUpdateNotification(update);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có bản cập nhật mới ${update.latestVersion}'),
            action: SnackBarAction(
              label: 'Cập nhật',
              textColor: Colors.white,
              onPressed: () => openUpdateScreen(context, update),
            ),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      debugPrint('UpdateService: Auto notification check failed: $e');
    }
  }

  static Future<void> _showNativeUpdateNotification(UpdateInfo update) async {
    try {
      final hasPermission =
          await _channel.invokeMethod<bool>('checkNotificationPermission') ??
          true;
      if (!hasPermission) return;

      await _channel.invokeMethod<bool>('showUpdateNotification', {
        'title': 'RockyDex ${update.latestVersion} đã có sẵn',
        'body': 'Mở app để tải và cài đặt bản cập nhật mới.',
      });
    } catch (e) {
      debugPrint(
        'UpdateService: Failed to show native update notification: $e',
      );
    }
  }

  // Version comparison helper (latest > current)
  static bool _isNewerVersion(String current, String latest) {
    final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');

    final currentParts = cleanCurrent
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final latestParts = cleanLatest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    while (currentParts.length < 3) {
      currentParts.add(0);
    }
    while (latestParts.length < 3) {
      latestParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
