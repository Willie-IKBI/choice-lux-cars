import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/users_provider.dart';
import 'widgets/user_card.dart';
import 'models/user.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import '../../shared/widgets/simple_app_bar.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';
  String? _roleFilter;
  String? _statusFilter;

  final List<_RoleOption> roles = const [
    _RoleOption('administrator', 'Administrator', Icons.admin_panel_settings_outlined),
    _RoleOption('manager', 'Manager', Icons.business_center_outlined),
    _RoleOption('driver_manager', 'Driver Manager', Icons.settings_suggest_outlined),
    _RoleOption('driver', 'Driver', Icons.directions_car_outlined),
    _RoleOption('agent', 'Agent', Icons.person_outline),
    _RoleOption('unassigned', 'Unassigned', Icons.help_outline),
  ];
  final List<_StatusOption> statuses = const [
    _StatusOption('active', 'Active', Icons.check_circle_outline),
    _StatusOption('deactivated', 'Deactivated', Icons.block),
    _StatusOption('unassigned', 'Unassigned', Icons.help_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    if (userProfile == null || (userProfile.role?.toLowerCase() != 'administrator' && userProfile.role?.toLowerCase() != 'manager')) {
      return const Scaffold(
        body: Center(child: Text('Access Denied: You do not have permission to view this page.')),
      );
    }
    final users = ref.watch(usersProvider);
    final usersNotifier = ref.read(usersProvider.notifier);
    final isLoading = users.isEmpty;
    final filtered = users.where((u) {
      final matchesSearch = _search.isEmpty ||
        u.displayName.toLowerCase().contains(_search.toLowerCase()) ||
        u.userEmail.toLowerCase().contains(_search.toLowerCase());
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      final matchesStatus = _statusFilter == null || u.status == _statusFilter;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Manage Users',
        subtitle: 'User administration',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: ChoiceLuxTheme.richGold,
                size: 20,
              ),
            ),
            onPressed: () => usersNotifier.fetchUsers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final horizontalPadding = isMobile ? 8.0 : 24.0;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Search by name or email',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          onChanged: (val) => setState(() => _search = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _roleFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Role',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          items: [
                            DropdownMenuItem<String>(value: null, child: Text('All Roles')),
                            ...roles.map((r) => DropdownMenuItem<String>(
                              value: r.value,
                              child: Row(children: [Icon(r.icon, size: 18), const SizedBox(width: 8), Text(r.label)]),
                            )),
                          ],
                          onChanged: (val) => setState(() => _roleFilter = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Status',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          items: [
                            DropdownMenuItem<String>(value: null, child: Text('All Statuses')),
                            ...statuses.map((s) => DropdownMenuItem<String>(
                              value: s.value,
                              child: Row(children: [Icon(s.icon, size: 18), const SizedBox(width: 8), Text(s.label)]),
                            )),
                          ],
                          onChanged: (val) => setState(() => _statusFilter = val),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: filtered.isEmpty
                              ? const Center(child: Text('No users found.'))
                              : ListView.separated(
                                  key: ValueKey(filtered.length),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final user = filtered[index];
                                    return UserCard(
                                      user: user,
                                      onTap: () {
                                        context.go('/users/${user.id}');
                                      },
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoleOption {
  final String value;
  final String label;
  final IconData icon;
  const _RoleOption(this.value, this.label, this.icon);
}
class _StatusOption {
  final String value;
  final String label;
  final IconData icon;
  const _StatusOption(this.value, this.label, this.icon);
} 