import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'RockyDex',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        // Request notification permission on first build (Android 13+)
        _requestNotificationPermission();
        return child ?? const SizedBox.shrink();
      },
    );
  }

  static bool _notificationPermissionRequested = false;

  static void _requestNotificationPermission() {
    if (_notificationPermissionRequested || !Platform.isAndroid) return;
    _notificationPermissionRequested = true;

    // Delay slightly to ensure the activity is fully ready
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        const channel = MethodChannel('com.rockydex.mobile/install_permission');
        final hasPermission = await channel.invokeMethod<bool>('checkNotificationPermission') ?? true;
        if (!hasPermission) {
          await channel.invokeMethod<bool>('requestNotificationPermission');
        }
      } catch (e) {
        debugPrint('NotificationPermission: Error requesting permission: $e');
      }
    });
  }
}
