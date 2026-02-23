import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/users/widgets/user_form.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart' as usersp;
import 'package:choice_lux_cars/features/insights/providers/driver_rating_provider.dart';
import 'package:choice_lux_cars/features/insights/data/driver_rating_service.dart';
import 'package:choice_lux_cars/features/insights/widgets/star_rating_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;
  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersp.usersProvider);
    final usersNotifier = ref.read(usersp.usersProvider.notifier);
    final usersList = users.value ?? [];
    User? user;
    try {
      user = usersList.firstWhere((u) => u.id == userId);
    } catch (_) {
      user = null;
    }
    if (usersList.isEmpty) {
      return SystemSafeScaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (user == null) {
      return SystemSafeScaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        appBar: LuxuryAppBar(
          title: 'User Not Found',
          showBackButton: true,
          onBackPressed: () => context.go('/users'),
        ),
        body: const Center(child: Text('User not found.')),
      );
    }
    final canDeactivate = user.status == 'active';
    final showDriverSummary = user.role?.toLowerCase() == 'driver';
    return SystemSafeScaffold(
      backgroundColor: ChoiceLuxTheme.jetBlack,
      appBar: LuxuryAppBar(
        title: 'Edit User',
        showBackButton: true,
        onBackPressed: () => context.go('/users'),
      ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: ResponsiveTokens.getSpacing(MediaQuery.of(context).size.width) * 3, horizontal: 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveTokens.getPadding(MediaQuery.of(context).size.width)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDriverSummary) _DriverSummaryCard(userId: user.id),
                      UserForm(
                    user: user,
                    canDeactivate: canDeactivate,
                    onDeactivate: canDeactivate
                        ? () async {
                            Log.d(
                              'Deactivate button clicked for user: ${user!.id}',
                            );
                            try {
                              await ref
                                  .read(usersp.usersProvider.notifier)
                                  .deactivateUser(user!.id);
                              Log.d('User deactivated successfully');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User deactivated successfully'),
                                  ),
                                );
                              }
                            } catch (error) {
                              Log.e('Error deactivating user: $error');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error deactivating user: $error',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    onSave: (updatedUser) async {
                      try {
                        Log.d('UserDetailScreen: Saving user with status: ${updatedUser.status}, role: ${updatedUser.role}, branch: ${updatedUser.branchId}');
                        await usersNotifier.updateUser(updatedUser);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User updated successfully')),
                          );
                          // Navigate back to users list to see refreshed data
                          context.go('/users');
                        }
                      } catch (e) {
                        Log.e('UserDetailScreen: Error updating user: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating user: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class _DriverSummaryCard extends ConsumerWidget {
  final String userId;

  const _DriverSummaryCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(driverSummaryProvider(userId));
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: summaryAsync.when(
          data: (DriverSummaryResult? summary) {
            if (summary == null) {
              return Text(
                'Unable to load driver summary.',
                style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car_outlined, color: ChoiceLuxTheme.richGold, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Driver summary',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total jobs as driver: ${summary.totalJobsAsDriver}',
                  style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Overall rating (last 10 trips): ',
                      style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
                    ),
                    if (summary.last10TripCount > 0) ...[
                      StarRatingBar(rating: summary.overallAvg, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '(${summary.last10TripCount} trip${summary.last10TripCount == 1 ? '' : 's'})',
                        style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
                      ),
                    ] else
                      Text(
                        'No rating yet',
                        style: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8), fontSize: 14),
                      ),
                  ],
                ),
                if (summary.recentJobRatings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Rating per job',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...summary.recentJobRatings.map((e) {
                    final jobLabel = e.jobNumber?.isNotEmpty == true ? 'Job #${e.jobNumber}' : 'Job #${e.jobId}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            '$jobLabel · ',
                            style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 13),
                          ),
                          StarRatingBar(rating: e.avgScore, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '(${e.tripCount} trip${e.tripCount == 1 ? '' : 's'})',
                            style: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8), fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold, strokeWidth: 2),
            ),
          ),
          error: (_, __) => Text(
            'Unable to load driver summary.',
            style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
