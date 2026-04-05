import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/top_right_notification.dart';
import '../view_models/auth_view_model.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../pantry/view_models/pantry_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoginMode = true;
  bool _showPassword = false;

  Future<RestoreConflictResolution?> _askConflictResolution(
    int conflictCount,
  ) async {
    return showDialog<RestoreConflictResolution>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Phát hiện xung đột dữ liệu'),
          content: Text(
            'Có $conflictCount mục khác nhau giữa máy và Firebase. Bạn muốn ưu tiên nguồn nào khi khôi phục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(RestoreConflictResolution.preferLocal),
              child: const Text('Giữ dữ liệu local'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(RestoreConflictResolution.preferCloud),
              child: const Text('Lấy dữ liệu Firebase'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runSyncAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    bool isDialogOpen = false;
    try {
      isDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await action();

      if (mounted) {
        showTopRightNotification(context, successMessage);
      }
    } catch (e) {
      if (mounted) {
        showTopRightNotification(context, e.toString());
      }
    } finally {
      if (isDialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _restoreAfterLogin() async {
    final SyncService syncService = context.read<SyncService>();
    RestoreConflictResolution? resolution;

    try {
      final conflicts = await syncService.getRestoreConflicts();
      if (!mounted) {
        return;
      }

      if (conflicts.isNotEmpty) {
        resolution = await _askConflictResolution(conflicts.length);
        if (!mounted || resolution == null) {
          return;
        }
      }

      await _runSyncAction(
        action: () async {
          await syncService.restoreFromCloud(
            conflictResolution:
                resolution ?? RestoreConflictResolution.preferLocal,
          );
          await syncService.restoreMealPlansFromCloud();
          await syncService.restoreShoppingListsFromCloud();

          if (resolution == RestoreConflictResolution.preferLocal) {
            await syncService.backupNow();
            await syncService.backupMealPlansNow();
            await syncService.backupShoppingListsNow();
          }

          final pantryViewModel = _tryReadPantryViewModel();
          if (pantryViewModel != null) {
            await pantryViewModel.loadItems();
          }
        },
        successMessage: 'Khôi phục dữ liệu từ Firebase thành công',
      );
    } catch (e) {
      if (mounted) {
        showTopRightNotification(context, e.toString());
      }
    }
  }

  PantryViewModel? _tryReadPantryViewModel() {
    try {
      return Provider.of<PantryViewModel>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Đăng nhập' : 'Đăng ký'),
        elevation: 0,
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Logo/Title
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.kitchen, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Fridge to Fork',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Error message
                if (authViewModel.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authViewModel.error ?? 'Lỗi không xác định',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: authViewModel.clearError,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Email input
                TextField(
                  controller: _emailController,
                  enabled: !authViewModel.isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@gmail.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Password input
                TextField(
                  controller: _passwordController,
                  enabled: !authViewModel.isLoading,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm password (only for register mode)
                if (!_isLoginMode)
                  Column(
                    children: [
                      TextField(
                        controller: _confirmPasswordController,
                        enabled: !authViewModel.isLoading,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Submit button
                ElevatedButton.icon(
                  onPressed: authViewModel.isLoading
                      ? null
                      : () async {
                          final success = _isLoginMode
                              ? await authViewModel.login(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                )
                              : await authViewModel.register(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  confirmPassword:
                                      _confirmPasswordController.text,
                                );

                          if (success) {
                            await _restoreAfterLogin();
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop(); // Return to pantry
                          }
                        },
                  icon: authViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          _isLoginMode ? Icons.login : Icons.app_registration,
                        ),
                  label: Text(
                    authViewModel.isLoading
                        ? 'Đang xử lý...'
                        : (_isLoginMode ? 'Đăng nhập' : 'Đăng ký'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                if (_isLoginMode) ...[
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Hoặc'),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: authViewModel.isLoading
                        ? null
                        : () async {
                            final success = await authViewModel
                                .loginWithGoogle();
                            if (success) {
                              await _restoreAfterLogin();
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Đăng nhập với Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Toggle login/register mode
                TextButton(
                  onPressed: authViewModel.isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            authViewModel.clearError();
                            _emailController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                  child: Text(
                    _isLoginMode
                        ? 'Chưa có tài khoản? Đăng ký'
                        : 'Đã có tài khoản? Đăng nhập',
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot password (only for login mode)
                if (_isLoginMode)
                  TextButton(
                    onPressed: authViewModel.isLoading
                        ? null
                        : () {
                            // TODO: Show forgot password dialog
                          },
                    child: const Text('Quên mật khẩu?'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
