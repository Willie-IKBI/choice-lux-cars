import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/admin/screens/not_authorized_screen.dart';
import 'package:choice_lux_cars/features/admin/screens/operations_dashboard_screen.dart';

/// Route gate: only administrator and super_admin may see OperationsDashboardScreen.
/// Non-admin users see NotAuthorizedScreen.
class OperationsDashboardRoute extends ConsumerWidget {
  const OperationsDashboardRoute({super.key});

  static const _adminRoles = ['administrator', 'super_admin'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final role = userProfile?.role?.toLowerCase();
    final isAdmin = role != null && _adminRoles.contains(role);

    if (isAdmin) {
      return const OperationsDashboardScreen();
    }
    return const NotAuthorizedScreen();
  }
}
