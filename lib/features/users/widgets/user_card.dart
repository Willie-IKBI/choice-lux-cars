import 'package:flutter/material.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/app/theme.dart';

class UserCard extends StatefulWidget {
  final User user;
  final VoidCallback? onTap;
  const UserCard({Key? key, required this.user, this.onTap}) : super(key: key);

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints for mobile optimization
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    // Responsive sizing
    final avatarRadius = isSmallMobile
        ? 20.0
        : isMobile
        ? 22.0
        : 24.0;
    final avatarIconSize = isSmallMobile
        ? 24.0
        : isMobile
        ? 26.0
        : 28.0;
    final cardPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 14.0
        : 16.0;
    final cardMargin = isSmallMobile
        ? 4.0
        : isMobile
        ? 6.0
        : 8.0;

    final user = widget.user;
    final status = _statusInfo(user);
    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        backgroundImage:
            user.profileImage != null && user.profileImage!.isNotEmpty
            ? NetworkImage(user.profileImage!)
            : null,
        child: user.profileImage == null || user.profileImage!.isEmpty
            ? Icon(
                Icons.person,
                color: ChoiceLuxTheme.platinumSilver,
                size: avatarIconSize,
              )
            : null,
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.charcoalGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
              width: 1,
            ),
          ),
          margin: EdgeInsets.symmetric(vertical: cardMargin, horizontal: 0),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
              highlightColor: ChoiceLuxTheme.richGold.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: cardPadding,
                  vertical: cardPadding - 2,
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              avatar,
                              SizedBox(width: isSmallMobile ? 10 : 12),
                              Expanded(
                                child: _userInfo(user, isMobile, isSmallMobile),
                              ),
                              _statusChip(status, isSmallMobile),
                            ],
                          ),
                          SizedBox(height: isSmallMobile ? 6 : 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: ChoiceLuxTheme.charcoalGray,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.chevron_right,
                                color: ChoiceLuxTheme.platinumSilver,
                                size: isSmallMobile ? 18 : 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          avatar,
                          const SizedBox(width: 16),
                          Expanded(
                            child: _userInfo(user, isMobile, isSmallMobile),
                          ),
                          const SizedBox(width: 12),
                          // Joined date placeholder (would need createdAt field in User model)
                          Text(
                            'Joined Jan 12, 2024',
                            style: TextStyle(
                              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _statusChip(status, isSmallMobile),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: ChoiceLuxTheme.charcoalGray,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.chevron_right,
                              color: ChoiceLuxTheme.platinumSilver,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userInfo(User user, bool isMobile, bool isSmallMobile) {
    final titleSize = isSmallMobile
        ? 16.0
        : isMobile
        ? 18.0
        : 20.0;
    final badgeSize = isSmallMobile
        ? 9.0
        : isMobile
        ? 10.0
        : 11.0;
    final detailSize = isSmallMobile
        ? 11.0
        : isMobile
        ? 12.0
        : 13.0;

    // Get role badge color
    final roleColor = _getRoleColor(user.role);
    final roleLabel = _getRoleLabel(user.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(height: isSmallMobile ? 4 : 6),
        // Role badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 6 : 8,
            vertical: isSmallMobile ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: roleColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            roleLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: badgeSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (user.userEmail.isNotEmpty) ...[
          SizedBox(height: isSmallMobile ? 4 : 6),
          Text(
            user.userEmail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
              fontSize: detailSize,
            ),
          ),
        ],
      ],
    );
  }

  Color _getRoleColor(String? role) {
    if (role == null) return Colors.grey;
    switch (role.toLowerCase()) {
      case 'driver':
        return const Color(0xFF4FC3F7); // Light blue
      case 'administrator':
      case 'super_admin':
        return ChoiceLuxTheme.purple;
      case 'unassigned':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String? role) {
    if (role == null) return 'UNASSIGNED';
    return role.toUpperCase().replaceAll('_', ' ');
  }

  Widget _statusChip(_StatusInfo status, bool isSmallMobile) {
    final fontSize = isSmallMobile ? 9.0 : 10.0;
    final padding = isSmallMobile ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding * 0.5,
      ),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.textColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(User user) {
    if (user.status?.toLowerCase() == 'active') {
      return _StatusInfo('ACTIVE', Colors.green, Colors.white);
    } else if (user.status?.toLowerCase() == 'deactivated') {
      return _StatusInfo('EXPIRED', Colors.red, Colors.white);
    } else if (user.status?.toLowerCase() == 'expiring') {
      return _StatusInfo('EXPIRING SOON', Colors.amber, Colors.black);
    }
    return _StatusInfo('UNKNOWN', Colors.grey, Colors.white);
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color textColor;
  _StatusInfo(this.label, this.color, this.textColor);
}
