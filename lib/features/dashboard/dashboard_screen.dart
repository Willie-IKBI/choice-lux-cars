import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/notifications/screens/notification_list_screen.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/dashboard_card.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

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
    final users = ref.watch(usersProvider);
    final jobs = ref.watch(jobsProvider);
    
    // Initialize notification provider once when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).initialize();
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
    final isAdmin = userRole == 'administrator';
    final isManager = userRole == 'manager';
    final isDriverManager = userRole == 'driver_manager';
    
    // Count today's jobs based on role
    final todayJobsCount = _getTodayJobsCount(jobs.value ?? [], userProfile, isDriver);
    
    // Count unassigned users for admin notification
    final unassignedUsersCount = isAdmin 
        ? (users.value ?? []).where((user) => user.role == null || user.role == 'unassigned').length 
        : 0;
    
    // Responsive padding - provide minimal padding for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;
    
    final horizontalPadding = isSmallMobile ? 8.0 : isMobile ? 12.0 : 24.0;
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
                _buildDashboardCards(context, todayJobsCount, unassignedUsersCount),
                SizedBox(height: sectionSpacing),
              ],
            ),
          ),
        ),
      ),
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
        job.jobStartDate.day
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
    
    final titleSize = isSmallMobile ? 18.0 : isMobile ? 20.0 : 32.0;
    final subtitleSize = isSmallMobile ? 12.0 : isMobile ? 14.0 : 18.0;
    final spacing = isSmallMobile ? 3.0 : isMobile ? 4.0 : 8.0;
    final sectionSpacing = isSmallMobile ? 6.0 : isMobile ? 8.0 : 16.0;
    
    // Add horizontal padding for mobile (accounting for main container padding)
    final horizontalPadding = isSmallMobile ? 8.0 : isMobile ? 8.0 : 0.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
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
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context, int todayJobsCount, int unassignedUsersCount) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final users = ref.watch(usersProvider);
    final userRole = userProfile?.role?.toLowerCase();
    final isDriver = userRole == 'driver';
    final isAdmin = userRole == 'administrator';
    final isManager = userRole == 'manager';
    final isDriverManager = userRole == 'driver_manager';
    
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
            badge: unassignedUsersCount > 0 ? unassignedUsersCount.toString() : null,
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
        DashboardItem(
          title: 'Invoices',
          subtitle: 'Generate and manage invoices',
          icon: Icons.receipt_long_outlined,
          route: '/invoices',
          color: ChoiceLuxTheme.richGold,
        ),
      ];
    }

    // Responsive grid configuration based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Debug logging for screen dimensions
    Log.d('Screen dimensions: ${screenWidth}x${screenHeight}');
    
    // TEMPORARY: Force 2 columns for mobile testing
    int crossAxisCount;
    double spacing;
    double childAspectRatio;
    EdgeInsets outerPadding = const EdgeInsets.all(16);
    
    if (screenWidth >= 1200) {
      // Large Desktop - 4 columns
      Log.d('Layout: Large Desktop (4 columns)');
      crossAxisCount = 4;
      spacing = 24.0;
      childAspectRatio = 1.2;
    } else if (screenWidth >= 900) {
      // Desktop - 3 columns
      Log.d('Layout: Desktop (3 columns)');
      crossAxisCount = 3;
      spacing = 20.0;
      childAspectRatio = 1.1;
    } else if (screenWidth >= 600) {
      // Tablet - 2 columns
      Log.d('Layout: Tablet (2 columns)');
      crossAxisCount = 2;
      spacing = 16.0;
      childAspectRatio = 1.0;
    } else {
      // Mobile - 2 columns (forced for testing)
      Log.d('Layout: Mobile (2 columns) - FORCED for testing');
      crossAxisCount = 2;
      spacing = 12.0;
      childAspectRatio = 0.9;
    }

    Log.d('Final GridView config: crossAxisCount=$crossAxisCount, spacing=$spacing, aspectRatio=$childAspectRatio');

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
          badge: item.badge,
          onTap: () => context.go(item.route),
        )).toList(),
      ),
    );
  }

  // Notification handler
  void _handleNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationListScreen(),
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

 