import 'package:flutter/material.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/vehicles/widgets/license_status_badge.dart';
import 'package:choice_lux_cars/app/theme.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  const VehicleCard({super.key, required this.vehicle, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints for mobile optimization
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    // Responsive sizing
    final cardPadding = isSmallMobile
        ? 8.0
        : isMobile
        ? 10.0
        : 12.0;
    final imageHeight = isSmallMobile
        ? 80.0
        : isMobile
        ? 90.0
        : 100.0;
    final titleSize = isSmallMobile
        ? 13.0
        : isMobile
        ? 14.0
        : 15.0;
    final subtitleSize = isSmallMobile
        ? 10.0
        : isMobile
        ? 11.0
        : 12.0;
    final iconSize = isSmallMobile
        ? 32.0
        : isMobile
        ? 36.0
        : 40.0;
    final borderRadius = isMobile ? 12.0 : 16.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
        highlightColor: ChoiceLuxTheme.richGold.withValues(alpha:0.05),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: isMobile ? 4 : 8,
          shadowColor: Colors.black.withValues(alpha:0.2),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            constraints: BoxConstraints(
              minHeight: isSmallMobile ? 140 : isMobile ? 150 : 160, // Ensure minimum height
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space needed
              children: [
                // Image section with overlay badge
                Stack(
                  children: [
                    // Vehicle image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius - 4),
                      child: Container(
                        width: double.infinity,
                        height: imageHeight,
                        constraints: BoxConstraints(
                          maxHeight: imageHeight, // Ensure image doesn't exceed allocated height
                        ),
                        child:
                            vehicle.vehicleImage != null &&
                                vehicle.vehicleImage!.isNotEmpty
                            ? Image.network(
                                vehicle.vehicleImage!,
                                width: double.infinity,
                                height: imageHeight,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(
                                      imageHeight,
                                      iconSize,
                                    ),
                              )
                            : _buildPlaceholderImage(imageHeight, iconSize),
                      ),
                    ),
                    // Status overlay badges
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // License expiry badge
                          LicenseStatusBadge(
                            expiryDate: vehicle.licenseExpiryDate,
                          ),

                          if (_isVehicleInactive(vehicle.status)) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[600]!.withValues(alpha:0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Deactivated',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: isSmallMobile
                      ? 6
                      : isMobile
                      ? 7
                      : 8,
                ),
                // Vehicle make and model
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: titleSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: isSmallMobile
                      ? 2
                      : isMobile
                      ? 2.5
                      : 3,
                ),
                // Registration plate
                Text(
                  vehicle.regPlate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double imageHeight, double iconSize) {
    return Container(
      width: double.infinity,
      height: imageHeight,
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.directions_car,
        size: iconSize,
        color: Colors.grey[500],
      ),
    );
  }

  bool _isVehicleInactive(String status) {
    final lowerStatus = status.toLowerCase();
    // Check for deactivated status values
    return lowerStatus == 'deactivated' ||
        lowerStatus == 'deactive' ||
        lowerStatus == 'inactive';
  }
}
