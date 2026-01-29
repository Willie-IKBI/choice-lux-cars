import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/admin/models/ops_today_summary.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Driver workload row: desktop = table-like row (Driver | Jobs today | State | Long wait | Active job | Actions),
/// mobile = card (name + state chip, jobs/long wait, active line, Call, WhatsApp, View).
class OpsDriverRow extends StatelessWidget {
  final OpsDriverWorkloadItem driver;
  final bool isAdmin;
  final bool isMobile;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const OpsDriverRow({
    super.key,
    required this.driver,
    required this.isAdmin,
    required this.isMobile,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return isMobile ? _buildCard(context) : _buildTableRow(context);
  }

  Widget _buildCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(width);
    final radius = ResponsiveTokens.getCornerRadius(width);
    final stateColor = _stateColor(driver.state);
    final stateLabel = _stateLabel(driver.state);
    final activeSummary = driver.activeJobId != null
        ? (driver.activeStep != null && driver.activeStep!.isNotEmpty
            ? 'Job #${driver.activeJobId} · ${driver.activeStep}'
            : 'Job #${driver.activeJobId}')
        : '—';

    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      padding: EdgeInsets.all(spacing * 1.5),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  driver.driverName,
                  style: TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              _stateChip(stateLabel, stateColor),
            ],
          ),
          SizedBox(height: spacing * 0.75),
          Row(
            children: [
              Text(
                '${driver.jobsToday} job${driver.jobsToday == 1 ? '' : 's'} today',
                style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 13),
              ),
              if (driver.longWaitJobs > 0) ...[
                SizedBox(width: spacing),
                Text(
                  '${driver.longWaitJobs} long wait',
                  style: TextStyle(color: ChoiceLuxTheme.errorColor, fontSize: 12),
                ),
              ],
            ],
          ),
          SizedBox(height: spacing * 0.5),
          Text(
            'Active: $activeSummary',
            style: TextStyle(color: ChoiceLuxTheme.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isAdmin && driver.phoneNumber != null && driver.phoneNumber!.isNotEmpty) ...[
                IconButton(
                  icon: Icon(Icons.phone, size: 20, color: ChoiceLuxTheme.richGold),
                  onPressed: onCall,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
                IconButton(
                  icon: Icon(Icons.chat, size: 20, color: Color(0xFF25D366)),
                  onPressed: onWhatsApp,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ],
              TextButton.icon(
                onPressed: driver.activeJobId != null
                    ? () => context.go('/jobs/${driver.activeJobId}/summary')
                    : null,
                icon: Icon(Icons.arrow_forward_ios, size: 12, color: ChoiceLuxTheme.platinumSilver),
                label: Text('View', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(width);
    final stateColor = _stateColor(driver.state);
    final stateLabel = _stateLabel(driver.state);
    final activeSummary = driver.activeJobId != null
        ? (driver.activeStep != null && driver.activeStep!.isNotEmpty
            ? 'Job #${driver.activeJobId} · ${driver.activeStep}'
            : 'Job #${driver.activeJobId}')
        : '—';

    final textStyle = TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 13);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: driver.activeJobId != null
            ? () => context.go('/jobs/${driver.activeJobId}/summary')
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing * 1.25, horizontal: spacing * 1.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  driver.driverName,
                  style: textStyle.copyWith(
                    color: ChoiceLuxTheme.softWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text('${driver.jobsToday}', style: textStyle, textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 1,
                child: Center(child: _stateChip(stateLabel, stateColor)),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  driver.longWaitJobs > 0 ? '${driver.longWaitJobs}' : '—',
                  style: textStyle.copyWith(
                    color: driver.longWaitJobs > 0 ? ChoiceLuxTheme.errorColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  activeSummary,
                  style: textStyle.copyWith(color: ChoiceLuxTheme.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin && driver.phoneNumber != null && driver.phoneNumber!.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(Icons.phone, size: 18, color: ChoiceLuxTheme.richGold),
                      onPressed: onCall,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                    IconButton(
                      icon: Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                      onPressed: onWhatsApp,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ],
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 12, color: ChoiceLuxTheme.platinumSilver),
                    onPressed: driver.activeJobId != null
                        ? () => context.go('/jobs/${driver.activeJobId}/summary')
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'stuck':
        return ChoiceLuxTheme.errorColor;
      case 'busy':
        return ChoiceLuxTheme.orange;
      default:
        return ChoiceLuxTheme.successColor;
    }
  }

  String _stateLabel(String state) {
    switch (state) {
      case 'stuck':
        return 'Stuck';
      case 'busy':
        return 'Busy';
      default:
        return 'Idle';
    }
  }
}
