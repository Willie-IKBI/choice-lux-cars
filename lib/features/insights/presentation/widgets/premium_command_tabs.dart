import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Model for a premium tab item
class PremiumTabItem {
  final String label;
  final IconData iconOutlined;
  final IconData iconFilled;
  final String? semanticLabel;

  const PremiumTabItem({
    required this.label,
    required this.iconOutlined,
    required this.iconFilled,
    this.semanticLabel,
  });
}

/// Premium Command Tabs - A modern, responsive navigation bar with premium styling
class PremiumCommandTabs extends StatefulWidget {
  final List<PremiumTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool scrollableOnMobile;
  final double? maxWidth;

  const PremiumCommandTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.scrollableOnMobile = true,
    this.maxWidth,
  });

  @override
  State<PremiumCommandTabs> createState() => _PremiumCommandTabsState();
}

class _PremiumCommandTabsState extends State<PremiumCommandTabs> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    final radius = ResponsiveTokens.getCornerRadius(screenWidth);

    return FocusableActionDetector(
      focusNode: _focusNode,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): _MoveTabIntent(-1),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): _MoveTabIntent(1),
      },
      actions: {
        _MoveTabIntent: CallbackAction<_MoveTabIntent>(
          onInvoke: (intent) {
            final newIndex = (widget.selectedIndex + intent.delta)
                .clamp(0, widget.items.length - 1);
            if (newIndex != widget.selectedIndex) {
              widget.onChanged(newIndex);
            }
            return null;
          },
        ),
      },
      child: widget.maxWidth != null
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.maxWidth!,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? padding : padding * 1.5,
                  ),
                  child: _buildTabContainer(context, screenWidth, isDesktop, isMobile, radius, spacing),
                ),
              ),
            )
          : _buildTabContainer(context, screenWidth, isDesktop, isMobile, radius, spacing),
    );
  }

  Widget _buildTabContainer(
    BuildContext context,
    double screenWidth,
    bool isDesktop,
    bool isMobile,
    double radius,
    double spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius * 1.5), // 16-18px equivalent
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 12,
        ),
        child: isMobile && widget.scrollableOnMobile
            ? _buildScrollableTabs(context, screenWidth, isMobile, spacing)
            : _buildStaticTabs(context, screenWidth, isDesktop, isMobile, spacing),
      ),
    );
  }

  Widget _buildScrollableTabs(
    BuildContext context,
    double screenWidth,
    bool isMobile,
    double spacing,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(
          widget.items.length,
          (index) => _buildTabItem(
            context,
            widget.items[index],
            index,
            screenWidth,
            isMobile,
            spacing,
            isScrollable: true,
          ),
        ),
      ),
    );
  }

  Widget _buildStaticTabs(
    BuildContext context,
    double screenWidth,
    bool isDesktop,
    bool isMobile,
    double spacing,
  ) {
    // On desktop, use equal width tabs; on tablet, allow natural sizing
    if (isDesktop) {
      return Row(
        children: List.generate(
          widget.items.length,
          (index) => Expanded(
            child: _buildTabItem(
              context,
              widget.items[index],
              index,
              screenWidth,
              isMobile,
              spacing,
              isScrollable: false,
            ),
          ),
        ),
      );
    } else {
      // Tablet: natural sizing with spacing
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          widget.items.length,
          (index) => _buildTabItem(
            context,
            widget.items[index],
            index,
            screenWidth,
            isMobile,
            spacing,
            isScrollable: false,
          ),
        ),
      );
    }
  }

  Widget _buildTabItem(
    BuildContext context,
    PremiumTabItem item,
    int index,
    double screenWidth,
    bool isMobile,
    double spacing,
    {required bool isScrollable}
  ) {
    final isSelected = index == widget.selectedIndex;
    final showLabel = !isMobile || isSelected; // Mobile: only show label for active tab

    return _TabItemWidget(
      item: item,
      isSelected: isSelected,
      showLabel: showLabel,
      isMobile: isMobile,
      spacing: spacing,
      isScrollable: isScrollable,
      onTap: () => widget.onChanged(index),
    );
  }
}

/// Individual tab item widget with animations
class _TabItemWidget extends StatefulWidget {
  final PremiumTabItem item;
  final bool isSelected;
  final bool showLabel;
  final bool isMobile;
  final double spacing;
  final bool isScrollable;
  final VoidCallback onTap;

  const _TabItemWidget({
    required this.item,
    required this.isSelected,
    required this.showLabel,
    required this.isMobile,
    required this.spacing,
    required this.isScrollable,
    required this.onTap,
  });

  @override
  State<_TabItemWidget> createState() => _TabItemWidgetState();
}

class _TabItemWidgetState extends State<_TabItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final radius = ResponsiveTokens.getCornerRadius(screenWidth);
    final tabPadding = widget.isMobile
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);

    return Semantics(
      label: widget.item.semanticLabel ?? '${widget.item.label} tab',
      selected: widget.isSelected,
      button: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isScrollable ? widget.spacing : widget.spacing * 0.5,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(radius * 0.75),
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: tabPadding,
                constraints: const BoxConstraints(
                  minHeight: 44, // Minimum tap target
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? ChoiceLuxTheme.richGold.withOpacity(0.2)
                      : (_isHovered && !widget.isMobile)
                          ? ChoiceLuxTheme.platinumSilver.withOpacity(0.05)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(radius * 0.75),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.isSelected
                            ? widget.item.iconFilled
                            : widget.item.iconOutlined,
                        key: ValueKey(widget.isSelected),
                        size: widget.isMobile ? 22 : 24,
                        color: widget.isSelected
                            ? ChoiceLuxTheme.richGold
                            : ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                    if (widget.showLabel) ...[
                      SizedBox(width: widget.isMobile ? 6 : 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: widget.isMobile ? 13 : 14,
                          fontWeight: widget.isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: widget.isSelected ? 0.3 : 0.1,
                          color: widget.isSelected
                              ? ChoiceLuxTheme.softWhite
                              : ChoiceLuxTheme.platinumSilver,
                        ),
                        child: Text(
                          widget.item.label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
    );
  }
}

/// Intent for keyboard navigation
class _MoveTabIntent extends Intent {
  final int delta;

  const _MoveTabIntent(this.delta);
}
