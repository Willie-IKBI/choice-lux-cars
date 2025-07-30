import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/auth/login/login_screen.dart';
import 'package:choice_lux_cars/features/auth/signup/signup_screen.dart';
import 'package:choice_lux_cars/features/auth/pending_approval_screen.dart';
import 'package:choice_lux_cars/features/dashboard/dashboard_screen.dart';
import 'package:choice_lux_cars/features/clients/clients_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_client_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/edit_client_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/client_detail_screen.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_agent_screen.dart';
import 'package:choice_lux_cars/features/clients/inactive_clients_screen.dart';
import 'package:choice_lux_cars/features/quotes/quotes_screen.dart';
import 'package:choice_lux_cars/features/jobs/jobs_screen.dart';
import 'package:choice_lux_cars/features/invoices/invoices_screen.dart';
import 'package:choice_lux_cars/features/vehicles/vehicles_screen.dart';
import 'package:choice_lux_cars/features/vehicles/vehicle_editor_screen.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/vouchers/vouchers_screen.dart';
import 'package:choice_lux_cars/features/users/users_screen.dart';
import 'package:choice_lux_cars/features/users/user_detail_screen.dart';
import 'package:choice_lux_cars/features/users/user_profile_screen.dart';
import '../shared/widgets/simple_app_bar.dart';

class ChoiceLuxCarsApp extends ConsumerWidget {
  const ChoiceLuxCarsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    return MaterialApp.router(
      title: 'Choice Lux Cars',
      theme: ChoiceLuxTheme.lightTheme,
      darkTheme: ChoiceLuxTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _buildRouter(authState, userProfile),
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _buildRouter(AsyncValue authState, userProfile) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        // Handle authentication and role-based routing
        if (authState.isLoading) {
          return null; // Still loading, don't redirect
        }

        final isAuthenticated = authState.value != null;
        final isLoginRoute = state.matchedLocation == '/login';
        final isSignupRoute = state.matchedLocation == '/signup';
        final isPendingApprovalRoute = state.matchedLocation == '/pending-approval';

        // If not authenticated, redirect to login (except for login/signup routes)
        if (!isAuthenticated) {
          if (isLoginRoute || isSignupRoute) {
            return null; // Allow access to auth routes
          }
          return '/login';
        }

        // If authenticated, check role
        if (isAuthenticated && userProfile != null) {
          final userRole = userProfile.role;
          final isUnassigned = userRole == null || userRole == 'unassigned';

          // If user is unassigned, redirect to pending approval (except for pending approval route)
          if (isUnassigned) {
            if (isPendingApprovalRoute) {
              return null; // Allow access to pending approval route
            }
            return '/pending-approval';
          }

          // If user is assigned but on auth routes, redirect to dashboard
          if (isLoginRoute || isSignupRoute || isPendingApprovalRoute) {
            return '/';
          }
        }

        return null; // No redirect needed
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
          path: '/jobs',
          name: 'jobs',
          builder: (context, state) => const JobsScreen(),
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
          builder: (context, state) => VehicleEditorScreen(vehicle: state.extra as Vehicle?),
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
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: SimpleAppBar(
          title: 'Page Not Found',
          subtitle: 'The requested page could not be found',
          showBackButton: true,
          onBackPressed: () => context.go('/'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.uri}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 