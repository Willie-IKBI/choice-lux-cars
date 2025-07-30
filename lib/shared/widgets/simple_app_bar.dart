import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';

class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? titleColor;

  const SimpleAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      height: isMobile ? 64 : 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? ChoiceLuxTheme.jetBlack.withOpacity(0.95),
            backgroundColor ?? ChoiceLuxTheme.jetBlack.withOpacity(0.90),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Back Button
              if (showBackButton) ...[
                _buildBackButton(context),
                const SizedBox(width: 16),
              ],
              
              // Title Section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? ChoiceLuxTheme.softWhite,
                        letterSpacing: 0.3,
                        fontSize: isMobile ? 18 : 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              if (actions != null) ...[
                const SizedBox(width: 12),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.richGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: ChoiceLuxTheme.richGold,
          size: 20,
        ),
        onPressed: onBackPressed ?? () => context.pop(),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
} 