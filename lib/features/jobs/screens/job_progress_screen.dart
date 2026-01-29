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
      title: 'Pickup Point',
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
      if (!mounted) return;
      
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
      
      // If progress is null, check if job has actually started (race condition fix)
      // Only retry for initial load, not for step completion updates
      if (progress == null && !skipLoadingState) {
        
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
              // Retry up to 3 times with increasing delays (only for initial load)
              for (int attempt = 1; attempt <= 3; attempt++) {
                final delayMs = 300 * attempt; // 300ms, 600ms, 900ms
                await Future.delayed(Duration(milliseconds: delayMs));
                
                final retryProgress = await DriverFlowApiService.getJobProgress(jobIdInt);
                if (retryProgress != null) {
                  progress = retryProgress;
                  break;
                }
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
        
        // CRITICAL FIX: If we're in the middle of an optimistic update (skipLoadingState = true),
        // preserve the existing _jobProgress data instead of clearing it
        // This prevents black screen after vehicle return when server data is temporarily unavailable
        if (skipLoadingState && _jobProgress != null) {
          // Load trip progress and addresses but keep existing job progress
          final trips = await DriverFlowApiService.getTripProgress(jobIdInt);
          final addresses = await DriverFlowApiService.getJobAddresses(jobIdInt);
          final nextTripIndex = _findNextIncompleteTripIndex(trips);
          
          setState(() {
            // Keep _jobProgress as-is (preserve optimistic update)
            _tripProgress = trips;
            _jobAddresses = addresses;
            _currentTripIndex = nextTripIndex;
            // Don't reset progress percentage if we have optimistic data
            if (_progressPercentage == 0 && _jobProgress!['progress_percentage'] != null) {
              _progressPercentage = _jobProgress!['progress_percentage'] as int;
            }
            // CRITICAL FIX: Explicitly preserve _currentStep if optimistic data indicates vehicle_return
            if (_jobProgress!['current_step']?.toString() == 'vehicle_return' ||
                _jobProgress!['job_closed_odo'] != null ||
                _jobProgress!['job_closed_time'] != null) {
              _currentStep = 'vehicle_return';
            }
          });
          
          // Update step status - this needs the correct _currentStep
          _updateStepStatus();
          // Don't call _determineCurrentStep() if we're already on vehicle_return
          if (_currentStep != 'vehicle_return') {
            _determineCurrentStep();
          }
          return;
        }
        
        // Only clear _jobProgress if this is a fresh load (not an optimistic update)
        // Load trip progress and addresses even when no job progress exists
        final trips = await DriverFlowApiService.getTripProgress(jobIdInt);
        final addresses = await DriverFlowApiService.getJobAddresses(jobIdInt);
        
        // Find next incomplete trip index
        final nextTripIndex = _findNextIncompleteTripIndex(trips);
        
        setState(() {
          _jobProgress = null;
          _tripProgress = trips;
          _jobAddresses = addresses;
          _currentTripIndex = nextTripIndex;
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

      // OPTIMIZATION: Load trip progress and addresses in parallel (3x faster)
      // Only reload if trips/addresses might have changed
      final shouldReloadTrips = _tripProgress == null || 
          (p['trip_complete_at'] != null && _tripProgress!.any((t) => t['status'] != 'completed'));
      final shouldReloadAddresses = _jobAddresses.isEmpty;
      
      final tripFuture = shouldReloadTrips 
          ? DriverFlowApiService.getTripProgress(jobIdInt)
          : Future.value(_tripProgress!);
      final addressFuture = shouldReloadAddresses
          ? DriverFlowApiService.getJobAddresses(jobIdInt)
          : Future.value(_jobAddresses);
      
      final results = await Future.wait([tripFuture, addressFuture]);
      
      final trips = results[0] as List<Map<String, dynamic>>;
      final addresses = results[1] as Map<String, String?>;

      // CRITICAL FIX: If we're in an optimistic update (skipLoadingState = true)
      // and have optimistic vehicle return data, merge it with server data
      // BEFORE setting state. This prevents losing optimistic data.
      Map<String, dynamic>? finalProgress = progress;
      String? explicitStep;
      
      if (skipLoadingState && _jobProgress != null && _isVehicleReturnComplete()) {
        // Explicitly preserve optimistic vehicle return data
        final optimisticOdo = _jobProgress!['job_closed_odo'];
        final optimisticTime = _jobProgress!['job_closed_time'];
        
        // Merge server data with optimistic vehicle return data
        finalProgress = {
          ...progress, // Server data (base)
          // Explicitly preserve optimistic fields if server doesn't have them yet
          if (optimisticOdo != null && progress['job_closed_odo'] == null)
            'job_closed_odo': optimisticOdo,
          if (optimisticTime != null && progress['job_closed_time'] == null)
            'job_closed_time': optimisticTime,
          // Always ensure these are set correctly
          'current_step': 'vehicle_return',
          'progress_percentage': 100,
        };
        explicitStep = 'vehicle_return';
        
      } else if (skipLoadingState && _jobProgress != null &&
          _jobProgress!['passenger_onboard_at'] != null &&
          progress['passenger_onboard_at'] == null) {
        // Preserve passenger_onboard_at if server returned null (e.g. stale refetch)
        finalProgress = {
          ...progress,
          'passenger_onboard_at': _jobProgress!['passenger_onboard_at'],
        };
      } else if (skipLoadingState && _jobProgress != null &&
          _jobProgress!['trip_complete_at'] != null &&
          progress['trip_complete_at'] == null) {
        // Preserve trip_complete_at if server returned null (e.g. stale refetch)
        finalProgress = {
          ...progress,
          'trip_complete_at': _jobProgress!['trip_complete_at'],
        };
      } else if (skipLoadingState && _jobProgress != null &&
          _jobProgress!['passenger_no_show_ind'] == true &&
          progress['passenger_no_show_ind'] != true) {
        // Preserve no-show state if server returned stale (e.g. refetch)
        finalProgress = {
          ...progress,
          'passenger_no_show_ind': _jobProgress!['passenger_no_show_ind'],
          if (_jobProgress!['passenger_no_show_at'] != null)
            'passenger_no_show_at': _jobProgress!['passenger_no_show_at'],
          if (_jobProgress!['passenger_no_show_comment'] != null)
            'passenger_no_show_comment': _jobProgress!['passenger_no_show_comment'],
        };
      }
      
      // Use atomic state update method
      _updateCompleteState(
        progress: finalProgress,
        trips: trips,
        addresses: addresses,
        explicitCurrentStep: explicitStep,
      );

      if (mounted) {
        setState(() {
          // Only set _isLoading to false if we set it to true
          if (!skipLoadingState) {
            _isLoading = false;
          }
        });
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
          // Trip complete is completed when:
          // 1. trip_complete_at is set (trip was actually completed)
          // 2. OR when we've moved beyond this step (current_step is vehicle_return or completed)
          // 3. OR when passenger is marked as no-show and transport is completed
          final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
          final transportCompleted = _jobProgress!['transport_completed_ind'] == true;
          final tripCompleteAt = _jobProgress!['trip_complete_at'];
          isCompleted = tripCompleteAt != null || // Trip was completed (trip_complete_at is set)
                       (isNoShow && transportCompleted) ||
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

      // Check if step status has changed before updating
      final isActive = step.id == _currentStep;
      final wasCompleted = _jobSteps[i].isCompleted;
      final wasActive = _jobSteps[i].isActive;
      
      if (wasCompleted != isCompleted || wasActive != isActive) {
        hasChanges = true;
        // Update the step completion status
        _jobSteps[i] = step.copyWith(
          isCompleted: isCompleted,
          isActive: isActive,
        );
      }
    }

    // Only trigger rebuild if there were actual changes
    if (hasChanges && mounted) {
      setState(() {
        // Trigger rebuild
      });
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
            newTitle = 'Pickup Point';
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
    
    // Check if vehicle_return button should be shown even if not current step
    // This is a fallback to ensure button shows when all trips are completed
    final shouldShowVehicleReturnButton = step.id == 'vehicle_return' &&
        _jobProgress != null &&
        (_jobProgress!['transport_completed_ind'] == true) &&
        (_jobProgress!['job_closed_odo'] == null && _jobProgress!['job_closed_time'] == null) &&
        (_isPreviousStepCompleted('trip_complete') || 
         _jobProgress!['trip_complete_at'] != null);
    
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
                      // Trip indicator (only show if multiple trips exist)
                      if (_tripProgress != null && _tripProgress!.length > 1)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Trip $_currentTripIndex of ${_tripProgress!.length}',
                            style: TextStyle(
                              fontSize: _isMobile ? 11 : 12,
                              color: ChoiceLuxTheme.richGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
            // For passenger_pickup step, use _buildActionButton to show Passenger Onboard/No-Show buttons
            // For other steps, only show if not completed
            // Use _buildActionButton for ALL steps to ensure consistent loading indicators
            if ((isCurrent && (step.id == 'vehicle_return' || step.id == 'passenger_pickup' || !isCompleted)) ||
                shouldShowVehicleReturnButton) ...[
              SizedBox(height: _isMobile ? 12 : 16),
              _buildActionButton(step),
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
        return _startJob; // Vehicle collection is handled by startJob
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
        // Keep passenger_pickup as passenger_pickup to show the step with buttons
        return 'passenger_pickup';
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
      Log.d('_determineCurrentStep: _jobProgress is null');
      // Don't immediately default to not_started - wait for retry logic in _loadJobProgress
      // Only set to not_started if we're not in a loading/updating state (which means retries have completed)
      if (!_isLoading && !_isUpdating && _currentStep != 'not_started') {
        Log.d('Retries completed, setting to not_started');
        setState(() {
          _currentStep = 'not_started';
        });
      }
      return;
    }

    // CRITICAL: If vehicle return is complete, always stay on vehicle_return step
    // This prevents any logic from changing the step incorrectly
    // Check both conditions: vehicle return data exists AND we're already on vehicle_return
    if (_isVehicleReturnComplete()) {
      if (_currentStep != 'vehicle_return') {
        Log.d('Vehicle return complete but step not set, updating to vehicle_return');
        setState(() {
          _currentStep = 'vehicle_return';
        });
        _updateStepStatus();
      } else {
        Log.d('Vehicle return complete, preserving vehicle_return step');
        _updateStepStatus(); // Still update step status for UI
      }
      return; // Don't change the step
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
      
      // Special case: If trip is completed (either all trips completed OR trip_complete_at is set), advance to vehicle_return step
      final tripCompleteAt = _jobProgress!['trip_complete_at'];
      final transportCompleted = _jobProgress!['transport_completed_ind'] == true;
      
      if (databaseStep == 'trip_complete' && (transportCompleted || tripCompleteAt != null)) {
        newCurrentStep = 'vehicle_return';
        Log.d('Trip completed, advancing from trip_complete to vehicle_return (transport_completed: $transportCompleted, trip_complete_at: $tripCompleteAt)');
      } else if (databaseStep == 'vehicle_return') {
        // If vehicle is returned, stay on vehicle_return (user can still add expenses and close job)
        // Only advance to completed if job_status is actually 'completed'
        final vehicleReturned = _jobProgress!['job_closed_odo'] != null || _jobProgress!['job_closed_time'] != null;
        if (vehicleReturned && _jobProgress!['job_status'] == 'completed') {
          newCurrentStep = 'completed';
          Log.d('Vehicle returned and job completed, advancing to completed step');
        } else {
          newCurrentStep = 'vehicle_return';
          Log.d('Vehicle returned, staying on vehicle_return step');
        }
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
      } else if (_jobProgress!['transport_completed_ind'] == true || _jobProgress!['trip_complete_at'] != null) {
        // Transport is completed OR trip was completed (trip_complete_at is set)
        newCurrentStep = 'vehicle_return';
        Log.d('Transport completed or trip completed, moving to vehicle return (transport_completed: ${_jobProgress!['transport_completed_ind']}, trip_complete_at: ${_jobProgress!['trip_complete_at']})');
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
    Log.d('Transport completed: ${_jobProgress!['transport_completed_ind']}');
    Log.d('Trip complete at: ${_jobProgress!['trip_complete_at']}');
    Log.d('Current step from DB: ${_jobProgress!['current_step']}');

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
      builder: (BuildContext modalContext) {
        return VehicleCollectionModal(
          onConfirm: ({
            required double odometerReading,
            required String odometerImageUrl,
            required double gpsLat,
            required double gpsLng,
            required double gpsAccuracy,
            String? vehicleCollectedAtTimestamp,
          }) async {
            await _completeModalStep(
              modalContext: modalContext,
              stepName: 'vehicle_collection',
              apiCall: () async {
                Log.d('=== STARTING JOB ===');
                Log.d('Job ID: ${widget.jobId}');
                Log.d('Odometer: $odometerReading');
                Log.d('Image URL: $odometerImageUrl');
                Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

                final progress = await DriverFlowApiService.startJob(
                  int.parse(widget.jobId),
                  odoStartReading: odometerReading,
                  pdpStartImage: odometerImageUrl,
                  gpsLat: gpsLat,
                  gpsLng: gpsLng,
                  gpsAccuracy: gpsAccuracy,
                  vehicleCollectedAtTimestamp: vehicleCollectedAtTimestamp,
                );

                Log.d('=== JOB STARTED SUCCESSFULLY ===');
                return progress;
              },
              optimisticData: {
                'vehicle_collected': true,
                'vehicle_collected_at': vehicleCollectedAtTimestamp ?? SATimeUtils.getCurrentSATimeISO(),
                'current_step': 'pickup_arrival',
                'progress_percentage': 17,
                'job_started_at': SATimeUtils.getCurrentSATimeISO(),
                'odo_start_reading': odometerReading,
                'pdp_start_image': odometerImageUrl,
                'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
                'updated_at': SATimeUtils.getCurrentSATimeISO(),
              },
              successMessage: 'Job started successfully!',
            );
          },
          onCancel: () {
            if (mounted) {
              Navigator.of(modalContext).pop();
            }
          },
        );
      },
    );
  }


  Future<void> _arriveAtPickup() async {
    if (!mounted) return;

    await _completeStandardStep(
      stepName: 'pickup_arrival',
      apiCall: (position) async {
        if (position == null) throw Exception('GPS position required for pickup arrival');
        
        Log.d('=== ARRIVING AT PICKUP ===');
        Log.d('Job ID: ${widget.jobId}');
        Log.d('Trip Index: $_currentTripIndex');
        Log.d('GPS: ${position.latitude}, ${position.longitude}, ${position.accuracy}');

        await DriverFlowApiService.arriveAtPickup(
          int.parse(widget.jobId),
          _currentTripIndex,
          gpsLat: position.latitude,
          gpsLng: position.longitude,
          gpsAccuracy: position.accuracy,
        );

        Log.d('=== PICKUP ARRIVAL COMPLETED ===');
      },
      optimisticDataBuilder: (position) {
        final currentTime = SATimeUtils.getCurrentSATimeISO();
        return {
          'current_step': 'passenger_pickup',
          'progress_percentage': 33,
          'pickup_arrive_time': currentTime,
          'pickup_arrive_loc': position != null ? 'GPS: ${position.latitude}, ${position.longitude}' : null,
          'last_activity_at': currentTime,
          'updated_at': currentTime,
        };
      },
      successMessage: 'Arrived at pickup location!',
      needsGPS: true,
    );
  }

  Future<void> _passengerOnboard() async {
    if (!mounted) return;

    await _completeStandardStep(
      stepName: 'passenger_onboard',
      apiCall: (position) async {
        if (position == null) throw Exception('GPS position required for passenger onboard');
        Log.d('=== PASSENGER ONBOARD ===');
        Log.d('Job ID: ${widget.jobId}');
        Log.d('Trip Index: $_currentTripIndex');
        Log.d('GPS: ${position.latitude}, ${position.longitude}');
        final progress = await DriverFlowApiService.passengerOnboard(
          int.parse(widget.jobId),
          _currentTripIndex,
          gpsLat: position.latitude,
          gpsLng: position.longitude,
        );
        Log.d('=== PASSENGER ONBOARD COMPLETED ===');
        return progress;
      },
      optimisticDataBuilder: (position) {
        final currentTime = SATimeUtils.getCurrentSATimeISO();
        return {
          'current_step': 'passenger_onboard',
          'progress_percentage': 50,
          'passenger_onboard_at': currentTime,
          'last_activity_at': currentTime,
          'updated_at': currentTime,
        };
      },
      successMessage: 'Passenger onboard!',
      needsGPS: true,
    );
  }

  Future<void> _markPassengerNoShow() async {
    if (!mounted) return;

    // Show the no-show modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext modalContext) {
        return PassengerNoShowModal(
          onConfirm: ({
            required String comment,
            required double gpsLat,
            required double gpsLng,
            required double gpsAccuracy,
          }) async {
            await _completeModalStep(
              modalContext: modalContext,
              stepName: 'passenger_no_show',
              apiCall: () async {
                Log.d('=== MARKING PASSENGER NO-SHOW ===');
                Log.d('Job ID: ${widget.jobId}');
                Log.d('Trip Index: $_currentTripIndex');
                Log.d('Comment: $comment');
                Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

                final progress = await DriverFlowApiService.markPassengerNoShow(
                  int.parse(widget.jobId),
                  _currentTripIndex,
                  comment: comment,
                  gpsLat: gpsLat,
                  gpsLng: gpsLng,
                  gpsAccuracy: gpsAccuracy,
                );

                Log.d('=== PASSENGER NO-SHOW MARKED SUCCESSFULLY ===');
                return progress;
              },
              optimisticData: {
                'passenger_no_show_ind': true,
                'passenger_no_show_comment': comment.trim(),
                'passenger_no_show_at': SATimeUtils.getCurrentSATimeISO(),
                'transport_completed_ind': true,
                'trip_complete_at': SATimeUtils.getCurrentSATimeISO(),
                'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
                'updated_at': SATimeUtils.getCurrentSATimeISO(),
                'current_step': 'vehicle_return',
                'progress_percentage': 100,
              },
              successMessage: 'Passenger marked as no-show',
            );
          },
          onCancel: () {
            if (modalContext.mounted) {
              Navigator.of(modalContext).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _arriveAtDropoff() async {
    if (!mounted) return;

    await _completeStandardStep(
      stepName: 'dropoff_arrival',
      apiCall: (position) async {
        if (position == null) throw Exception('GPS position required for dropoff arrival');
        
        Log.d('=== ARRIVING AT DROPOFF ===');
        Log.d('Job ID: ${widget.jobId}');
        Log.d('Trip Index: $_currentTripIndex');
        Log.d('GPS: ${position.latitude}, ${position.longitude}, ${position.accuracy}');

        await DriverFlowApiService.arriveAtDropoff(
          int.parse(widget.jobId),
          _currentTripIndex,
          gpsLat: position.latitude,
          gpsLng: position.longitude,
          gpsAccuracy: position.accuracy,
        );

        Log.d('=== DROPOFF ARRIVAL COMPLETED ===');
      },
      optimisticDataBuilder: (position) {
        final currentTime = SATimeUtils.getCurrentSATimeISO();
        return {
          'current_step': 'trip_complete',
          'progress_percentage': 67,
          'dropoff_arrive_at': currentTime,
          'last_activity_at': currentTime,
          'updated_at': currentTime,
        };
      },
      successMessage: 'Arrived at dropoff location!',
      needsGPS: true,
    );
  }

  Future<void> _completeTrip() async {
    if (!mounted) return;

    // Check if all trips will be completed after this one
    final willCompleteAllTrips = _tripProgress != null &&
        _tripProgress!.isNotEmpty &&
        _tripProgress!.where((trip) => 
          trip['trip_index'] == _currentTripIndex || trip['status'] == 'completed'
        ).length == _tripProgress!.length;

    await _completeStandardStep(
      stepName: 'trip_complete',
      apiCall: (position) async {
        if (position == null) throw Exception('GPS position required for trip completion');
        
        Log.d('=== COMPLETE TRIP ===');
        Log.d('Job ID: ${widget.jobId}');
        Log.d('Trip Index: $_currentTripIndex');
        Log.d('GPS: ${position.latitude}, ${position.longitude}, ${position.accuracy}');

        final progress = await DriverFlowApiService.completeTrip(
          int.parse(widget.jobId),
          _currentTripIndex,
          gpsLat: position.latitude,
          gpsLng: position.longitude,
          gpsAccuracy: position.accuracy,
        );

        Log.d('=== TRIP COMPLETED ===');
        return progress;
      },
      optimisticDataBuilder: (position) {
        final currentTime = SATimeUtils.getCurrentSATimeISO();
        
        if (willCompleteAllTrips) {
          // All trips completed - advance to vehicle_return
          return {
            'current_step': 'vehicle_return',
            'progress_percentage': 100,
            'transport_completed_ind': true,
            'trip_complete_at': currentTime,
            'last_activity_at': currentTime,
            'updated_at': currentTime,
          };
        } else {
          // More trips exist - reset to pickup_arrival for next trip
          final resetData = _resetForNextTrip();
          return {
            ...resetData,
            'transport_completed_ind': false,
            'trip_complete_at': currentTime,
            'last_activity_at': currentTime,
            'updated_at': currentTime,
          };
        }
      },
      successMessage: willCompleteAllTrips
          ? 'All trips completed! Proceed to vehicle return.'
          : 'Trip $_currentTripIndex completed! Proceed to next trip.',
      needsGPS: true,
    );
  }


  /// Check if vehicle return is complete (has return data)
  bool _isVehicleReturnComplete() {
    return _jobProgress != null && 
        (_jobProgress!['job_closed_odo'] != null || 
         _jobProgress!['job_closed_time'] != null);
  }

  /// Check if state is ready for rendering (prevents black screen)
  bool _isStateReady() {
    return _jobProgress != null &&
        _currentStep.isNotEmpty &&
        _jobSteps.isNotEmpty &&
        _jobSteps.any((s) => s.id == _currentStep);
  }

  /// Update step status internally (doesn't call setState - called from within setState)
  void _updateStepStatusInternal() {
    if (_jobProgress == null) {
      // Reset all steps to not completed, mark not_started as active
      for (int i = 0; i < _jobSteps.length; i++) {
        final step = _jobSteps[i];
        final isNotStarted = step.id == 'not_started';
        _jobSteps[i] = step.copyWith(
          isCompleted: false,
          isActive: isNotStarted,
        );
      }
      return;
    }

    // Update step completion status based on job progress
    for (int i = 0; i < _jobSteps.length; i++) {
      final step = _jobSteps[i];
      bool isCompleted = false;

      switch (step.id) {
        case 'not_started':
          isCompleted = _jobProgress!['vehicle_collected'] == true;
          break;
        case 'vehicle_collection':
          isCompleted = _jobProgress!['vehicle_collected'] == true;
          break;
        case 'pickup_arrival':
          isCompleted = _jobProgress!['current_step'] == 'passenger_pickup' ||
                       _jobProgress!['current_step'] == 'passenger_onboard' ||
                       _jobProgress!['current_step'] == 'dropoff_arrival' ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'passenger_pickup':
          isCompleted = _jobProgress!['current_step'] == 'passenger_onboard' ||
                       _jobProgress!['current_step'] == 'dropoff_arrival' ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'passenger_onboard':
          final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
          isCompleted = isNoShow ||
                       _jobProgress!['current_step'] == 'dropoff_arrival' ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'dropoff_arrival':
          final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
          isCompleted = isNoShow ||
                       _jobProgress!['current_step'] == 'trip_complete' ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'trip_complete':
          final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
          final transportCompleted = _jobProgress!['transport_completed_ind'] == true;
          final tripCompleteAt = _jobProgress!['trip_complete_at'];
          isCompleted = tripCompleteAt != null ||
                       (isNoShow && transportCompleted) ||
                       _jobProgress!['current_step'] == 'vehicle_return' ||
                       _jobProgress!['current_step'] == 'completed';
          break;
        case 'vehicle_return':
          isCompleted = _jobProgress!['job_closed_odo'] != null || 
                       _jobProgress!['job_closed_time'] != null;
          break;
        case 'completed':
          isCompleted = _jobProgress!['job_status'] == 'completed';
          break;
      }

      // Update the step completion status
      _jobSteps[i] = step.copyWith(
        isCompleted: isCompleted,
        isActive: step.id == _currentStep,
      );
    }
  }

  /// Update complete state atomically (all state in single setState)
  void _updateCompleteState({
    required Map<String, dynamic>? progress,
    required List<Map<String, dynamic>> trips,
    required Map<String, String?> addresses,
    String? explicitCurrentStep,
  }) {
    if (!mounted) return;

    final nextTripIndex = _findNextIncompleteTripIndex(trips);
    final newCurrentStep = explicitCurrentStep ?? 
        _determineCurrentStepFromData(progress);
    final progressPercentage = progress?['progress_percentage'] ?? 0;

    // Single atomic setState with all updates
    setState(() {
      _jobProgress = progress;
      _tripProgress = trips;
      _jobAddresses = addresses;
      _currentTripIndex = nextTripIndex;
      _currentStep = newCurrentStep;
      _progressPercentage = progressPercentage;

      // Update step status INSIDE setState to avoid extra rebuild
      _updateStepStatusInternal();
    });

    // Update step titles with addresses (doesn't call setState)
    _updateStepTitlesWithAddresses();
  }

  /// Determine current step from data (doesn't call setState)
  String _determineCurrentStepFromData(Map<String, dynamic>? progress) {
    if (progress == null) return 'not_started';

    // If vehicle return is complete, always return vehicle_return
    if (progress['job_closed_odo'] != null || progress['job_closed_time'] != null) {
      return 'vehicle_return';
    }

    // Use database current_step if available
    if (progress['current_step'] != null &&
        progress['current_step'].toString().isNotEmpty &&
        progress['current_step'].toString() != 'null') {
      return _mapDatabaseStepToUIStep(progress['current_step'].toString());
    }

    // Fallback to completion-based logic
    if (progress['job_status'] == 'completed') {
      return 'completed';
    } else if (progress['transport_completed_ind'] == true || 
               progress['trip_complete_at'] != null) {
      return 'vehicle_return';
    } else if (progress['vehicle_collected'] == true) {
      return 'pickup_arrival';
    }

    return 'not_started';
  }

  /// Complete step optimistically with background sync
  Future<void> _completeStepOptimistically({
    required String stepId,
    required Map<String, dynamic> stepData,
    bool needsServerSync = true,
  }) async {
    if (!mounted || _jobProgress == null) return;

    // Update state optimistically (immediate UI update)
    setState(() {
      _jobProgress = {
        ..._jobProgress!,
        ...stepData,
      };
      // Update step status inside setState
      _updateStepStatusInternal();
    });

    // Determine new current step if not explicitly set
    if (stepData['current_step'] == null) {
      final newStep = _determineCurrentStepFromData(_jobProgress);
      if (newStep != _currentStep) {
        setState(() {
          _currentStep = newStep;
        });
      }
    } else {
      setState(() {
        _currentStep = stepData['current_step'] as String;
      });
    }

    // Sync to server in background (non-blocking)
    if (needsServerSync) {
      _syncStepInBackground(stepId, stepData).catchError((e) {
        Log.e('Background sync failed for step $stepId: $e');
        // If sync fails, reload full state as fallback
        if (mounted) {
          _loadJobProgress(skipLoadingState: true).catchError((reloadError) {
            Log.e('Failed to reload after sync error: $reloadError');
          });
        }
      });
    }
  }

  /// Sync step completion to server in background (non-blocking)
  Future<void> _syncStepInBackground(String stepId, Map<String, dynamic> stepData) async {
    // This is a placeholder - actual sync happens via API call in step methods
    // This method can be used for additional sync operations if needed
    Log.d('Background sync for step $stepId completed');
  }

  /// Reset flow for next trip (used when more trips exist)
  Map<String, dynamic> _resetForNextTrip() {
    return {
      'current_step': 'pickup_arrival',
      'progress_percentage': 17,
      'pickup_arrive_time': null,
      'pickup_arrive_loc': null,
      'passenger_onboard_at': null,
      'dropoff_arrive_at': null,
    };
  }

  /// Recover from error - reload state and show error message
  Future<void> _recoverFromError(String errorMessage, {String? stepId}) async {
    if (!mounted) return;

    Log.d('=== RECOVERING FROM ERROR ===');
    Log.d('Step: $stepId, Error: $errorMessage');

    // Attempt to reload state
    try {
      await _loadJobProgress(skipLoadingState: true);
      Log.d('State reloaded successfully after error');
    } catch (reloadError) {
      Log.e('Failed to reload state after error: $reloadError');
    }

    // Show error message
    if (mounted) {
      SnackBarUtils.showError(context, errorMessage);
    }
  }

  /// Standard step completion template - used by all non-modal steps
  /// Pattern: Set loading -> Get GPS (if needed) -> Call API -> Optimistic update -> Background sync -> Success message
  /// If apiCall returns Map<String, dynamic>, that is used as stepData (e.g. server row for passenger_onboard).
  Future<void> _completeStandardStep({
    required String stepName,
    required Future<dynamic> Function(Position? position) apiCall,
    required Map<String, dynamic> Function(Position? position) optimisticDataBuilder,
    required String successMessage,
    bool needsGPS = true,
  }) async {
    if (!mounted) return;

    try {
      // Set loading state BEFORE API call
      setState(() => _isUpdating = true);

      // Get GPS if needed
      Position? position;
      if (needsGPS) {
        position = await _getCurrentLocation();
      }

      final result = await apiCall(position);
      final stepData = result is Map<String, dynamic> ? result : optimisticDataBuilder(position);

      await _completeStepOptimistically(
        stepId: stepName,
        stepData: stepData,
        needsServerSync: true,
      );

      // Show success message
      if (mounted) {
        SnackBarUtils.showSuccess(context, successMessage);
      }
    } catch (e) {
      Log.e('=== ERROR IN $stepName ===');
      Log.e('Error: $e');
      
      if (mounted) {
        await _recoverFromError('Failed to complete $stepName: $e', stepId: stepName);
      }
    } finally {
      // Only set _isUpdating to false if state is ready
      if (mounted) {
        if (_isStateReady()) {
          setState(() => _isUpdating = false);
        } else {
          // State not ready, try to reload
          try {
            await _loadJobProgress(skipLoadingState: true);
            if (mounted && _isStateReady()) {
              setState(() => _isUpdating = false);
            }
          } catch (reloadError) {
            Log.e('Failed to reload state before setting _isUpdating to false: $reloadError');
            // Set it anyway to prevent infinite loading
            if (mounted) {
              setState(() => _isUpdating = false);
            }
          }
        }
      }
    }
  }

  /// Modal step completion helper - used by modal-based steps
  /// Pattern: Close modal -> Set loading -> Call API -> Optimistic update -> Background sync -> Success message
  Future<void> _completeModalStep({
    required BuildContext modalContext,
    required String stepName,
    required Future<dynamic> Function() apiCall,
    required Map<String, dynamic> optimisticData,
    required String successMessage,
  }) async {
    if (!mounted) return;

    try {
      // Close modal first so overlay is visible
      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }

      // Set loading state BEFORE API call (no delay needed)
      if (mounted) {
        setState(() => _isUpdating = true);
      }

      // Call API (single call) - may return progress data
      final apiResult = await apiCall();

      // Use returned progress data if available, otherwise use optimistic data
      final finalOptimisticData = apiResult is Map<String, dynamic>
          ? {...optimisticData, ...apiResult} // Merge returned data with optimistic data
          : optimisticData;

      // Optimistic update (immediate UI feedback)
      await _completeStepOptimistically(
        stepId: stepName,
        stepData: finalOptimisticData,
        needsServerSync: true,
      );

      // Show success message
      if (mounted) {
        SnackBarUtils.showSuccess(context, successMessage);
      }
    } catch (e) {
      Log.e('=== ERROR IN $stepName ===');
      Log.e('Error: $e');

      // Close modal on error if still open
      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }

      if (mounted) {
        await _recoverFromError('Failed to complete $stepName: $e', stepId: stepName);
      }
    } finally {
      // Only set _isUpdating to false if state is ready
      if (mounted) {
        if (_isStateReady()) {
          setState(() => _isUpdating = false);
        } else {
          // State not ready, try to reload
          try {
            await _loadJobProgress(skipLoadingState: true);
            if (mounted && _isStateReady()) {
              setState(() => _isUpdating = false);
            }
          } catch (reloadError) {
            Log.e('Failed to reload state before setting _isUpdating to false: $reloadError');
            // Set it anyway to prevent infinite loading
            if (mounted) {
              setState(() => _isUpdating = false);
            }
          }
        }
      }
    }
  }

  /// Retry loading job progress with exponential backoff
  /// Returns true if successful, false if all attempts fail
  Future<bool> _retryLoadJobProgress({int maxAttempts = 3}) async {
    if (!mounted) return false;
    
    Log.d('=== STARTING RETRY LOAD JOB PROGRESS ===');
    Log.d('Max attempts: $maxAttempts');
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final delayMs = 300 * attempt; // 300ms, 600ms, 900ms
        Log.d('Retry attempt $attempt: waiting ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
        
        if (!mounted) return false;
        
        await _loadJobProgress(skipLoadingState: true);
        Log.d('Successfully reloaded progress on retry attempt $attempt');
        return true;
      } catch (retryError) {
        Log.e('Retry attempt $attempt failed: $retryError');
        if (attempt == maxAttempts) {
          Log.e('All retry attempts failed');
          return false;
        }
      }
    }
    
    return false;
  }

  Future<void> _returnVehicle() async {
    if (!mounted) return;

    // Show the vehicle return modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext modalContext) {
        return VehicleReturnModal(
          onConfirm: ({
            required double odoEndReading,
            required double gpsLat,
            required double gpsLng,
            required double gpsAccuracy,
          }) async {
            await _completeModalStep(
              modalContext: modalContext,
              stepName: 'vehicle_return',
              apiCall: () async {
                Log.d('=== RETURNING VEHICLE ===');
                Log.d('Job ID: ${widget.jobId}');
                Log.d('Odometer: $odoEndReading');
                Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

                await DriverFlowApiService.returnVehicle(
                  int.parse(widget.jobId),
                  odoEndReading: odoEndReading,
                  gpsLat: gpsLat,
                  gpsLng: gpsLng,
                  gpsAccuracy: gpsAccuracy,
                );

                Log.d('=== VEHICLE RETURN API COMPLETED ===');
              },
              optimisticData: {
                'job_closed_odo': odoEndReading,
                'job_closed_time': SATimeUtils.getCurrentSATimeISO(),
                'current_step': 'vehicle_return',
                'progress_percentage': 100,
                'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
                'updated_at': SATimeUtils.getCurrentSATimeISO(),
              },
              successMessage: 'Vehicle returned successfully! You can now add expenses and close the job.',
            );

            // Refresh jobs list to update job card status
            if (mounted) {
              ref.invalidate(jobsProvider);
            }
          },
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
    if (_isUpdating) return;

    final jobId = widget.jobId;
    final t0 = DateTime.now().millisecondsSinceEpoch;
    Log.d('_closeJob: tapped jobId=$jobId current_step=${_jobProgress?['current_step']}');

    try {
      if (!mounted) return;
      setState(() => _isUpdating = true);

      final progress = await DriverFlowApiService.closeJob(int.parse(jobId));
      final t1 = DateTime.now().millisecondsSinceEpoch;
      Log.d('_closeJob: closeJob API took ${t1 - t0}ms');

      if (!mounted) return;
      if (progress != null) {
        setState(() {
          _jobProgress = progress;
          _currentStep = 'completed';
          _progressPercentage = 100;
          _updateStepStatusInternal();
        });
      } else {
        await _loadJobProgress(skipLoadingState: true);
      }

      if (!mounted) return;
      ref.invalidate(jobsProvider);

      if (!mounted) return;
      showJobCompletionDialog(
        context,
        jobNumber: widget.job.jobNumber ?? 'Unknown',
        passengerName: widget.job.passengerName,
        onDismiss: () {
          if (mounted) context.go('/jobs');
        },
      );
      Log.d('_closeJob: total to dialog ${DateTime.now().millisecondsSinceEpoch - t0}ms');
    } catch (e) {
      Log.e('_closeJob: error jobId=$jobId: $e');
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      if (mounted) {
        SnackBarUtils.showError(context, msg.length > 100 ? 'Failed to close job. Please try again.' : msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
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
            onPressed: _isUpdating ? null : _startJob,
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
              onPressed: _isUpdating ? null : _startJob,
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
        // Check if passenger was already marked as no-show
        final isNoShow = _jobProgress != null && 
            (_jobProgress!['passenger_no_show_ind'] == true);
        
        // Check if pickup_arrival is completed
        final pickupArrivalCompleted = _isPreviousStepCompleted('pickup_arrival');
        
        // Show buttons if pickup_arrival is completed and passenger is not marked as no-show
        if (!step.isCompleted && pickupArrivalCompleted && !isNoShow) {
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
        } else if (!pickupArrivalCompleted) {
          return _buildStepLockedMessage('Complete arrival at pickup first');
        } else if (isNoShow) {
          // Passenger was marked as no-show, show message
          return _buildStepCompletedMessage('Passenger marked as no-show');
        }
        break;

      case 'passenger_onboard':
        // Check if passenger was already marked as no-show
        final isNoShow = _jobProgress != null && 
            (_jobProgress!['passenger_no_show_ind'] == true);
        
        // Check if passenger_pickup step is completed (previous step)
        final passengerPickupCompleted = _isPreviousStepCompleted('passenger_pickup');
        
        // Only show button if previous step (passenger_pickup) is completed
        if (!step.isCompleted && passengerPickupCompleted && !isNoShow) {
          return _buildLuxuryButton(
            onPressed: _isUpdating ? null : () => _arriveAtDropoff(), // Disable during processing
            icon: Icons.location_on_rounded,
            label: 'Arrive at Dropoff',
            isPrimary: false,
          );
        } else if (!passengerPickupCompleted) {
          return _buildStepLockedMessage('Complete pickup point first');
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
        // NULL SAFETY: If _jobProgress is null, show loading indicator
        if (_jobProgress == null) {
          Log.e('_jobProgress is null in vehicle_return step, showing loading indicator');
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ChoiceLuxTheme.richGold,
                ),
              ),
            ),
          );
        }
        
        // Check if trip_complete step is completed first (or no-show)
        final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
        final tripCompleted = _isPreviousStepCompleted('trip_complete');
        
        // CRITICAL: Check if ALL trips are completed before allowing vehicle return
        final allTripsCompleted = _jobProgress!['transport_completed_ind'] == true;
        
        if (!tripCompleted && !isNoShow) {
          return _buildStepLockedMessage('Complete trip first');
        }
        
        // If trip is completed but not all trips are completed, show message
        if (tripCompleted && !allTripsCompleted && !isNoShow) {
          return _buildStepLockedMessage('Complete all trips before returning vehicle');
        }
        
        // Check if vehicle is already returned (job_closed_odo or job_closed_time is set)
        final vehicleReturned = _jobProgress!['job_closed_odo'] != null || 
            _jobProgress!['job_closed_time'] != null;
        
        // Check if job is already closed
        final jobClosed = _jobProgress!['job_status'] == 'completed';
        
        if (!vehicleReturned) {
          // Only show button if all trips are completed (or no-show)
          if (!allTripsCompleted && !isNoShow) {
            return _buildStepLockedMessage('Complete all trips before returning vehicle');
          }
          
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

    // Special case for trip_complete: Check actual completion indicators, not just step flag
    // This ensures the flow works even if current_step hasn't advanced yet
    if (stepId == 'trip_complete' && _jobProgress != null) {
      final tripCompleteAt = _jobProgress!['trip_complete_at'];
      final isNoShow = _jobProgress!['passenger_no_show_ind'] == true;
      final transportCompleted = _jobProgress!['transport_completed_ind'] == true;
      final currentStep = _jobProgress!['current_step'];
      
      // Trip is completed if trip_complete_at is set, or if we've moved beyond this step
      return tripCompleteAt != null ||
             (isNoShow && transportCompleted) ||
             currentStep == 'vehicle_return' ||
             currentStep == 'completed';
    }

    // For other steps, check if the step is completed
    return _jobSteps[stepIndex].isCompleted;
  }

  /// Find the next incomplete trip index
  /// Returns the trip_index of the first trip that is not completed
  /// If all trips are completed, returns the last trip's index
  /// If no trips exist, returns 1 as default
  int _findNextIncompleteTripIndex(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) {
      Log.d('No trips found, defaulting to trip index 1');
      return 1;
    }
    
    // Find first trip with status != 'completed'
    try {
      final incompleteTrip = trips.firstWhere(
        (trip) => trip['status'] != 'completed',
        orElse: () => trips.last, // If all completed, use last trip
      );
      
      final tripIndex = incompleteTrip['trip_index'] as int;
      Log.d('Found next incomplete trip: index $tripIndex, status: ${incompleteTrip['status']}');
      return tripIndex;
    } catch (e) {
      Log.e('Error finding next incomplete trip: $e');
      // Fallback to first trip
      return trips.first['trip_index'] as int? ?? 1;
    }
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
    
    // STATE VALIDATION: Prevent black screen if widget is in invalid state
    // If we're loading/updating and have no data, show loading indicator instead of empty screen
    if ((_isLoading || _isUpdating) && _jobProgress == null && _tripProgress == null) {
      Log.d('Widget in loading/updating state with no data, showing loading indicator');
      return Scaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                ChoiceLuxTheme.richGold,
              ),
            ),
          ),
        ),
      );
    }
    
    // Additional validation: If we have jobProgress but no valid steps, show loading
    // This prevents black screen when state is inconsistent
    if (_jobProgress != null && _jobSteps.isEmpty) {
      Log.d('Widget has jobProgress but no steps, showing loading indicator');
      return Scaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                ChoiceLuxTheme.richGold,
              ),
            ),
          ),
        ),
      );
    }
    
    // Additional validation: If state is not ready, show loading
    if (!_isStateReady() && (_isLoading || _isUpdating)) {
      Log.d('Widget state not ready, showing loading indicator');
      return Scaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                ChoiceLuxTheme.richGold,
              ),
            ),
          ),
        ),
      );
    }
    if (_jobProgress != null && _jobSteps.isEmpty && !_isLoading && !_isUpdating) {
      Log.d('Widget has jobProgress but no steps, showing loading indicator');
      return Scaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                ChoiceLuxTheme.richGold,
              ),
            ),
          ),
        ),
      );
    }
    
    // Match dashboard background (solid color, no pattern)
    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen (solid obsidian to match dashboard)
        Container(
          color: ChoiceLuxTheme.jetBlack,
        ),
        // Layer 2: Loading overlay when updating
        // Standardized to match action button loading style (20x20, strokeWidth: 2, no text)
        if (_isUpdating)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ChoiceLuxTheme.richGold,
                  ),
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
              child: (_isLoading == true || (_isUpdating && _jobProgress == null))
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ChoiceLuxTheme.richGold,
                              ),
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
                                onPressed: _startJob,
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

