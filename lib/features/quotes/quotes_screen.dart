import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'providers/quotes_provider.dart';
import 'widgets/quote_card.dart';
import 'models/quote.dart';

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final quotes = ref.watch(quotesProvider);
    final canCreateQuotes = ref.read(quotesProvider.notifier).canCreateQuotes;

    // Filter quotes based on selected status
    List<Quote> filteredQuotes = (quotes.value ?? []);
    if (_selectedStatus != 'all') {
      switch (_selectedStatus) {
        case 'draft':
          filteredQuotes = (quotes.value ?? [])
              .where((quote) => quote.quoteStatus.toLowerCase() == 'draft')
              .toList();
          break;
        case 'open':
          filteredQuotes = (quotes.value ?? [])
              .where((quote) => quote.quoteStatus.toLowerCase() == 'open')
              .toList();
          break;
        case 'accepted':
          filteredQuotes = (quotes.value ?? [])
              .where((quote) => quote.isAccepted)
              .toList();
          break;
        case 'expired':
          filteredQuotes = (quotes.value ?? [])
              .where((quote) => quote.isExpired)
              .toList();
          break;
        case 'closed':
          filteredQuotes = (quotes.value ?? [])
              .where((quote) => quote.quoteStatus.toLowerCase() == 'closed')
              .toList();
          break;
        case 'rejected':
          filteredQuotes = (quotes.value ?? [])
              .where((quote) => quote.quoteStatus.toLowerCase() == 'rejected')
              .toList();
          break;
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredQuotes = filteredQuotes.where((quote) {
        final passengerName = quote.passengerName?.toLowerCase() ?? '';
        final quoteId = quote.id?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return passengerName.contains(query) || quoteId.contains(query);
      }).toList();
    }

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: 'Quotes',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(color: ChoiceLuxTheme.jetBlack),
              ),
              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header Section with Stats
                    _buildHeaderSection(
                      filteredQuotes.length,
                      (quotes.value ?? []).length,
                    ),

                    // Search and Filter Section
                    _buildSearchAndFilterSection(isMobile),

                    // Quotes List/Grid
                    Expanded(
                      child: filteredQuotes.isEmpty
                          ? _buildEmptyState()
                          : _buildQuotesList(
                              filteredQuotes,
                              isMobile,
                              isSmallMobile,
                              isDesktop,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canCreateQuotes ? _buildMobileOptimizedFAB() : null,
    );
  }

  Widget _buildHeaderSection(int filteredCount, int totalCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);

    // Responsive padding system: 12px mobile, 16px tablet, 24px desktop
    final horizontalPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 12.0
        : isTablet
        ? 16.0
        : 24.0;
    final verticalPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 16.0
        : isTablet
        ? 20.0
        : 24.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filteredCount == totalCount
                ? '$totalCount total quotes'
                : '$filteredCount of $totalCount quotes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 2,
            width: isSmallMobile
                ? 40
                : isMobile
                ? 60
                : 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChoiceLuxTheme.richGold,
                  ChoiceLuxTheme.richGold.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);

    // Responsive padding system: 12px mobile, 16px tablet, 24px desktop
    final horizontalPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 12.0
        : isTablet
        ? 16.0
        : 24.0;
    final verticalPadding = isSmallMobile
        ? 8.0
        : isMobile
        ? 12.0
        : isTablet
        ? 16.0
        : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        children: [
          // Search Bar - Mobile optimized
          Container(
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: isMobile
                    ? 'Search quotes...'
                    : 'Search quotes by passenger name or quote ID...',
                hintStyle: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                  fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 15),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                  size: ResponsiveTokens.getIconSize(screenWidth),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                          size: ResponsiveTokens.getIconSize(screenWidth),
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                        tooltip: 'Clear search',
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isMobile ? 14 : 16,
                ),
              ),
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                  fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Filter - Mobile uses bottom sheet, Desktop uses horizontal chips
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              if (isMobile) {
                return _buildMobileFilterButton();
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('all', 'All', Colors.grey),
                      SizedBox(width: spacing),
                      _buildStatusChip('draft', 'Draft', Colors.orange),
                      SizedBox(width: spacing),
                      _buildStatusChip('open', 'Open', Colors.blue),
                      SizedBox(width: spacing),
                      _buildStatusChip(
                        'accepted',
                        'Accepted',
                        ChoiceLuxTheme.successColor,
                      ),
                      SizedBox(width: spacing),
                      _buildStatusChip(
                        'expired',
                        'Expired',
                        ChoiceLuxTheme.errorColor,
                      ),
                      SizedBox(width: spacing),
                      _buildStatusChip('closed', 'Closed', Colors.grey),
                      SizedBox(width: spacing),
                      _buildStatusChip('rejected', 'Rejected', Colors.red),
                    ],
                  ),
                );
              }
            },
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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




  Widget _buildQuotesList(
    List<Quote> quotes,
    bool isMobile,
    bool isSmallMobile,
    bool isDesktop,
  ) {
    // Responsive padding system: 12px mobile, 16px tablet, 24px desktop
    final horizontalPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 12.0
        : 16.0;
    final gridPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 16.0
        : 24.0;

    // List view for all screen sizes
      return RefreshIndicator(
        onRefresh: () => ref.read(quotesProvider.notifier).fetchQuotes(),
        color: ChoiceLuxTheme.richGold,
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return QuoteCard(
              quote: quote,
              onTap: () => context.go('/quotes/${quote.id ?? ''}'),
              context: context,
            );
          },
        ),
      );
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
            child: Icon(icon, size: 48, color: iconColor),
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

  Widget _buildMobileFilterButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showMobileFilterBottomSheet(),
        icon: Icon(Icons.filter_list, color: ChoiceLuxTheme.richGold, size: 20),
        label: Text(
          'Filter: ${_getStatusLabel(_selectedStatus)}',
          style: TextStyle(
            color: ChoiceLuxTheme.richGold,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
          foregroundColor: ChoiceLuxTheme.richGold,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(0, 48), // Ensure minimum 44px touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: ChoiceLuxTheme.richGold.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: ChoiceLuxTheme.richGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Quotes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ChoiceLuxTheme.softWhite,
                    ),
                  ),
                ],
              ),
            ),

            // Filter options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMobileFilterOption('all', 'All Quotes', Colors.grey),
                  _buildMobileFilterOption(
                    'draft',
                    'Draft Quotes',
                    Colors.orange,
                  ),
                  _buildMobileFilterOption('open', 'Open Quotes', Colors.blue),
                  _buildMobileFilterOption(
                    'accepted',
                    'Accepted Quotes',
                    ChoiceLuxTheme.successColor,
                  ),
                  _buildMobileFilterOption(
                    'expired',
                    'Expired Quotes',
                    ChoiceLuxTheme.errorColor,
                  ),
                  _buildMobileFilterOption(
                    'closed',
                    'Closed Quotes',
                    Colors.grey,
                  ),
                  _buildMobileFilterOption(
                    'rejected',
                    'Rejected Quotes',
                    Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilterOption(String status, String label, Color color) {
    final isSelected = _selectedStatus == status;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedStatus = status);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            constraints: const BoxConstraints(
              minHeight: 48,
            ), // Ensure minimum 44px touch target
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color
                    : ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : ChoiceLuxTheme.softWhite,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'draft':
        return 'Draft';
      case 'open':
        return 'Open';
      case 'accepted':
        return 'Accepted';
      case 'expired':
        return 'Expired';
      case 'closed':
        return 'Closed';
      case 'rejected':
        return 'Rejected';
      default:
        return 'All';
    }
  }

  Widget _buildMobileOptimizedFAB() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);

    if (isMobile) {
      // Mobile: Compact FAB with icon only
      return FloatingActionButton(
        onPressed: () => context.go('/quotes/create'),
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.black,
        elevation: 6,
        child: const Icon(Icons.add, size: 24),
        tooltip: 'Create Quote',
      );
    } else {
      // Desktop: Extended FAB with label
      return FloatingActionButton.extended(
        onPressed: () => context.go('/quotes/create'),
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Create Quote'),
        elevation: 6,
      );
    }
  }
}
