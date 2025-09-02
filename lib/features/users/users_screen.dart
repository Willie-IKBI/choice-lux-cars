import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/users_provider.dart';
import 'widgets/user_card.dart';
import 'models/user.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import '../../shared/widgets/luxury_app_bar.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

// Helper classes for role and status options
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

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';
  String? _roleFilter;
  String? _statusFilter;

  final List<_RoleOption> roles = const [
    _RoleOption(
      'administrator',
      'Administrator',
      Icons.admin_panel_settings_outlined,
    ),
    _RoleOption('manager', 'Manager', Icons.business_center_outlined),
    _RoleOption(
      'driver_manager',
      'Driver Manager',
      Icons.settings_suggest_outlined,
    ),
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
    if (userProfile == null ||
        (userProfile.role?.toLowerCase() != 'administrator' &&
            userProfile.role?.toLowerCase() != 'manager')) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied: You do not have permission to view this page.',
          ),
        ),
      );
    }

    // Responsive breakpoints for mobile optimization
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 800;
    final isDesktop = screenWidth >= 800;

    final users = ref.watch(usersProvider);
    final usersNotifier = ref.read(usersProvider.notifier);
    final usersList = users.value ?? [];
    final isLoading = usersList.isEmpty;
    final filtered = usersList.where((u) {
      final matchesSearch =
          _search.isEmpty ||
          u.displayName.toLowerCase().contains(_search.toLowerCase()) ||
          u.userEmail.toLowerCase().contains(_search.toLowerCase());
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      final matchesStatus = _statusFilter == null || u.status == _statusFilter;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Manage Users',
        subtitle: 'User administration',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 12.0
                  : isMobile
                  ? 16.0
                  : 24.0,
            ),
            child: Column(
              children: [
                // Responsive search and filters section
                _buildResponsiveSearchAndFilters(isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoading
                      ? _buildMobileLoadingState(isMobile, isSmallMobile)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: filtered.isEmpty
                              ? _buildEmptyState(isMobile, isSmallMobile)
                              : RefreshIndicator(
                                  onRefresh: () => usersNotifier.fetchUsers(),
                                  color: ChoiceLuxTheme.richGold,
                                  backgroundColor: ChoiceLuxTheme.charcoalGray,
                                  child: ListView.separated(
                                    key: ValueKey(filtered.length),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallMobile
                                          ? 4.0
                                          : isMobile
                                          ? 6.0
                                          : 8.0,
                                      vertical: 8.0,
                                    ),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => SizedBox(
                                      height: isSmallMobile ? 8 : 12,
                                    ),
                                    itemBuilder: (context, index) {
                                      final user = filtered[index];
                                      return _buildSwipeableUserCard(
                                        context: context,
                                        user: user,
                                        isMobile: isMobile,
                                        isSmallMobile: isSmallMobile,
                                        onTap: () =>
                                            context.go('/users/${user.id}'),
                                        onEdit: () => context.go(
                                          '/users/${user.id}/edit',
                                        ),
                                        onToggleStatus: () =>
                                            _toggleUserStatus(user),
                                      );
                                    },
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveSearchAndFilters(bool isMobile, bool isSmallMobile) {
    if (isMobile) {
      // Mobile: Search bar + filter button that opens bottom sheet
      return Column(
        children: [
          // Search bar
          _buildResponsiveSearchBar(isMobile, isSmallMobile),
          SizedBox(height: isSmallMobile ? 8.0 : 12.0),
          // Filter button
          _buildMobileFilterButton(isSmallMobile),
        ],
      );
    } else {
      // Desktop: Horizontal layout
      return Row(
        children: [
          Expanded(child: _buildResponsiveSearchBar(isMobile, isSmallMobile)),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: _buildResponsiveDropdown(
              value: _roleFilter,
              hintText: 'Role',
              items: [
                DropdownMenuItem<String>(value: null, child: Text('All Roles')),
                ...roles.map(
                  (r) => DropdownMenuItem<String>(
                    value: r.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(r.icon, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(r.label, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _roleFilter = val),
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: _buildResponsiveDropdown(
              value: _statusFilter,
              hintText: 'Status',
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...statuses.map(
                  (s) => DropdownMenuItem<String>(
                    value: s.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(s.label, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _statusFilter = val),
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveSearchBar(bool isMobile, bool isSmallMobile) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _search = val),
        decoration: InputDecoration(
          hintText: isMobile ? 'Search users...' : 'Search by name or email',
          hintStyle: TextStyle(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
            fontSize: isMobile ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
            size: isMobile ? 20 : 24,
          ),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                    size: isMobile ? 20 : 24,
                  ),
                  onPressed: () => setState(() => _search = ''),
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 14 : 16,
          ),
        ),
        style: TextStyle(
          color: ChoiceLuxTheme.softWhite,
          fontSize: isMobile ? 14 : 16,
        ),
      ),
    );
  }

  Widget _buildResponsiveDropdown({
    required String? value,
    required String hintText,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
            fontSize: isMobile ? 14 : 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 14 : 16,
          ),
        ),
        dropdownColor: ChoiceLuxTheme.charcoalGray,
        style: TextStyle(
          color: ChoiceLuxTheme.softWhite,
          fontSize: isMobile ? 14 : 16,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
          size: isMobile ? 20 : 24,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMobileFilterButton(bool isSmallMobile) {
    final hasActiveFilters = _roleFilter != null || _statusFilter != null;
    final filterCount =
        (_roleFilter != null ? 1 : 0) + (_statusFilter != null ? 1 : 0);

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showMobileFilterBottomSheet(),
        icon: Icon(Icons.filter_list, color: ChoiceLuxTheme.richGold, size: 20),
        label: Text(
          hasActiveFilters ? 'Filters: $filterCount active' : 'Filter users',
          style: TextStyle(
            color: ChoiceLuxTheme.richGold,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
          foregroundColor: ChoiceLuxTheme.richGold,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(0, 48), // Ensure minimum 44px touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: ChoiceLuxTheme.richGold.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: ChoiceLuxTheme.richGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ChoiceLuxTheme.softWhite,
                    ),
                  ),
                ],
              ),
            ),

            // Filter options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Role filter section
                  _buildMobileFilterSection(
                    title: 'Role',
                    options: roles
                        .map((r) => _FilterOption(r.value, r.label, r.icon))
                        .toList(),
                    selectedValue: _roleFilter,
                    onChanged: (value) => setState(() => _roleFilter = value),
                  ),

                  const SizedBox(height: 16),

                  // Status filter section
                  _buildMobileFilterSection(
                    title: 'Status',
                    options: statuses
                        .map((s) => _FilterOption(s.value, s.label, s.icon))
                        .toList(),
                    selectedValue: _statusFilter,
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilterSection({
    required String title,
    required List<_FilterOption> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map(
          (option) => _buildMobileFilterOption(
            option: option,
            isSelected: selectedValue == option.value,
            onTap: () {
              onChanged(selectedValue == option.value ? null : option.value);
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilterOption({
    required _FilterOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            constraints: const BoxConstraints(
              minHeight: 48,
            ), // Ensure minimum 44px touch target
            decoration: BoxDecoration(
              color: isSelected
                  ? ChoiceLuxTheme.richGold.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? ChoiceLuxTheme.richGold
                    : ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  color: isSelected
                      ? ChoiceLuxTheme.richGold
                      : ChoiceLuxTheme.platinumSilver,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: isSelected
                          ? ChoiceLuxTheme.richGold
                          : ChoiceLuxTheme.softWhite,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: ChoiceLuxTheme.richGold,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableUserCard({
    required BuildContext context,
    required User user,
    required bool isMobile,
    required bool isSmallMobile,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onToggleStatus,
  }) {
    return Dismissible(
      key: Key(user.id),
      direction: DismissDirection.endToStart, // Only swipe from right to left
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ChoiceLuxTheme.charcoalGray,
            title: Text(
              'Toggle User Status',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to ${user.status?.toLowerCase() == 'active' ? 'deactivate' : 'activate'} ${user.displayName}?',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onToggleStatus();
      },
      background: Container(
        margin: EdgeInsets.symmetric(vertical: isSmallMobile ? 4 : 6),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.richGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.status?.toLowerCase() == 'active'
                      ? Icons.block
                      : Icons.check_circle,
                  color: ChoiceLuxTheme.richGold,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  user.status?.toLowerCase() == 'active'
                      ? 'Deactivate'
                      : 'Activate',
                  style: TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: UserCard(user: user, onTap: onTap),
    );
  }

  Widget _buildMobileLoadingState(bool isMobile, bool isSmallMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading animation
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 16
                  : isMobile
                  ? 20
                  : 24,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ChoiceLuxTheme.richGold,
              strokeWidth: isMobile ? 2.0 : 3.0,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 16
                : isMobile
                ? 20
                : 24,
          ),
          // Loading text
          Text(
            'Loading users...',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 14
                  : isMobile
                  ? 16
                  : 18,
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 10
                : 12,
          ),
          Text(
            'Please wait while we fetch user data',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 12
                  : isMobile
                  ? 13
                  : 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isSmallMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 20
                  : isMobile
                  ? 24
                  : 28,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: isSmallMobile
                  ? 40
                  : isMobile
                  ? 48
                  : 56,
              color: ChoiceLuxTheme.richGold,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 16
                : isMobile
                ? 20
                : 24,
          ),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 16
                  : isMobile
                  ? 18
                  : 20,
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 10
                : 12,
          ),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 12
                  : isMobile
                  ? 13
                  : 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(User user) {
    // TODO: Implement user status toggle functionality
    // This would typically call a provider method to update the user status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.displayName} status updated'),
        backgroundColor: ChoiceLuxTheme.richGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;
  final IconData icon;
  const _FilterOption(this.value, this.label, this.icon);
}
