import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password';

      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please log out and log back in before changing password';
          break;
        default:
          message = e.message ?? message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.marginL),

                // Current Password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                  ),
                  validator: _validateCurrentPassword,
                ),

                const SizedBox(height: AppDimensions.marginL),

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                  ),
                  validator: _validateNewPassword,
                ),

                const SizedBox(height: AppDimensions.marginL),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: AppDimensions.marginXL),

                // Change Password Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),

                const SizedBox(height: AppDimensions.marginL),

                // Security Tips
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Security Tips:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.marginS),
                      const Text('• Use at least 8 characters'),
                      const Text('• Include uppercase and lowercase letters'),
                      const Text('• Add numbers and special characters'),
                      const Text(
                        '• Avoid common words or personal information',
                      ),
                      const Text(
                        '• Don\'t reuse passwords from other accounts',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
