import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/services/permission_service.dart';

class LuxuryDrawer extends ConsumerStatefulWidget {
  const LuxuryDrawer({super.key});

  @override
  ConsumerState<LuxuryDrawer> createState() => _LuxuryDrawerState();
}

class _LuxuryDrawerState extends ConsumerState<LuxuryDrawer> {
  bool _isLegalExpanded = false;
  bool _isAppExpanded = false;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Get display name from profile, fallback to email, then to 'User'
    String displayName = 'User';
    if (userProfile != null && userProfile.displayNameOrEmail != 'User') {
      displayName = userProfile.displayNameOrEmail;
    } else if (currentUser?.email != null) {
      displayName = currentUser!.email!.split('@')[0];
    }

    // Use modal bottom sheet for mobile devices
    if (isMobile) {
      return _buildMobileDrawer(context, displayName, userProfile);
    }

    return _buildDesktopDrawer(context, displayName, userProfile);
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    String displayName,
    userProfile,
  ) {
    final userRole = userProfile?.role;
    final permissionService = const PermissionService();
    final isAdmin = permissionService.isAdmin(userRole);
    final canAccessUsers = permissionService.isAdmin(userRole) || permissionService.isManager(userRole);
    final canAccessInsights = permissionService.isAdmin(userRole) || permissionService.isManager(userRole);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ChoiceLuxTheme.jetBlack, ChoiceLuxTheme.charcoalGray],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: true, // Ensure bottom padding for system navigation bar
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Section (Compact)
          _buildMobileHeader(context, displayName, userProfile),

          // Menu Items (Scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Account Section
                  if (userProfile?.role != null &&
                      userProfile!.role != 'unassigned')
                    _buildMobileMenuSection(
                      title: 'Account',
                      items: [
                        _buildMobileMenuItem(
                          icon: Icons.person_outline,
                          title: 'User Profile',
                          onTap: () {
                            context.go('/user-profile');
                          },
                        ),
                        _buildMobileMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: () {
                            Log.d('Navigate to Settings');
                            Navigator.pop(context);
                            context.push('/settings');
                          },
                        ),
                      ],
                    ),

                  // Company Section
                  _buildMobileMenuSection(
                    title: 'Company',
                    items: [
                      _buildMobileMenuItem(
                        icon: Icons.business_outlined,
                        title: 'About Choice Lux Cars',
                        onTap: () {
                          Log.d('Navigate to About');
                          Navigator.pop(context);
                          context.push('/about');
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.contact_support_outlined,
                        title: 'Contact Information',
                        onTap: () {
                          Log.d('Navigate to Contact');
                          Navigator.pop(context);
                          context.push('/contact');
                        },
                      ),
                    ],
                  ),

                  // Legal & Support Section (Collapsible)
                  _buildCollapsibleSection(
                    title: 'Legal & Support',
                    isExpanded: _isLegalExpanded,
                    onToggle: () =>
                        setState(() => _isLegalExpanded = !_isLegalExpanded),
                    items: [
                      _buildMobileMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          Log.d('Navigate to Privacy Policy');
                          Navigator.pop(context);
                          context.push('/privacy-policy');
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {
                          Log.d('Navigate to Terms of Service');
                          Navigator.pop(context);
                          context.push('/terms-of-service');
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Log.d('Navigate to Help & Support');
                          Navigator.pop(context);
                          context.push('/help-support');
                        },
                      ),
                    ],
                  ),

                  // Administration Section (Role-based) - Admin only
                  if (isAdmin) ...[
                    _buildMobileMenuSection(
                      title: 'Administration',
                      items: [
                        if (canAccessUsers)
                          _buildMobileMenuItem(
                            icon: Icons.people_outline,
                            title: 'User Management',
                            onTap: () {
                              context.go('/users');
                            },
                          ),
                        _buildMobileMenuItem(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'System Settings',
                          onTap: () {
                            Log.d('Navigate to System Settings');
                            Navigator.pop(context);
                            context.push('/system-settings');
                          },
                        ),
                        if (canAccessInsights)
                          _buildMobileMenuItem(
                            icon: Icons.analytics_outlined,
                            title: 'Business Insights',
                            onTap: () {
                              Log.d('Navigate to Business Insights');
                              Navigator.pop(context);
                              context.go('/insights');
                            },
                          ),
                      ],
                    ),
                  ] else ...[
                    // Show User Management and Business Insights for Managers outside Administration section
                    if (canAccessUsers || canAccessInsights)
                      _buildMobileMenuSection(
                        title: 'Management',
                        items: [
                          if (canAccessUsers)
                            _buildMobileMenuItem(
                              icon: Icons.people_outline,
                              title: 'User Management',
                              onTap: () {
                                context.go('/users');
                              },
                            ),
                          if (canAccessInsights)
                            _buildMobileMenuItem(
                              icon: Icons.analytics_outlined,
                              title: 'Business Insights',
                              onTap: () {
                                Log.d('Navigate to Business Insights');
                                Navigator.pop(context);
                                context.go('/insights');
                              },
                            ),
                        ],
                      ),
                  ],

                  // App Section (Collapsible)
                  _buildCollapsibleSection(
                    title: 'App',
                    isExpanded: _isAppExpanded,
                    onToggle: () =>
                        setState(() => _isAppExpanded = !_isAppExpanded),
                    items: [
                      _buildMobileMenuItem(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        subtitle: 'Version 1.0.0',
                        onTap: () {
                          Log.d('Show App Version Info');
                          _showVersionInfo(context);
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.update_outlined,
                        title: 'Check for Updates',
                        onTap: () {
                          Log.d('Check for Updates');
                          _checkForUpdates(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Section - Sign Out & Exit
          _buildMobileBottomSection(context),
        ],
        ),
      ),
    );
  }

  Widget _buildDesktopDrawer(
    BuildContext context,
    String displayName,
    userProfile,
  ) {
    final userRole = userProfile?.role;
    final permissionService = const PermissionService();
    final isAdmin = permissionService.isAdmin(userRole);
    final canAccessUsers = permissionService.isAdmin(userRole) || permissionService.isManager(userRole);
    final canAccessInsights = permissionService.isAdmin(userRole) || permissionService.isManager(userRole);
    return Drawer(
      width: 280,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ChoiceLuxTheme.jetBlack, ChoiceLuxTheme.charcoalGray],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            _buildDesktopHeader(context, displayName, userProfile),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // User Profile Section
                    if (userProfile?.role != null &&
                        userProfile!.role != 'unassigned')
                      _buildMenuSection(
                        title: 'Account',
                        items: [
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'User Profile',
                            subtitle: 'View and edit your profile',
                            onTap: () {
                              context.go('/user-profile');
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'App preferences and notifications',
                            onTap: () {
                              Log.d('Navigate to Settings');
                              Navigator.pop(context);
                              context.push('/settings');
                            },
                          ),
                        ],
                      ),

                    // Company Information Section
                    _buildMenuSection(
                      title: 'Company',
                      items: [
                        _buildMenuItem(
                          icon: Icons.business_outlined,
                          title: 'About Choice Lux Cars',
                          subtitle: 'Learn about our company',
                          onTap: () {
                            Log.d('Navigate to About');
                            Navigator.pop(context);
                            context.push('/about');
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.contact_support_outlined,
                          title: 'Contact Information',
                          subtitle: 'Get in touch with us',
                          onTap: () {
                            Log.d('Navigate to Contact');
                            Navigator.pop(context);
                            context.push('/contact');
                          },
                        ),
                      ],
                    ),

                    // Legal & Support Section
                    _buildMenuSection(
                      title: 'Legal & Support',
                      items: [
                        _buildMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'How we protect your data',
                          onTap: () {
                            Log.d('Navigate to Privacy Policy');
                            Navigator.pop(context);
                            context.push('/privacy-policy');
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          subtitle: 'Our terms and conditions',
                          onTap: () {
                            Log.d('Navigate to Terms of Service');
                            Navigator.pop(context);
                            context.push('/terms-of-service');
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help and support',
                          onTap: () {
                            Log.d('Navigate to Help & Support');
                            Navigator.pop(context);
                            context.push('/help-support');
                          },
                        ),
                      ],
                    ),

                    // Administration Section (Role-based) - Admin only
                    if (isAdmin) ...[
                      _buildMenuSection(
                        title: 'Administration',
                        items: [
                          if (canAccessUsers)
                            _buildMenuItem(
                              icon: Icons.people_outline,
                              title: 'User Management',
                              subtitle: 'Manage system users',
                              onTap: () {
                                context.go('/users');
                              },
                            ),
                          _buildMenuItem(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'System Settings',
                            subtitle: 'Configure system options',
                            onTap: () {
                              Log.d('Navigate to System Settings');
                              Navigator.pop(context);
                              context.push('/system-settings');
                            },
                          ),
                          if (canAccessInsights)
                            _buildMenuItem(
                              icon: Icons.analytics_outlined,
                              title: 'Business Insights',
                              subtitle: 'View analytics and reports',
                              onTap: () {
                                Log.d('Navigate to Business Insights');
                                Navigator.pop(context);
                                context.go('/insights');
                              },
                            ),
                        ],
                      ),
                    ] else ...[
                      // Show User Management and Business Insights for Managers outside Administration section
                      if (canAccessUsers || canAccessInsights)
                        _buildMenuSection(
                          title: 'Management',
                          items: [
                            if (canAccessUsers)
                              _buildMenuItem(
                                icon: Icons.people_outline,
                                title: 'User Management',
                                subtitle: 'Manage system users',
                                onTap: () {
                                  context.go('/users');
                                },
                              ),
                            if (canAccessInsights)
                              _buildMenuItem(
                                icon: Icons.analytics_outlined,
                                title: 'Business Insights',
                                subtitle: 'View analytics and reports',
                                onTap: () {
                                  Log.d('Navigate to Business Insights');
                                  Navigator.pop(context);
                                  context.go('/insights');
                                },
                              ),
                          ],
                        ),
                    ],

                    // App Management Section
                    _buildMenuSection(
                      title: 'App',
                      items: [
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'App Information',
                          subtitle: 'Version 1.0.0',
                          onTap: () {
                            Log.d('Show App Version Info');
                            _showVersionInfo(context);
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.system_update_outlined,
                          title: 'Check for Updates',
                          subtitle: 'Update the application',
                          onTap: () {
                            Log.d('Check for Updates');
                            _checkForUpdates(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section - Sign Out & Exit
            _buildBottomSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader(
    BuildContext context,
    String displayName,
    userProfile,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.richGold.withValues(alpha: 0.15),
            ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  ChoiceLuxTheme.richGold.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: ChoiceLuxTheme.richGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ChoiceLuxTheme.softWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (userProfile?.role != null)
                  Text(
                    userProfile!.role!.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ChoiceLuxTheme.richGold,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          // App Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.directions_car,
              color: ChoiceLuxTheme.richGold,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(
    BuildContext context,
    String displayName,
    userProfile,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.richGold.withValues(alpha: 0.15),
            ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and App Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: ChoiceLuxTheme.richGold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choice Lux Cars',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: ChoiceLuxTheme.richGold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Luxury Car Services',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ChoiceLuxTheme.platinumSilver,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Info with Enhanced Avatar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ChoiceLuxTheme.richGold,
                      ChoiceLuxTheme.richGold.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (userProfile?.role != null)
                      Text(
                        userProfile!.role!.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ChoiceLuxTheme.richGold,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[...items, const SizedBox(height: 4)],
      ],
    );
  }

  Widget _buildMobileMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
        highlightColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
        highlightColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _showSignOutDialog(context);
              },
              icon: const Icon(
                Icons.logout,
                color: ChoiceLuxTheme.errorColor,
                size: 20,
              ),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: ChoiceLuxTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.errorColor.withValues(alpha: 0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: ChoiceLuxTheme.errorColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _showSignOutDialog(context);
              },
              icon: const Icon(
                Icons.logout,
                color: ChoiceLuxTheme.errorColor,
                size: 20,
              ),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: ChoiceLuxTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.errorColor.withValues(alpha: 0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: ChoiceLuxTheme.errorColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
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
          title: const Row(
            children: [
              Icon(Icons.logout, color: ChoiceLuxTheme.errorColor, size: 24),
              SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
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
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  void _showVersionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ChoiceLuxTheme.charcoalGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: ChoiceLuxTheme.richGold,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'App Version',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Version 1.0.0',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: ChoiceLuxTheme.richGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _checkForUpdates(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ChoiceLuxTheme.charcoalGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.update_outlined,
                color: ChoiceLuxTheme.richGold,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Check for Updates',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Checking for updates...',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: ChoiceLuxTheme.richGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
