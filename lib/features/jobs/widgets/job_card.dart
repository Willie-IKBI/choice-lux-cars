import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/shared/widgets/dashboard_card.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final Client? client;
  final Vehicle? vehicle;
  final User? driver;

  const JobCard({
    super.key,
    required this.job,
    this.client,
    this.vehicle,
    this.driver,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigation will be handled by parent
        },
        borderRadius: BorderRadius.circular(16),
                 child: Container(
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(16),
             gradient: const LinearGradient(
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
               colors: [
                 Color(0xFF1E1E1E),
                 Color(0xFF2A2A2A),
               ],
             ),
             border: Border.all(
               color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
               width: 1,
             ),
           ),
                       child: Padding(
              padding: const EdgeInsets.all(12),
              child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
            ),
         ),
      ),
    );
  }

                 Widget _buildDesktopLayout(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ZONE: Header + Metadata
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Passenger Name + Status Badges in one line
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Passenger Name (Left)
                  Expanded(
                    child: Text(
                      job.passengerName ?? 'Unnamed Job',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badges (Right) - Horizontal layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 350) {
                        // Stack vertically on very small screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildStatusBadge(),
                            const SizedBox(height: 4),
                            _buildDriverConfirmationBadge(),
                          ],
                        );
                      } else {
                        // Side by side on larger screens
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusBadge(),
                            const SizedBox(width: 6),
                            _buildDriverConfirmationBadge(),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              
                             const SizedBox(height: 8),
               
               // Metadata Section: All details in compact vertical layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                     _buildDetailChip(
                     Icons.business,
                     client?.companyName ?? 'Unknown Client',
                   ),
                   const SizedBox(height: 3),
                   _buildDetailChip(
                     Icons.person,
                     driver?.displayName ?? 'Unassigned',
                   ),
                   const SizedBox(height: 3),
                   _buildDetailChip(
                     Icons.directions_car,
                     vehicle != null 
                         ? '${vehicle!.make} ${vehicle!.model}'
                         : 'Vehicle not assigned',
                   ),
                   const SizedBox(height: 3),
                  _buildDetailChip(
                    Icons.tag,
                    'Job #${job.id}',
                  ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Info Badges: Time + Pax/Bags in horizontal row
              Row(
                children: [
                  Expanded(child: _buildTimeStatusBadge()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPaxBagsInfo()),
                ],
              ),
            ],
          ),
          
          // EXPANDER ZONE: Push content up, ensure bottom buttons are visible
          const Spacer(),
          
          // BOTTOM ZONE: Warning + Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning indicator if incomplete details
              if (!job.hasCompletePassengerDetails) ...[
                _buildWarningIndicator(),
                const SizedBox(height: 8),
              ],
              
                             // Action Buttons - Always stack vertically to prevent overflow
               Column(
                 children: [
                   if (job.collectPayment && job.paymentAmount != null) ...[
                     _buildPaymentCTA(),
                     const SizedBox(height: 6),
                   ],
                   SizedBox(
                     width: double.infinity,
                     child: _buildViewButton(context),
                   ),
                 ],
               ),
            ],
          ),
        ],
      );
    }

                 Widget _buildMobileLayout(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ZONE: Header + Metadata
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Passenger Name + Status Badges in one line
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      job.passengerName ?? 'Unnamed Job',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badges - Horizontal layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 350) {
                        // Stack vertically on very small screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildStatusBadge(),
                            const SizedBox(height: 4),
                            _buildDriverConfirmationBadge(),
                          ],
                        );
                      } else {
                        // Side by side on larger screens
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusBadge(),
                            const SizedBox(width: 6),
                            _buildDriverConfirmationBadge(),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              
                             const SizedBox(height: 8),
               
               // Metadata Section - Allow wrapping on small screens
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildDetailChip(
                    Icons.business,
                    client?.companyName ?? 'Unknown Client',
                  ),
                  _buildDetailChip(
                    Icons.person,
                    driver?.displayName ?? 'Unassigned',
                  ),
                  _buildDetailChip(
                    Icons.directions_car,
                    vehicle != null 
                        ? '${vehicle!.make} ${vehicle!.model}'
                        : 'Vehicle not assigned',
                  ),
                  _buildDetailChip(
                    Icons.tag,
                    'Job #${job.id}',
                  ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Info Badges Row - Stack vertically on very small screens
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 300) {
                    // Stack vertically on very small screens
                    return Column(
                      children: [
                        _buildTimeStatusBadge(),
                        const SizedBox(height: 4),
                        _buildPaxBagsInfo(),
                      ],
                    );
                  } else {
                    // Side by side on larger mobile screens
                    return Row(
                      children: [
                        Expanded(child: _buildTimeStatusBadge()),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPaxBagsInfo()),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          
          // EXPANDER ZONE: Push content up, ensure bottom buttons are visible
          const Spacer(),
          
          // BOTTOM ZONE: Warning + Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning indicator if incomplete details
              if (!job.hasCompletePassengerDetails) ...[
                _buildWarningIndicator(),
                const SizedBox(height: 8),
              ],
              
              // Action Buttons - Stack vertically on mobile
              if (job.collectPayment && job.paymentAmount != null) ...[
                _buildPaymentCTA(),
                const SizedBox(height: 8),
              ],
              
              SizedBox(
                width: double.infinity,
                child: _buildViewButton(context),
              ),
            ],
          ),
        ],
      );
    }

     Widget _buildDetailChip(IconData icon, String text) {
     return Container(
       constraints: const BoxConstraints(maxWidth: 200),
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
       decoration: BoxDecoration(
         color: Colors.grey.withOpacity(0.08),
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
           color: Colors.grey.withOpacity(0.15),
           width: 1,
         ),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(
             icon,
             size: 10,
             color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
           ),
           const SizedBox(width: 4),
           Flexible(
             child: Text(
               text,
               style: TextStyle(
                 color: ChoiceLuxTheme.platinumSilver.withOpacity(0.9),
                 fontSize: 10,
                 fontWeight: FontWeight.w500,
               ),
               overflow: TextOverflow.ellipsis,
               maxLines: 1,
             ),
           ),
         ],
       ),
     );
   }

     Widget _buildPaxBagsInfo() {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
       decoration: BoxDecoration(
         color: Colors.grey.withOpacity(0.08),
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
           color: Colors.grey.withOpacity(0.15),
           width: 1,
         ),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(
             Icons.people,
             size: 10,
             color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
           ),
           const SizedBox(width: 3),
           Text(
             '${job.pasCount}',
             style: TextStyle(
               color: ChoiceLuxTheme.platinumSilver.withOpacity(0.9),
               fontSize: 9,
               fontWeight: FontWeight.w500,
             ),
           ),
           const SizedBox(width: 6),
           Icon(
             Icons.work,
             size: 10,
             color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
           ),
           const SizedBox(width: 3),
           Text(
             '${job.luggageCount}',
             style: TextStyle(
               color: ChoiceLuxTheme.platinumSilver.withOpacity(0.9),
               fontSize: 9,
               fontWeight: FontWeight.w500,
             ),
           ),
         ],
       ),
     );
   }

     Widget _buildPaymentCTA() {
     return LayoutBuilder(
       builder: (context, constraints) {
         final isNarrow = constraints.maxWidth < 200;
         return Container(
           width: double.infinity,
           padding: EdgeInsets.symmetric(
             horizontal: isNarrow ? 6 : 8,
             vertical: isNarrow ? 4 : 5,
           ),
           decoration: BoxDecoration(
             color: ChoiceLuxTheme.richGold.withOpacity(0.12),
             borderRadius: BorderRadius.circular(6),
             border: Border.all(
               color: ChoiceLuxTheme.richGold.withOpacity(0.25),
               width: 1,
             ),
           ),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(
                 Icons.payment,
                 size: isNarrow ? 10 : 12,
                 color: ChoiceLuxTheme.richGold,
               ),
               SizedBox(width: isNarrow ? 3 : 4),
               Flexible(
                 child: Text(
                   'Collect R${job.paymentAmount!.toStringAsFixed(2)}',
                   style: TextStyle(
                     color: ChoiceLuxTheme.richGold,
                     fontSize: isNarrow ? 10 : 11,
                     fontWeight: FontWeight.bold,
                   ),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
             ],
           ),
         );
       },
     );
   }

     Widget _buildViewButton(BuildContext context) {
     return LayoutBuilder(
       builder: (context, constraints) {
         final isNarrow = constraints.maxWidth < 150;
         return InkWell(
           onTap: () {
             // Navigate to job details/summary screen
             context.go('/jobs/${job.id}/summary');
           },
           borderRadius: BorderRadius.circular(6),
           child: Container(
             padding: EdgeInsets.symmetric(
               horizontal: isNarrow ? 6 : 8,
               vertical: isNarrow ? 4 : 5,
             ),
             decoration: BoxDecoration(
               color: _getStatusColor().withOpacity(0.12),
               borderRadius: BorderRadius.circular(6),
               border: Border.all(
                 color: _getStatusColor().withOpacity(0.25),
                 width: 1,
               ),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(
                   _getActionText(),
                   style: TextStyle(
                     color: _getStatusColor(),
                     fontSize: isNarrow ? 9 : 10,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
                 SizedBox(width: isNarrow ? 1 : 2),
                 Icon(
                   Icons.arrow_forward,
                   size: isNarrow ? 9 : 10,
                   color: _getStatusColor(),
                 ),
               ],
             ),
           ),
         );
       },
     );
   }

     Widget _buildWarningIndicator() {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
       decoration: BoxDecoration(
         color: ChoiceLuxTheme.errorColor.withOpacity(0.12),
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
           color: ChoiceLuxTheme.errorColor.withOpacity(0.25),
           width: 1,
         ),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(
             Icons.warning,
             size: 12,
             color: ChoiceLuxTheme.errorColor,
           ),
           const SizedBox(width: 4),
           Flexible(
             child: Text(
               'Passenger details incomplete',
               style: TextStyle(
                 color: ChoiceLuxTheme.errorColor,
                 fontSize: 10,
                 fontWeight: FontWeight.w600,
               ),
               overflow: TextOverflow.ellipsis,
             ),
           ),
         ],
       ),
     );
   }

     Widget _buildStatusBadge() {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
       decoration: BoxDecoration(
         color: _getStatusColor().withOpacity(0.12),
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
           color: _getStatusColor().withOpacity(0.25),
           width: 1,
         ),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Container(
             width: 5,
             height: 5,
             decoration: BoxDecoration(
               color: _getStatusColor(),
               shape: BoxShape.circle,
             ),
           ),
           const SizedBox(width: 3),
           Flexible(
             child: Text(
               _getStatusText(),
               style: TextStyle(
                 color: _getStatusColor(),
                 fontSize: 9,
                 fontWeight: FontWeight.w600,
               ),
               overflow: TextOverflow.ellipsis,
             ),
           ),
         ],
       ),
     );
   }

     Widget _buildDriverConfirmationBadge() {
     if (job.driverConfirmation == null) {
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
         decoration: BoxDecoration(
           color: Colors.grey.withOpacity(0.12),
           borderRadius: BorderRadius.circular(6),
           border: Border.all(
             color: Colors.grey.withOpacity(0.25),
             width: 1,
           ),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Container(
               width: 5,
               height: 5,
               decoration: BoxDecoration(
                 color: Colors.grey,
                 shape: BoxShape.circle,
               ),
             ),
             const SizedBox(width: 3),
             Text(
               'Pending',
               style: TextStyle(
                 color: Colors.grey,
                 fontSize: 9,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ],
         ),
       );
     }
     
     if (job.driverConfirmation == true) {
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
         decoration: BoxDecoration(
           color: Colors.green.withOpacity(0.12),
           borderRadius: BorderRadius.circular(6),
           border: Border.all(
             color: Colors.green.withOpacity(0.25),
             width: 1,
           ),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Container(
               width: 5,
               height: 5,
               decoration: BoxDecoration(
                 color: Colors.green,
                 shape: BoxShape.circle,
               ),
             ),
             const SizedBox(width: 3),
             Text(
               'Confirmed',
               style: TextStyle(
                 color: Colors.green,
                 fontSize: 9,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ],
         ),
       );
     }
     
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
       decoration: BoxDecoration(
         color: Colors.red.withOpacity(0.12),
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
           color: Colors.red.withOpacity(0.25),
           width: 1,
         ),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Container(
             width: 5,
             height: 5,
             decoration: BoxDecoration(
               color: Colors.red,
               shape: BoxShape.circle,
             ),
           ),
           const SizedBox(width: 3),
           Text(
             'Not Confirmed',
             style: TextStyle(
               color: Colors.red,
               fontSize: 9,
               fontWeight: FontWeight.w600,
             ),
           ),
         ],
       ),
     );
   }

     Widget _buildTimeStatusBadge() {
     final daysUntilStart = job.daysUntilStart;
     final isStarted = daysUntilStart < 0;
     final isToday = daysUntilStart == 0;
     final isSoon = daysUntilStart <= 3 && daysUntilStart > 0;
     
     String text;
     Color color;
     
     if (isStarted) {
       text = 'Started ${daysUntilStart.abs()}d ago';
       color = ChoiceLuxTheme.platinumSilver;
     } else if (isToday) {
       text = 'Today';
       color = Colors.orange;
     } else if (isSoon) {
       text = 'In ${daysUntilStart}d';
       color = Colors.red;
     } else {
       text = 'In ${daysUntilStart}d';
       color = Colors.green;
     }
     
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
       decoration: BoxDecoration(
         color: color.withOpacity(0.12),
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
           color: color.withOpacity(0.25),
           width: 1,
         ),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Container(
             width: 5,
             height: 5,
             decoration: BoxDecoration(
               color: color,
               shape: BoxShape.circle,
             ),
           ),
           const SizedBox(width: 3),
           Flexible(
             child: Text(
               text,
               style: TextStyle(
                 color: color,
                 fontSize: 9,
                 fontWeight: FontWeight.w500,
               ),
               overflow: TextOverflow.ellipsis,
             ),
           ),
         ],
       ),
     );
   }

  Color _getStatusColor() {
    switch (job.status) {
      case 'open':
        return ChoiceLuxTheme.richGold;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
      case 'completed':
        return ChoiceLuxTheme.successColor;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  IconData _getStatusIcon() {
    switch (job.status) {
      case 'open':
        return Icons.folder_open;
      case 'in_progress':
        return Icons.sync;
      case 'closed':
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (job.status) {
      case 'open':
        return 'OPEN';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'closed':
        return 'CLOSED';
      case 'completed':
        return 'COMPLETED';
      default:
        return job.status.toUpperCase();
    }
  }

  String _getActionText() {
    switch (job.status) {
      case 'open':
        return 'VIEW';
      case 'in_progress':
        return 'TRACK';
      case 'closed':
      case 'completed':
        return 'DETAILS';
      default:
        return 'VIEW';
    }
  }
}