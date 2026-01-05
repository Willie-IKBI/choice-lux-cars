import 'package:flutter/material.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/app/theme.dart';

class ClientCard extends StatefulWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewAgents;
  final bool isSelected;

  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onViewAgents,
    this.isSelected = false,
  });

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive breakpoints for mobile optimization
        final screenWidth = constraints.maxWidth;
        final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
        final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);

        final spacing = ResponsiveTokens.getSpacing(screenWidth);
        
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Card(
                  margin: EdgeInsets.all(spacing * 0.5),
                  elevation: _isHovered ? 8 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Fix: Add clipBehavior to ensure ripple is clipped to rounded corners
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ChoiceLuxTheme.charcoalGray.withOpacity(0.95),
                          ChoiceLuxTheme.charcoalGray.withOpacity(0.9),
                        ],
                      ),
                      border: widget.isSelected
                          ? Border.all(color: ChoiceLuxTheme.richGold, width: 2)
                          : _isHovered
                          ? Border.all(
                              color: ChoiceLuxTheme.richGold.withOpacity(0.5),
                              width: 1,
                            )
                          : Border.all(
                              color: ChoiceLuxTheme.platinumSilver.withOpacity(
                                0.1,
                              ),
                              width: 1,
                            ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      // Fix: Add proper shape and clipBehavior to Material
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: widget.onTap,
                        splashColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
                        highlightColor: ChoiceLuxTheme.richGold.withOpacity(
                          0.05,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Semantics(
                          label: 'Client card for ${widget.client.companyName}',
                          button: true,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isSmallMobile
                                  ? 6.0
                                  : isMobile
                                  ? 8.0
                                  : 16.0,
                              isSmallMobile
                                  ? 6.0
                                  : isMobile
                                  ? 8.0
                                  : 16.0,
                              isSmallMobile
                                  ? 6.0
                                  : isMobile
                                  ? 8.0
                                  : 16.0,
                              isSmallMobile
                                  ? 4.0
                                  : isMobile
                                  ? 6.0
                                  : 12.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header with logo and company name
                                Row(
                                  children: [
                                    // Company logo or placeholder
                                    Container(
                                      width: isSmallMobile
                                          ? 28
                                          : isMobile
                                          ? 32
                                          : 44,
                                      height: isSmallMobile
                                          ? 28
                                          : isMobile
                                          ? 32
                                          : 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: ChoiceLuxTheme.richGold
                                            .withOpacity(0.1),
                                        border: Border.all(
                                          color: ChoiceLuxTheme.richGold
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      // Fix: Check for both null and empty URLs
                                      child: _buildLogo(),
                                    ),
                                    SizedBox(width: spacing),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.client.companyName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 16),
                                                  color:
                                                      ChoiceLuxTheme.softWhite,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: spacing * 0.25),
                                          Text(
                                            'Contact: ${widget.client.contactPerson}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 13),
                                                  color: ChoiceLuxTheme
                                                      .platinumSilver
                                                      .withOpacity(0.8),
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status and selection indicators
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildStatusIndicator(),
                                        if (widget.isSelected) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: ChoiceLuxTheme.richGold,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: isSmallMobile
                                      ? 2
                                      : isMobile
                                      ? 4
                                      : 8,
                                ),

                                // Contact information with consistent spacing
                                _buildContactInfo(
                                  Icons.email,
                                  widget.client.contactEmail,
                                  isMobile,
                                  isSmallMobile,
                                ),
                                SizedBox(
                                  height: isSmallMobile
                                      ? 1
                                      : isMobile
                                      ? 2
                                      : 4,
                                ),
                                _buildContactInfo(
                                  Icons.phone,
                                  widget.client.contactNumber,
                                  isMobile,
                                  isSmallMobile,
                                ),

                                                                 // Action buttons - reduced spacing
                                 // Fix: Detect pointer kind and show actions appropriately
                                 if (_isHovered || isMobile) ...[
                                  // Visual divider
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: isMobile ? 2 : 2,
                                    ),
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          ChoiceLuxTheme.platinumSilver
                                              .withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  _buildActionButtons(isMobile, isSmallMobile),
                                ] else ...[
                                  // Show hint for desktop
                                  Center(
                                    child: Text(
                                      'Hover for actions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ChoiceLuxTheme.platinumSilver
                                                .withOpacity(0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Fix: Robust logo rendering with null/empty URL handling
  Widget _buildLogo() {
    final logo = widget.client.companyLogo;
    final hasLogo = logo != null && logo.trim().isNotEmpty;
    
    if (hasLogo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logo!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
        ),
      );
    } else {
      return _buildLogoPlaceholder();
    }
  }

  Widget _buildLogoPlaceholder() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Icon(Icons.business, color: ChoiceLuxTheme.richGold, size: ResponsiveTokens.getIconSize(screenWidth));
  }

  Widget _buildStatusIndicator() {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (widget.client.status) {
      case ClientStatus.vip:
        backgroundColor = ChoiceLuxTheme.richGold;
        textColor = Colors.black;
        label = 'VIP';
        icon = Icons.star;
        break;
      case ClientStatus.pending:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case ClientStatus.inactive:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        label = 'Inactive';
        icon = Icons.block;
        break;
      case ClientStatus.active:
      default:
        backgroundColor = ChoiceLuxTheme.successColor;
        textColor = Colors.white;
        label = 'Active';
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
    IconData icon,
    String? text,
    bool isMobile,
    bool isSmallMobile,
  ) {
    final displayText = text?.isNotEmpty == true ? text! : '—';
    final textColor = text?.isNotEmpty == true
        ? ChoiceLuxTheme.softWhite
        : ChoiceLuxTheme.platinumSilver.withOpacity(0.5);

    return Row(
      children: [
        Icon(
          icon,
          size: isSmallMobile
              ? 12
              : isMobile
              ? 14
              : 16,
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
        ),
        SizedBox(
          width: isSmallMobile
              ? 3
              : isMobile
              ? 4
              : 6,
        ),
        Expanded(
          child: Text(
            displayText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isSmallMobile
                  ? 11
                  : isMobile
                  ? 13
                  : 14,
              color: textColor.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile, bool isSmallMobile) {
    if (isMobile) {
      // Stack buttons vertically on mobile with better spacing
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          // Fix: Use theme colors instead of hard-coded greys
          color: ChoiceLuxTheme.charcoalGray.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            // Primary action - Edit (full width)
            SizedBox(
              width: double.infinity,
              child: _buildPrimaryButton(
                Icons.edit,
                'Edit Client',
                widget.onEdit,
                isMobile,
                isSmallMobile,
              ),
            ),
            const SizedBox(height: 3),
            // Secondary actions in a row
            Row(
              children: [
                Expanded(
                  child: _buildIconButton(
                    Icons.people,
                    'Manage Agents',
                    widget.onViewAgents,
                    isMobile,
                    isSmallMobile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildIconButton(
                    Icons.archive,
                    'Deactivate',
                    widget.onDelete,
                    isMobile,
                    isSmallMobile,
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Horizontal layout for tablet and desktop
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          // Fix: Use theme colors instead of hard-coded greys
          color: ChoiceLuxTheme.charcoalGray.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Primary action - Edit
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                Icons.edit,
                'Edit',
                widget.onEdit,
                isMobile,
                isSmallMobile,
              ),
            ),
            const SizedBox(width: 12),
            // Secondary actions
            _buildIconButton(
              Icons.people,
              'Manage Agents',
              widget.onViewAgents,
              isMobile,
              isSmallMobile,
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              Icons.archive,
              'Deactivate',
              widget.onDelete,
              isMobile,
              isSmallMobile,
              isDestructive: true,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPrimaryButton(
    IconData icon,
    String label,
    VoidCallback? onPressed,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: isSmallMobile
            ? 14
            : isMobile
            ? 16
            : 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSmallMobile
              ? 12
              : isMobile
              ? 13
              : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.black,
        elevation: _isHovered ? 4 : 2,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile
              ? 8
              : isMobile
              ? 12
              : 16,
          vertical: isSmallMobile
              ? 8
              : isMobile
              ? 10
              : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size(
          0,
          isSmallMobile
              ? 28
              : isMobile
              ? 32
              : 44,
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    String tooltip,
    VoidCallback? onPressed,
    bool isMobile,
    bool isSmallMobile, {
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: _IconButtonWithHover(
        icon: icon,
        onPressed: onPressed,
        isMobile: isMobile,
        isSmallMobile: isSmallMobile,
        isDestructive: isDestructive,
      ),
    );
  }
}

class _IconButtonWithHover extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isMobile;
  final bool isSmallMobile;
  final bool isDestructive;

  const _IconButtonWithHover({
    required this.icon,
    required this.onPressed,
    required this.isMobile,
    required this.isSmallMobile,
    required this.isDestructive,
  });

  @override
  State<_IconButtonWithHover> createState() => _IconButtonWithHoverState();
}

class _IconButtonWithHoverState extends State<_IconButtonWithHover> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.isSmallMobile
            ? 28
            : widget.isMobile
            ? 32
            : 44,
        width: widget.isSmallMobile
            ? 28
            : widget.isMobile
            ? 32
            : 44,
        decoration: BoxDecoration(
          color: isHovered
              ? (widget.isDestructive
                    ? ChoiceLuxTheme.errorColor.withOpacity(0.2)
                    : ChoiceLuxTheme.richGold.withOpacity(0.2))
              : (widget.isDestructive
                    ? ChoiceLuxTheme.errorColor.withOpacity(0.1)
                    : ChoiceLuxTheme.richGold.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHovered
                ? (widget.isDestructive
                      ? ChoiceLuxTheme.errorColor.withOpacity(0.5)
                      : ChoiceLuxTheme.richGold.withOpacity(0.5))
                : (widget.isDestructive
                      ? ChoiceLuxTheme.errorColor.withOpacity(0.3)
                      : ChoiceLuxTheme.richGold.withOpacity(0.3)),
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color:
                        (widget.isDestructive
                                ? ChoiceLuxTheme.errorColor
                                : ChoiceLuxTheme.richGold)
                            .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: AnimatedScale(
                scale: isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon,
                  size: widget.isSmallMobile
                      ? 14
                      : widget.isMobile
                      ? 16
                      : 22,
                  color: widget.isDestructive
                      ? ChoiceLuxTheme.errorColor
                      : ChoiceLuxTheme.richGold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
