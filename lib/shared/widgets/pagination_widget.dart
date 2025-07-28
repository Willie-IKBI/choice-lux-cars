import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Text(
            'Showing ${((currentPage - 1) * itemsPerPage) + 1} to ${(currentPage * itemsPerPage).clamp(0, totalItems)} of $totalItems items',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          
          // Pagination controls
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                color: currentPage > 1 ? ChoiceLuxTheme.richGold : ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
              ),
              
              // Page numbers
              ..._buildPageNumbers(),
              
              // Next button
              IconButton(
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                color: currentPage < totalPages ? ChoiceLuxTheme.richGold : ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
              ),
            ],
          ),
        ],
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
      }
    } else {
      // Show smart pagination with ellipsis
      if (currentPage <= 3) {
        // Show first 3 pages + ellipsis + last page
        for (int i = 1; i <= 3; i++) {
          pageNumbers.add(_buildPageButton(i));
        }
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(_buildPageButton(totalPages));
      } else if (currentPage >= totalPages - 2) {
        // Show first page + ellipsis + last 3 pages
        pageNumbers.add(_buildPageButton(1));
        pageNumbers.add(_buildEllipsis());
        for (int i = totalPages - 2; i <= totalPages; i++) {
          pageNumbers.add(_buildPageButton(i));
        }
      } else {
        // Show first page + ellipsis + current-1, current, current+1 + ellipsis + last page
        pageNumbers.add(_buildPageButton(1));
        pageNumbers.add(_buildEllipsis());
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pageNumbers.add(_buildPageButton(i));
        }
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(_buildPageButton(totalPages));
      }
    }
    
    return pageNumbers;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == currentPage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onPageChanged(page),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentPage ? ChoiceLuxTheme.richGold : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isCurrentPage ? null : Border.all(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
            ),
          ),
          child: Text(
            page.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCurrentPage ? Colors.black : ChoiceLuxTheme.softWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 12,
          color: ChoiceLuxTheme.platinumSilver,
        ),
      ),
    );
  }
} 