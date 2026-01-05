import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/agents_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/client_stats_provider.dart';
import 'package:choice_lux_cars/features/clients/widgets/agent_card.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_agent_screen.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check if we should open to a specific tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final tabParam = uri.queryParameters['tab'];
      if (tabParam == 'agents') {
        _tabController.animateTo(1); // Switch to agents tab (index 1)
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh client data when screen becomes active (e.g., returning from edit)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(clientProvider(widget.clientId));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientProvider(widget.clientId));
    final agentsAsync = ref.watch(agentsNotifierProvider(widget.clientId));

    // Add refresh capability
    void refreshClient() {
      ref.invalidate(clientProvider(widget.clientId));
    }

    return SystemSafeScaffold(
      backgroundColor: ChoiceLuxTheme.jetBlack,
      appBar: LuxuryAppBar(
        title: 'Client Details',
        showBackButton: true,
        onBackPressed: () => context.go('/clients'),
      ),
      body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
                final padding = ResponsiveTokens.getPadding(screenWidth);
                final spacing = ResponsiveTokens.getSpacing(screenWidth);

                return Column(
                  children: [
                    // Client Info Header
                    clientAsync.when(
                      data: (client) => client != null
                          ? _buildClientHeader(client, isMobile)
                          : _buildErrorState('Client not found'),
                      loading: () => _buildLoadingHeader(),
                      error: (error, stackTrace) =>
                          _buildErrorState(error.toString()),
                    ),

                    // Tab Bar
                    _buildTabBar(isMobile),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(clientAsync, agentsAsync, isMobile),
                          _buildAgentsTab(agentsAsync, isMobile),
                          _buildActivityTab(isMobile),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
  }

  Widget _buildClientHeader(Client client, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 24.0,
        vertical: isMobile ? 12.0 : 16.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 1200,
          ),
          child: Row(
            children: [
              // Company Logo - Circular Style
              Container(
                width: isMobile ? 70 : 90,
                height: isMobile ? 70 : 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: client.companyLogo != null
                    ? ClipOval(
                        child: Image.network(
                          client.companyLogo!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildLogoPlaceholder(),
                        ),
                      )
                    : _buildLogoPlaceholder(),
              ),

              SizedBox(width: isMobile ? 16 : 20),

              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      client.companyName,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        color: ChoiceLuxTheme.softWhite,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      'Contact: ${client.contactPerson}',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        color: ChoiceLuxTheme.platinumSilver,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: isMobile ? 14 : 16,
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            client.contactEmail,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: ChoiceLuxTheme.platinumSilver,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: isMobile ? 14 : 16,
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                        SizedBox(width: 6),
                        Text(
                          client.contactNumber,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                        ),
                      ],
                    ),
                
                // Additional Information (only show if available)
                if (client.websiteAddress != null && client.websiteAddress!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        size: isMobile ? 16 : 18,
                        color: ChoiceLuxTheme.richGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          client.websiteAddress!,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 15,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (client.companyRegistrationNumber != null && client.companyRegistrationNumber!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.business_center,
                        size: isMobile ? 16 : 18,
                        color: ChoiceLuxTheme.richGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reg: ${client.companyRegistrationNumber!}',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 15,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (client.vatNumber != null && client.vatNumber!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: isMobile ? 16 : 18,
                        color: ChoiceLuxTheme.richGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'VAT: ${client.vatNumber!}',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 15,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (client.billingAddress != null && client.billingAddress!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: isMobile ? 16 : 18,
                        color: ChoiceLuxTheme.richGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Address: ${client.billingAddress!}',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 15,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildLogoPlaceholder() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Icon(Icons.business, color: ChoiceLuxTheme.richGold, size: ResponsiveTokens.getIconSize(screenWidth) * 1.3);
  }

  // Helper method to format currency with comma separators
  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'R0';

    double value;
    if (amount is int) {
      value = amount.toDouble();
    } else if (amount is double) {
      value = amount;
    } else {
      value = double.tryParse(amount.toString()) ?? 0.0;
    }

    // Format with comma separators and no decimals
    final formatted = value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
        );

    return 'R$formatted';
  }

  Widget _buildLoadingHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: ChoiceLuxTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading client',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 6),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: ChoiceLuxTheme.richGold,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorPadding: EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: ChoiceLuxTheme.platinumSilver,
          labelStyle: TextStyle(
            fontSize: isMobile ? 13 : 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: isMobile ? 13 : 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          labelPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 10 : 12,
          ),
          tabs: [
            _buildTab('Overview', Icons.grid_view, isMobile),
            _buildTab('Agents', Icons.people_outlined, isMobile),
            _buildTab('Activity', Icons.bolt, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, IconData icon, bool isMobile) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 15 : 18),
          SizedBox(width: isMobile ? 4 : 6),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<Client?> clientAsync,
    AsyncValue<List<Agent>> agentsAsync,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 24.0,
        vertical: isMobile ? 12.0 : 16.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 1200,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats
              _buildQuickStats(clientAsync, agentsAsync, isMobile),

              SizedBox(height: isMobile ? 20 : 24),

              // Recent Activity
              _buildRecentActivity(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    AsyncValue<Client?> clientAsync,
    AsyncValue<List<Agent>> agentsAsync,
    bool isMobile,
  ) {
    // Get client stats using the new provider
    final clientStatsAsync = ref.watch(clientStatsProvider(widget.clientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK STATS',
          style: TextStyle(
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.w700,
            color: ChoiceLuxTheme.softWhite,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final spacing = ResponsiveTokens.getSpacing(screenWidth);
            final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(constraints.maxWidth);
            final isMobile = ResponsiveBreakpoints.isMobile(constraints.maxWidth);
            final isTablet = ResponsiveBreakpoints.isTablet(constraints.maxWidth);
            final isDesktop = ResponsiveBreakpoints.isDesktop(constraints.maxWidth);
            
            int crossAxisCount;
            if (isSmallMobile) {
              crossAxisCount = 1;
            } else if (isTablet) {
              crossAxisCount = 2;
            } else if (isDesktop) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 4; // Large desktop
            }

            // Calculate aspect ratio based on screen size
            double aspectRatio;
            final isVeryNarrow = screenWidth < 400;
            if (isSmallMobile) {
              aspectRatio = 1.35; // 1 column - more vertical space
            } else if (crossAxisCount == 2 && (isVeryNarrow || screenWidth < 500)) {
              aspectRatio = 1.15; // 2 columns on narrow screens - need more height
            } else if (isTablet && crossAxisCount == 2) {
              aspectRatio = 1.2; // 2 columns on tablet
            } else if (isMobile) {
              aspectRatio = 1.25; // Mobile with multiple columns
            } else {
              aspectRatio = 1.6; // Desktop
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
              children: [
                _buildQuickStatCard(
                  label: 'Total Agents',
                  value: agentsAsync.when(
                    data: (agents) => agents.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  icon: Icons.people,
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                ),
                _buildQuickStatCard(
                  label: 'Completed Jobs',
                  value: clientStatsAsync.when(
                    data: (stats) => stats['completedJobs'].toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  icon: Icons.work,
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                ),
                _buildQuickStatCard(
                  label: 'Total Quotes',
                  value: clientStatsAsync.when(
                    data: (stats) => stats['totalQuotes'].toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  icon: Icons.description,
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                ),
                _buildQuickStatCard(
                  label: 'Total Revenue',
                  value: clientStatsAsync.when(
                    data: (stats) => _formatCurrency(stats['totalRevenue']),
                    loading: () => '...',
                    error: (_, __) => 'R0',
                  ),
                  icon: Icons.attach_money,
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required String label,
    required String value,
    required IconData icon,
    required bool isMobile,
    required double screenWidth,
  }) {
    final isVeryNarrow = screenWidth < 400;
    final cardPadding = isVeryNarrow ? 10.0 : (isMobile ? 10.0 : 16.0);
    final iconSize = isVeryNarrow ? 32.0 : (isMobile ? 36.0 : 40.0);
    final iconIconSize = isVeryNarrow ? 18.0 : (isMobile ? 20.0 : 22.0);
    final valueFontSize = isVeryNarrow ? 20.0 : (isMobile ? 22.0 : 28.0);
    final labelFontSize = isMobile ? 12.0 : 14.0;
    final iconSpacing = isVeryNarrow ? 6.0 : (isMobile ? 8.0 : 16.0);
    final valueSpacing = isVeryNarrow ? 2.0 : (isMobile ? 2.0 : 6.0);
    final labelSpacing = isVeryNarrow ? 4.0 : (isMobile ? 6.0 : 16.0);

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon in rounded square container
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: ChoiceLuxTheme.richGold,
              size: iconIconSize,
            ),
          ),
          SizedBox(height: iconSpacing),
          // Value - use Flexible to allow it to shrink if needed
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: ChoiceLuxTheme.softWhite,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: valueSpacing),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: ChoiceLuxTheme.platinumSilver,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: labelSpacing),
          // Progress bar at bottom
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.6, // Partial fill
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: ChoiceLuxTheme.richGold,
                size: isMobile ? 18 : 22,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: ChoiceLuxTheme.softWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      color: ChoiceLuxTheme.platinumSilver,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: TextStyle(
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.w700,
            color: ChoiceLuxTheme.softWhite,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),

        Column(
          children: [
            _buildActivityCard(
              'Client created',
              '2 days ago',
              Icons.person_add,
              isMobile,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildActivityCard(
              'First agent added',
              '1 day ago',
              Icons.people,
              isMobile,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildActivityCard(
              'No recent activity',
              'No activity yet',
              Icons.access_time,
              isMobile,
              isPlaceholder: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String title,
    String time,
    IconData icon,
    bool isMobile, {
    bool isPlaceholder = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: isPlaceholder
                  ? ChoiceLuxTheme.platinumSilver.withOpacity(0.1)
                  : ChoiceLuxTheme.richGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isPlaceholder
                  ? ChoiceLuxTheme.platinumSilver.withOpacity(0.5)
                  : ChoiceLuxTheme.richGold,
              size: isMobile ? 18 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: isPlaceholder
                        ? ChoiceLuxTheme.platinumSilver.withOpacity(0.5)
                        : ChoiceLuxTheme.softWhite,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsTab(AsyncValue<List<Agent>> agentsAsync, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AGENTS',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: ChoiceLuxTheme.softWhite,
                  letterSpacing: 1.2,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditAgentScreen(
                        clientId: widget.clientId,
                        agent: null, // null for new agent
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Agent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          agentsAsync.when(
            data: (agents) {
              if (agents.isEmpty) {
                return _buildEmptyAgentsState(isMobile);
              }
              return _buildAgentsList(agents, isMobile);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: ChoiceLuxTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading agents',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: ChoiceLuxTheme.platinumSilver,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAgentsState(bool isMobile) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: isMobile ? 64 : 80,
            color: ChoiceLuxTheme.platinumSilver,
          ),
          const SizedBox(height: 16),
          Text(
            'No agents yet',
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first agent to get started',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditAgentScreen(
                    clientId: widget.clientId,
                    agent: null, // null for new agent
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList(List<Agent> agents, bool isMobile) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: agents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final agent = agents[index];
        return AgentCard(
          agent: agent,
          onTap: () {
            // TODO: Navigate to agent detail screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Viewing ${agent.agentName}'),
                backgroundColor: ChoiceLuxTheme.richGold,
              ),
            );
          },
          onEdit: () {
            if (agent.id == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Error: Agent ID is null. Cannot edit this agent.',
                  ),
                  backgroundColor: ChoiceLuxTheme.errorColor,
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddEditAgentScreen(clientId: widget.clientId, agent: agent),
              ),
            );
          },
          onDelete: () => _showDeleteAgentDialog(agent),
        );
      },
    );
  }

  Widget _buildActivityTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVITY HISTORY',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: ChoiceLuxTheme.softWhite,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          Column(
            children: [
              _buildActivityCard(
                'Client created',
                '2 days ago',
                Icons.person_add,
                isMobile,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildActivityCard(
                'First agent added',
                '1 day ago',
                Icons.people,
                isMobile,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildActivityCard(
                'No recent activity',
                'No activity yet',
                Icons.access_time,
                isMobile,
                isPlaceholder: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAgentDialog(Agent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        title: Text(
          'Delete Agent',
          style: TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${agent.agentName}"? This action cannot be undone.',
          style: TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                // Delete the agent and wait for the operation to complete
                await ref
                    .read(agentsNotifierProvider(widget.clientId).notifier)
                    .deleteAgent(agent.id.toString());

                // Force a rebuild by refreshing the agents list
                await ref
                    .read(agentsNotifierProvider(widget.clientId).notifier)
                    .refresh();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${agent.agentName} deleted successfully'),
                      backgroundColor: ChoiceLuxTheme.successColor,
                    ),
                  );
                }
              } catch (error) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete ${agent.agentName}: ${error.toString()}',
                      ),
                      backgroundColor: ChoiceLuxTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.errorColor,
              foregroundColor: ChoiceLuxTheme.softWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
