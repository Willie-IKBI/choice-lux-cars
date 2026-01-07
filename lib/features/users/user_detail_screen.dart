import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/users/widgets/user_form.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart' as usersp;
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
                  child: UserForm(
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
                ),
              ),
            ),
          ),
    );
  }
}
