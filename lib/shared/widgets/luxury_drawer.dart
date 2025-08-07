import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

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

  Widget _buildMobileDrawer(BuildContext context, String displayName, userProfile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.jetBlack,
            ChoiceLuxTheme.charcoalGray,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
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
                  if (userProfile?.role != null && userProfile!.role != 'unassigned')
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
                            print('Navigate to Settings');
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
                          print('Navigate to About');
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.contact_support_outlined,
                        title: 'Contact Information',
                        onTap: () {
                          print('Navigate to Contact');
                        },
                      ),
                    ],
                  ),
                  
                  // Legal & Support Section (Collapsible)
                  _buildCollapsibleSection(
                    title: 'Legal & Support',
                    isExpanded: _isLegalExpanded,
                    onToggle: () => setState(() => _isLegalExpanded = !_isLegalExpanded),
                    items: [
                      _buildMobileMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          print('Navigate to Privacy Policy');
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {
                          print('Navigate to Terms of Service');
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          print('Navigate to Help & Support');
                        },
                      ),
                    ],
                  ),
                  
                  // Administration Section (Role-based)
                  if (userProfile?.role == 'admin') ...[
                    _buildMobileMenuSection(
                      title: 'Administration',
                      items: [
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
                            print('Navigate to System Settings');
                          },
                        ),
                        _buildMobileMenuItem(
                          icon: Icons.analytics_outlined,
                          title: 'Reports & Analytics',
                          onTap: () {
                            print('Navigate to Reports & Analytics');
                          },
                        ),
                      ],
                    ),
                  ],
                  
                  // App Section (Collapsible)
                  _buildCollapsibleSection(
                    title: 'App',
                    isExpanded: _isAppExpanded,
                    onToggle: () => setState(() => _isAppExpanded = !_isAppExpanded),
                    items: [
                      _buildMobileMenuItem(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        subtitle: 'Version 1.0.0',
                        onTap: () {
                          print('Show App Version Info');
                        },
                      ),
                      _buildMobileMenuItem(
                        icon: Icons.update_outlined,
                        title: 'Check for Updates',
                        onTap: () {
                          print('Check for Updates');
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
    );
  }

  Widget _buildDesktopDrawer(BuildContext context, String displayName, userProfile) {
    return Drawer(
      width: 280,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ChoiceLuxTheme.jetBlack,
              ChoiceLuxTheme.charcoalGray,
            ],
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
                    if (userProfile?.role != null && userProfile!.role != 'unassigned')
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
                              print('Navigate to Settings');
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
                              print('Navigate to About');
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.contact_support_outlined,
                            title: 'Contact Information',
                            subtitle: 'Get in touch with us',
                            onTap: () {
                              print('Navigate to Contact');
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
                              print('Navigate to Privacy Policy');
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'Our terms and conditions',
                            onTap: () {
                              print('Navigate to Terms of Service');
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'Get help and support',
                            onTap: () {
                              print('Navigate to Help & Support');
                            },
                          ),
                        ],
                      ),
                    
                    // Administration Section (Role-based)
                    if (userProfile?.role == 'admin') ...[
                      _buildMenuSection(
                        title: 'Administration',
                        items: [
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
                              print('Navigate to System Settings');
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.analytics_outlined,
                            title: 'Reports & Analytics',
                            subtitle: 'View business insights',
                            onTap: () {
                              print('Navigate to Reports & Analytics');
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
                            print('Show App Version Info');
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.system_update_outlined,
                          title: 'Check for Updates',
                          subtitle: 'Update the application',
                          onTap: () {
                            print('Check for Updates');
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

  Widget _buildMobileHeader(BuildContext context, String displayName, userProfile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.richGold.withOpacity(0.15),
            ChoiceLuxTheme.richGold.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  ChoiceLuxTheme.richGold.withOpacity(0.7),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.2),
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
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
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.directions_car,
              color: ChoiceLuxTheme.richGold,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, String displayName, userProfile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.richGold.withOpacity(0.15),
            ChoiceLuxTheme.richGold.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
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
                      ChoiceLuxTheme.richGold.withOpacity(0.7),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
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
            style: TextStyle(
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
                  style: TextStyle(
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
        if (isExpanded) ...[
          ...items,
          const SizedBox(height: 4),
        ],
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
        splashColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
        highlightColor: ChoiceLuxTheme.richGold.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
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
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5),
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
            style: TextStyle(
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
        splashColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
        highlightColor: ChoiceLuxTheme.richGold.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
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
            color: ChoiceLuxTheme.richGold.withOpacity(0.2),
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
              icon: Icon(
                Icons.logout,
                color: ChoiceLuxTheme.errorColor,
                size: 20,
              ),
              label: Text(
                'Sign Out',
                style: TextStyle(
                  color: ChoiceLuxTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: ChoiceLuxTheme.errorColor.withOpacity(0.3),
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
            color: ChoiceLuxTheme.richGold.withOpacity(0.2),
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
              icon: Icon(
                Icons.logout,
                color: ChoiceLuxTheme.errorColor,
                size: 20,
              ),
              label: Text(
                'Sign Out',
                style: TextStyle(
                  color: ChoiceLuxTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: ChoiceLuxTheme.errorColor.withOpacity(0.3),
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
      await ref.read(authProvider.notifier).signOut();
    }
  }


} 
