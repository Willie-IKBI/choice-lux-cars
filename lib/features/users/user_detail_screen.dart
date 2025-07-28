import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/users/widgets/user_form.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';

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
        appBar: AppBar(title: const Text('User Not Found')),
        body: const Center(child: Text('User not found.')),
      );
    }
    final canDeactivate = user.status == 'active';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/users'),
          tooltip: 'Back to Users',
        ),
        title: const Text('Edit User'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
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