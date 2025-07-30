import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/users/widgets/user_form.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/simple_app_bar.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;
  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final usersNotifier = ref.read(usersProvider.notifier);
    User? user;
    try {
      user = users.firstWhere((u) => u.id == userId);
    } catch (_) {
      user = null;
    }
    if (users.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (user == null) {
      return Scaffold(
        appBar: SimpleAppBar(
          title: 'User Not Found',
          showBackButton: true,
          onBackPressed: () => context.go('/users'),
        ),
        body: const Center(child: Text('User not found.')),
      );
    }
    final canDeactivate = user.status == 'active';
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Edit User',
        subtitle: user.displayName,
        showBackButton: true,
        onBackPressed: () => context.go('/users'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: UserForm(
                user: user,
                canDeactivate: canDeactivate,
                onDeactivate: canDeactivate
                    ? () async {
                        await usersNotifier.deactivateUser(user!.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User deactivated')),
                        );
                      }
                    : null,
                onSave: (updatedUser) async {
                  await usersNotifier.updateUser(updatedUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
} 