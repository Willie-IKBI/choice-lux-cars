import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/notifications/screens/notification_list_screen.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/features/notifications/services/notification_service.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/dashboard_card.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/core/services/job_deadline_check_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  void _startDeadlineCheckService(WidgetRef ref) {
    // Start deadline check service when dashboard loads
    final userProfile = ref.read(currentUserProfileProvider);
    if (userProfile?.role != null) {
      JobDeadlineCheckService.instance.start(userRole: userProfile!.role);
    }
  }

  @override
  void dispose() {
    // Stop the service when leaving dashboard
    JobDeadlineCheckService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final users = ref.watch(usersProvider);
    final jobs = ref.watch(jobsProvider);
    
    print('Dashboard - Main build - User profile: ${userProfile?.displayName}');
    print('Dashboard - Main build - User role: ${userProfile?.role}');
    print('Dashboard - Main build - Current user: ${currentUser?.email}');

    // Initialize notification provider once when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).initialize();
      // Start deadline check service for admin/manager/driver_manager
      _startDeadlineCheckService(ref);
    });
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

    // Get display name from profile, fallback to email, then to 'User'
    String userName = 'User';
    if (userProfile != null && userProfile.displayNameOrEmail != 'User') {
      userName = userProfile.displayNameOrEmail;
    } else if (currentUser?.email != null) {
      userName = currentUser!.email!.split('@')[0];
    }

    // Check user role
    final userRole = userProfile?.role?.toLowerCase();
    final isDriver = userRole == 'driver';
    final isAdmin = userRole == 'administrator' || userRole == 'super_admin';
    final isManager = userRole == 'manager';
    final isDriverManager = userRole == 'driver_manager';
    

    // Count today's jobs based on role
    final todayJobsCount = _getTodayJobsCount(
      jobs.value ?? [],
      userProfile,
      isDriver,
    );

    // Count unassigned users for admin notification
    final unassignedUsersCount = isAdmin
        ? (users.value ?? [])
              .where((user) => user.role == null || user.role == 'unassigned')
              .length
        : 0;

    // Responsive padding - provide minimal padding for mobile
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);

    final horizontalPadding = isSmallMobile
        ? 8.0
        : isMobile
        ? 12.0
        : 24.0;
    final verticalPadding = isSmallMobile
        ? 8.0
        : isMobile
        ? 12.0
        : 8.0; // Further reduced to 8px for desktop
    final sectionSpacing = isSmallMobile
        ? 16.0
        : isMobile
        ? 24.0
        : 12.0; // Further reduced to 12px for desktop

    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen (solid obsidian)
        Container(
          color: ChoiceLuxTheme.jetBlack,
        ),
        // Layer 2: The SystemSafeScaffold with proper system UI handling
        SystemSafeScaffold(
          scaffoldKey: _scaffoldKey,
          backgroundColor: Colors.transparent, // CRITICAL
          appBar: LuxuryAppBar(
            title: 'Dashboard',
            subtitle: 'OVERVIEW & STATISTICS',
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
          body: SingleChildScrollView(
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
                _buildDashboardCards(
                  context,
                  todayJobsCount,
                  unassignedUsersCount,
                ),
                SizedBox(height: sectionSpacing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Get today's jobs count based on user role
  int _getTodayJobsCount(List<Job> jobs, dynamic userProfile, bool isDriver) {
    if (jobs.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Filter jobs for today
    final todayJobs = jobs.where((job) {
      final jobDate = DateTime(
        job.jobStartDate.year,
        job.jobStartDate.month,
        job.jobStartDate.day,
      );
      return jobDate.isAtSameMomentAs(todayDate);
    }).toList();

    if (isDriver) {
      // For drivers, only count their assigned jobs
      return todayJobs.where((job) => job.driverId == userProfile?.id).length;
    } else {
      // For admin/manager/driver_manager, count all jobs
      return todayJobs.length;
    }
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
    // Get time-based greeting
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good Morning';
    } else if (hour < 17) {
      timeGreeting = 'Good Afternoon';
    } else {
      timeGreeting = 'Good Evening';
    }

    // Responsive sizing for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);

    final titleSize = isSmallMobile
        ? 24.0
        : isMobile
        ? 28.0
        : 32.0;
    final subtitleSize = isSmallMobile
        ? 14.0
        : isMobile
        ? 16.0
        : 16.0;
    final lineHeight = 2.0;
    final lineWidth = isSmallMobile
        ? 60.0
        : isMobile
        ? 80.0
        : 100.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 0.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$timeGreeting, $userName',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ChoiceLuxTheme.softWhite,
              fontWeight: FontWeight.w700,
              fontSize: titleSize,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Here's what's happening in your fleet today.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
              fontSize: subtitleSize,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: lineHeight,
            width: lineWidth,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards(
    BuildContext context,
    int todayJobsCount,
    int unassignedUsersCount,
  ) {
    print('Dashboard - _buildDashboardCards called');
    final userProfile = ref.watch(currentUserProfileProvider);
    final users = ref.watch(usersProvider);
    final userRole = userProfile?.role?.toLowerCase();
    final isDriver = userRole == 'driver';
    final isAdmin = userRole == 'administrator' || userRole == 'super_admin';
    final isManager = userRole == 'manager';
    final isDriverManager = userRole == 'driver_manager';
    
    print('Dashboard - User profile: ${userProfile?.displayName}');
    print('Dashboard - User role: $userRole');
    print('Dashboard - isAdmin: $isAdmin, isManager: $isManager, isDriver: $isDriver');

    // Build dashboard items based on role
    List<DashboardItem> dashboardItems = [];

    if (isDriver) {
      // Drivers only see Jobs card
      dashboardItems = [
        DashboardItem(
          title: 'Jobs',
          subtitle: todayJobsCount > 0
              ? '$todayJobsCount job${todayJobsCount == 1 ? '' : 's'} today'
              : 'No jobs today',
          icon: Icons.work_outline,
          route: '/jobs',
          color: const Color(0xFFEF5350), // Red
          badge: todayJobsCount > 0 ? todayJobsCount.toString() : null,
        ),
      ];
    } else {
      // Admin, Manager, Driver Manager see all cards
      dashboardItems = [
        if (isAdmin || isManager)
          DashboardItem(
            title: 'Manage Users',
            subtitle: unassignedUsersCount > 0
                ? '$unassignedUsersCount user${unassignedUsersCount == 1 ? '' : 's'} pending approval'
                : 'User & driver management',
            icon: Icons.people,
            route: '/users',
            color: const Color(0xFFFFA726), // Orange/Gold
            badge: unassignedUsersCount > 0
                ? unassignedUsersCount.toString()
                : null,
          ),
        DashboardItem(
          title: 'Clients',
          subtitle: 'Manage client relationships',
          icon: Icons.people_outline,
          route: '/clients',
          color: const Color(0xFF42A5F5), // Blue
        ),
        DashboardItem(
          title: 'Vehicles',
          subtitle: 'Manage fleet vehicles',
          icon: Icons.directions_car_outlined,
          route: '/vehicles',
          color: const Color(0xFF26A69A), // Teal/Green
        ),
        DashboardItem(
          title: 'Quotes',
          subtitle: 'Create and manage quotes',
          icon: Icons.description_outlined,
          route: '/quotes',
          color: const Color(0xFF8E24AA), // Purple
        ),
        DashboardItem(
          title: 'Jobs',
          subtitle: todayJobsCount > 0
              ? '$todayJobsCount job${todayJobsCount == 1 ? '' : 's'} today'
              : 'Track job progress',
          icon: Icons.work_outline,
          route: '/jobs',
          color: const Color(0xFFEF5350), // Red
          badge: todayJobsCount > 0 ? todayJobsCount.toString() : null,
        ),
      ];
      
      // Add Insights card for admin users
      if (isAdmin) {
        print('Dashboard - Adding Insights card for admin user');
        dashboardItems.add(
          DashboardItem(
            title: 'Insights',
            subtitle: 'View business analytics and reports',
            icon: Icons.analytics_outlined,
            route: '/insights',
            color: const Color(0xFFFFA726), // Orange/Gold
          ),
        );
      } else {
        print('Dashboard - NOT adding Insights card - user is not admin');
      }
    }

    // Responsive grid configuration based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
    final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);

    // Debug logging for screen dimensions
    Log.d('Screen dimensions: ${screenWidth}x${screenHeight}');

    // Responsive grid configuration with compact sizing for desktop
    int crossAxisCount;
    double spacingValue;
    double childAspectRatio;
    // Reduced padding for more compact layout
    final EdgeInsets outerPadding = !isMobile
        ? EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0) // Compact padding
        : EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0); // Compact mobile padding

    if (!isMobile) {
      // Desktop/Tablet/Large Desktop - 3 columns, 2 rows (6 cards), square cards (more compact)
      Log.d('Layout: Desktop/Tablet (3 columns, 2 rows - compact square cards)');
      crossAxisCount = 3;
      spacingValue = 16.0; // Reduced spacing
      childAspectRatio = 1.0; // Square cards (height = width)
    } else {
      // Mobile - 1 column (single cards)
      Log.d('Layout: Mobile (1 column - single cards)');
      crossAxisCount = 1;
      spacingValue = 16.0; // Reduced spacing
      childAspectRatio = 2.5; // Wider cards (width is 2.5x height)
    }

    Log.d(
      'Final GridView config: crossAxisCount=$crossAxisCount, spacing=$spacingValue, aspectRatio=$childAspectRatio',
    );

    // For desktop/tablet/large desktop, center the grid with fixed width constraint
    if (!isMobile) {
      // Fixed maximum card size to prevent cards from expanding
      // Max card width: 200px, so grid content width: (200 * 3) + (spacing * 2) = 632px
      const maxCardWidth = 200.0;
      const gridContentWidth = (maxCardWidth * 3) + (16.0 * 2); // 3 columns + 2 spacing gaps
      
      return Center(
        child: Padding(
          padding: outerPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: gridContentWidth,
              minWidth: gridContentWidth,
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacingValue,
              mainAxisSpacing: spacingValue,
              childAspectRatio: childAspectRatio,
              children: dashboardItems
                  .map(
                    (item) => DashboardCard(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      iconColor: item.color,
                      badge: item.badge,
                      onTap: () => context.go(item.route),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    }
    
    // Mobile layout - full width
    return Padding(
      padding: outerPadding,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacingValue,
        mainAxisSpacing: spacingValue,
        childAspectRatio: childAspectRatio,
        children: dashboardItems
            .map(
              (item) => DashboardCard(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                iconColor: item.color,
                badge: item.badge,
                onTap: () => context.go(item.route),
              ),
            )
            .toList(),
      ),
    );
  }

  // Notification handler
  void _handleNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationListScreen()),
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
  final String? badge;

  DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
    this.badge,
  });
}
