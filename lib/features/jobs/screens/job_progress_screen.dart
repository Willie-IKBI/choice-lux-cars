import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';

import 'package:choice_lux_cars/features/jobs/widgets/gps_capture_widget.dart';
import 'package:choice_lux_cars/features/jobs/widgets/odometer_capture_widget.dart';
import 'package:choice_lux_cars/features/jobs/widgets/vehicle_collection_modal.dart';
import 'package:choice_lux_cars/features/jobs/widgets/vehicle_return_modal.dart';
import 'package:choice_lux_cars/features/jobs/widgets/passenger_no_show_modal.dart';
import 'package:choice_lux_cars/features/jobs/widgets/address_display_widget.dart';
import 'package:choice_lux_cars/features/jobs/widgets/add_expense_modal.dart';
import 'package:choice_lux_cars/features/jobs/models/expense.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'dart:typed_data';
import 'package:choice_lux_cars/features/jobs/models/job_step.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/shared/utils/status_color_utils.dart';
import 'package:choice_lux_cars/shared/utils/date_utils.dart';
import 'package:choice_lux_cars/shared/utils/driver_flow_utils.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_button.dart';
import 'package:choice_lux_cars/shared/widgets/job_completion_dialog.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';

class JobProgressScreen extends ConsumerStatefulWidget {
  final String jobId;
  final Job job;

  const JobProgressScreen({Key? key, required this.jobId, required this.job})
    : super(key: key);

  @override
  ConsumerState<JobProgressScreen> createState() => _JobProgressScreenState();
}

class _JobProgressScreenState extends ConsumerState<JobProgressScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;
  Map<String, dynamic>? _jobProgress;
  List<Map<String, dynamic>>? _tripProgress;
  String _currentStep = 'not_started';
  int _currentTripIndex = 1;
  int _progressPercentage = 0;
  Map<String, String?> _jobAddresses = {};

  // Store references to avoid ancestor lookup issues
  JobsNotifier? _jobsNotifier;

  /// Responsive design helpers
  bool get _isMobile {
    final screenWidth = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.isMobile(screenWidth) || ResponsiveBreakpoints.isSmallMobile(screenWidth);
  }
  bool get _isTablet {
    final screenWidth = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.isTablet(screenWidth);
  }
  bool get _isDesktop {
    final screenWidth = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.isDesktop(screenWidth) || ResponsiveBreakpoints.isLargeDesktop(screenWidth);
  }

  /// Contact helper methods
  Future<void> _callPassenger() async {
    try {
      final contact = widget.job.passengerContact;
      if (contact == null || contact.isEmpty) {
        SnackBarUtils.showError(context, 'No contact number available');
        return;
      }
      
      final url = 'tel:$contact';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        SnackBarUtils.showError(context, 'Could not open phone app');
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to make call: $e');
    }
  }

  /// Safe type conversion helpers
  int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return defaultValue;
      final parsed = int.tryParse(trimmed);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  bool _safeToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed.isEmpty) return false;
      
      // Truthy strings
      if (['true', 'yes', 'y', 'completed', 'done', 'closed', 'finished', '1'].contains(trimmed)) {
        return true;
      }
      
      // Falsy strings
      if (['false', 'no', 'n', 'pending', 'open', '0'].contains(trimmed)) {
        return false;
      }
      
      // Check if it's a timestamp-like string (ISO/SQL date format)
      if (trimmed.contains('-') && (trimmed.contains('T') || trimmed.contains(' '))) {
        try {
          final date = DateTime.parse(trimmed);
          return date.isAfter(DateTime(1900)); // Valid date
        } catch (_) {
          // Not a valid date string
        }
      }
      
      // Default to false for arbitrary strings
      return false;
    }
    if (value is DateTime) return value.isAfter(DateTime(1900));
    return false;
  }

  final List<JobStep> _jobSteps = [
    JobStep(
      id: 'not_started',
      title: 'Job Not Started',
      description: 'Job is assigned but not yet started by driver',
      icon: Icons.schedule,
      isCompleted: false,
    ),
    JobStep(
      id: 'vehicle_collection',
      title: 'Vehicle Collection',
      description: 'Collect vehicle and record odometer',
      icon: Icons.directions_car,
      isCompleted: false,
    ),
    JobStep(
      id: 'pickup_arrival',
      title: 'Arrive at Pickup',
      description: 'Arrive at passenger pickup location',
      icon: Icons.location_on,
      isCompleted: false,
    ),
    JobStep(
      id: 'passenger_pickup', // ADDED: Database step ID
      title: 'Pickup Arrival',
      description: 'Arrived at passenger pickup location',
      icon: Icons.location_on,
      isCompleted: false,
    ),
    JobStep(
      id: 'passenger_onboard',
      title: 'Passenger Onboard',
      description: 'Passenger has boarded the vehicle',
      icon: Icons.person_add,
      isCompleted: false,
    ),
    JobStep(
      id: 'dropoff_arrival',
      title: 'Arrive at Dropoff',
      description: 'Arrive at passenger dropoff location',
      icon: Icons.location_on,
      isCompleted: false,
    ),
    JobStep(
      id: 'trip_complete',
      title: 'Trip Complete',
      description: 'Trip has been completed',
      icon: Icons.check_circle,
      isCompleted: false,
    ),
    JobStep(
      id: 'vehicle_return',
      title: 'Vehicle Return',
      description: 'Return vehicle and record final odometer',
      icon: Icons.home,
      isCompleted: false,
    ),
    JobStep(
      id: 'completed',
      title: 'Job Complete',
      description: 'Job has been completed successfully',
      icon: Icons.done_all,
      isCompleted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadJobProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if all steps are completed and update job status if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndUpdateJobStatus();
    });
    // Store reference to avoid ancestor lookup issues
    _jobsNotifier = ref.read(jobsProvider.notifier);
  }

  Future<void> _loadJobProgress({bool skipLoadingState = false}) async {
    try {
      Log.d('=== _loadJobProgress STARTED ===');
      Log.d('Job ID: ${widget.jobId}');
      Log.d('Skip loading state: $skipLoadingState');
      
      if (!mounted) {
        Log.d('Widget not mounted, returning early');
        return;
      }
      
      // Only set _isLoading if not skipping (i.e., not during a step update)
      // When skipLoadingState is true, _isUpdating overlay is shown instead
      if (!skipLoadingState) {
        setState(() => _isLoading = true);
      }

      // Parse job ID once and validate
      final jobIdInt = int.tryParse(widget.jobId);
      if (jobIdInt == null) {
        throw Exception('Invalid job ID: ${widget.jobId}');
      }

      // Load job progress
      var progress = await DriverFlowApiService.getJobProgress(jobIdInt);
      Log.d('=== LOADED JOB PROGRESS ===');
      Log.d('Progress data: $progress');
      
      // If progress is null, check if job has actually started (race condition fix)
      // Sometimes driver_flow record might not be immediately available after startJob()
      if (progress == null) {
        Log.d('No job progress found for jobId: $jobIdInt');
        
        // Check if job has actually started by checking job status
        try {
          final supabase = Supabase.instance.client;
          final jobResponse = await supabase
              .from('jobs')
              .select('job_status, vehicle_collected')
              .eq('id', jobIdInt)
              .maybeSingle();
          
          if (jobResponse != null) {
            final jobStatus = jobResponse['job_status']?.toString();
            final vehicleCollected = jobResponse['vehicle_collected'] == true;
            
            // If job appears to have started (status is started/in_progress or vehicle_collected),
            // wait a bit and retry loading progress (handles race condition)
            if ((jobStatus == 'started' || jobStatus == 'in_progress' || vehicleCollected)) {
              Log.d('Job appears to have started but driver_flow not found yet, waiting 300ms and retrying...');
              await Future.delayed(const Duration(milliseconds: 300));
              
              // Retry loading progress once
              final retryProgress = await DriverFlowApiService.getJobProgress(jobIdInt);
              if (retryProgress != null) {
                progress = retryProgress;
                Log.d('Successfully loaded job progress on retry');
              }
            }
          }
        } catch (e) {
          Log.e('Error checking job status when progress is null: $e');
        }
      }
      
      if (progress == null) {
        // Still no progress after retry - set safe defaults
        Log.d('No job progress found after retry, setting defaults');
        
        // Load trip progress and addresses even when no job progress exists
        final trips = await DriverFlowApiService.getTripProgress(jobIdInt);
        final addresses = await DriverFlowApiService.getJobAddresses(jobIdInt);
        
        setState(() {
          _jobProgress = null;
          _tripProgress = trips;
          _jobAddresses = addresses;
          _currentTripIndex = 1;
          _progressPercentage = 0;
          // Only set _isLoading to false if we set it to true
          if (!skipLoadingState) {
            _isLoading = false;
          }
        });
        
        return;
      }
      
      // Use local non-null variable for subsequent access
      final p = progress;
      Log.d('Vehicle collected: ${p['vehicle_collected']}');
      Log.d('Current step from DB: ${p['current_step']}');
      Log.d('Job status: ${p['job_status']}');

      // Load trip progress
      final trips = await DriverFlowApiService.getTripProgress(jobIdInt);
      Log.d('=== LOADED TRIP PROGRESS ===');
      Log.d('Trip data: $trips');

      // Load job addresses
      final addresses = await DriverFlowApiService.getJobAddresses(jobIdInt);
      Log.d('=== LOADED JOB ADDRESSES ===');
      Log.d('Addresses: $addresses');

      setState(() {
        _jobProgress = progress;
        _tripProgress = trips;
        _jobAddresses = addresses;
        _currentTripIndex = 1; // Single transport record per job
        _progressPercentage = p['progress_percentage'] ?? 0;
      });

      // Update step statuses
      _updateStepStatus();

      // Determine current step
      _determineCurrentStep();
      
      // Debug logging after step determination
      Log.d('=== AFTER STEP DETERMINATION ===');
      Log.d('Current step: $_currentStep');
      Log.d('Step completion status:');
      for (final step in _jobSteps) {
        Log.d('  ${step.id}: ${step.isCompleted}');
      }

      // Check if all steps are completed and update job status if needed
      if (_jobSteps.every((s) => s.isCompleted) &&
          _jobProgress != null &&
          _jobProgress!['job_status'] != 'completed') {
        Log.d('=== AUTO-UPDATING JOB STATUS TO COMPLETED ===');
        try {
          await DriverFlowApiService.updateJobStatusToCompleted(
            int.parse(widget.jobId),
          );
          // Refresh jobs list to update job card
          ref.invalidate(jobsProvider);
        } catch (e) {
          Log.e('Error auto-updating job status: $e');
        }
      }

      if (mounted) {
        Log.d('=== SETTING _isLoading = false ===');
        setState(() {
          // Only set _isLoading to false if we set it to true
          if (!skipLoadingState) {
            _isLoading = false;
          }
        });
        Log.d('=== _loadJobProgress COMPLETED ===');
      }

      // Final UI update already triggered above; avoid extra delayed rebuilds
      if (mounted) {
        _debugCurrentState();
      }
    } catch (e) {
      Log.e('ERROR in _loadJobProgress: $e');
      if (mounted) {
        setState(() {
          // Only set _isLoading to false if we set it to true
          if (!skipLoadingState) {
            _isLoading = false;
          }
        });
        SnackBarUtils.showError(context, 'Failed to load job progress: $e');
      }
    }
  }

  /// Show the start job modal when no driver_flow record exists
  void _showStartJobModal() {
    showDialog(
      context: context,
      builder: (context) => VehicleCollectionModal(
        onConfirm: ({
          required double odometerReading,
          required String odometerImageUrl,
          required double gpsLat,
          required double gpsLng,
          required double gpsAccuracy,
          String? vehicleCollectedAtTimestamp,
        }) async {
          try {
            // Start the job using the vehicle collection data
            await DriverFlowApiService.startJob(
              int.parse(widget.jobId),
              odoStartReading: odometerReading,
              pdpStartImage: odometerImageUrl,
              gpsLat: gpsLat,
              gpsLng: gpsLng,
              gpsAccuracy: gpsAccuracy,
              vehicleCollectedAtTimestamp: vehicleCollectedAtTimestamp, // Pass captured timestamp
            );

            // Refresh job progress and await it to ensure UI updates correctly
            await _loadJobProgress(skipLoadingState: true);
            
            if (mounted) {
              SnackBarUtils.showSuccess(context, 'Job started successfully!');
            }
          } catch (e) {
            if (mounted) {
              SnackBarUtils.showError(context, 'Failed to start job: $e');
            }
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _updateStepStatus() {
    if (_jobProgress == null) {
      Log.d('_updateStepStatus: _jobProgress is null, setting not_started as active');
      // When progress is null, mark not_started as active and all others as not completed
      bool hasChanges = false;
      for (int i = 0; i < _jobSteps.length; i++) {
        final step = _jobSteps[i];
        final isNotStarted = step.id == 'not_started';
        if (step.isCompleted != false || step.isActive != isNotStarted) {
          hasChanges = true;
          _jobSteps[i] = step.copyWith(
            isCompleted: false,
            isActive: isNotStarted,
          );
        }
      }
      if (hasChanges && mounted) {
        setState(() {
          // Trigger rebuild
        });
      }
      return;
    }

    Log.d('=== UPDATING STEP STATUS ===');
    bool hasChanges = false;

    // Update step completion status based on job progress
    for (int i = 0; i < _jobSteps.length; i++) {
      final step = _jobSteps[i];
      bool isCompleted = false;

      switch (step.id) {
        case 'not_started':
          // Not started step is completed when job actually starts
          isCompleted = _jobProgress!['vehicle_collected'] == true;
          break;
        case 'vehicle_collection':
          // Vehicle collection is completed only if vehicle_collected is true
          // Once completed, it cannot be undone
          isCompleted = _jobProgress!['vehicle_collected'] == true;
          Log.d('Vehicle collection step - completed: $isCompleted, vehicle_collected: ${_jobProgress!['vehicle_collected']}');
          break;
        case 'pickup_arrival':
          // Pickup arrival is completed only when we've moved beyond this step
          // NOT when it's the current step - that's when the action button should show
          isCompleted = _jobProgress!['current_step'] == 'passenger_pickup' ||
                       _jobProgress!['current_step'] == 'passenger_onboard' ||
                       _jobProgress!['current_step'] == 'dropoff_arrival' ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'passenger_pickup':
          // Passenger pickup is completed only when we've moved beyond this step
          // NOT when it's the current step - that's when the action button should show
          isCompleted = _jobProgress!['current_step'] == 'passenger_onboard' ||
                       _jobProgress!['current_step'] == 'dropoff_arrival' ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'passenger_onboard':
          // Passenger onboard is completed only when we've moved beyond this step
          // OR when passenger is marked as no-show
          // NOT when it's the current step - that's when the action button should show
          final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
          isCompleted = isNoShow ||
                       _jobProgress!['current_step'] == 'dropoff_arrival' ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'dropoff_arrival':
          // Dropoff arrival is completed only when we've moved beyond this step
          // OR when passenger is marked as no-show (skip this step)
          // NOT when it's the current step - that's when the action button should show
          final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
          isCompleted = isNoShow ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'trip_complete':
          // Trip complete is completed only when we've moved beyond this step
          // OR when passenger is marked as no-show (trip automatically completed)
          // NOT when it's the current step - that's when the action button should show
          final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
          final transportCompleted = _jobProgress!['transport_completed_ind'] == true;
          isCompleted = (isNoShow && transportCompleted) ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'vehicle_return':
          // Vehicle return is completed if job_closed_odo is set (vehicle returned)
          // This is different from job_closed_time which is also set when vehicle is returned
          // We use job_closed_odo to check if vehicle is returned, then show Add Expenses/Close Job buttons
          isCompleted = _jobProgress!['job_closed_odo'] != null || _jobProgress!['job_closed_time'] != null;
          break;
        case 'completed':
          // Job completion step is completed when job_status is 'completed'
          isCompleted = _jobProgress!['job_status'] == 'completed';
          break;
      }

      // Check if step status has changed
      if (_jobSteps[i].isCompleted != isCompleted || _jobSteps[i].isActive != (step.id == _currentStep)) {
        hasChanges = true;
        Log.d('Step ${step.id} status changed - completed: $isCompleted, active: ${step.id == _currentStep}');
      }

      // Update the step completion status
      _jobSteps[i] = step.copyWith(
        isCompleted: isCompleted,
        isActive: step.id == _currentStep,
      );

      // Debug logging for step completion
      Log.d('Step ${step.id}: isCompleted = $isCompleted, isActive = ${step.id == _currentStep}');
    }

    // Only trigger rebuild if there were actual changes
    if (hasChanges) {
      Log.d('Step status changes detected, triggering rebuild');
      if (mounted) {
        setState(() {
          // Trigger rebuild
        });
      }
    } else {
      Log.d('No step status changes, skipping rebuild');
    }

    // Update step titles with addresses
    _updateStepTitlesWithAddresses();
  }

  void _updateStepTitlesWithAddresses() {
    for (int i = 0; i < _jobSteps.length; i++) {
      final step = _jobSteps[i];
      String newTitle = step.title;

      switch (step.id) {
        case 'not_started':
          // Update title to "Job Started" when vehicle is collected
          if (_jobProgress != null && _jobProgress!['vehicle_collected'] == true) {
            newTitle = 'Job Started';
          } else {
            newTitle = 'Job Not Started';
          }
          break;
        case 'pickup_arrival':
          final pickupAddress = _jobAddresses['pickup'];
          if (pickupAddress != null && pickupAddress.isNotEmpty) {
            newTitle = 'Arrive at Pickup';
          }
          break;
        case 'passenger_pickup':
          final pickupAddress = _jobAddresses['pickup'];
          if (pickupAddress != null && pickupAddress.isNotEmpty) {
            newTitle = 'Pickup Arrival';
          }
          break;
        case 'dropoff_arrival':
          final dropoffAddress = _jobAddresses['dropoff'];
          if (dropoffAddress != null && dropoffAddress.isNotEmpty) {
            newTitle = 'Arrive at Dropoff';
          }
          break;
      }

      if (newTitle != step.title) {
        _jobSteps[i] = step.copyWith(title: newTitle);
      }
    }
  }

  /// Build enhanced step card with navigation and contact functionality
  Widget _buildEnhancedStepCard(JobStep step) {
    final isCurrent = step.id == _currentStep;
    final isCompleted = step.isCompleted;
    
    // Check if passenger was marked as no-show
    final isNoShow = _jobProgress != null && 
        (_jobProgress!['passenger_no_show_ind'] == true);
    
    // Get address for location-based steps
    String? stepAddress;
    if (step.id == 'pickup_arrival' || step.id == 'passenger_pickup') {
      stepAddress = _jobAddresses['pickup'];
    } else if (step.id == 'dropoff_arrival') {
      stepAddress = _jobAddresses['dropoff'];
    }

    // Responsive sizing
    final cardPadding = _isMobile ? 16.0 : 20.0;
    final iconSize = _isMobile ? 40.0 : 48.0;
    final titleFontSize = _isMobile ? 16.0 : 18.0;
    final descriptionFontSize = _isMobile ? 12.0 : 14.0;

    return Container(
      margin: EdgeInsets.only(bottom: _isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        gradient: isCurrent 
            ? LinearGradient(
                colors: [
                  ChoiceLuxTheme.richGold.withOpacity(0.1),
                  ChoiceLuxTheme.richGold.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
        border: Border.all(
          color: isCurrent 
              ? ChoiceLuxTheme.richGold.withOpacity(0.5)
              : ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: ChoiceLuxTheme.richGold.withOpacity(0.2),
            blurRadius: _isMobile ? 6 : 8,
            offset: Offset(0, _isMobile ? 2 : 4),
          ),
        ] : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step header with status
            Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? ChoiceLuxTheme.successColor
                        : isCurrent 
                            ? ChoiceLuxTheme.richGold
                            : ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted 
                        ? Icons.check
                        : isCurrent 
                            ? Icons.play_arrow
                            : Icons.circle_outlined,
                    color: isCompleted || isCurrent 
                        ? Colors.white
                        : ChoiceLuxTheme.platinumSilver,
                    size: _isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: _isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (step.description.isNotEmpty)
                        Text(
                          step.description,
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: descriptionFontSize,
                          ),
                        ),
                    ],
                  ),
                ),
                // Show badge for no-show status
                if (isNoShow && (step.id == 'passenger_onboard' || step.id == 'dropoff_arrival'))
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(
                      horizontal: _isMobile ? 8 : 12, 
                      vertical: _isMobile ? 4 : 6
                    ),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.errorColor,
                      borderRadius: BorderRadius.circular(_isMobile ? 16 : 20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          color: Colors.white,
                          size: _isMobile ? 12 : 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NO-SHOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isMobile ? 9 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCurrent && (!isNoShow || step.id != 'passenger_onboard'))
                  Container(
                    margin: EdgeInsets.only(left: (isNoShow && step.id == 'dropoff_arrival') ? 8 : 0),
                    padding: EdgeInsets.symmetric(
                      horizontal: _isMobile ? 8 : 12, 
                      vertical: _isMobile ? 4 : 6
                    ),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.richGold,
                      borderRadius: BorderRadius.circular(_isMobile ? 16 : 20),
                    ),
                    child: Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: _isMobile ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Address display with navigation
            if (stepAddress != null && stepAddress.isNotEmpty) ...[
              SizedBox(height: _isMobile ? 12 : 16),
              Container(
                padding: EdgeInsets.all(_isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(_isMobile ? 8 : 12),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: ChoiceLuxTheme.richGold,
                          size: _isMobile ? 18 : 20,
                        ),
                        SizedBox(width: _isMobile ? 6 : 8),
                        Text(
                          'Address',
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontSize: _isMobile ? 12 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _isMobile ? 6 : 8),
                    Text(
                      stepAddress,
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: _isMobile ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Show Call Passenger button if contact exists
                    if (widget.job.passengerContact != null && 
                        widget.job.passengerContact!.isNotEmpty) ...[
                      SizedBox(height: _isMobile ? 10 : 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _callPassenger,
                          icon: Icon(Icons.phone, size: _isMobile ? 16 : 18),
                          label: Text(_isMobile ? 'Call Passenger' : 'Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ChoiceLuxTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Action button for current step
            // For vehicle_return step, show buttons even when completed if job not closed
            // For other steps, only show if not completed
            if (isCurrent && (step.id == 'vehicle_return' || !isCompleted)) ...[
              SizedBox(height: _isMobile ? 12 : 16),
              // Use _buildActionButton for vehicle_return step to show Add Expenses/Close Job buttons
              // Use standard action button for other steps
              step.id == 'vehicle_return'
                  ? _buildActionButton(step)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _getStepAction(step.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChoiceLuxTheme.richGold,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            vertical: _isMobile ? 14 : 16,
                            horizontal: _isMobile ? 16 : 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_isMobile ? 10 : 12),
                          ),
                          elevation: _isMobile ? 2 : 4,
                        ),
                        child: Text(
                          _getStepActionText(step.id),
                          style: TextStyle(
                            fontSize: _isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get the action function for a step
  VoidCallback? _getStepAction(String stepId) {
    switch (stepId) {
      case 'not_started':
        return widget.job.isConfirmed == true ? _startJob : null;
      case 'vehicle_collection':
        return _collectVehicle;
      case 'pickup_arrival':
        return _arriveAtPickup;
      case 'passenger_pickup':
        return _passengerOnboard;
      case 'passenger_onboard':
        return _arriveAtDropoff;
      case 'dropoff_arrival':
        return _completeTrip;
      case 'trip_complete':
        return _returnVehicle;
      default:
        return null;
    }
  }

  /// Get the action text for a step
  String _getStepActionText(String stepId) {
    switch (stepId) {
      case 'not_started':
        return 'Start Job';
      case 'vehicle_collection':
        return 'Collect Vehicle';
      case 'pickup_arrival':
        return 'Arrive at Pickup';
      case 'passenger_pickup':
        return 'Passenger Onboard';
      case 'passenger_onboard':
        return 'Arrive at Dropoff';
      case 'dropoff_arrival':
        return 'Complete Trip';
      case 'trip_complete':
        return 'Return Vehicle';
      default:
        return 'No Action';
    }
  }

  /// Map database step IDs to UI step IDs
  String _mapDatabaseStepToUIStep(String databaseStep) {
    Log.d('Mapping database step: $databaseStep');
    
    switch (databaseStep) {
      case 'not_started':
        return 'not_started';
      case 'vehicle_collection':
        return 'vehicle_collection';
      case 'pickup_arrival':
        return 'pickup_arrival';
      case 'passenger_pickup':
        // Map passenger_pickup to passenger_onboard to show both buttons
        return 'passenger_onboard';
      case 'passenger_onboard':
        return 'passenger_onboard';
      case 'en_route':
        return 'passenger_onboard';
      case 'dropoff_arrival':
        return 'dropoff_arrival';
      case 'passenger_dropoff':
        return 'dropoff_arrival';
      case 'trip_complete':
        return 'trip_complete';
      case 'vehicle_return':
        return 'vehicle_return';
      case 'return_vehicle':
        return 'vehicle_return';
      case 'completed':
        return 'completed';
      default:
        Log.e('Unknown database step: $databaseStep, defaulting to pickup_arrival');
        return 'pickup_arrival';
    }
  }

  void _determineCurrentStep() {
    if (_jobProgress == null) {
      Log.d('_determineCurrentStep: _jobProgress is null, setting to not_started');
      // Set current step to not_started when progress is null
      if (_currentStep != 'not_started') {
        setState(() {
          _currentStep = 'not_started';
        });
      }
      return;
    }

    // Debug logging
    Log.d('=== DETERMINING CURRENT STEP ===');
    Log.d('Vehicle collected: ${_jobProgress!['vehicle_collected']}');
    Log.d('Current step from DB: ${_jobProgress!['current_step']}');
    Log.d('Trip progress: $_tripProgress');
    Log.d('Job closed time: ${_jobProgress!['job_closed_time']}');

    String newCurrentStep = 'not_started'; // Default to not started

    // Validate step transition logic
    try {

    // Priority 1: Check if job has actually started
    if (_jobProgress!['vehicle_collected'] == false &&
        _jobProgress!['current_step'] == null) {
      newCurrentStep = 'not_started';
      Log.d('Job has not started yet - showing as not started');
    }
    // Priority 2: If vehicle is collected, progress to pickup arrival
    else if (_jobProgress!['vehicle_collected'] == true) {
      // Check if we're still on vehicle_collection step or need to advance
      if (_jobProgress!['current_step'] == 'vehicle_collection' || 
          _jobProgress!['current_step'] == null) {
        newCurrentStep = 'pickup_arrival';
        Log.d('Vehicle collected, progressing to pickup arrival');
      } else {
        // Use the existing current_step from database
        newCurrentStep = _mapDatabaseStepToUIStep(_jobProgress!['current_step'].toString());
        Log.d('Vehicle collected, using existing step: ${_jobProgress!['current_step']} -> $newCurrentStep');
      }
    }
    // Priority 3: Trust the database current_step if it exists and is valid
    // BUT: Only skip this if job_status is actually 'completed'
    // This ensures we respect the database current_step even when job_closed_time is set
    // EXCEPTION: If current_step is 'trip_complete' and transport is completed, advance to vehicle_return
    else if (_jobProgress!['current_step'] != null &&
        _jobProgress!['current_step'].toString().isNotEmpty &&
        _jobProgress!['current_step'].toString() != 'null' &&
        _jobProgress!['current_step'].toString() != 'completed' &&
        _jobProgress!['job_status'] != 'completed') {
      final databaseStep = _jobProgress!['current_step'].toString();
      
      // Special case: If trip is completed, advance to vehicle_return step
      if (databaseStep == 'trip_complete' && _jobProgress!['transport_completed_ind'] == true) {
        newCurrentStep = 'vehicle_return';
        Log.d('Trip completed, advancing from trip_complete to vehicle_return');
      } else {
        // Map database step ID to UI step ID
        newCurrentStep = _mapDatabaseStepToUIStep(databaseStep);
        Log.d('Using current step from DB: $databaseStep, mapped to UI step: $newCurrentStep');
      }
    } else {
      // Priority 4: Determine step based on completion status
      Log.d('No valid current_step in DB, using completion-based logic');

      // Check job_status instead of job_closed_time
      // job_closed_time is set when vehicle is returned, not when job is completed
      if (_jobProgress!['job_status'] == 'completed') {
        newCurrentStep = 'completed';
        Log.d('Job is completed');
      } else if (_jobProgress!['job_closed_time'] != null || _jobProgress!['job_closed_odo'] != null) {
        // Vehicle is returned but job not closed yet - stay on vehicle_return step
        newCurrentStep = 'vehicle_return';
        Log.d('Vehicle returned, staying on vehicle_return step (job_status: ${_jobProgress!['job_status']})');
      } else if (_jobProgress!['transport_completed_ind'] == true) {
        newCurrentStep = 'vehicle_return';
        Log.d('Transport completed, moving to vehicle return');
      } else if (_jobProgress!['pickup_ind'] == true) {
        newCurrentStep = 'dropoff_arrival';
        Log.d('Passenger onboard, moving to dropoff arrival');
      } else if (_jobProgress!['pickup_arrive_time'] != null) {
        newCurrentStep = 'passenger_onboard';
        Log.d('Pickup arrived, moving to passenger onboard');
      } else if (_jobProgress!['vehicle_collected'] == true) {
        newCurrentStep = 'pickup_arrival';
        Log.d('Vehicle collected, moving to pickup arrival');
      } else {
        newCurrentStep = 'not_started';
        Log.d('Job has not started yet');
      }
    }

    Log.d('Final current step: $newCurrentStep');

    // Update the current step if it changed
    if (_currentStep != newCurrentStep) {
      Log.d('=== STEP CHANGED ===');
      Log.d('Previous step: $_currentStep');
      Log.d('New step: $newCurrentStep');
      Log.d('Reason: Step progression logic determined new step');
      
      setState(() {
        _currentStep = newCurrentStep;
      });
      
      // Update the database with the new current step
      _updateCurrentStepInDatabase(newCurrentStep);
      
      Log.d('=== STEP UPDATE COMPLETE ===');
    } else {
      Log.d('Step unchanged: $_currentStep');
      Log.d('No database update needed');
    }

    // Update step status only if needed
    _updateStepStatus();
    
    } catch (e) {
      Log.e('=== ERROR IN STEP DETERMINATION ===');
      Log.e('Error: $e');
      Log.e('Stack trace: ${StackTrace.current}');
      
      // Fallback to safe default based on job progress
      if (_jobProgress != null && _jobProgress!['vehicle_collected'] == true) {
        newCurrentStep = 'pickup_arrival';
        Log.d('Fallback: Vehicle collected, defaulting to pickup_arrival');
      } else {
        newCurrentStep = 'not_started';
        Log.d('Fallback: Defaulting to not_started');
      }
      
      // Update the current step even in error case
      if (_currentStep != newCurrentStep) {
        setState(() {
          _currentStep = newCurrentStep;
        });
      }
    }
  }

  Future<void> _updateCurrentStepInDatabase(String newStep) async {
    try {
      final jobIdInt = int.tryParse(widget.jobId);
      if (jobIdInt == null) return;

      Log.d('Updating current step in database to: $newStep');
      
      await DriverFlowApiService.updateCurrentStep(jobIdInt, newStep);
      
      Log.d('Successfully updated current step in database');
    } catch (e) {
      Log.e('Error updating current step in database: $e');
    }
  }

  Future<void> _startJob() async {
    if (!mounted) return;

    // Show the vehicle collection modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return VehicleCollectionModal(
          onConfirm:
              (({
                required double odometerReading,
                required String odometerImageUrl,
                required double gpsLat,
                required double gpsLng,
                required double gpsAccuracy,
                String? vehicleCollectedAtTimestamp,
              }) async {
                // Store the modal context before any async operations
                final modalContext = context;

                try {
                  Log.d('=== STARTING JOB ===');
                  Log.d('Job ID: ${widget.jobId}');
                  Log.d('Odometer: $odometerReading');
                  Log.d('Image URL: $odometerImageUrl');
                  Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

                  // Close the modal first so loading overlay is visible
                  if (modalContext.mounted) {
                    Navigator.of(modalContext).pop();
                  }

                  // Wait for modal to fully close before showing loading overlay
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Now set loading state - overlay will be visible since modal is closed
                  if (mounted) {
                    setState(() => _isUpdating = true);
                  }

                  await DriverFlowApiService.startJob(
                    int.parse(widget.jobId),
                    odoStartReading: odometerReading,
                    pdpStartImage: odometerImageUrl,
                    gpsLat: gpsLat,
                    gpsLng: gpsLng,
                    gpsAccuracy: gpsAccuracy,
                    vehicleCollectedAtTimestamp: vehicleCollectedAtTimestamp, // Pass captured timestamp
                  );

                  Log.d('=== JOB STARTED SUCCESSFULLY ===');
                  Log.d('Now loading job progress...');

                  // Single reload with proper state management
                  if (mounted) {
                    await _loadJobProgress(skipLoadingState: true);
                    Log.d('=== JOB PROGRESS LOADED ===');
                    Log.d('Current step after reload: $_currentStep');

                    // Show success message
                    SnackBarUtils.showSuccess(
                      context,
                      'Job started successfully!',
                    );
                  }
                } catch (e) {
                  Log.d('=== ERROR STARTING JOB ===');
                  Log.e('Error: $e');

                  // Close the modal using the stored context
                  if (modalContext.mounted) {
                    Navigator.of(modalContext).pop();
                  }

                  // Show error message after modal is closed and widget is still mounted
                  if (mounted) {
                    SnackBarUtils.showError(context, 'Failed to start job: $e');
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isUpdating = false);
                  }
                }
              }),
          onCancel: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _collectVehicle() async {
    if (!mounted) return;

    try {
      // Show loading state during GPS capture and API call
      setState(() => _isUpdating = true);

      final position = await _getCurrentLocation();

      await DriverFlowApiService.collectVehicle(
        int.parse(widget.jobId),
        gpsLat: position.latitude,
        gpsLng: position.longitude,
        gpsAccuracy: position.accuracy,
      );

      if (mounted) {
        await _loadJobProgress(skipLoadingState: true);
        SnackBarUtils.showSuccess(context, 'Vehicle collected successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to collect vehicle: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _arriveAtPickup() async {
    if (!mounted) return;

    try {
      // Show loading state during GPS capture and API call
      setState(() => _isUpdating = true);

      // Get current location (loading indicator already shown)
      final position = await _getCurrentLocation();

      Log.d('=== ARRIVING AT PICKUP ===');
      Log.d('Job ID: ${widget.jobId}');
      Log.d('Trip Index: $_currentTripIndex');
      Log.d(
        'GPS: ${position.latitude}, ${position.longitude}, ${position.accuracy}',
      );

      await DriverFlowApiService.arriveAtPickup(
        int.parse(widget.jobId),
        _currentTripIndex,
        gpsLat: position.latitude,
        gpsLng: position.longitude,
        gpsAccuracy: position.accuracy,
      );

      Log.d('=== PICKUP ARRIVAL COMPLETED ===');

      if (mounted) {
        await _loadJobProgress(skipLoadingState: true);
        SnackBarUtils.showSuccess(context, 'Arrived at pickup location!');

        // Step completed - user must manually proceed to next step
        // No automatic advancement - user controls progression
      }
    } catch (e) {
      Log.e('=== ERROR IN PICKUP ARRIVAL ===');
      Log.e('Error: $e');

      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to record pickup arrival: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _passengerOnboard() async {
    if (!mounted) return;

    try {
      setState(() => _isUpdating = true);

      final position = await _getCurrentLocation();
      final lat = position.latitude;
      final lng = position.longitude;

      await DriverFlowApiService.passengerOnboard(
        int.parse(widget.jobId),
        _currentTripIndex,
        gpsLat: lat,
        gpsLng: lng,
      );

      if (mounted) {
        await _loadJobProgress(skipLoadingState: true);
        SnackBarUtils.showSuccess(context, 'Passenger onboard!');

        // Step completed - user must manually proceed to next step
        // No automatic advancement - user controls progression
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Failed to record passenger onboard: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _markPassengerNoShow() async {
    if (!mounted) return;

    // Show the no-show modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PassengerNoShowModal(
          onConfirm: ({
            required String comment,
            required double gpsLat,
            required double gpsLng,
            required double gpsAccuracy,
          }) async {
            try {
              Log.d('=== MARKING PASSENGER NO-SHOW ===');
              Log.d('Job ID: ${widget.jobId}');
              Log.d('Comment: $comment');
              Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

              // The modal closes itself in its _confirmNoShow method (after calling onConfirm)
              // Wait for modal to fully close before showing loading overlay
              await Future.delayed(const Duration(milliseconds: 150));

              // Now set loading state - overlay will be visible since modal is closed
              if (mounted) {
                setState(() => _isUpdating = true);
              }

              await DriverFlowApiService.markPassengerNoShow(
                int.parse(widget.jobId),
                _currentTripIndex,
                comment: comment,
                gpsLat: gpsLat,
                gpsLng: gpsLng,
                gpsAccuracy: gpsAccuracy,
              );

              Log.d('=== PASSENGER NO-SHOW MARKED SUCCESSFULLY ===');

              if (mounted) {
                await _loadJobProgress(skipLoadingState: true);
                SnackBarUtils.showSuccess(context, 'Passenger marked as no-show');
              }
            } catch (e) {
              if (mounted) {
                SnackBarUtils.showError(
                  context,
                  'Failed to mark passenger as no-show: $e',
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isUpdating = false);
              }
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _arriveAtDropoff() async {
    if (!mounted) return;

    try {
      setState(() => _isUpdating = true);

      final position = await _getCurrentLocation();

      await DriverFlowApiService.arriveAtDropoff(
        int.parse(widget.jobId),
        _currentTripIndex,
        gpsLat: position.latitude,
        gpsLng: position.longitude,
        gpsAccuracy: position.accuracy,
      );

      if (mounted) {
        await _loadJobProgress(skipLoadingState: true);
        SnackBarUtils.showSuccess(context, 'Arrived at dropoff location!');

        // Step completed - user must manually proceed to next step
        // No automatic advancement - user controls progression
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Failed to record dropoff arrival: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _completeTrip() async {
    if (!mounted) return;

    try {
      setState(() => _isUpdating = true);

      final position = await _getCurrentLocation();
      final lat = position.latitude;
      final lng = position.longitude;

      await DriverFlowApiService.completeTrip(
        int.parse(widget.jobId),
        _currentTripIndex,
        gpsLat: lat,
        gpsLng: lng,
      );

      if (mounted) {
        await _loadJobProgress(skipLoadingState: true);
        SnackBarUtils.showSuccess(context, 'Trip completed!');

        // Step completed - user must manually proceed to next step
        // No automatic advancement - user controls progression
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to complete trip: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _returnVehicle() async {
    if (!mounted) return;

    // Store the modal context before any async operations
    final modalContext = context;

    // Show the vehicle return modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return VehicleReturnModal(
          onConfirm:
              (({
                required double odoEndReading,
                required double gpsLat,
                required double gpsLng,
                required double gpsAccuracy,
              }) async {
                try {
                  Log.d('=== RETURNING VEHICLE ===');
                  Log.d('Job ID: ${widget.jobId}');
                  Log.d('Odometer: $odoEndReading');
                  Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

                  // Close the modal first so loading overlay is visible
                  if (modalContext.mounted) {
                    Navigator.of(modalContext).pop();
                  }

                  // Wait for modal to fully close before showing loading overlay
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Now set loading state - overlay will be visible since modal is closed
                  if (mounted) {
                    setState(() => _isUpdating = true);
                  }

                  await DriverFlowApiService.returnVehicle(
                    int.parse(widget.jobId),
                    odoEndReading: odoEndReading,
                    gpsLat: gpsLat,
                    gpsLng: gpsLng,
                    gpsAccuracy: gpsAccuracy,
                  );

                  Log.d('=== VEHICLE RETURN COMPLETED ===');

                  if (mounted) {
                    await _loadJobProgress(skipLoadingState: true);

                    // Show success message after modal is closed and widget is still mounted
                    if (mounted) {
                      // Refresh jobs list to update job card status
                      ref.invalidate(jobsProvider);

                      // Don't show completion dialog here - vehicle is returned but job not closed yet
                      // User still needs to add expenses and close job
                      SnackBarUtils.showSuccess(
                        context,
                        'Vehicle returned successfully! You can now add expenses and close the job.',
                      );
                    }
                  }
                } catch (e) {
                  Log.e('=== ERROR IN VEHICLE RETURN ===');
                  Log.e('Error: $e');

                  // Close the modal using the stored context
                  if (modalContext.mounted) {
                    Navigator.of(modalContext).pop();
                  }

                  // Show error message after modal is closed and widget is still mounted
                  if (mounted) {
                    SnackBarUtils.showError(
                      context,
                      'Failed to return vehicle: $e',
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isUpdating = false);
                  }
                }
              }),
          onCancel: () {
            if (modalContext.mounted) {
              Navigator.of(modalContext).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _closeJob() async {
    if (!mounted) return;

    try {
      setState(() => _isUpdating = true);

      await DriverFlowApiService.closeJob(int.parse(widget.jobId));

      await _loadJobProgress(skipLoadingState: true);

      // Refresh jobs list to update job card status
      ref.invalidate(jobsProvider);

      // Show job completion dialog and navigate to jobs screen
      showJobCompletionDialog(
        context,
        jobNumber: widget.job.jobNumber ?? 'Unknown',
        passengerName: widget.job.passengerName,
        onDismiss: () {
          // Navigate to jobs screen after dialog is dismissed
          context.go('/jobs');
        },
      );
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to close job: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _addExpenses() async {
    if (!mounted) return;

    // Get current user ID
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      SnackBarUtils.showError(context, 'User not authenticated');
      return;
    }

    final driverId = currentUser.id;

    // Show the add expense modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AddExpenseModal(
          jobId: int.parse(widget.jobId),
          driverId: driverId,
          onSubmit: (expense, slipBytes, slipFileName) async {
            try {
              setState(() => _isUpdating = true);

              Log.d('=== CREATING EXPENSE ===');
              Log.d('Job ID: ${expense.jobId}');
              Log.d('Driver ID: ${expense.driverId}');
              Log.d('Expense Type: ${expense.expenseType}');
              Log.d('Amount: ${expense.amount}');

              // Upload slip image to storage if provided
              String? slipImageUrl;
              if (slipBytes.isNotEmpty && slipFileName.isNotEmpty) {
                try {
                  final supabase = Supabase.instance.client;
                  final storagePath = 'expenses/${widget.jobId}/${DateTime.now().millisecondsSinceEpoch}_$slipFileName';
                  
                  await supabase.storage
                      .from('expense-slips')
                      .uploadBinary(storagePath, slipBytes);

                  final publicUrl = supabase.storage
                      .from('expense-slips')
                      .getPublicUrl(storagePath);

                  slipImageUrl = publicUrl;
                  Log.d('Slip uploaded: $slipImageUrl');
                } catch (e) {
                  Log.e('Error uploading slip: $e');
                  // Continue with expense creation even if slip upload fails
                }
              }

              // Create expense in database
              final supabase = Supabase.instance.client;
              // Convert DateTime to ISO string for database
              final expDateISO = expense.expDate.toIso8601String();
              final expenseData = {
                'job_id': expense.jobId,
                'driver_id': expense.driverId,
                'expense_type': expense.expenseType,
                'amount': expense.amount,
                'exp_date': expDateISO,
                'expense_description': expense.expenseDescription,
                'other_description': expense.otherDescription,
                'expense_location': expense.expenseLocation,
                'slip_image': slipImageUrl,
                'created_at': SATimeUtils.getCurrentSATimeISO(),
                'updated_at': SATimeUtils.getCurrentSATimeISO(),
              };

              await supabase.from('expenses').insert(expenseData);

              Log.d('=== EXPENSE CREATED SUCCESSFULLY ===');

              if (mounted) {
                SnackBarUtils.showSuccess(
                  context,
                  'Expense added successfully!',
                );
              }

              // Refresh jobs list to update job card status
              ref.invalidate(jobsProvider);
            } catch (e) {
              Log.e('=== ERROR CREATING EXPENSE ===');
              Log.e('Error: $e');
              
              if (mounted) {
                SnackBarUtils.showError(
                  context,
                  'Failed to add expense: $e',
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isUpdating = false);
              }
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> _captureOdometerImage() async {
    // This is a placeholder - in a real implementation, you'd use the OdometerCaptureWidget
    return 'placeholder_image_url';
  }

  Future<void> _debugCurrentState() async {
    Log.d('=== DEBUG CURRENT STATE ===');
    Log.d('Current step: $_currentStep');
    Log.d('Job progress: $_jobProgress');
    Log.d('Trip progress: $_tripProgress');
    Log.d('Vehicle collected: ${_jobProgress?['vehicle_collected']}');
    Log.d('Current step from DB: ${_jobProgress?['current_step']}');

    for (int i = 0; i < _jobSteps.length; i++) {
      final step = _jobSteps[i];
      Log.d('Step ${i + 1}: ${step.id} - Completed: ${step.isCompleted}');
    }
    Log.d('=== END DEBUG ===');
  }

  Future<void> _checkAndUpdateJobStatus() async {
    if (_jobSteps.every((s) => s.isCompleted)) {
      try {
        Log.d('=== CHECKING JOB STATUS UPDATE ===');
        Log.d('All steps completed, updating job status to completed');
        Log.d('Current job status: ${_jobProgress?['job_status']}');

        await DriverFlowApiService.updateJobStatusToCompleted(
          int.parse(widget.jobId),
        );

        // Refresh job progress to get updated status
        _loadJobProgress();

        // Refresh jobs list to update job card
        ref.invalidate(jobsProvider);

        Log.d('=== JOB STATUS UPDATE COMPLETED ===');
      } catch (e) {
        Log.e('=== ERROR UPDATING JOB STATUS ===');
        Log.e('Error: $e');
      }
    }
  }

  Future<void> _forceUpdateJobStatus() async {
    try {
      Log.d('=== FORCE UPDATING JOB STATUS TO COMPLETED ===');

      await DriverFlowApiService.updateJobStatusToCompleted(
        int.parse(widget.jobId),
      );

      // Refresh job progress to get updated status
      _loadJobProgress();

      // Refresh jobs list to update job card
      ref.invalidate(jobsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job status updated to completed!'),
          backgroundColor: Colors.green,
        ),
      );

      Log.d('=== FORCE JOB STATUS UPDATE COMPLETED ===');
    } catch (e) {
      Log.e('=== ERROR FORCE UPDATING JOB STATUS ===');
      Log.e('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating job status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButton(JobStep step) {
    if (_isUpdating) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
        ),
      );
    }

    // Check if all steps are completed
    final allStepsCompleted = _jobSteps.every((s) => s.isCompleted);

    if (allStepsCompleted) {
      // Show completion message when all steps are done
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChoiceLuxTheme.successColor.withOpacity(0.1),
              ChoiceLuxTheme.successColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.successColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: ChoiceLuxTheme.successColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Completed!',
                    style: TextStyle(
                      color: ChoiceLuxTheme.successColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All steps have been completed successfully',
                    style: TextStyle(
                      color: ChoiceLuxTheme.platinumSilver,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await _forceUpdateJobStatus();
              },
              icon: const Icon(Icons.update, size: 18),
              label: const Text('Update Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    switch (step.id) {
      case 'not_started':
        // Check if job is confirmed before allowing start
        if (widget.job.isConfirmed == true) {
          return _buildLuxuryButton(
            onPressed: _startJob,
            icon: Icons.play_arrow_rounded,
            label: 'Start Job',
            isPrimary: true,
          );
        } else {
          // Job not confirmed - show message to confirm first
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChoiceLuxTheme.richGold.withOpacity(0.1),
                  ChoiceLuxTheme.richGold.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: ChoiceLuxTheme.richGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Not Confirmed',
                        style: TextStyle(
                          color: ChoiceLuxTheme.richGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please confirm the job before starting',
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

      case 'vehicle_collection':
        if (!step.isCompleted) {
          // Check if job is confirmed before allowing start
          if (widget.job.isConfirmed == true) {
            return _buildLuxuryButton(
              onPressed: _startJob,
              icon: Icons.play_arrow_rounded,
              label: 'Start Job',
              isPrimary: true,
            );
          } else {
            // Job not confirmed - show message to confirm first
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ChoiceLuxTheme.richGold.withOpacity(0.1),
                    ChoiceLuxTheme.richGold.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: ChoiceLuxTheme.richGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Not Confirmed',
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please confirm the job before starting',
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        }
        break;

      case 'pickup_arrival':
        // Only show button if previous step (vehicle_collection) is completed
        if (!step.isCompleted &&
            _isPreviousStepCompleted('vehicle_collection')) {
          return _buildLuxuryButton(
            onPressed: _isUpdating ? null : _arriveAtPickup, // Disable during processing
            icon: Icons.location_on_rounded,
            label: 'Arrive at Pickup',
            isPrimary: false,
          );
        } else if (!_isPreviousStepCompleted('vehicle_collection')) {
          return _buildStepLockedMessage('Complete vehicle collection first');
        }
        break;

      case 'passenger_pickup':
        // This step represents the actual arrival at pickup - no action button needed
        // It's automatically completed when pickup_arrival is done
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ChoiceLuxTheme.successColor.withOpacity(0.1),
                ChoiceLuxTheme.successColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChoiceLuxTheme.successColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: ChoiceLuxTheme.successColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup Arrival Completed',
                      style: TextStyle(
                        color: ChoiceLuxTheme.successColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                                          Text(
                        'Successfully arrived at pickup location',
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'passenger_onboard':
        // Check if passenger was already marked as no-show
        final isNoShow = _jobProgress != null && 
            (_jobProgress!['passenger_no_show_ind'] == true);
        
        // Only show buttons if previous step (pickup_arrival) is completed
        if (!step.isCompleted && _isPreviousStepCompleted('pickup_arrival') && !isNoShow) {
          // Show both Passenger Onboard and No-Show buttons
          return _isMobile
            ? Column(
                children: [
                  _buildLuxuryButton(
                    onPressed: _isUpdating ? null : () => _passengerOnboard(), // Disable during processing
                    icon: Icons.person_add_rounded,
                    label: 'Passenger Onboard',
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  _buildLuxuryButton(
                    onPressed: _isUpdating ? null : () => _markPassengerNoShow(), // Disable during processing
                    icon: Icons.person_off_rounded,
                    label: 'Passenger No-Show',
                    isPrimary: false,
                    isWarning: true,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: _isUpdating ? null : () => _passengerOnboard(), // Disable during processing
                      icon: Icons.person_add_rounded,
                      label: 'Passenger Onboard',
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: _isUpdating ? null : () => _markPassengerNoShow(), // Disable during processing
                      icon: Icons.person_off_rounded,
                      label: 'Passenger No-Show',
                      isPrimary: false,
                      isWarning: true,
                    ),
                  ),
                ],
              );
        } else if (!_isPreviousStepCompleted('pickup_arrival')) {
          return _buildStepLockedMessage('Arrive at pickup location first');
        } else if (isNoShow) {
          // Passenger was marked as no-show, show message
          return _buildStepCompletedMessage('Passenger marked as no-show');
        }
        break;

      case 'dropoff_arrival':
        // Check if passenger was marked as no-show
        final isNoShow = _jobProgress != null && 
            (_jobProgress!['passenger_no_show_ind'] == true);
        
        // If no-show, skip this step
        if (isNoShow) {
          return _buildStepCompletedMessage('Not applicable - Passenger no-show');
        }
        
        // Only show button if previous step (passenger_onboard) is completed
        if (!step.isCompleted &&
            _isPreviousStepCompleted('passenger_onboard')) {
          return _buildLuxuryButton(
            onPressed: _isUpdating ? null : () => _arriveAtDropoff(), // Disable during processing
            icon: Icons.location_on_rounded,
            label: 'Arrive at Dropoff',
            isPrimary: false,
          );
        } else if (!_isPreviousStepCompleted('passenger_onboard')) {
          return _buildStepLockedMessage('Complete passenger onboarding first');
        }
        break;

      case 'trip_complete':
        // Only show button if previous step (dropoff_arrival) is completed
        if (!step.isCompleted && _isPreviousStepCompleted('dropoff_arrival')) {
          return _buildLuxuryButton(
            onPressed: _isUpdating ? null : () => _completeTrip(), // Disable during processing
            icon: Icons.check_circle_rounded,
            label: 'Complete Trip',
            isPrimary: false,
          );
        } else if (!_isPreviousStepCompleted('dropoff_arrival')) {
          return _buildStepLockedMessage('Arrive at dropoff location first');
        } else if (step.isCompleted) {
          // Trip is completed, show message that vehicle return is next
          return _buildStepCompletedMessage('Trip completed! Proceed to vehicle return.');
        }
        break;

      case 'vehicle_return':
        // Check if trip_complete step is completed first (or no-show)
        final isNoShow = _jobProgress != null && 
            (_jobProgress!['passenger_no_show_ind'] == true);
        final tripCompleted = _isPreviousStepCompleted('trip_complete');
        
        if (!tripCompleted && !isNoShow) {
          return _buildStepLockedMessage('Complete trip first');
        }
        
        // Check if vehicle is already returned (job_closed_odo or job_closed_time is set)
        final vehicleReturned = _jobProgress != null && 
            (_jobProgress!['job_closed_odo'] != null || _jobProgress!['job_closed_time'] != null);
        
        // Check if job is already closed
        final jobClosed = _jobProgress != null && 
            _jobProgress!['job_status'] == 'completed';
        
        if (!vehicleReturned) {
          // Vehicle not returned yet, show Return Vehicle button
          // Also allow adding expenses before returning vehicle
          return _isMobile
            ? Column(
                children: [
                  _buildLuxuryButton(
                    onPressed: _isUpdating ? null : () => _returnVehicle(), // Disable during processing
                    icon: Icons.home_rounded,
                    label: 'Return Vehicle',
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  _buildLuxuryButton(
                    onPressed: _isUpdating ? null : () => _addExpenses(), // Disable during processing
                    icon: Icons.receipt_long_rounded,
                    label: 'Add Expenses',
                    isPrimary: false,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: _isUpdating ? null : () => _returnVehicle(), // Disable during processing
                      icon: Icons.home_rounded,
                      label: 'Return Vehicle',
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: _isUpdating ? null : () => _addExpenses(), // Disable during processing
                      icon: Icons.receipt_long_rounded,
                      label: 'Add Expenses',
                      isPrimary: false,
                    ),
                  ),
                ],
              );
        } else if (jobClosed) {
          // Job is already closed, show completion message
          return _buildStepCompletedMessage('Job completed successfully!');
        } else {
          // Vehicle returned but job not closed yet - show both Add Expenses and Close Job buttons
          return _isMobile 
            ? Column(
                children: [
                  _buildLuxuryButton(
                    onPressed: _isUpdating ? null : () => _addExpenses(), // Disable during processing
                    icon: Icons.receipt_long_rounded,
                    label: 'Add Expenses',
                    isPrimary: false,
                  ),
                  const SizedBox(height: 12),
                  _buildLuxuryButton(
                    onPressed: _isUpdating ? null : () => _closeJob(), // Disable during processing
                    icon: Icons.done_all_rounded,
                    label: 'Close Job',
                    isPrimary: true,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: _isUpdating ? null : () => _addExpenses(), // Disable during processing
                      icon: Icons.receipt_long_rounded,
                      label: 'Add Expenses',
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: _isUpdating ? null : () => _closeJob(), // Disable during processing
                      icon: Icons.done_all_rounded,
                      label: 'Close Job',
                      isPrimary: true,
                    ),
                  ),
                ],
              );
        }

      case 'completed':
        // Job is completed, show completion message
        return _buildStepCompletedMessage('Job completed successfully!');
    }

    return const SizedBox.shrink();
  }

  /// Check if a previous step is completed
  bool _isPreviousStepCompleted(String stepId) {
    final stepIndex = _jobSteps.indexWhere((step) => step.id == stepId);
    if (stepIndex == -1) return false;

    // Check if the step is completed
    return _jobSteps[stepIndex].isCompleted;
  }

  /// Build a message indicating the step is locked
  Widget _buildStepLockedMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_rounded,
            color: ChoiceLuxTheme.platinumSilver,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a message indicating the step is completed
  Widget _buildStepCompletedMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ChoiceLuxTheme.successColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: ChoiceLuxTheme.successColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ChoiceLuxTheme.successColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryButton({
    VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isWarning = false,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isWarning
                ? [
                    ChoiceLuxTheme.errorColor,
                    ChoiceLuxTheme.errorColor.withOpacity(0.9),
                  ]
                : [
                    ChoiceLuxTheme.richGold,
                    ChoiceLuxTheme.richGold.withOpacity(0.9),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isWarning ? ChoiceLuxTheme.errorColor : ChoiceLuxTheme.richGold).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: isWarning ? Colors.white : Colors.black, size: 20),
          label: Text(
            label,
            style: TextStyle(
              color: isWarning ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: isWarning 
              ? ChoiceLuxTheme.errorColor.withOpacity(0.1)
              : ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWarning
                ? ChoiceLuxTheme.errorColor.withOpacity(0.5)
                : ChoiceLuxTheme.richGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
          label: Text(
            label,
            style: TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLuxuryAppBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.jetBlack.withOpacity(0.95),
            ChoiceLuxTheme.jetBlack.withOpacity(0.90),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Back Button
              IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/jobs');
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: ChoiceLuxTheme.richGold,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(40, 40),
                ),
              ),
              const SizedBox(width: 8),

              // Brand Icon with Gold Glow
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ChoiceLuxTheme.richGold,
                      ChoiceLuxTheme.richGold.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ChoiceLuxTheme.richGold.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: ChoiceLuxTheme.jetBlack,
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: ChoiceLuxTheme.richGold,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title with Gold Accent
              Expanded(
                child: Text(
                  'Progress',
                  style: const TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // Premium Refresh Button
              Container(
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: ChoiceLuxTheme.richGold,
                    size: 20,
                  ),
                  onPressed: () {
                    _loadJobProgress();
                    _debugCurrentState();
                  },
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(40, 40),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // User Menu
              Consumer(
                builder: (context, ref, child) {
                  final currentUser = ref.watch(currentUserProvider);
                  final userProfile = ref.watch(currentUserProfileProvider);

                  // Get display name from profile, fallback to email, then to 'User'
                  String displayName = 'User';
                  if (userProfile != null &&
                      userProfile.displayNameOrEmail != 'User') {
                    displayName = userProfile.displayNameOrEmail;
                  } else if (currentUser?.email != null) {
                    displayName = currentUser!.email!.split('@')[0];
                  }

                  return PopupMenuButton<String>(
                    offset: const Offset(0, 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: ChoiceLuxTheme.charcoalGray,
                    elevation: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            color: ChoiceLuxTheme.richGold,
                            size: 20,
                          ),
                          // Enhanced user indicator
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ChoiceLuxTheme.richGold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ChoiceLuxTheme.jetBlack,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: ChoiceLuxTheme.jetBlack,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      // Enhanced User Info Header
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              // Enhanced Avatar with Gold Ring
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      ChoiceLuxTheme.richGold,
                                      ChoiceLuxTheme.richGold.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: ChoiceLuxTheme.richGold
                                      .withOpacity(0.2),
                                  child: Text(
                                    displayName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: ChoiceLuxTheme.richGold,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: ChoiceLuxTheme.softWhite,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (userProfile?.role != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        userProfile!.role!.toUpperCase(),
                                        style: const TextStyle(
                                          color: ChoiceLuxTheme.richGold,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      // Enhanced Menu Items
                      PopupMenuItem<String>(
                        value: 'profile',
                        onTap: () {
                          context.go('/user-profile');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                color: ChoiceLuxTheme.richGold,
                                size: 22,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'settings',
                        onTap: () {
                          Log.d('Navigate to Settings');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.settings_outlined,
                                color: ChoiceLuxTheme.richGold,
                                size: 22,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<String>(
                        value: 'signout',
                        onTap: () async {
                          await ref.read(authProvider.notifier).signOut();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: ChoiceLuxTheme.errorColor,
                                size: 22,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: ChoiceLuxTheme.errorColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryJobInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: ChoiceLuxTheme.richGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job ${widget.job.jobNumber}',
                        style: const TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${widget.job.status ?? 'Unknown'}',
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressPercentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold,
                        ChoiceLuxTheme.richGold.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: $_progressPercentage%',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryTimeline() {
    return Container(
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline_rounded,
                  color: ChoiceLuxTheme.richGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Job Progress',
                  style: TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._jobSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrentStep = step.id == _currentStep;
              final isCompleted = step.isCompleted;

              return Column(
                children: [
                  Row(
                    children: [
                      // Step Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isCurrentStep
                              ? (step.id == 'not_started'
                                    ? LinearGradient(
                                        colors: [
                                          ChoiceLuxTheme.infoColor,
                                          ChoiceLuxTheme.infoColor.withOpacity(
                                            0.8,
                                          ),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          ChoiceLuxTheme.richGold,
                                          ChoiceLuxTheme.richGold.withOpacity(
                                            0.8,
                                          ),
                                        ],
                                      ))
                              : isCompleted
                              ? LinearGradient(
                                  colors: [
                                    ChoiceLuxTheme.successColor,
                                    ChoiceLuxTheme.successColor.withOpacity(
                                      0.8,
                                    ),
                                  ],
                                )
                              : null,
                          color: isCurrentStep || isCompleted
                              ? null
                              : ChoiceLuxTheme.charcoalGray,
                          border: Border.all(
                            color: isCurrentStep
                                ? (step.id == 'not_started'
                                      ? ChoiceLuxTheme.infoColor
                                      : ChoiceLuxTheme.richGold)
                                : isCompleted
                                ? ChoiceLuxTheme.successColor
                                : ChoiceLuxTheme.platinumSilver.withOpacity(
                                    0.3,
                                  ),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : step.icon,
                          color: isCompleted
                              ? Colors.black
                              : isCurrentStep
                              ? (step.id == 'not_started'
                                    ? Colors.white
                                    : Colors.black)
                              : ChoiceLuxTheme.platinumSilver,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Step Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    color: isCurrentStep
                                        ? (step.id == 'not_started'
                                              ? ChoiceLuxTheme.infoColor
                                              : ChoiceLuxTheme.richGold)
                                        : isCompleted
                                        ? ChoiceLuxTheme.successColor
                                        : ChoiceLuxTheme.softWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isCurrentStep) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: step.id == 'not_started'
                                          ? ChoiceLuxTheme.infoColor
                                          : ChoiceLuxTheme.richGold,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      step.id == 'not_started'
                                          ? 'Not Started'
                                          : 'Current',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.description,
                              style: TextStyle(
                                color: ChoiceLuxTheme.platinumSilver,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (index < _jobSteps.length - 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: 2,
                      height: 20,
                      margin: const EdgeInsets.only(left: 19),
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryCurrentStepCard() {
    // Check if all steps are completed
    final allStepsCompleted = _jobSteps.every((s) => s.isCompleted);

    if (allStepsCompleted) {
      // Show completion card when all steps are done
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChoiceLuxTheme.successColor.withOpacity(0.1),
              ChoiceLuxTheme.successColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ChoiceLuxTheme.successColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ChoiceLuxTheme.successColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: ChoiceLuxTheme.successColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Job Completed',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ChoiceLuxTheme.successColor,
                          ChoiceLuxTheme.successColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.done_all_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Steps Completed',
                          style: TextStyle(
                            color: ChoiceLuxTheme.successColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The job has been completed successfully. All required steps have been finished.',
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Debug logging for step resolution
    Log.d('=== BUILDING CURRENT STEP CARD ===');
    Log.d('Current step ID: $_currentStep');
    Log.d('Available step IDs: ${_jobSteps.map((s) => s.id).toList()}');
    
    final currentStep = _jobSteps.firstWhere(
      (step) => step.id == _currentStep,
      orElse: () {
        Log.e('Step $_currentStep not found in _jobSteps, falling back to first step');
        return _jobSteps.first;
      },
    );
    
    Log.d('Resolved step: ${currentStep.id} - ${currentStep.title}');

    // Special handling for not started jobs
    if (_currentStep == 'not_started') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChoiceLuxTheme.infoColor.withOpacity(0.1),
              ChoiceLuxTheme.infoColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ChoiceLuxTheme.infoColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ChoiceLuxTheme.infoColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: ChoiceLuxTheme.infoColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Job Status',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ChoiceLuxTheme.infoColor,
                          ChoiceLuxTheme.infoColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.isConfirmed == true
                              ? 'Job Ready to Start'
                              : 'Job Not Confirmed',
                          style: const TextStyle(
                            color: ChoiceLuxTheme.infoColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.job.isConfirmed == true
                              ? 'Driver has confirmed the job and can now start'
                              : 'Driver must confirm the job before starting',
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(currentStep),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ChoiceLuxTheme.richGold.withOpacity(0.1),
            ChoiceLuxTheme.richGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ChoiceLuxTheme.richGold.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.play_circle_rounded,
                  color: ChoiceLuxTheme.richGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Current Step',
                  style: TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold,
                        ChoiceLuxTheme.richGold.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(currentStep.icon, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStep.title,
                        style: const TextStyle(
                          color: ChoiceLuxTheme.richGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentStep.description,
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionButton(currentStep),
              ],
            ),
          ],
        ),
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    // Debug logging
    Log.d('=== BUILD METHOD CALLED ===');
    Log.d('_isLoading: $_isLoading');
    Log.d('_jobProgress: $_jobProgress');
    Log.d('_currentStep: $_currentStep');
    Log.d('_jobSteps length: ${_jobSteps.length}');
    
    // Match dashboard background (solid color, no pattern)
    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen (solid obsidian to match dashboard)
        Container(
          color: ChoiceLuxTheme.jetBlack,
        ),
        // Layer 2: Loading overlay when updating
        if (_isUpdating)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.jetBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ChoiceLuxTheme.richGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Updating...',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Layer 3: The Scaffold with a transparent background
        SystemSafeScaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: _buildLuxuryAppBar(),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _isLoading == true
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ChoiceLuxTheme.richGold,
                            ),
                          ),
                        )
                      : _jobProgress == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: 64,
                                    color: ChoiceLuxTheme.richGold.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 16),
                              Text(
                                'Ready to Start Job',
                                style: TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Job ID: ${widget.jobId}',
                                style: TextStyle(
                                  color: ChoiceLuxTheme.softWhite.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showStartJobModal,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Job'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ChoiceLuxTheme.richGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadJobProgress,
                          color: ChoiceLuxTheme.richGold,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Job Progress Summary Card
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(_isMobile ? 16 : 20),
                                  decoration: BoxDecoration(
                                    gradient: ChoiceLuxTheme.cardGradient,
                                    borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
                                    border: Border.all(
                                      color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Job Progress - ${widget.job.jobNumber}',
                                        style: TextStyle(
                                          color: ChoiceLuxTheme.richGold,
                                          fontSize: _isMobile ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: _isMobile ? 12 : 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Status: ${widget.job.status}',
                                                  style: TextStyle(
                                                    color: ChoiceLuxTheme.softWhite,
                                                    fontSize: _isMobile ? 14 : 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Current Step: $_currentStep',
                                                  style: TextStyle(
                                                    color: ChoiceLuxTheme.softWhite,
                                                    fontSize: _isMobile ? 14 : 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: _isMobile ? 12 : 16,
                                              vertical: _isMobile ? 6 : 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$_progressPercentage%',
                                              style: TextStyle(
                                                color: ChoiceLuxTheme.richGold,
                                                fontSize: _isMobile ? 16 : 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: _isMobile ? 16 : 24),
                                // Enhanced Job Steps with Responsive Design
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(_isMobile ? 16 : 20),
                                  decoration: BoxDecoration(
                                    gradient: ChoiceLuxTheme.cardGradient,
                                    borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
                                    border: Border.all(
                                      color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timeline,
                                            color: ChoiceLuxTheme.richGold,
                                            size: _isMobile ? 20 : 24,
                                          ),
                                          SizedBox(width: _isMobile ? 8 : 12),
                                          Text(
                                            'Job Steps',
                                            style: TextStyle(
                                              color: ChoiceLuxTheme.richGold,
                                              fontSize: _isMobile ? 18 : 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: _isMobile ? 6 : 8),
                                      Text(
                                        'Follow the steps below to complete your job',
                                        style: TextStyle(
                                          color: ChoiceLuxTheme.platinumSilver,
                                          fontSize: _isMobile ? 12 : 14,
                                        ),
                                      ),
                                      SizedBox(height: _isMobile ? 16 : 20),
                                      // Enhanced step cards with responsive design
                                      ..._jobSteps.map((step) => _buildEnhancedStepCard(step)).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ],
    );
  }
}

