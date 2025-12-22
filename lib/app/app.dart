import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/auth/login/login_screen.dart';
import 'package:choice_lux_cars/features/auth/signup/signup_screen.dart';
import 'package:choice_lux_cars/features/auth/forgot_password/forgot_password_screen.dart';
import 'package:choice_lux_cars/features/auth/reset_password/reset_password_screen.dart';
import 'package:choice_lux_cars/features/auth/pending_approval_screen.dart';
import 'package:choice_lux_cars/features/dashboard/dashboard_screen.dart';
import 'package:choice_lux_cars/features/clients/clients_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_client_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/edit_client_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/client_detail_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_agent_screen.dart';
import 'package:choice_lux_cars/features/clients/inactive_clients_screen.dart';
import 'package:choice_lux_cars/features/quotes/quotes_screen.dart';
import 'package:choice_lux_cars/features/quotes/screens/create_quote_screen.dart';
import 'package:choice_lux_cars/features/quotes/screens/quote_details_screen.dart';
import 'package:choice_lux_cars/features/quotes/screens/quote_transport_details_screen.dart';
import 'package:choice_lux_cars/features/jobs/jobs_screen.dart';
import 'package:choice_lux_cars/features/jobs/screens/create_job_screen.dart';
import 'package:choice_lux_cars/features/jobs/screens/trip_management_screen.dart';
import 'package:choice_lux_cars/features/jobs/screens/job_summary_screen.dart';
import 'package:choice_lux_cars/features/jobs/screens/job_progress_screen.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/invoices/invoices_screen.dart';
import 'package:choice_lux_cars/features/vehicles/vehicles_screen.dart';
import 'package:choice_lux_cars/features/vehicles/vehicle_editor_screen.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/vouchers/vouchers_screen.dart';
import 'package:choice_lux_cars/features/users/users_screen.dart';
import 'package:choice_lux_cars/features/users/user_detail_screen.dart';
import 'package:choice_lux_cars/features/users/user_profile_screen.dart';
import 'package:choice_lux_cars/features/notifications/screens/notification_list_screen.dart';
import 'package:choice_lux_cars/features/notifications/screens/notification_preferences_screen.dart';
import 'package:choice_lux_cars/features/insights/screens/insights_screen.dart';
import 'package:choice_lux_cars/features/insights/screens/insights_jobs_list_screen.dart';
import 'package:choice_lux_cars/features/insights/screens/completed_jobs_details_screen.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/core/services/fcm_service.dart';
import 'package:choice_lux_cars/core/router/guards.dart';

class ChoiceLuxCarsApp extends ConsumerStatefulWidget {
  const ChoiceLuxCarsApp({super.key});

  @override
  ConsumerState<ChoiceLuxCarsApp> createState() => _ChoiceLuxCarsAppState();
}

class _ChoiceLuxCarsAppState extends ConsumerState<ChoiceLuxCarsApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM service
    FCMService.initialize(ref);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return MaterialApp.router(
      title: 'Choice Lux Cars',
      theme: ChoiceLuxTheme.lightTheme,
      darkTheme: ChoiceLuxTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: _buildRouter(authState, userProfile, authNotifier),
    );
  }

  GoRouter _buildRouter(
    AsyncValue authState,
    userProfile,
    AuthNotifier authNotifier,
  ) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        // Use router guards for cleaner, more maintainable logic
        return RouterGuards.guardRoute(
          user: authState.value,
          currentRoute: state.matchedLocation,
          isLoading: authState.isLoading,
          hasError: authState.hasError,
          isPasswordRecovery: authNotifier.isPasswordRecovery,
          userRole: userProfile?.role,
        );
      },
      routes: [
        // Authentication routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot_password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset_password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),

        GoRoute(
          path: '/pending-approval',
          name: 'pending_approval',
          builder: (context, state) => const PendingApprovalScreen(),
        ),
        GoRoute(
          path: '/user-profile',
          name: 'user_profile',
          builder: (context, state) => const UserProfileScreen(),
        ),

        // Main app routes (protected)
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/clients',
          name: 'clients',
          builder: (context, state) => const ClientsScreen(),
        ),
        GoRoute(
          path: '/clients/inactive',
          name: 'inactive_clients',
          builder: (context, state) => const InactiveClientsScreen(),
        ),
        GoRoute(
          path: '/clients/add',
          name: 'add_client',
          builder: (context, state) => const AddEditClientScreen(),
        ),
        GoRoute(
          path: '/clients/edit/:id',
          name: 'edit_client',
          builder: (context, state) {
            final clientId = state.pathParameters['id']!;
            return EditClientScreen(clientId: clientId);
          },
        ),
        GoRoute(
          path: '/clients/:id',
          name: 'client_detail',
          builder: (context, state) {
            final clientId = state.pathParameters['id']!;
            return ClientDetailScreen(clientId: clientId);
          },
        ),
        GoRoute(
          path: '/clients/:clientId/agents/add',
          name: 'add_agent',
          builder: (context, state) {
            final clientId = state.pathParameters['clientId']!;
            return AddEditAgentScreen(clientId: clientId);
          },
        ),
        GoRoute(
          path: '/clients/:clientId/agents/edit/:agentId',
          name: 'edit_agent',
          builder: (context, state) {
            final clientId = state.pathParameters['clientId']!;
            // TODO: Get agent data and pass to screen
            return AddEditAgentScreen(clientId: clientId);
          },
        ),
        GoRoute(
          path: '/quotes',
          name: 'quotes',
          builder: (context, state) => const QuotesScreen(),
        ),
        GoRoute(
          path: '/quotes/create',
          name: 'create_quote',
          builder: (context, state) => const CreateQuoteScreen(),
        ),
        GoRoute(
          path: '/quotes/:id',
          name: 'quote_details',
          builder: (context, state) {
            final quoteId = state.pathParameters['id']!;
            return QuoteDetailsScreen(quoteId: quoteId);
          },
        ),
        GoRoute(
          path: '/quotes/:id/transport-details',
          name: 'quote_transport_details',
          builder: (context, state) {
            final quoteId = state.pathParameters['id']!;
            return QuoteTransportDetailsScreen(quoteId: quoteId);
          },
        ),
        GoRoute(
          path: '/quotes/:id/summary',
          name: 'quote_summary',
          builder: (context, state) {
            // TODO: Create QuoteSummaryScreen
            return const Scaffold(
              body: Center(child: Text('Quote Summary Screen - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/jobs',
          name: 'jobs',
          builder: (context, state) => const JobsScreen(),
        ),
        GoRoute(
          path: '/jobs/create',
          name: 'create_job',
          builder: (context, state) => const CreateJobScreen(),
        ),
        GoRoute(
          path: '/jobs/:id/summary',
          name: 'job_summary',
          builder: (context, state) {
            final jobId = state.pathParameters['id']!;
            return JobSummaryScreen(jobId: jobId);
          },
        ),
        GoRoute(
          path: '/jobs/:id/progress',
          name: 'job_progress',
          builder: (context, state) {
            final jobId = state.pathParameters['id']!;
            // Create a placeholder job - the screen will load the actual job data
            final int parsedJobId = (jobId is int) 
                ? jobId as int 
                : (int.tryParse(jobId.toString()) ?? 0);
            
            // Guard against invalid job ID - 0 is typically not a valid database ID
            assert(parsedJobId > 0, 'Invalid job ID: $jobId (parsed as $parsedJobId)');
            
            final placeholderJob = Job(
              id: parsedJobId,
              jobNumber: 'JOB-$jobId',
              clientId: '',
              vehicleId: '',
              driverId: '',
              managerId: null,
              passengerName: 'Loading...',
              passengerContact: '',
              pasCount: 1.0,
              luggageCount: '',
              jobStartDate: DateTime.now(),
              notes: '',
              quoteNo: null,
              voucherPdf: null,
              cancelReason: null,
              cancelledBy: null,
              cancelledAt: null,
              branchId: null,
              createdBy: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              driverConfirmation: false,
              isConfirmed: false,
              confirmedAt: null,
              confirmedBy: null,
              status: 'open',
              orderDate: DateTime.now(),
              paymentAmount: null,
              collectPayment: false,
            );
            return JobProgressScreen(jobId: jobId, job: placeholderJob);
          },
        ),
        GoRoute(
          path: '/jobs/:id/trip-management',
          name: 'trip_management',
          builder: (context, state) {
            final jobId = state.pathParameters['id']!;
            return TripManagementScreen(jobId: jobId);
          },
        ),
        GoRoute(
          path: '/jobs/:id/edit',
          name: 'edit_job',
          builder: (context, state) {
            final jobId = state.pathParameters['id']!;
            return CreateJobScreen(jobId: jobId);
          },
        ),
        GoRoute(
          path: '/invoices',
          name: 'invoices',
          builder: (context, state) => const InvoicesScreen(),
        ),
        GoRoute(
          path: '/vehicles',
          name: 'vehicles',
          builder: (context, state) => const VehicleListScreen(),
        ),
        GoRoute(
          path: '/vehicles/edit',
          name: 'edit_vehicle',
          builder: (context, state) =>
              VehicleEditorScreen(vehicle: state.extra as Vehicle?),
        ),
        GoRoute(
          path: '/vouchers',
          name: 'vouchers',
          builder: (context, state) => const VouchersScreen(),
        ),
        GoRoute(
          path: '/users',
          name: 'users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/users/:id',
          name: 'user_detail',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return UserDetailScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationListScreen(),
        ),
        GoRoute(
          path: '/notification-settings',
          name: 'notification-settings',
          builder: (context, state) => const NotificationPreferencesScreen(),
        ),
        GoRoute(
          path: '/insights',
          name: 'insights',
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/insights/jobs',
          name: 'insights-jobs',
          builder: (context, state) {
            final timePeriodStr = state.uri.queryParameters['timePeriod'] ?? 'thisMonth';
            final locationStr = state.uri.queryParameters['location'] ?? 'all';
            final status = state.uri.queryParameters['status'] ?? 'all';

            TimePeriod timePeriod;
            try {
              timePeriod = TimePeriod.values.firstWhere(
                (e) => e.toString().split('.').last == timePeriodStr,
                orElse: () => TimePeriod.thisMonth,
              );
            } catch (e) {
              timePeriod = TimePeriod.thisMonth;
            }

            LocationFilter location;
            try {
              location = LocationFilter.values.firstWhere(
                (e) => e.toString().split('.').last == locationStr,
                orElse: () => LocationFilter.all,
              );
            } catch (e) {
              location = LocationFilter.all;
            }

            return InsightsJobsListScreen(
              timePeriod: timePeriod,
              location: location,
              status: status,
            );
          },
        ),
        GoRoute(
          path: '/insights/completed-jobs-details',
          name: 'completed-jobs-details',
          builder: (context, state) {
            final timePeriodStr = state.uri.queryParameters['timePeriod'] ?? 'thisMonth';
            final locationStr = state.uri.queryParameters['location'] ?? 'all';
            final metricType = state.uri.queryParameters['metricType'] ?? 'km';

            TimePeriod timePeriod;
            try {
              timePeriod = TimePeriod.values.firstWhere(
                (e) => e.toString().split('.').last == timePeriodStr,
                orElse: () => TimePeriod.thisMonth,
              );
            } catch (e) {
              timePeriod = TimePeriod.thisMonth;
            }

            LocationFilter location;
            try {
              location = LocationFilter.values.firstWhere(
                (e) => e.toString().split('.').last == locationStr,
                orElse: () => LocationFilter.all,
              );
            } catch (e) {
              location = LocationFilter.all;
            }

            return CompletedJobsDetailsScreen(
              timePeriod: timePeriod,
              location: location,
              metricType: metricType,
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: LuxuryAppBar(
          title: 'Something went wrong',
          subtitle: 'An unexpected error occurred',
          showBackButton: true,
          onBackPressed: () => context.go('/'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: ChoiceLuxTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ChoiceLuxTheme.softWhite,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We encountered an unexpected error. Please try again or contact support if the problem persists.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChoiceLuxTheme.richGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Go to Dashboard'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ChoiceLuxTheme.richGold,
                        side: BorderSide(color: ChoiceLuxTheme.richGold),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Sign In Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
