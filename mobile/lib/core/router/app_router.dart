import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Screens
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/home/presentation/screens/category_screen.dart';
import '../../features/home/presentation/screens/category_detail_screen.dart';
import '../../features/library/presentation/screens/favorites_screen.dart';
import '../../features/library/presentation/screens/history_screen.dart';
import '../../features/library/presentation/screens/storage_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/comic/presentation/screens/comic_detail_screen.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/update_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/comic/:slug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return ComicDetailScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/reader/:comicSlug/:chapterSlug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final comicSlug = state.pathParameters['comicSlug']!;
          final chapterSlug = state.pathParameters['chapterSlug']!;
          
          String? apiDataUrl;
          String? comicName;
          String? comicThumb;
          String? chapterName;
          
          if (state.extra is Map<String, dynamic>) {
            final extraMap = state.extra as Map<String, dynamic>;
            apiDataUrl = extraMap['api_data_url'] as String?;
            comicName = extraMap['comic_name'] as String?;
            comicThumb = extraMap['comic_thumb'] as String?;
            chapterName = extraMap['chapter_name'] as String?;
          } else {
            apiDataUrl = state.extra as String?;
          }
          
          return ReaderScreen(
            comicSlug: comicSlug,
            chapterSlug: chapterSlug,
            apiDataUrl: apiDataUrl,
            comicName: comicName,
            comicThumb: comicThumb,
            chapterName: chapterName,
          );
        },
      ),
      GoRoute(
        path: '/categories/:slug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final name = state.extra as String? ?? slug;
          return CategoryDetailScreen(categorySlug: slug, categoryName: name);
        },
      ),
      GoRoute(
        path: '/library',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const StorageScreen(),
      ),
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/update',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final currentVersion = extra['currentVersion'] as String? ?? '';
          final latestVersion = extra['latestVersion'] as String? ?? '';
          final downloadUrl = extra['downloadUrl'] as String? ?? '';
          final changelog = extra['changelog'] as String? ?? '';
          return UpdateScreen(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl,
            changelog: changelog,
          );
        },
      ),
    ],
  );
});

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/search')) {
      currentIndex = 1;
    } else if (location.startsWith('/categories')) {
      currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      currentIndex = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/categories');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Tìm kiếm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Thể loại',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
