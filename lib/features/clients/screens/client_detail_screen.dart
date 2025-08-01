import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/agents_provider.dart';
import 'package:choice_lux_cars/features/clients/widgets/agent_card.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_agent_screen.dart';
import '../../../shared/widgets/simple_app_bar.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({
    super.key,
    required this.clientId,
  });

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientProvider(widget.clientId));
    final agentsAsync = ref.watch(agentsNotifierProvider(widget.clientId));

    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Client Details',
        subtitle: 'View and manage client information',
        showBackButton: true,
        onBackPressed: () => context.go('/clients'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              return Column(
                children: [
                  // Client Info Header
                  clientAsync.when(
                    data: (client) => client != null 
                        ? _buildClientHeader(client, isMobile)
                        : _buildErrorState('Client not found'),
                    loading: () => _buildLoadingHeader(),
                    error: (error, stackTrace) => _buildErrorState(error.toString()),
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
      ),
    );
  }



  Widget _buildClientHeader(Client client, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Row(
        children: [
          // Company Logo - Circular Style
          Container(
            width: isMobile ? 70 : 90,
            height: isMobile ? 70 : 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: client.companyLogo != null
                ? ClipOval(
                    child: Image.network(
                      client.companyLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildLogoPlaceholder(),
                    ),
                  )
                : _buildLogoPlaceholder(),
          ),
          
          const SizedBox(width: 20),
          
          // Client Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.companyName,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 26,
                    fontWeight: FontWeight.w700,
                    color: ChoiceLuxTheme.softWhite,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact: ${client.contactPerson}',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    color: ChoiceLuxTheme.platinumSilver,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: isMobile ? 16 : 18,
                      color: ChoiceLuxTheme.richGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        client.contactEmail,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: isMobile ? 16 : 18,
                      color: ChoiceLuxTheme.richGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      client.contactNumber,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Icon(
      Icons.business,
      color: ChoiceLuxTheme.richGold,
      size: 32,
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: CircularProgressIndicator(
          color: ChoiceLuxTheme.richGold,
        ),
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
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ChoiceLuxTheme.charcoalGray.withOpacity(0.8),
            ChoiceLuxTheme.charcoalGray.withOpacity(0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 10),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ChoiceLuxTheme.richGold,
                ChoiceLuxTheme.richGold.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ChoiceLuxTheme.richGold.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorPadding: EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: ChoiceLuxTheme.platinumSilver,
          labelStyle: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          labelPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 18 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          tabs: [
            _buildTab('Overview', Icons.dashboard_outlined, isMobile),
            _buildTab('Agents', Icons.people_outlined, isMobile),
            _buildTab('Activity', Icons.history_outlined, isMobile),
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
          Icon(
            icon,
            size: isMobile ? 16 : 18,
          ),
          const SizedBox(width: 6),
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
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          _buildQuickStats(clientAsync, agentsAsync, isMobile),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          _buildRecentActivity(isMobile),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    AsyncValue<Client?> clientAsync,
    AsyncValue<List<Agent>> agentsAsync,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK STATS',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: ChoiceLuxTheme.richGold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallMobile = constraints.maxWidth < 400;
            final crossAxisCount = isSmallMobile ? 1 : 2;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.8,
              children: [
                _buildStatCard(
                  'Total Agents',
                  agentsAsync.when(
                    data: (agents) => agents.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.people,
                  isMobile,
                ),
                _buildStatCard(
                  'Active Jobs',
                  '0', // TODO: Get from jobs provider
                  Icons.work,
                  isMobile,
                ),
                _buildStatCard(
                  'Total Quotes',
                  '0', // TODO: Get from quotes provider
                  Icons.description,
                  isMobile,
                ),
                _buildStatCard(
                  'Total Revenue',
                  '\$0', // TODO: Get from invoices provider
                  Icons.attach_money,
                  isMobile,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 14),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: ChoiceLuxTheme.richGold,
                size: isMobile ? 22 : 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      color: ChoiceLuxTheme.softWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
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
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: ChoiceLuxTheme.richGold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          decoration: BoxDecoration(
            gradient: ChoiceLuxTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              children: [
                _buildActivityItem(
                  'Client created',
                  '2 days ago',
                  Icons.person_add,
                  isMobile,
                ),
                const Divider(color: ChoiceLuxTheme.platinumSilver),
                _buildActivityItem(
                  'First agent added',
                  '1 day ago',
                  Icons.people,
                  isMobile,
                ),
                const Divider(color: ChoiceLuxTheme.platinumSilver),
                _buildActivityItem(
                  'No recent activity',
                  'No activity yet',
                  Icons.info_outline,
                  isMobile,
                  isPlaceholder: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    bool isMobile, {
    bool isPlaceholder = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w600,
                    color: isPlaceholder 
                        ? ChoiceLuxTheme.platinumSilver.withOpacity(0.5)
                        : ChoiceLuxTheme.softWhite,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
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
                  color: ChoiceLuxTheme.richGold,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: CircularProgressIndicator(
                color: ChoiceLuxTheme.richGold,
              ),
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
                  content: Text('Error: Agent ID is null. Cannot edit this agent.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditAgentScreen(
                  clientId: widget.clientId,
                  agent: agent,
                ),
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
              color: ChoiceLuxTheme.richGold,
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            decoration: BoxDecoration(
              gradient: ChoiceLuxTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                children: [
                  _buildActivityItem(
                    'Client created',
                    '2 days ago',
                    Icons.person_add,
                    isMobile,
                  ),
                  const Divider(color: ChoiceLuxTheme.platinumSilver),
                  _buildActivityItem(
                    'First agent added',
                    '1 day ago',
                    Icons.people,
                    isMobile,
                  ),
                  const Divider(color: ChoiceLuxTheme.platinumSilver),
                  _buildActivityItem(
                    'No recent activity',
                    'No activity yet',
                    Icons.info_outline,
                    isMobile,
                    isPlaceholder: true,
                  ),
                ],
              ),
            ),
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
                await ref.read(agentsNotifierProvider(widget.clientId).notifier)
                    .deleteAgent(agent.id.toString());
                
                // Force a rebuild by refreshing the agents list
                await ref.read(agentsNotifierProvider(widget.clientId).notifier).refresh();
                
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
                      content: Text('Failed to delete ${agent.agentName}: ${error.toString()}'),
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