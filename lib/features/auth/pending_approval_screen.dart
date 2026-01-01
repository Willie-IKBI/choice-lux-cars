import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final displayName = userProfile?.displayNameOrEmail ?? 'User';

    return Scaffold(
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
                shadowColor: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
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
                          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
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
                          color: ChoiceLuxTheme.softWhite.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.charcoalGray.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
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
                              '• You will receive access to the system\n'
                              '• You can then log in and start using the app',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ChoiceLuxTheme.softWhite.withValues(alpha: 
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
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
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
