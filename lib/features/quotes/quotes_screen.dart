import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/luxury_app_bar.dart';
import '../../app/theme.dart';
import 'providers/quotes_provider.dart';
import 'widgets/quote_card.dart';

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final quotes = ref.watch(quotesProvider);
    final canCreateQuotes = ref.read(quotesProvider.notifier).canCreateQuotes;

    // Filter quotes based on selected status
    List<dynamic> filteredQuotes = quotes;
    if (_selectedStatus != 'all') {
      switch (_selectedStatus) {
        case 'open':
          filteredQuotes = quotes.where((quote) => quote.isOpen).toList();
          break;
        case 'accepted':
          filteredQuotes = quotes.where((quote) => quote.isAccepted).toList();
          break;
        case 'expired':
          filteredQuotes = quotes.where((quote) => quote.isExpired).toList();
          break;
        case 'closed':
          filteredQuotes = quotes.where((quote) => quote.isClosed).toList();
          break;
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredQuotes = filteredQuotes.where((quote) {
        final passengerName = quote.passengerName?.toLowerCase() ?? '';
        final quoteId = quote.id.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return passengerName.contains(query) || quoteId.contains(query);
      }).toList();
    }

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Quotes',
        subtitle: 'Manage quotations',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Stats
              _buildHeaderSection(filteredQuotes.length, quotes.length),
              
              // Search and Filter Section
              _buildSearchAndFilterSection(isMobile),
              
              // View Toggle (Desktop only)
              if (!isMobile) _buildViewToggle(),
              
              // Quotes List/Grid
              Expanded(
                child: filteredQuotes.isEmpty
                    ? _buildEmptyState()
                    : _buildQuotesList(filteredQuotes, isMobile, isSmallMobile, isDesktop),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canCreateQuotes
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/quotes/create'),
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Create Quote'),
            )
          : null,
    );
  }

  Widget _buildHeaderSection(int filteredCount, int totalCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 16 : isMobile ? 20 : 24,
        vertical: isSmallMobile ? 16 : isMobile ? 20 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quotes',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: ChoiceLuxTheme.richGold,
                        fontWeight: FontWeight.w700,
                        fontSize: isSmallMobile ? 20 : isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filteredCount == totalCount 
                          ? '$totalCount total quotes'
                          : '$filteredCount of $totalCount quotes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ChoiceLuxTheme.platinumSilver,
                        fontSize: isSmallMobile ? 12 : isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) _buildQuickStats(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 2,
            width: isSmallMobile ? 40 : isMobile ? 60 : 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChoiceLuxTheme.richGold,
                  ChoiceLuxTheme.richGold.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final quotes = ref.watch(quotesProvider);
    final openCount = quotes.where((q) => q.isOpen).length;
    final acceptedCount = quotes.where((q) => q.isAccepted).length;
    final expiredCount = quotes.where((q) => q.isExpired).length;

    return Row(
      children: [
        _buildStatChip('Open', openCount, Colors.blue),
        const SizedBox(width: 8),
        _buildStatChip('Accepted', acceptedCount, ChoiceLuxTheme.successColor),
        const SizedBox(width: 8),
        _buildStatChip('Expired', expiredCount, ChoiceLuxTheme.errorColor),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
              ),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search quotes by passenger name or quote ID...',
                hintStyle: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(color: ChoiceLuxTheme.softWhite),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('all', 'All', Colors.grey),
                const SizedBox(width: 8),
                _buildStatusChip('open', 'Open', Colors.blue),
                const SizedBox(width: 8),
                _buildStatusChip('accepted', 'Accepted', ChoiceLuxTheme.successColor),
                const SizedBox(width: 8),
                _buildStatusChip('expired', 'Expired', ChoiceLuxTheme.errorColor),
                const SizedBox(width: 8),
                _buildStatusChip('closed', 'Closed', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, Color color) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton(
                  icon: Icons.view_list,
                  isSelected: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
                _buildToggleButton(
                  icon: Icons.grid_view,
                  isSelected: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? ChoiceLuxTheme.richGold : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.black : ChoiceLuxTheme.platinumSilver,
        ),
      ),
    );
  }

  Widget _buildQuotesList(List<dynamic> quotes, bool isMobile, bool isSmallMobile, bool isDesktop) {
    if (_isGridView && !isMobile) {
      // Grid view for desktop
      return RefreshIndicator(
        onRefresh: () => ref.read(quotesProvider.notifier).fetchQuotes(),
        child: GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return QuoteCard(
              quote: quote,
              onTap: () => context.go('/quotes/${quote.id}'),
            );
          },
        ),
      );
    } else {
      // List view for mobile and desktop
      return RefreshIndicator(
        onRefresh: () => ref.read(quotesProvider.notifier).fetchQuotes(),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 12 : isMobile ? 16 : 24,
            vertical: 8,
          ),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return QuoteCard(
              quote: quote,
              onTap: () => context.go('/quotes/${quote.id}'),
            );
          },
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    Color iconColor;

    if (_searchQuery.isNotEmpty) {
      message = 'No quotes found matching "$_searchQuery"';
      icon = Icons.search_off;
      iconColor = ChoiceLuxTheme.platinumSilver;
    } else if (_selectedStatus != 'all') {
      message = 'No $_selectedStatus quotes found';
      icon = Icons.inbox_outlined;
      iconColor = ChoiceLuxTheme.platinumSilver;
    } else {
      message = 'No quotes found';
      icon = Icons.description_outlined;
      iconColor = ChoiceLuxTheme.richGold;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty && _selectedStatus == 'all')
            Text(
              'Create your first quote to get started',
              style: TextStyle(
                fontSize: 14,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
} 