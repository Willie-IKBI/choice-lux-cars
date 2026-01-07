import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/typography.dart';
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
        // Set password recovery state to true when we have a valid session
        // This prevents the router guard from redirecting the user away
        ref.read(authProvider.notifier).setPasswordRecovery(true);
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
        decoration: BoxDecoration(gradient: ChoiceLuxTheme.authBackgroundGradient),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
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
                                      style: outfitSafe(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: ChoiceLuxTheme.softWhite,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),

                                    // Subtitle
                                    Text(
                                      'Please enter your new password below.',
                                      style: interSafe(
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
                                        labelText: 'NEW PASSWORD',
                                        labelStyle: TextStyle(
                                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: ChoiceLuxTheme.platinumSilver,
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
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.2),
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
                                            color: Colors.red.withOpacity(0.5),
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.red.withOpacity(0.8),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.05),
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
                                        labelText: 'CONFIRM NEW PASSWORD',
                                        labelStyle: TextStyle(
                                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: ChoiceLuxTheme.platinumSilver,
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
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.2),
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
                                            color: Colors.red.withOpacity(0.5),
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.red.withOpacity(0.8),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.05),
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
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _resetPassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: ChoiceLuxTheme.richGold,
                                          foregroundColor: Colors.black,
                                          elevation: 8,
                                          shadowColor: ChoiceLuxTheme.richGold
                                              .withOpacity(0.4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Updating...',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                'Update Password',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
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
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }
}


