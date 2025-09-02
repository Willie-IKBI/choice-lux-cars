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
    final avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
      backgroundImage:
          user.profileImage != null && user.profileImage!.isNotEmpty
          ? NetworkImage(user.profileImage!)
          : null,
      child: user.profileImage == null || user.profileImage!.isEmpty
          ? Icon(
              Icons.person,
              color: ChoiceLuxTheme.richGold,
              size: avatarIconSize,
            )
          : null,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: _isHovered ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: _isHovered
                ? BorderSide(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                    width: 1,
                  )
                : BorderSide.none,
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
                            child: Icon(
                              Icons.chevron_right,
                              color: ChoiceLuxTheme.platinumSilver,
                              size: isSmallMobile ? 20 : 24,
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
                          _statusChip(status, isSmallMobile),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: ChoiceLuxTheme.platinumSilver,
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
    final subtitleSize = isSmallMobile
        ? 12.0
        : isMobile
        ? 13.0
        : 14.0;
    final detailSize = isSmallMobile
        ? 11.0
        : isMobile
        ? 12.0
        : 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
          ),
        ),
        SizedBox(height: isSmallMobile ? 1 : 2),
        Text(
          _titleCase(user.role ?? 'Unassigned'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ChoiceLuxTheme.platinumSilver,
            fontSize: subtitleSize,
          ),
        ),
        if ((user.userEmail.isNotEmpty || (user.number?.isNotEmpty ?? false)))
          Padding(
            padding: EdgeInsets.only(top: isSmallMobile ? 1 : 2),
            child: Text(
              user.userEmail.isNotEmpty ? user.userEmail : (user.number ?? ''),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                fontSize: detailSize,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusChip(_StatusInfo status, bool isSmallMobile) {
    final fontSize = isSmallMobile ? 10.0 : 12.0;
    final padding = isSmallMobile ? 6.0 : 8.0;

    return Chip(
      label: Text(
        status.label,
        style: TextStyle(
          color: status.textColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
      backgroundColor: status.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  _StatusInfo _statusInfo(User user) {
    // Add logic for expiring soon/expired if you have expiry fields
    if (user.status?.toLowerCase() == 'active') {
      return _StatusInfo('Active', ChoiceLuxTheme.successColor, Colors.white);
    } else if (user.status?.toLowerCase() == 'deactivated') {
      return _StatusInfo('Expired', Colors.red, Colors.white);
    } else if (user.status?.toLowerCase() == 'expiring') {
      return _StatusInfo('Expiring Soon', Colors.amber, Colors.black);
    }
    return _StatusInfo('Unknown', Colors.grey, Colors.white);
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
