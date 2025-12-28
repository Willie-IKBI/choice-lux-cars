import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/services/pdf_viewer_service.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/features/clients/data/clients_repository.dart';
import 'package:choice_lux_cars/features/clients/models/client_branch.dart';

class QuoteCard extends ConsumerWidget {
  final Quote quote;
  final VoidCallback? onTap;

  const QuoteCard({super.key, required this.quote, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallMobile
            ? 4
            : isMobile
            ? 8
            : 12,
        vertical: isSmallMobile
            ? 6
            : isMobile
            ? 8
            : 12,
      ),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 12
                  : isMobile
                  ? 16
                  : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Quote ID and Status
                _buildHeader(isMobile, isSmallMobile),

                SizedBox(
                  height: isSmallMobile
                      ? 12
                      : isMobile
                      ? 16
                      : 20,
                ),

                // Passenger Information
                _buildPassengerInfo(isMobile, isSmallMobile),

                SizedBox(
                  height: isSmallMobile
                      ? 8
                      : isMobile
                      ? 12
                      : 16,
                ),

                // Trip Details
                _buildTripDetails(context, ref, isMobile, isSmallMobile),

                SizedBox(
                  height: isSmallMobile
                      ? 12
                      : isMobile
                      ? 16
                      : 20,
                ),

                // Footer with Amount and Action
                _buildFooter(context, isMobile, isSmallMobile),
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
              fontSize: isSmallMobile
                  ? 14
                  : isMobile
                  ? 16
                  : 18,
              fontWeight: FontWeight.w700,
              color: ChoiceLuxTheme.richGold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile
                ? 6
                : isMobile
                ? 8
                : 10,
            vertical: isSmallMobile
                ? 3
                : isMobile
                ? 4
                : 6,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            quote.statusDisplayName,
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 10
                  : isMobile
                  ? 11
                  : 12,
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
              padding: EdgeInsets.all(
                isSmallMobile
                    ? 4
                    : isMobile
                    ? 6
                    : 8,
              ),
              decoration: BoxDecoration(
                color: quote.hasCompletePassengerDetails
                    ? ChoiceLuxTheme.successColor.withOpacity(0.1)
                    : ChoiceLuxTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                size: isSmallMobile
                    ? 14
                    : isMobile
                    ? 16
                    : 18,
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
                  fontSize: isSmallMobile
                      ? 13
                      : isMobile
                      ? 14
                      : 16,
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
        SizedBox(
          height: isSmallMobile
              ? 6
              : isMobile
              ? 8
              : 10,
        ),
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
        horizontal: isSmallMobile
            ? 6
            : isMobile
            ? 8
            : 10,
        vertical: isSmallMobile
            ? 3
            : isMobile
            ? 4
            : 6,
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
            size: isSmallMobile
                ? 12
                : isMobile
                ? 14
                : 16,
            color: ChoiceLuxTheme.platinumSilver,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 10
                  : isMobile
                  ? 11
                  : 12,
              color: ChoiceLuxTheme.platinumSilver,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(BuildContext context, WidgetRef ref, bool isMobile, bool isSmallMobile) {
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
                    size: isSmallMobile
                        ? 12
                        : isMobile
                        ? 14
                        : 16,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    quote.daysUntilJobDateText,
                    style: TextStyle(
                      fontSize: isSmallMobile
                          ? 11
                          : isMobile
                          ? 12
                          : 13,
                      fontWeight: FontWeight.w500,
                      color: _getDateColor(),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: isSmallMobile
                    ? 4
                    : isMobile
                    ? 6
                    : 8,
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: isSmallMobile
                        ? 12
                        : isMobile
                        ? 14
                        : 16,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    quote.location ?? 'Location not specified',
                    style: TextStyle(
                      fontSize: isSmallMobile
                          ? 11
                          : isMobile
                          ? 12
                          : 13,
                      color: ChoiceLuxTheme.platinumSilver,
                    ),
                  ),
                ],
              ),
              // Branch Name (if exists)
              if (quote.branchId != null)
                FutureBuilder<ClientBranch?>(
                  future: ref.read(clientsRepositoryProvider).fetchBranchById(int.tryParse(quote.branchId!) ?? 0).then((result) => result.data),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    
                    if (snapshot.hasData && snapshot.data != null) {
                      return Padding(
                        padding: EdgeInsets.only(top: isSmallMobile ? 4 : isMobile ? 6 : 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: isSmallMobile
                                  ? 12
                                  : isMobile
                                  ? 14
                                  : 16,
                              color: ChoiceLuxTheme.platinumSilver,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                snapshot.data!.branchName,
                                style: TextStyle(
                                  fontSize: isSmallMobile
                                      ? 11
                                      : isMobile
                                      ? 12
                                      : 13,
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
        if (quote.quoteAmount != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 8
                  : isMobile
                  ? 10
                  : 12,
            ),
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
                    fontSize: isSmallMobile
                        ? 14
                        : isMobile
                        ? 16
                        : 18,
                    fontWeight: FontWeight.w700,
                    color: ChoiceLuxTheme.richGold,
                  ),
                ),
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: isSmallMobile
                        ? 9
                        : isMobile
                        ? 10
                        : 11,
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

  Widget _buildFooter(BuildContext context, bool isMobile, bool isSmallMobile) {
    return Row(
      children: [
        // View Details Button
        Expanded(
          child: Container(
            height: isSmallMobile
                ? 36
                : isMobile
                ? 40
                : 44,
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
                        size: isSmallMobile
                            ? 14
                            : isMobile
                            ? 16
                            : 18,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          fontSize: isSmallMobile
                              ? 11
                              : isMobile
                              ? 12
                              : 13,
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
            height: isSmallMobile
                ? 36
                : isMobile
                ? 40
                : 44,
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
                onTap: () => _openPdf(quote.quotePdf!, context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile
                        ? 12
                        : isMobile
                        ? 14
                        : 16,
                    vertical: isSmallMobile
                        ? 8
                        : isMobile
                        ? 10
                        : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: isSmallMobile
                            ? 14
                            : isMobile
                            ? 16
                            : 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: isSmallMobile
                              ? 11
                              : isMobile
                              ? 12
                              : 13,
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

  void _showSnack(BuildContext context, String msg) {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m != null) m.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openPdf(String url, BuildContext context) async {
    try {
      await PdfViewerService.openPdf(
        context: context,
        pdfUrl: url,
        title: 'Quote #${quote.id}',
        documentType: 'quote',
        documentData: {
          'id': quote.id,
          'title': quote.quoteTitle ?? 'Untitled Quote',
          'recipientEmail': quote.clientId, // You might want to get actual client email
        },
      );
    } catch (e) {
      Log.e('Error opening PDF: $e');
      // Show error message to user
      if (context.mounted) {
        _showSnack(context, 'Error opening PDF: $e');
      }
    }
  }
}
