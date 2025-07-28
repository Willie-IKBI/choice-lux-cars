import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:choice_lux_cars/app/theme.dart';

class UserCard extends StatefulWidget {
  final User user;
  final VoidCallback? onTap;
  const UserCard({Key? key, required this.user, this.onTap}) : super(key: key);

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final user = widget.user;
    final status = _statusInfo(user);
    final avatar = CircleAvatar(
      radius: 24,
      backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
      backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty ? NetworkImage(user.profileImage!) : null,
      child: user.profileImage == null || user.profileImage!.isEmpty ? Icon(Icons.person, color: ChoiceLuxTheme.richGold, size: 28) : null,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: _isHovered ? 6 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: _isHovered ? BorderSide(color: ChoiceLuxTheme.richGold.withOpacity(0.3), width: 1) : BorderSide.none),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            splashColor: ChoiceLuxTheme.richGold.withOpacity(0.08),
            highlightColor: ChoiceLuxTheme.richGold.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [avatar, const SizedBox(width: 12), Expanded(child: _userInfo(user, isMobile)), _statusChip(status)],
                        ),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerRight, child: Icon(Icons.chevron_right, color: ChoiceLuxTheme.platinumSilver)),
                      ],
                    )
                  : Row(
                      children: [
                        avatar,
                        const SizedBox(width: 16),
                        Expanded(child: _userInfo(user, isMobile)),
                        _statusChip(status),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: ChoiceLuxTheme.platinumSilver),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userInfo(User user, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(_titleCase(user.role ?? 'Unassigned'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ChoiceLuxTheme.platinumSilver, fontSize: 13)),
        if ((user.userEmail.isNotEmpty || (user.number?.isNotEmpty ?? false)))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(user.userEmail.isNotEmpty ? user.userEmail : (user.number ?? ''), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7), fontSize: 12)),
          ),
      ],
    );
  }

  Widget _statusChip(_StatusInfo status) {
    return Chip(
      label: Text(status.label, style: TextStyle(color: status.textColor, fontWeight: FontWeight.w600, fontSize: 12)),
      backgroundColor: status.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color textColor;
  _StatusInfo(this.label, this.color, this.textColor);
} 