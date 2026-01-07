import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Poll profile every 3 seconds to check for updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkProfileAndRedirect();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _checkProfileAndRedirect() async {
    // Refresh profile from server
    await ref.read(userProfileProvider.notifier).refreshProfile();
    
    // Check profile after refresh
    final userProfile = ref.read(currentUserProfileProvider);
    if (userProfile != null) {
      final role = userProfile.role;
      final status = userProfile.status;
      final branchId = userProfile.branchId;
      
      // Check if user is now fully assigned
      final isUnassigned = role == null || role == 'unassigned';
      final isNotActive = status == null || status != 'active';
      final hasNoBranch = branchId == null || branchId.isEmpty;
      
      if (!isUnassigned && !isNotActive && !hasNoBranch) {
        Log.d('PendingApprovalScreen - User is now fully assigned, redirecting to dashboard');
        _refreshTimer?.cancel();
        if (mounted) {
          context.go('/');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final displayName = userProfile?.displayNameOrEmail ?? 'User';

    return SystemSafeScaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ChoiceLuxTheme.jetBlack,
              ChoiceLuxTheme.charcoalGray,
              ChoiceLuxTheme.jetBlack,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 8,
                shadowColor: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pending_actions,
                          size: 64,
                          color: ChoiceLuxTheme.richGold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Account Pending Approval',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: ChoiceLuxTheme.softWhite,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Welcome, $displayName!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ChoiceLuxTheme.richGold,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Message
                      Text(
                        'Your account has been created successfully, but it requires administrator approval before you can access the system.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ChoiceLuxTheme.softWhite.withOpacity(0.8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: ChoiceLuxTheme.richGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'What happens next?',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: ChoiceLuxTheme.richGold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• An administrator will review your account\n'
                              '• You will be assigned an appropriate role\n'
                              '• You will be assigned a branch location\n'
                              '• Your status will be set to active\n'
                              '• You will then receive access to the system',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ChoiceLuxTheme.softWhite.withOpacity(
                                      0.8,
                                    ),
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await ref.read(authProvider.notifier).signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ChoiceLuxTheme.errorColor.withOpacity(0.8),
                            foregroundColor: ChoiceLuxTheme.softWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
