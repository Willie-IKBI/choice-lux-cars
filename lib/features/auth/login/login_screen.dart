import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/constants.dart';
import 'package:choice_lux_cars/app/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isHoveringSignUp = false;
  bool _isHoveringForgotPassword = false;
  bool _isHoveringLogo = false;
  
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  String _getErrorMessage(Object? error) {
    if (error == null) return 'An unknown error occurred';
    
    final errorString = error.toString();
    
    // Handle common authentication errors
    if (errorString.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    } else if (errorString.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account before signing in.';
    } else if (errorString.contains('Too many requests')) {
      return 'Too many login attempts. Please wait a moment before trying again.';
    } else if (errorString.contains('User not found')) {
      return 'No account found with this email address. Please check your email or sign up.';
    } else if (errorString.contains('Network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (errorString.contains('server')) {
      return 'Server error. Please try again later.';
    }
    
    // Return a sanitized version of the error message
    return errorString.replaceAll('Exception:', '').replaceAll('Error:', '').trim();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ChoiceLuxTheme.errorColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: ChoiceLuxTheme.errorColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Login Error',
                  style: TextStyle(
                    color: ChoiceLuxTheme.errorColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Clear the error state
                      ref.read(authProvider.notifier).clearError();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChoiceLuxTheme.richGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      _buttonAnimationController.forward().then((_) {
        _buttonAnimationController.reverse();
      });
      
      try {
        await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } catch (e) {
        // The auth provider should handle the error and set the state
        // This catch is just for any unexpected errors
        print('Unexpected sign in error in UI: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Handle authentication state changes
    ref.listen(authProvider, (previous, next) {
      print('Auth state changed - Previous: ${previous?.hasError}, Next: ${next.hasError}');
      print('Next error: ${next.error}');
      
      // Navigate to dashboard if authenticated
      if (next.hasValue && next.value != null) {
        context.go('/');
      }
      
      // Handle authentication errors with popup
      if (next.hasError) {
        print('Showing error popup for: ${next.error}');
        // Show error popup
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog(context, _getErrorMessage(next.error));
        });
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A1A),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 400;
                              final padding = isMobile 
                                  ? const EdgeInsets.all(24.0)
                                  : const EdgeInsets.all(40.0);
                              
                              return Padding(
                                padding: padding,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Logo and Title
                                      MouseRegion(
                                        onEnter: (_) => setState(() => _isHoveringLogo = true),
                                        onExit: (_) => setState(() => _isHoveringLogo = false),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                          width: 72,
                                          height: 72,
                                          transform: Matrix4.identity()..scale(_isHoveringLogo ? 1.05 : 1.0),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withOpacity(0.7),
                                            border: Border.all(
                                              color: ChoiceLuxTheme.richGold,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                                blurRadius: _isHoveringLogo ? 15 : 10,
                                                offset: Offset(0, _isHoveringLogo ? 6 : 4),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Image.asset(
                                              'assets/images/clc_logo.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile = constraints.maxWidth < 400;
                                          final titleSize = isMobile ? 24.0 : 28.0;
                                          final subtitleSize = isMobile ? 10.0 : 12.0;
                                          
                                          return Column(
                                            children: [
                                              Text(
                                                'Choice Lux Cars',
                                                style: GoogleFonts.outfit(
                                                  fontSize: titleSize,
                                                  fontWeight: FontWeight.w700,
                                                  color: ChoiceLuxTheme.richGold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'SIGN IN TO YOUR ACCOUNT',
                                                style: GoogleFonts.inter(
                                                  letterSpacing: 1.2,
                                                  fontSize: subtitleSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 40),

                                      // Email Field
                                      _buildInputField(
                                        controller: _emailController,
                                        label: 'Email Address',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Password Field
                                      _buildInputField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock_outline,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: ChoiceLuxTheme.platinumSilver,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (value.length < AppConstants.minPasswordLength) {
                                            return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile = constraints.maxWidth < 400;
                                          return SizedBox(height: isMobile ? 16.0 : 20.0);
                                        },
                                      ),

                                      // Remember Me and Forgot Password
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile = constraints.maxWidth < 400;
                                          
                                          if (isMobile) {
                                            // Stack vertically on mobile
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Switch(
                                                        value: _rememberMe,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _rememberMe = value;
                                                          });
                                                        },
                                                        activeColor: ChoiceLuxTheme.richGold,
                                                        activeTrackColor: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Remember me',
                                                      style: TextStyle(
                                                        color: ChoiceLuxTheme.platinumSilver,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                MouseRegion(
                                                  onEnter: (_) => setState(() => _isHoveringForgotPassword = true),
                                                  onExit: (_) => setState(() => _isHoveringForgotPassword = false),
                                                  child: TextButton(
                                                    onPressed: () {
                                                      // TODO: Implement forgot password
                                                    },
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: _isHoveringForgotPassword 
                                                          ? ChoiceLuxTheme.richGold 
                                                          : ChoiceLuxTheme.platinumSilver,
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      'Forgot Password?',
                                                      style: TextStyle(
                                                        decoration: _isHoveringForgotPassword 
                                                            ? TextDecoration.underline 
                                                            : null,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else {
                                            // Side by side on larger screens
                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Switch(
                                                        value: _rememberMe,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _rememberMe = value;
                                                          });
                                                        },
                                                        activeColor: ChoiceLuxTheme.richGold,
                                                        activeTrackColor: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Remember me',
                                                      style: TextStyle(
                                                        color: ChoiceLuxTheme.platinumSilver,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                MouseRegion(
                                                  onEnter: (_) => setState(() => _isHoveringForgotPassword = true),
                                                  onExit: (_) => setState(() => _isHoveringForgotPassword = false),
                                                  child: TextButton(
                                                    onPressed: () {
                                                      // TODO: Implement forgot password
                                                    },
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: _isHoveringForgotPassword 
                                                          ? ChoiceLuxTheme.richGold 
                                                          : ChoiceLuxTheme.platinumSilver,
                                                    ),
                                                    child: Text(
                                                      'Forgot Password?',
                                                      style: TextStyle(
                                                        decoration: _isHoveringForgotPassword 
                                                            ? TextDecoration.underline 
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile = constraints.maxWidth < 400;
                                          return SizedBox(height: isMobile ? 24.0 : 32.0);
                                        },
                                      ),

                                      // Sign In Button
                                      AnimatedBuilder(
                                        animation: _buttonScaleAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _buttonScaleAnimation.value,
                                            child: SizedBox(
                                              width: double.infinity,
                                              height: 56,
                                              child: ElevatedButton(
                                                onPressed: authState.isLoading ? null : _signIn,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: ChoiceLuxTheme.richGold,
                                                  foregroundColor: Colors.black,
                                                  elevation: 8,
                                                  shadowColor: ChoiceLuxTheme.richGold.withOpacity(0.4),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                ),
                                                child: authState.isLoading
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
                                                            'Signing In...',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        'Sign In',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile = constraints.maxWidth < 400;
                                          return SizedBox(height: isMobile ? 24.0 : 32.0);
                                        },
                                      ),

                                      // Sign Up Link
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                          MouseRegion(
                                            onEnter: (_) => setState(() => _isHoveringSignUp = true),
                                            onExit: (_) => setState(() => _isHoveringSignUp = false),
                                            child: TextButton(
                                              onPressed: () => context.go('/signup'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: _isHoveringSignUp 
                                                    ? ChoiceLuxTheme.richGold 
                                                    : ChoiceLuxTheme.richGold.withOpacity(0.8),
                                              ),
                                              child: Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  decoration: _isHoveringSignUp 
                                                      ? TextDecoration.underline 
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) {
        // Clear error state when user starts typing
        if (ref.read(authProvider).hasError) {
          ref.read(authProvider.notifier).clearError();
        }
      },
      style: const TextStyle(
        color: ChoiceLuxTheme.softWhite,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: ChoiceLuxTheme.platinumSilver,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
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
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.8)),
        ),
        labelStyle: TextStyle(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ChoiceLuxTheme.richGold.withOpacity(0.03)
      ..strokeWidth = 1;

    // Draw subtle grid pattern
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 