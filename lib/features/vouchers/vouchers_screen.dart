import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/core/services/permission_service.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class VouchersScreen extends ConsumerWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen
        Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
        ),
        // Layer 2: Background pattern that covers the entire screen
        const Positioned.fill(
          child: CustomPaint(painter: BackgroundPatterns.dashboard),
        ),
        // Layer 3: The SystemSafeScaffold with proper system UI handling
        SystemSafeScaffold(
          backgroundColor: Colors.transparent,
          appBar: LuxuryAppBar(
            title: 'Vouchers',
            showBackButton: true,
            onBackPressed: () => context.go('/'),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.teal),
                SizedBox(height: 16),
                Text(
                  'Vouchers Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Coming soon...'),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(ref, context),
        ),
      ],
    );
  }

  Widget? _buildFAB(WidgetRef ref, BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final userRole = userProfile?.role;
    final permissionService = const PermissionService();
    
    if (!permissionService.isAdmin(userRole) &&
        !permissionService.isManager(userRole) &&
        !permissionService.isDriverManager(userRole)) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () {
        // Navigate to create voucher screen
        context.push('/vouchers/create');
      },
      child: const Icon(Icons.add),
    );
  }
}
