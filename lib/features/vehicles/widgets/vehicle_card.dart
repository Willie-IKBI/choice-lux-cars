import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/app/theme.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  const VehicleCard({Key? key, required this.vehicle, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints for mobile optimization
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    // Responsive sizing
    final borderRadius = isMobile ? 12.0 : 16.0;
    final imageHeight = isSmallMobile ? 100.0 : (isMobile ? 120.0 : 220.0);
    final isActive = _isVehicleActive(vehicle.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
        highlightColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.charcoalGray,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image section with ACTIVE badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: imageHeight,
                      child: vehicle.vehicleImage != null &&
                              vehicle.vehicleImage!.isNotEmpty
                          ? Image.network(
                              vehicle.vehicleImage!,
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(imageHeight),
                            )
                          : _buildPlaceholderImage(imageHeight),
                    ),
                  ),
                  // ACTIVE status badge in top-right
                  if (isActive)
                    Positioned(
                      top: isMobile ? 8 : 12,
                      right: isMobile ? 8 : 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 10,
                          vertical: isMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isMobile ? 9 : 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Details section
              Container(
                padding: EdgeInsets.all(isSmallMobile ? 10.0 : (isMobile ? 12.0 : 20.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle name with menu icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${vehicle.make} ${vehicle.model}',
                            style: GoogleFonts.outfit(
                              fontSize: isSmallMobile ? 14.0 : (isMobile ? 16.0 : 20.0),
                              fontWeight: FontWeight.w700,
                              color: ChoiceLuxTheme.softWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                            size: isMobile ? 18 : 20,
                          ),
                          onPressed: onTap,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 8.0 : 12.0),
                    // Registration plate with border
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vehicle.regPlate,
                        style: GoogleFonts.inter(
                          fontSize: isSmallMobile ? 11.0 : (isMobile ? 12.0 : 14.0),
                          fontWeight: FontWeight.w500,
                          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.9),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double imageHeight) {
    return Container(
      width: double.infinity,
      height: imageHeight,
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Icon(
        Icons.directions_car,
        size: 60,
        color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.5),
      ),
    );
  }

  bool _isVehicleActive(String status) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'active';
  }
}
