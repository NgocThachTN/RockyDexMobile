import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  static const fallbackVersion = '1.3.0';
  static const fallbackVersionLabel = 'v$fallbackVersion';

  static Future<String> displayVersionLabel() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return 'v${info.version}';
    } catch (_) {
      return fallbackVersionLabel;
    }
  }
}
