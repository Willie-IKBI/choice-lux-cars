import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/dashboard_card.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Get display name from profile, fallback to email, then to 'User'
    String userName = 'User';
    if (userProfile != null && userProfile.displayNameOrEmail != 'User') {
      userName = userProfile.displayNameOrEmail;
    } else if (currentUser?.email != null) {
      userName = currentUser!.email!.split('@')[0];
    }
    
    // Responsive padding - removed horizontal padding for mobile since GridView handles it
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;
    
    final horizontalPadding = isSmallMobile ? 0.0 : isMobile ? 0.0 : 24.0;
    final verticalPadding = isSmallMobile ? 8.0 : isMobile ? 12.0 : 16.0;
    final sectionSpacing = isSmallMobile ? 16.0 : isMobile ? 24.0 : 32.0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: LuxuryAppBar(
        title: 'Choice Lux Cars',
        showLogo: true,
        showProfile: true,
        onNotificationTap: _handleNotifications,
        onMenuTap: () {
          if (isMobile) {
            _showMobileDrawer(context);
          } else {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
      ),
      drawer: isMobile ? null : LuxuryDrawer(),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, 
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(context, userName),
                SizedBox(height: sectionSpacing),
                
                // Dashboard Cards
                _buildDashboardCards(context),
                SizedBox(height: sectionSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LuxuryDrawer(),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String userName) {
    // Responsive sizing for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    
    final titleSize = isSmallMobile ? 18.0 : isMobile ? 20.0 : 32.0;
    final subtitleSize = isSmallMobile ? 12.0 : isMobile ? 14.0 : 18.0;
    final spacing = isSmallMobile ? 3.0 : isMobile ? 4.0 : 8.0;
    final sectionSpacing = isSmallMobile ? 6.0 : isMobile ? 8.0 : 16.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: ChoiceLuxTheme.richGold,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: titleSize,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          'Welcome back, $userName 👋',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ChoiceLuxTheme.platinumSilver,
            fontWeight: FontWeight.w500,
            fontSize: subtitleSize,
          ),
        ),
        SizedBox(height: sectionSpacing),
        Container(
          height: 2,
          width: isSmallMobile ? 30 : isMobile ? 40 : 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ChoiceLuxTheme.richGold,
                ChoiceLuxTheme.richGold.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final dashboardItems = [
      if (userProfile != null && (userProfile.role?.toLowerCase() == 'administrator' || userProfile.role?.toLowerCase() == 'manager'))
        DashboardItem(
          title: 'Manage Users',
          subtitle: 'User & driver management',
          icon: Icons.people,
          route: '/users',
          color: ChoiceLuxTheme.richGold,
        ),
      DashboardItem(
        title: 'Clients',
        subtitle: 'Manage client relationships',
        icon: Icons.people_outline,
        route: '/clients',
        color: ChoiceLuxTheme.richGold,
      ),
      DashboardItem(
        title: 'Vehicles',
        subtitle: 'Manage fleet vehicles',
        icon: Icons.directions_car_outlined,
        route: '/vehicles',
        color: ChoiceLuxTheme.richGold,
      ),
      DashboardItem(
        title: 'Quotes',
        subtitle: 'Create and manage quotes',
        icon: Icons.description_outlined,
        route: '/quotes',
        color: ChoiceLuxTheme.richGold,
      ),
      DashboardItem(
        title: 'Jobs',
        subtitle: 'Track job progress',
        icon: Icons.work_outline,
        route: '/jobs',
        color: ChoiceLuxTheme.richGold,
      ),
      DashboardItem(
        title: 'Invoices',
        subtitle: 'Generate and manage invoices',
        icon: Icons.receipt_long_outlined,
        route: '/invoices',
        color: ChoiceLuxTheme.richGold,
      ),
      DashboardItem(
        title: 'Vouchers',
        subtitle: 'Create and track vouchers',
        icon: Icons.card_giftcard_outlined,
        route: '/vouchers',
        color: ChoiceLuxTheme.richGold,
      ),
    ];

    // Responsive grid configuration based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Debug: Print screen dimensions
    print('Screen dimensions: ${screenWidth}x${screenHeight}');
    
    // TEMPORARY: Force 2 columns for mobile testing
    int crossAxisCount;
    double spacing;
    double childAspectRatio;
    EdgeInsets outerPadding;
    
    if (screenWidth > 1200) {
      crossAxisCount = 4; // Large desktop
      spacing = 20.0;
      childAspectRatio = 1.1;
      outerPadding = const EdgeInsets.all(24.0);
      print('Layout: Large Desktop (4 columns)');
    } else if (screenWidth > 800) {
      crossAxisCount = 3; // Desktop
      spacing = 18.0;
      childAspectRatio = 1.0;
      outerPadding = const EdgeInsets.all(20.0);
      print('Layout: Desktop (3 columns)');
    } else if (screenWidth > 600) {
      crossAxisCount = 2; // Tablet
      spacing = 16.0;
      childAspectRatio = 1.0;
      outerPadding = const EdgeInsets.all(16.0);
      print('Layout: Tablet (2 columns)');
    } else {
      // FORCE 2 columns for all mobile devices for testing
      crossAxisCount = 2; // Mobile phones - 2 cards per row
      spacing = 12.0;
      childAspectRatio = 1.0;
      outerPadding = const EdgeInsets.all(12.0);
      print('Layout: Mobile (2 columns) - FORCED for testing');
    }

    print('Final GridView config: crossAxisCount=$crossAxisCount, spacing=$spacing, aspectRatio=$childAspectRatio');

    return Padding(
      padding: outerPadding,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Prevent internal scrolling
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
        children: dashboardItems.map((item) => DashboardCard(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          iconColor: item.color,
          onTap: () => context.go(item.route),
        )).toList(),
      ),
    );
  }
}

// Dashboard Item Model
class DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });
}

// Notification handler
void _handleNotifications() {
  // TODO: Implement notifications screen
  print('Notifications tapped');
} 