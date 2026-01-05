import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final success = await ref
          .read(authProvider.notifier)
          .resetPassword(email: _emailController.text.trim());

      setState(() {
        _isLoading = false;
      });

      if (success) {
        setState(() {
          _emailSent = true;
        });
      } else {
        // Error handling is done in the provider
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Failed to send reset email. Please try again.',
              ),
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
                            child: _emailSent
                                ? _buildSuccessView(isMobile)
                                : _buildResetForm(isMobile),
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
      ),
    );
  }

  Widget _buildResetForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/images/clc_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title and Subtitle
          Text(
            'Forgot Password',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 28.0 : 32.0,
              fontWeight: FontWeight.w700,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.w400,
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'EMAIL ADDRESS',
              prefixIcon: Icon(Icons.email_outlined, color: ChoiceLuxTheme.platinumSilver),
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            onFieldSubmitted: (_) => _sendResetEmail(),
          ),
          SizedBox(height: isMobile ? 24.0 : 32.0),

          // Send Reset Email button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.richGold,
                foregroundColor: Colors.black,
                elevation: 8,
                shadowColor: ChoiceLuxTheme.richGold.withOpacity(0.4),
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
                          'Sending...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Send Reset Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
          SizedBox(height: isMobile ? 24.0 : 32.0),

          // Back to Login link
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
            ),
            child: Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/images/clc_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        
        // Success icon
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: ChoiceLuxTheme.successColor,
        ),
        const SizedBox(height: 24),

        // Success title
        Text(
          'Email Sent',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 28.0 : 32.0,
            fontWeight: FontWeight.w700,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your inbox',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 12.0 : 14.0,
            fontWeight: FontWeight.w400,
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),

        // Email address
        Text(
          _emailController.text.trim(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: ChoiceLuxTheme.platinumSilver,
          ),
        ),
        SizedBox(height: isMobile ? 32.0 : 40.0),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _emailSent = false;
                    _emailController.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ChoiceLuxTheme.platinumSilver,
                  side: BorderSide(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Send Again'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: ChoiceLuxTheme.richGold.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


