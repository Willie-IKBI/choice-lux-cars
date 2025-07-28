import 'package:flutter/material.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/app/theme.dart';

class AgentCard extends StatefulWidget {
  final Agent agent;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AgentCard({
    super.key,
    required this.agent,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard>
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
        final isMobile = constraints.maxWidth < 600;
        
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Card(
                  margin: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: ChoiceLuxTheme.cardGradient,
                      border: _isHovered
                          ? Border.all(
                              color: ChoiceLuxTheme.richGold,
                              width: 2,
                            )
                          : null,
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with avatar and agent name
                            Row(
                              children: [
                                // Agent avatar
                                Container(
                                  width: isMobile ? 40 : 48,
                                  height: isMobile ? 40 : 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                                    border: Border.all(
                                      color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: ChoiceLuxTheme.richGold,
                                    size: isMobile ? 20 : 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.agent.agentName,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: ChoiceLuxTheme.softWhite,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Agent',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: ChoiceLuxTheme.platinumSilver,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Contact information
                            _buildContactInfo(
                              Icons.email,
                              widget.agent.contactEmail,
                              isMobile,
                            ),
                            const SizedBox(height: 8),
                            _buildContactInfo(
                              Icons.phone,
                              widget.agent.contactNumber,
                              isMobile,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Action buttons
                            if (_isHovered || isMobile) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    Icons.edit,
                                    'Edit',
                                    widget.onEdit,
                                    isMobile,
                                  ),
                                  _buildActionButton(
                                    Icons.delete,
                                    'Delete',
                                    widget.onDelete,
                                    isMobile,
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Show hint for desktop
                              Center(
                                child: Text(
                                  'Hover for actions',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContactInfo(IconData icon, String text, bool isMobile) {
    return Row(
      children: [
        Icon(
          icon,
          size: isMobile ? 16 : 18,
          color: ChoiceLuxTheme.platinumSilver,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ChoiceLuxTheme.softWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback? onPressed,
    bool isMobile, {
    bool isDestructive = false,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 2.0 : 4.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: isMobile ? 16 : 18,
          ),
          label: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive
                ? ChoiceLuxTheme.errorColor
                : ChoiceLuxTheme.richGold,
            foregroundColor: isDestructive
                ? ChoiceLuxTheme.softWhite
                : Colors.black,
            elevation: 1,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 8 : 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
} 