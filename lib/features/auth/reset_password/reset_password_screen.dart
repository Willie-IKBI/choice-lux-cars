import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Check if user has a valid session for password reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkResetSession();
    });
  }

  void _checkResetSession() async {
    // Check if user has a valid session for password reset
    try {
      final session =
          await SupabaseService.instance.supabase.auth.currentSession;
      Log.d(
        'Reset Password Screen - Session check: ${session != null ? 'Valid session' : 'No session'}',
      );

      if (session == null) {
        Log.d(
          'Reset Password Screen - No session found, redirecting to forgot password',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Invalid or expired reset link. Please request a new password reset.',
              ),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
          context.go('/forgot-password');
        }
      } else {
        Log.d('Reset Password Screen - Session found, user can reset password');
      }
    } catch (error) {
      Log.e('Reset Password Screen - Error checking session: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error validating reset session. Please try again.',
            ),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
        context.go('/forgot-password');
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Clear password recovery state when leaving the screen
    // This prevents the router from redirecting back to reset password
    if (mounted) {
      ref.read(authProvider.notifier).setPasswordRecovery(false);
    }

    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the current session from Supabase
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          throw Exception(
            'No active session found. Please use the reset link from your email.',
          );
        }

        // Update the password using the current session
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim()),
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          // Clear the password recovery state before redirecting
          ref.read(authProvider.notifier).setPasswordRecovery(false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Password updated successfully! Please sign in with your new password.',
              ),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
          // Sign out the user and redirect to login
          await Supabase.instance.client.auth.signOut();
          context.go('/login');
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update password: ${error.toString()}'),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ChoiceLuxTheme.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 1200;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 24.0
                        : isTablet
                        ? 64.0
                        : 120.0,
                    vertical: 32.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 400,
                    ),
                    child: Card(
                      elevation: 12,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ChoiceLuxTheme.charcoalGray,
                              ChoiceLuxTheme.charcoalGray.withOpacity(0.95),
                            ],
                          ),
                          border: Border.all(
                            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'Create New Password',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'Please enter your new password below.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ChoiceLuxTheme.platinumSilver
                                      .withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // New Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  labelStyle: TextStyle(
                                    color: ChoiceLuxTheme.platinumSilver,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: ChoiceLuxTheme.richGold,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: ChoiceLuxTheme.platinumSilver,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.platinumSilver
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.richGold,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.errorColor,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.errorColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: ChoiceLuxTheme.charcoalGray
                                      .withOpacity(0.3),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Confirm Password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                style: TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password',
                                  labelStyle: TextStyle(
                                    color: ChoiceLuxTheme.platinumSilver,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: ChoiceLuxTheme.richGold,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: ChoiceLuxTheme.platinumSilver,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.platinumSilver
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.richGold,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.errorColor,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: ChoiceLuxTheme.errorColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: ChoiceLuxTheme.charcoalGray
                                      .withOpacity(0.3),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _resetPassword(),
                              ),
                              const SizedBox(height: 24),

                              // Update Password button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ChoiceLuxTheme.richGold,
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shadowColor: ChoiceLuxTheme.richGold
                                      .withOpacity(0.3),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Update Password',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),

                              // Back to Login link
                              Center(
                                child: TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: ChoiceLuxTheme.platinumSilver,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
