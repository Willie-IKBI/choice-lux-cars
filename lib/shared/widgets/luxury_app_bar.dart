import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

import 'package:choice_lux_cars/shared/widgets/notification_bell.dart';
import 'package:go_router/go_router.dart';

class LuxuryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogo;
  final bool showProfile;
  final bool showBackButton;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSignOut;
  final VoidCallback? onBackPressed;

  const LuxuryAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLogo = true,
    this.showProfile = true,
    this.showBackButton = false,
    this.onProfileTap,
    this.onNotificationTap,
    this.onMenuTap,
    this.onSignOut,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    // Get display name from profile, fallback to email, then to 'User'
    String displayName = 'User';
    if (userProfile != null && userProfile.displayNameOrEmail != 'User') {
      displayName = userProfile.displayNameOrEmail;
    } else if (currentUser?.email != null) {
      displayName = currentUser!.email!.split('@')[0];
    }

    return Container(
      height: isMobile ? 64 : 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.jetBlack.withValues(alpha: 0.95),
            ChoiceLuxTheme.jetBlack.withValues(alpha: 0.90),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
              // Back Button or Menu Button
              if (showBackButton)
                _buildBackButton(context)
              else
                _buildMenuButton(context),

              const SizedBox(width: 16),

              // Brand Icon with Enhanced Glow
              if (showLogo) ...[_buildBrandIcon(), const SizedBox(width: 16)],

              // Title Section with Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ChoiceLuxTheme.softWhite,
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
                          color: ChoiceLuxTheme.platinumSilver.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Notification Icon with Enhanced Badge
              if (onNotificationTap != null) ...[
                _buildNotificationButton(),
                const SizedBox(width: 16),
              ],

              // User Profile Section
              if (showProfile && currentUser != null) ...[
                if (isMobile)
                  _buildMobileUserMenu(context, displayName, userProfile)
                else
                  _buildDesktopUserMenu(context, displayName, userProfile),
                const SizedBox(width: 8),
              ],

              // Custom Actions
              if (actions != null) ...[...actions!],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: ChoiceLuxTheme.richGold,
          size: 20,
        ),
        onPressed:
            onBackPressed ??
            () {
              Log.d('Back button pressed - attempting to pop context');
              try {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                  Log.d('Context pop successful');
                } else {
                  Log.d('Cannot pop - navigating to dashboard');
                  context.go('/dashboard');
                }
              } catch (e) {
                Log.d('Error popping context: $e');
                // Fallback to go to dashboard
                context.go('/dashboard');
              }
            },
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.menu_rounded,
          color: ChoiceLuxTheme.richGold,
          size: 20,
        ),
        onPressed:
            onMenuTap ??
            () {
              Scaffold.of(context).openDrawer();
            },
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }

  Widget _buildBrandIcon() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            ChoiceLuxTheme.richGold,
            ChoiceLuxTheme.richGold.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: ChoiceLuxTheme.jetBlack,
        child: Icon(
          Icons.directions_car_rounded,
          color: ChoiceLuxTheme.richGold,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Consumer(
      builder: (context, ref, child) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        return NotificationBell(
          iconColor: ChoiceLuxTheme.richGold,
          size: isMobile ? 18 : 20,
          showCount: true, // You can set this to false for just a dot
          onTap: onNotificationTap,
        );
      },
    );
  }

  Widget _buildMobileUserMenu(
    BuildContext context,
    String displayName,
    userProfile,
  ) {
    // Hide profile menu for unassigned users
    if (userProfile?.role == null || userProfile!.role == 'unassigned') {
      return Container();
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ChoiceLuxTheme.charcoalGray,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.person_rounded,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
            // Enhanced user indicator
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ChoiceLuxTheme.jetBlack,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: ChoiceLuxTheme.jetBlack,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // Enhanced User Info Header
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Enhanced Avatar with Gold Ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold,
                        ChoiceLuxTheme.richGold.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.2),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: ChoiceLuxTheme.richGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (userProfile?.role != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          userProfile!.role!.toUpperCase(),
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Enhanced Menu Items
        _buildPopupMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Profile',
          onTap: () {
            context.go('/user-profile');
          },
        ),
        _buildPopupMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Log.d('Navigate to Settings');
            context.push('/settings');
          },
        ),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          isDestructive: true,
          onTap: () async {
            await _showSignOutDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildDesktopUserMenu(
    BuildContext context,
    String displayName,
    userProfile,
  ) {
    // Hide profile menu for unassigned users
    if (userProfile?.role == null || userProfile!.role == 'unassigned') {
      return Container();
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ChoiceLuxTheme.charcoalGray,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Avatar with Gold Ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    ChoiceLuxTheme.richGold,
                    ChoiceLuxTheme.richGold.withOpacity(0.7),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.2),
                child: Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              displayName,
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ChoiceLuxTheme.richGold,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // Enhanced User Info Header
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Enhanced Avatar with Gold Ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold,
                        ChoiceLuxTheme.richGold.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.2),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: ChoiceLuxTheme.richGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      if (userProfile?.role != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          userProfile!.role!.toUpperCase(),
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Enhanced Menu Items
        _buildPopupMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Profile',
          onTap: () {
            context.go('/user-profile');
          },
        ),
        _buildPopupMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Log.d('Navigate to Settings');
            context.push('/settings');
          },
        ),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          isDestructive: true,
          onTap: () async {
            await _showSignOutDialog(context);
          },
        ),
      ],
    );
  }

  PopupMenuEntry<String> _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: title,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? ChoiceLuxTheme.errorColor
                  : ChoiceLuxTheme.richGold,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive
                    ? ChoiceLuxTheme.errorColor
                    : ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ChoiceLuxTheme.charcoalGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: ChoiceLuxTheme.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.errorColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      onSignOut?.call();
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
