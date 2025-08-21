import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../app/theme.dart';
import '../models/quote.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onTap;

  const QuoteCard({
    super.key,
    required this.quote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 4 : isMobile ? 8 : 12,
        vertical: isSmallMobile ? 6 : isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.go('/quotes/${quote.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallMobile ? 12 : isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Quote ID and Status
                _buildHeader(isMobile, isSmallMobile),
                
                SizedBox(height: isSmallMobile ? 12 : isMobile ? 16 : 20),
                
                // Passenger Information
                _buildPassengerInfo(isMobile, isSmallMobile),
                
                SizedBox(height: isSmallMobile ? 8 : isMobile ? 12 : 16),
                
                // Trip Details
                _buildTripDetails(isMobile, isSmallMobile),
                
                SizedBox(height: isSmallMobile ? 12 : isMobile ? 16 : 20),
                
                // Footer with Amount and Action
                _buildFooter(isMobile, isSmallMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isSmallMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Quote #${quote.id}',
            style: TextStyle(
              fontSize: isSmallMobile ? 14 : isMobile ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: ChoiceLuxTheme.richGold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 6 : isMobile ? 8 : 10,
            vertical: isSmallMobile ? 3 : isMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            quote.statusDisplayName,
            style: TextStyle(
              fontSize: isSmallMobile ? 10 : isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerInfo(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallMobile ? 4 : isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: quote.hasCompletePassengerDetails 
                    ? ChoiceLuxTheme.successColor.withOpacity(0.1)
                    : ChoiceLuxTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                size: isSmallMobile ? 14 : isMobile ? 16 : 18,
                color: quote.hasCompletePassengerDetails 
                    ? ChoiceLuxTheme.successColor 
                    : ChoiceLuxTheme.warningColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                quote.passengerName ?? 'Passenger name not specified',
                style: TextStyle(
                  fontSize: isSmallMobile ? 13 : isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: quote.hasCompletePassengerDetails 
                      ? ChoiceLuxTheme.softWhite 
                      : ChoiceLuxTheme.warningColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallMobile ? 6 : isMobile ? 8 : 10),
        Row(
          children: [
            _buildInfoChip(
              icon: Icons.group,
              label: '${quote.pasCount.toInt()} passengers',
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              icon: Icons.luggage,
              label: quote.luggage.isNotEmpty ? quote.luggage : 'No luggage',
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 6 : isMobile ? 8 : 10,
        vertical: isSmallMobile ? 3 : isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallMobile ? 12 : isMobile ? 14 : 16,
            color: ChoiceLuxTheme.platinumSilver,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallMobile ? 10 : isMobile ? 11 : 12,
              color: ChoiceLuxTheme.platinumSilver,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(bool isMobile, bool isSmallMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isSmallMobile ? 12 : isMobile ? 14 : 16,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    quote.daysUntilJobDateText,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 11 : isMobile ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: _getDateColor(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallMobile ? 4 : isMobile ? 6 : 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: isSmallMobile ? 12 : isMobile ? 14 : 16,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    quote.location ?? 'Location not specified',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 11 : isMobile ? 12 : 13,
                      color: ChoiceLuxTheme.platinumSilver,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (quote.quoteAmount != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 8 : isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R ${quote.quoteAmount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 14 : isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: ChoiceLuxTheme.richGold,
                  ),
                ),
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 9 : isMobile ? 10 : 11,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(bool isMobile, bool isSmallMobile) {
    return Row(
      children: [
        // View Details Button
        Expanded(
          child: Container(
            height: isSmallMobile ? 36 : isMobile ? 40 : 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChoiceLuxTheme.richGold,
                  ChoiceLuxTheme.richGold.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: isSmallMobile ? 14 : isMobile ? 16 : 18,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 11 : isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // PDF View Button (if PDF exists)
        if (quote.quotePdf != null && quote.quotePdf!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            height: isSmallMobile ? 36 : isMobile ? 40 : 44,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.successColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ChoiceLuxTheme.successColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openPdf(quote.quotePdf!),
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: isSmallMobile ? 14 : isMobile ? 16 : 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 11 : isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    switch (quote.quoteStatus.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'open':
        return Colors.blue;
      case 'sent':
        return Colors.orange;
      case 'accepted':
        return ChoiceLuxTheme.successColor;
      case 'rejected':
        return ChoiceLuxTheme.errorColor;
      case 'expired':
        return ChoiceLuxTheme.errorColor;
      case 'closed':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }

  Color _getDateColor() {
    if (quote.daysUntilJobDate < 0) {
      return ChoiceLuxTheme.errorColor;
    } else if (quote.daysUntilJobDate == 0) {
      return ChoiceLuxTheme.warningColor;
    } else if (quote.daysUntilJobDate <= 3) {
      return ChoiceLuxTheme.warningColor;
    } else {
      return ChoiceLuxTheme.platinumSilver;
    }
  }

  Future<void> _openPdf(String url) async {
    try {
      final cacheBustedUrl = '$url?cb=${DateTime.now().millisecondsSinceEpoch}';
      await launchUrlString(cacheBustedUrl);
    } catch (e) {
      // Handle error silently or show a snackbar
      print('Error opening PDF: $e');
    }
  }
}
