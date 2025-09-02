import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChanged;
  final Function(int)? onItemsPerPageChanged;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 768;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Expanded(
            child: Text(
              'Showing ${((currentPage - 1) * itemsPerPage) + 1} to ${(currentPage * itemsPerPage).clamp(0, totalItems)} of $totalItems items',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Pagination controls
          Row(
            children: [
              // Previous button
              _buildNavigationButton(
                icon: Icons.chevron_left,
                isEnabled: currentPage > 1,
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                isMobile: isMobile,
              ),
              
              const SizedBox(width: 8),
              
              // Page numbers (hidden on mobile)
              if (!isMobile) ...[
                ..._buildPageNumbers(),
                const SizedBox(width: 8),
              ] else ...[
                // Mobile: show current page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.brandGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tokens.brandGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$currentPage / $totalPages',
                    style: TextStyle(
                      color: tokens.brandGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Next button
              _buildNavigationButton(
                icon: Icons.chevron_right,
                isEnabled: currentPage < totalPages,
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                isMobile: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
              ? ChoiceLuxTheme.richGold 
              : ChoiceLuxTheme.charcoalGray,
          foregroundColor: isEnabled 
              ? Colors.black 
              : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
          elevation: isEnabled ? 1 : 0,
          padding: isMobile
              ? const EdgeInsets.all(8)
              : const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isEnabled 
                ? BorderSide.none
                : BorderSide(
                    color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
                    width: 1,
                  ),
          ),
        ),
        child: Icon(
          icon,
          size: isMobile ? 16 : 20,
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageNumbers = [];
    const int maxVisiblePages = 5;
    
    if (totalPages <= maxVisiblePages) {
      // Show all pages if total is small
      for (int i = 1; i <= totalPages; i++) {
        pageNumbers.add(_buildPageButton(i));
        if (i < totalPages) {
          pageNumbers.add(const SizedBox(width: 4));
        }
      }
    } else {
      // Show smart pagination with ellipsis
      if (currentPage <= 3) {
        // Show first 3 pages + ellipsis + last page
        for (int i = 1; i <= 3; i++) {
          pageNumbers.add(_buildPageButton(i));
          pageNumbers.add(const SizedBox(width: 4));
        }
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 4));
        pageNumbers.add(_buildPageButton(totalPages));
      } else if (currentPage >= totalPages - 2) {
        // Show first page + ellipsis + last 3 pages
        pageNumbers.add(_buildPageButton(1));
        pageNumbers.add(const SizedBox(width: 4));
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 4));
        for (int i = totalPages - 2; i <= totalPages; i++) {
          pageNumbers.add(_buildPageButton(i));
          if (i < totalPages) {
            pageNumbers.add(const SizedBox(width: 4));
          }
        }
      } else {
        // Show first page + ellipsis + current-1, current, current+1 + ellipsis + last page
        pageNumbers.add(_buildPageButton(1));
        pageNumbers.add(const SizedBox(width: 4));
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 4));
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pageNumbers.add(_buildPageButton(i));
          pageNumbers.add(const SizedBox(width: 4));
        }
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 4));
        pageNumbers.add(_buildPageButton(totalPages));
      }
    }
    
    return pageNumbers;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == currentPage;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: isCurrentPage ? [
          BoxShadow(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: () => onPageChanged(page),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentPage 
              ? ChoiceLuxTheme.richGold 
              : ChoiceLuxTheme.charcoalGray,
          foregroundColor: isCurrentPage 
              ? Colors.black 
              : ChoiceLuxTheme.platinumSilver,
          elevation: isCurrentPage ? 1 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isCurrentPage 
                ? BorderSide.none
                : BorderSide(
                    color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                    width: 1,
                  ),
          ),
        ),
        child: Text(
          page.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 12,
          color: ChoiceLuxTheme.platinumSilver,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 