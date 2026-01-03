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
    final isMobile = MediaQuery.of(context).size.width < 600;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;

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
        // Layer 1: The background that fills the entire screen
        Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
        ),
        // Layer 2: Background pattern that covers the entire screen
        Positioned.fill(
          child: CustomPaint(painter: BackgroundPatterns.dashboard),
        ),
        // Layer 3: The SystemSafeScaffold with proper system UI handling
        SystemSafeScaffold(
          scaffoldKey: _scaffoldKey,
          backgroundColor: Colors.transparent, // CRITICAL
          appBar: LuxuryAppBar(
            title: 'Dashboard',
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
    // Responsive sizing for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    final titleSize = isSmallMobile
        ? 18.0
        : isMobile
        ? 20.0
        : 20.0; // Further reduced to 20px for desktop
    final subtitleSize = isSmallMobile
        ? 12.0
        : isMobile
        ? 14.0
        : 14.0; // Further reduced to 14px for desktop
    final spacing = isSmallMobile
        ? 3.0
        : isMobile
        ? 4.0
        : 4.0; // Further reduced to 4px for desktop
    final sectionSpacing = isSmallMobile
        ? 6.0
        : isMobile
        ? 8.0
        : 6.0; // Further reduced to 6px for desktop

    // Add horizontal padding for mobile (accounting for main container padding)
    final horizontalPadding = isSmallMobile
        ? 8.0
        : isMobile
        ? 8.0
        : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            width: isSmallMobile
                ? 30
                : isMobile
                ? 40
                : 50, // Reduced from 60px to 50px for desktop
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
          color: ChoiceLuxTheme.richGold,
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
            color: ChoiceLuxTheme.richGold,
            badge: unassignedUsersCount > 0
                ? unassignedUsersCount.toString()
                : null,
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
          subtitle: todayJobsCount > 0
              ? '$todayJobsCount job${todayJobsCount == 1 ? '' : 's'} today'
              : 'Track job progress',
          icon: Icons.work_outline,
          route: '/jobs',
          color: ChoiceLuxTheme.richGold,
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
            color: ChoiceLuxTheme.richGold,
          ),
        );
      } else {
        print('Dashboard - NOT adding Insights card - user is not admin');
      }
    }

    // Responsive grid configuration based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Debug logging for screen dimensions
    Log.d('Screen dimensions: ${screenWidth}x${screenHeight}');

    // Responsive grid configuration with compact sizing for desktop
    int crossAxisCount;
    double spacing;
    double childAspectRatio;
    // Reduce outer padding for desktop to save vertical space
    final EdgeInsets outerPadding = screenWidth >= 600 
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) // Less vertical padding on desktop
        : const EdgeInsets.all(16);

    if (screenWidth >= 600) {
      // Desktop/Tablet - 3 columns, 2 rows (6 cards), square cards
      Log.d('Layout: Desktop (3 columns, 2 rows - square cards)');
      crossAxisCount = 3;
      spacing = 12.0; // Clean 12px spacing
      childAspectRatio = 1.0; // Square cards (height = width)
    } else {
      // Mobile - 2 columns
      Log.d('Layout: Mobile (2 columns)');
      crossAxisCount = 2;
      spacing = 12.0;
      childAspectRatio = 0.9;
    }

    Log.d(
      'Final GridView config: crossAxisCount=$crossAxisCount, spacing=$spacing, aspectRatio=$childAspectRatio',
    );

    // For desktop, center the grid with max width to ensure 2 rows fit without scrolling
    if (screenWidth >= 600) {
      // Calculate max width: ensure 2 rows of square cards fit in viewport
      // Account for: header (~72px), welcome section (~60px), padding/spacing (~40px)
      // Remaining height for cards: screenHeight - 172px
      // For 2 rows: (remainingHeight - 12px spacing) / 2 = card height
      // Card width = card height (square), so max grid width = (card width * 3) + (spacing * 2)
      final availableHeight = screenHeight - 180; // Reserve space for header, welcome, padding
      final cardHeight = (availableHeight - spacing) / 2; // 2 rows with spacing
      final maxGridWidth = (cardHeight * 3) + (spacing * 2); // 3 columns with spacing
      final constrainedWidth = maxGridWidth < 750.0 ? maxGridWidth : 750.0; // Cap at 750px, ensure double
      
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constrainedWidth),
          child: Padding(
            padding: outerPadding,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
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
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
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
