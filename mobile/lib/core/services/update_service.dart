import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class UpdateService {
  static const String _repoUrl = 'https://api.github.com/repos/NgocThachTN/RockyDexMobile/releases/latest';

  // Check for updates and redirect to the update screen if a new version is available
  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdatePrompt = false}) async {
    // Only support Android auto-update
    if (!Platform.isAndroid) return;

    debugPrint('UpdateService: Starting update check against: $_repoUrl');
    try {
      final dio = Dio();
      final response = await dio.get(
        _repoUrl,
        options: Options(
          headers: {
            'User-Agent': 'RockyDexMobile',
          },
        ),
      );
      
      if (response.statusCode != 200) {
        debugPrint('UpdateService: Failed to get latest release. HTTP Status: ${response.statusCode}');
        return;
      }

      final data = response.data as Map<String, dynamic>;
      final latestTag = data['tag_name'] as String? ?? '';
      final changelog = data['body'] as String? ?? '';
      
      if (latestTag.isEmpty) {
        debugPrint('UpdateService: Latest release tag name is empty');
        return;
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint('UpdateService: Current version = $currentVersion, Latest tag on GitHub = $latestTag');

      if (_isNewerVersion(currentVersion, latestTag)) {
        // Find APK asset
        final assets = data['assets'] as List? ?? [];
        String downloadUrl = '';
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? '';
            break;
          }
        }

        if (downloadUrl.isNotEmpty) {
          debugPrint('UpdateService: Found newer version. Redirecting to UpdateScreen. Download URL: $downloadUrl');
          if (context.mounted) {
            context.push('/update', extra: {
              'currentVersion': currentVersion,
              'latestVersion': latestTag,
              'downloadUrl': downloadUrl,
              'changelog': changelog,
            });
          }
        } else {
          debugPrint('UpdateService: Newer version tag exists, but no APK asset found in the release');
        }
      } else {
        debugPrint('UpdateService: App is up-to-date (Latest tag is not newer than current version)');
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

  // Version comparison helper (latest > current)
  static bool _isNewerVersion(String current, String latest) {
    final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
    
    final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
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
