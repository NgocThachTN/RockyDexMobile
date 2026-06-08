import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSendingCode = false;
  bool _isResettingPassword = false;
  int _currentStep = 0; // 0: Enter email, 1: Enter PIN and new password
  String? _devResetCode;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendResetCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isSendingCode = true;
    });

    try {
      final email = _emailController.text.trim();
      final response = await ref.read(authRepositoryProvider).forgotPassword(email);
      
      // Dev-friendly helper: retrieve PIN from local response
      final devCode = response['reset_code_dev_only'] as String?;
      
      setState(() {
        _isSendingCode = false;
        _currentStep = 1;
        _devResetCode = devCode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(devCode != null
                ? 'Mã PIN đặt lại mật khẩu: $devCode (Dev mode)'
                : 'Yêu cầu thành công. Vui lòng check email của bạn.'),
            backgroundColor: AppColors.primaryBlue,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSendingCode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() {
      _isResettingPassword = true;
    });

    try {
      final email = _emailController.text.trim();
      final code = _codeController.text.trim();
      final newPassword = _passwordController.text;

      await ref.read(authRepositoryProvider).resetPassword(email, code, newPassword);

      setState(() {
        _isResettingPassword = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Thành Công'),
            content: const Text('Mật khẩu của bạn đã được đặt lại thành công. Vui lòng đăng nhập lại.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isResettingPassword = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Lại Mật Khẩu'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentStep == 0 ? _buildEmailStep(isDark) : _buildResetStep(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(bool isDark) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 48,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            'Quên Mật Khẩu?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập email đã đăng ký của bạn. Chúng tôi sẽ gửi mã PIN 6 chữ số để đặt lại mật khẩu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Email của bạn',
              labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
              floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold),
              prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.white54 : Colors.black45, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.0),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSendingCode ? null : _sendResetCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSendingCode
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'GỬI MÃ XÁC NHẬN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(bool isDark) {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.pin_outlined,
            size: 48,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            'Nhập Mã PIN & Mật Khẩu Mới',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chúng tôi đã gửi mã xác nhận đến ${_emailController.text}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          if (_devResetCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Mã PIN Dev: $_devResetCode',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ),
          ],
          const SizedBox(height: 24),

          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Mã PIN 6 chữ số',
              labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
              floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold),
              prefixIcon: Icon(Icons.pin_outlined, color: isDark ? Colors.white54 : Colors.black45, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.0),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mã PIN';
              }
              if (value.length != 6) {
                return 'Mã PIN phải có 6 chữ số';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới',
              labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
              floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold),
              prefixIcon: Icon(Icons.lock_outlined, color: isDark ? Colors.white54 : Colors.black45, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.0),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu mới';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải từ 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Xác nhận mật khẩu mới',
              labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
              floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold),
              prefixIcon: Icon(Icons.lock_clock_outlined, color: isDark ? Colors.white54 : Colors.black45, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.0),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu mới';
              }
              if (value != _passwordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isResettingPassword ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isResettingPassword
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'ĐẶT LẠI MẬT KHẨU',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2),
                  ),
          ),
          const SizedBox(height: 12),
          
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _devResetCode = null;
              });
            },
            child: const Text('Quay lại bước trước', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }
}
