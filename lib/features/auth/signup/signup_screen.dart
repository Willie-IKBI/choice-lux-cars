import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/constants.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/utils/auth_error_utils.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isHoveringSignIn = false;
  bool _isHoveringLogo = false;
  // New users are unassigned by default - only admins can assign roles later

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      _buttonAnimationController.forward().then((_) {
        _buttonAnimationController.reverse();
      });

      await ref
          .read(authProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate to dashboard if authenticated
    ref.listen(authProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        context.go('/');
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ChoiceLuxTheme.backgroundGradient),
        child: Stack(
          children: [
                         // Subtle background pattern
             Positioned.fill(
               child: CustomPaint(painter: BackgroundPatterns.signin),
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
                                        onEnter: (_) => setState(
                                          () => _isHoveringLogo = true,
                                        ),
                                        onExit: (_) => setState(
                                          () => _isHoveringLogo = false,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          curve: Curves.easeInOut,
                                          width: 72,
                                          height: 72,
                                          transform: Matrix4.identity()
                                            ..scale(
                                              _isHoveringLogo ? 1.05 : 1.0,
                                            ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            border: Border.all(
                                              color: ChoiceLuxTheme.richGold,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: ChoiceLuxTheme.richGold
                                                    .withOpacity(0.3),
                                                blurRadius: _isHoveringLogo
                                                    ? 15
                                                    : 10,
                                                offset: Offset(
                                                  0,
                                                  _isHoveringLogo ? 6 : 4,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Image.asset(
                                              'assets/images/clc_logo.png',
                                              fit: BoxFit.contain,
                                              // Optional: Apply color filter if logo needs to match theme
                                              // color: ChoiceLuxTheme.richGold,
                                              // colorBlendMode: BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          final titleSize = isMobile
                                              ? 24.0
                                              : 28.0;
                                          final subtitleSize = isMobile
                                              ? 10.0
                                              : 12.0;

                                          return Column(
                                            children: [
                                              Text(
                                                'Choice Lux Cars',
                                                style: GoogleFonts.outfit(
                                                  fontSize: titleSize,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      ChoiceLuxTheme.richGold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'CREATE YOUR ACCOUNT',
                                                style: GoogleFonts.inter(
                                                  letterSpacing: 1.2,
                                                  fontSize: subtitleSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: ChoiceLuxTheme
                                                      .platinumSilver
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 40),

                                      // Display Name Field
                                      _buildInputField(
                                        controller: _displayNameController,
                                        label: 'Full Name',
                                        icon: Icons.person_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your full name';
                                          }
                                          if (value.length >
                                              AppConstants.maxNameLength) {
                                            return 'Name must be less than ${AppConstants.maxNameLength} characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          return SizedBox(
                                            height: isMobile ? 16.0 : 20.0,
                                          );
                                        },
                                      ),

                                      // Email Field
                                      _buildInputField(
                                        controller: _emailController,
                                        label: 'Email Address',
                                        icon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          return SizedBox(
                                            height: isMobile ? 16.0 : 20.0,
                                          );
                                        },
                                      ),

                                      // Password Field
                                      _buildInputField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock_outline,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color:
                                                ChoiceLuxTheme.platinumSilver,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a password';
                                          }
                                          if (value.length <
                                              AppConstants.minPasswordLength) {
                                            return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          return SizedBox(
                                            height: isMobile ? 16.0 : 20.0,
                                          );
                                        },
                                      ),

                                      // Confirm Password Field
                                      _buildInputField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirm Password',
                                        icon: Icons.lock_outline,
                                        obscureText: _obscureConfirmPassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color:
                                                ChoiceLuxTheme.platinumSilver,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your password';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          return SizedBox(
                                            height: isMobile ? 24.0 : 32.0,
                                          );
                                        },
                                      ),

                                      // Error Message
                                      if (authState.hasError)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          margin: const EdgeInsets.only(
                                            bottom: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ChoiceLuxTheme.errorColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: ChoiceLuxTheme.errorColor
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: ChoiceLuxTheme
                                                      .errorColor
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.error_outline_rounded,
                                                  color:
                                                      ChoiceLuxTheme.errorColor,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Signup Error',
                                                      style: TextStyle(
                                                        color: ChoiceLuxTheme
                                                            .errorColor,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      AuthErrorUtils.getErrorMessage(
                                                        authState.error,
                                                      ),
                                                      style: TextStyle(
                                                        color: ChoiceLuxTheme
                                                            .platinumSilver,
                                                        fontSize: 13,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                        authProvider.notifier,
                                                      )
                                                      .clearError();
                                                },
                                                icon: Icon(
                                                  Icons.close_rounded,
                                                  color: ChoiceLuxTheme
                                                      .platinumSilver,
                                                  size: 20,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          return SizedBox(
                                            height: isMobile ? 16.0 : 20.0,
                                          );
                                        },
                                      ),

                                      // Sign Up Button
                                      AnimatedBuilder(
                                        animation: _buttonScaleAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _buttonScaleAnimation.value,
                                            child: SizedBox(
                                              width: double.infinity,
                                              height: 56,
                                              child: ElevatedButton(
                                                onPressed: authState.isLoading
                                                    ? null
                                                    : _signUp,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      ChoiceLuxTheme.richGold,
                                                  foregroundColor: Colors.black,
                                                  elevation: 8,
                                                  shadowColor: ChoiceLuxTheme
                                                      .richGold
                                                      .withOpacity(0.4),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                child: authState.isLoading
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Colors
                                                                        .black,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Text(
                                                            'Creating Account...',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        'Create Account',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          return SizedBox(
                                            height: isMobile ? 16.0 : 20.0,
                                          );
                                        },
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile =
                                              constraints.maxWidth < 400;
                                          return SizedBox(
                                            height: isMobile ? 24.0 : 32.0,
                                          );
                                        },
                                      ),

                                      // Sign In Link
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Already have an account? ",
                                            style: TextStyle(
                                              color: ChoiceLuxTheme
                                                  .platinumSilver
                                                  .withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                          MouseRegion(
                                            onEnter: (_) => setState(
                                              () => _isHoveringSignIn = true,
                                            ),
                                            onExit: (_) => setState(
                                              () => _isHoveringSignIn = false,
                                            ),
                                            child: TextButton(
                                              onPressed: () =>
                                                  context.go('/login'),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    _isHoveringSignIn
                                                    ? ChoiceLuxTheme.richGold
                                                    : ChoiceLuxTheme.richGold
                                                          .withOpacity(0.8),
                                              ),
                                              child: Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  decoration: _isHoveringSignIn
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
      style: const TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ChoiceLuxTheme.platinumSilver),
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
          borderSide: BorderSide(color: ChoiceLuxTheme.richGold, width: 2),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}


