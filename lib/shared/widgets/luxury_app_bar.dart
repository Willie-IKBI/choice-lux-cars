import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class LuxuryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;
  final bool showProfile;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSignOut;

  const LuxuryAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true,
    this.showProfile = true,
    this.onProfileTap,
    this.onNotificationTap,
    this.onMenuTap,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Get display name from profile, fallback to email, then to 'User'
    String displayName = 'User';
    if (userProfile != null && userProfile.displayNameOrEmail != 'User') {
      displayName = userProfile.displayNameOrEmail;
    } else if (currentUser?.email != null) {
      displayName = currentUser!.email!.split('@')[0];
    }
    
    return Container(
      height: isMobile ? 56 : 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.jetBlack.withOpacity(0.98),
            ChoiceLuxTheme.jetBlack.withOpacity(0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Menu Button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu,
                    color: ChoiceLuxTheme.richGold,
                    size: 20,
                  ),
                ),
                onPressed: onMenuTap ?? () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              
              const SizedBox(width: 12),
              
              // Brand Icon with Glow
              if (showLogo) ...[
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold,
                        ChoiceLuxTheme.richGold.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: ChoiceLuxTheme.jetBlack,
                    child: Icon(
                      Icons.directions_car,
                      color: ChoiceLuxTheme.richGold,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // App Title
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ChoiceLuxTheme.richGold,
                    letterSpacing: 0.5,
                    fontSize: isMobile ? 16 : 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Notification Icon with Badge
              if (onNotificationTap != null)
                Stack(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: ChoiceLuxTheme.richGold,
                          size: 20,
                        ),
                      ),
                      onPressed: onNotificationTap,
                    ),
                    // Notification Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ChoiceLuxTheme.jetBlack,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(width: 8),
              
              // User Profile Section
              if (showProfile && currentUser != null) ...[
                if (isMobile)
                  // Mobile: Icon-only with popup menu
                  _buildMobileUserMenu(context, displayName, userProfile)
                else
                  // Desktop: Full user chip with popup menu
                  _buildDesktopUserChip(context, displayName, userProfile),
              ],
              
              // Custom Actions
              if (actions != null) ...[
                const SizedBox(width: 8),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUserMenu(BuildContext context, String displayName, userProfile) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: ChoiceLuxTheme.charcoalGray,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.richGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.person,
              color: ChoiceLuxTheme.richGold,
              size: 18,
            ),
            // Show first letter of name as overlay
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: ChoiceLuxTheme.jetBlack,
                      fontSize: 6,
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
        // User Info Header
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (userProfile?.role != null)
                        Text(
                          userProfile!.role!.toUpperCase(),
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        // Menu Items
        _buildPopupMenuItem(
          icon: Icons.person_outline,
          title: 'Profile',
          onTap: () {
            Navigator.of(context).pop();
            print('Navigate to Profile');
          },
        ),
        _buildPopupMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Navigator.of(context).pop();
            print('Navigate to Settings');
          },
        ),
        const PopupMenuDivider(),
        _buildPopupMenuItem(
          icon: Icons.logout,
          title: 'Sign Out',
          isDestructive: true,
          onTap: () async {
            Navigator.of(context).pop();
            await _showSignOutDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildDesktopUserChip(BuildContext context, String displayName, userProfile) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: ChoiceLuxTheme.charcoalGray,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.richGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
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
                radius: 14,
                backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.2),
                child: Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayName,
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: ChoiceLuxTheme.richGold,
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // User Info Header
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                    radius: 20,
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
                const SizedBox(width: 12),
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
                      if (userProfile?.role != null)
                        Text(
                          userProfile!.role!.toUpperCase(),
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        // Menu Items
        _buildPopupMenuItem(
          icon: Icons.person_outline,
          title: 'Profile',
          onTap: () {
            Navigator.of(context).pop();
            print('Navigate to Profile');
          },
        ),
        _buildPopupMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Navigator.of(context).pop();
            print('Navigate to Settings');
          },
        ),
        const PopupMenuDivider(),
        _buildPopupMenuItem(
          icon: Icons.logout,
          title: 'Sign Out',
          isDestructive: true,
          onTap: () async {
            Navigator.of(context).pop();
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
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive 
                ? ChoiceLuxTheme.errorColor 
                : ChoiceLuxTheme.richGold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDestructive 
                  ? ChoiceLuxTheme.errorColor 
                  : ChoiceLuxTheme.softWhite,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
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
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: ChoiceLuxTheme.errorColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
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
  Size get preferredSize => const Size.fromHeight(64);
} 
