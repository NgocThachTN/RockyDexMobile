import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';

class UpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String changelog;

  const UpdateScreen({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.rockydex.mobile/install_permission');

  double _progress = 0.0;
  bool _isDownloading = false;
  bool _isCompleted = false;
  String? _errorMessage;
  String _apkPath = '';
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If download is complete and we were showing permission error, retry installation
      if (_isCompleted && _errorMessage != null && _errorMessage!.contains('quyền cài đặt')) {
        _checkAndInstallOnResume();
      }
    }
  }

  Future<void> _checkAndInstallOnResume() async {
    bool hasPermission = true;
    try {
      hasPermission = await _channel.invokeMethod<bool>('checkInstallPermission') ?? true;
    } catch (e) {
      // Fallback
    }

    if (hasPermission) {
      setState(() {
        _errorMessage = null;
      });
      await _triggerInstall();
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      Directory? downloadDir;
      if (Platform.isAndroid) {
        // Use external storage directory so system installer has read permission
        downloadDir = await getExternalStorageDirectory();
      }
      downloadDir ??= await getTemporaryDirectory();
      _apkPath = '${downloadDir.path}/rockydex_update.apk';

      // Delete existing file if any to prevent package installer corruption
      final apkFile = File(_apkPath);
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      _cancelToken = CancelToken();

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        _apkPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _isCompleted = true;
      });

      // Automatically trigger installation
      await _triggerInstall();
    } catch (e) {
      if (e is! DioException || !CancelToken.isCancel(e)) {
        setState(() {
          _isDownloading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _triggerInstall() async {
    if (_apkPath.isEmpty) return;

    try {
      // Check installation permission on Android
      bool hasPermission = true;
      try {
        hasPermission = await _channel.invokeMethod<bool>('checkInstallPermission') ?? true;
      } catch (e) {
        // Fallback for non-Android platforms or channel errors
      }

      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Ứng dụng cần quyền cài đặt nguồn không xác định. Vui lòng bật quyền cài đặt cho RockyDex trong cài đặt hệ thống vừa mở ra.';
        });

        // Request permission (opens Settings page for user to toggle)
        try {
          await _channel.invokeMethod('requestInstallPermission');
        } catch (e) {
          // Ignore settings launch failure
        }
        return;
      }

      // Use native FileProvider-based installer via MethodChannel
      final result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': _apkPath,
      });

      if (result == true) {
        setState(() {
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể mở trình cài đặt.\n\nHãy đảm bảo bạn đã cấp quyền cài đặt ứng dụng từ nguồn không xác định cho RockyDex.';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = 'Lỗi cài đặt: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khởi chạy cài đặt: $e';
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanChangelog = widget.changelog.trim().isEmpty 
        ? '• Sửa lỗi và cải thiện hiệu năng.' 
        : widget.changelog.trim();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black87),
          onPressed: () {
            if (_isDownloading) {
              // Confirm cancel
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? AppColors.bgDarkCard : Colors.white,
                  title: const Text('Hủy Tải Xuống?'),
                  content: const Text('Bạn có chắc chắn muốn hủy tải bản cập nhật không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Không'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelDownload();
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: const Text('Có', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 64,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  'Cập Nhật Ứng Dụng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Version Info Box
              Card(
                color: isDark ? AppColors.bgDarkCard : AppColors.bgLightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppColors.bgDarkDivider : AppColors.bgLightDivider,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Phiên bản hiện tại',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.currentVersion,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.trending_flat,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                      Column(
                        children: [
                          Text(
                            'Phiên bản mới nhất',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.latestVersion,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Changelog Title
              const Text(
                'Nội dung cập nhật:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Changelog Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDarkCard : AppColors.bgLightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.bgDarkDivider : AppColors.bgLightDivider,
                    ),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          cleanChangelog,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Actions Block
              if (_isDownloading) ...[
                // Download progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đang tải xuống... ${(_progress * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: _cancelDownload,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'HỦY',
                            style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (_isCompleted) ...[
                // Install triggers
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _triggerInstall,
                  icon: const Icon(Icons.install_mobile_rounded),
                  label: const Text(
                    'CÀI ĐẶT CẬP NHẬT',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? AppColors.bgDarkDivider : AppColors.bgLightDivider),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: Text(
                          'ĐỂ SAU',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _startDownload,
                        child: const Text(
                          'CẬP NHẬT NGAY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
