import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import 'license_status_badge.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  const VehicleCard({Key? key, required this.vehicle, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.all(12.0), // Reduced from 16.0 to 12.0
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with overlay badge
              Stack(
                children: [
                  // Vehicle image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 100, // Reduced from 120 to 100
                      child: vehicle.vehicleImage != null && vehicle.vehicleImage!.isNotEmpty
                          ? Image.network(
                              vehicle.vehicleImage!,
                              width: double.infinity,
                              height: 100, // Reduced from 120 to 100
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
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
                        LicenseStatusBadge(expiryDate: vehicle.licenseExpiryDate),

                        if (_isVehicleInactive(vehicle.status)) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[600]!.withOpacity(0.9),
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
              const SizedBox(height: 8), // Reduced from 10 to 8
              // Vehicle make and model
              Text(
                '${vehicle.make} ${vehicle.model}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15, // Reduced from 16 to 15
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3), // Reduced from 4 to 3
              // Registration plate
              Text(
                vehicle.regPlate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                  fontSize: 12, // Reduced from 13 to 12
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 100, // Reduced from 120 to 100
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.directions_car,
        size: 40, // Reduced from 48 to 40 for better proportion
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

  bool _isVehicleActive(String status) {
    final lowerStatus = status.toLowerCase();
    // Check for active status values
    return lowerStatus == 'active';
  }
} 