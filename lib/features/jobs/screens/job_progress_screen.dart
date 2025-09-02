import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';

import 'package:choice_lux_cars/features/jobs/widgets/gps_capture_widget.dart';
import 'package:choice_lux_cars/features/jobs/widgets/odometer_capture_widget.dart';
import 'package:choice_lux_cars/features/jobs/widgets/vehicle_collection_modal.dart';
import 'package:choice_lux_cars/features/jobs/widgets/vehicle_return_modal.dart';
import 'package:choice_lux_cars/features/jobs/widgets/address_display_widget.dart';
import 'package:choice_lux_cars/features/jobs/models/job_step.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/shared/utils/status_color_utils.dart';
import 'package:choice_lux_cars/shared/utils/date_utils.dart';
import 'package:choice_lux_cars/shared/utils/driver_flow_utils.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_button.dart';
import 'package:choice_lux_cars/shared/widgets/job_completion_dialog.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

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

  Future<void> _loadJobProgress() async {
    try {
      setState(() => _isLoading = true);

      // Parse job ID once and validate
      final jobIdInt = int.tryParse(widget.jobId);
      if (jobIdInt == null) {
        throw Exception('Invalid job ID: ${widget.jobId}');
      }

      // Load job progress
      final progress = await DriverFlowApiService.getJobProgress(jobIdInt);
      Log.d('=== LOADED JOB PROGRESS ===');
      Log.d('Progress data: $progress');
      Log.d('Vehicle collected: ${progress['vehicle_collected']}');
      Log.d('Current step from DB: ${progress['current_step']}');
      Log.d('Job status: ${progress['job_status']}');

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
        _currentTripIndex = progress['current_trip_index'] ?? 1;
        _progressPercentage = progress['progress_percentage'] ?? 0;
      });

      // Update step statuses
      _updateStepStatus();

      // Determine current step
      _determineCurrentStep();

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
        setState(() {
          _isLoading = false;
        });
      }

      // Force a final UI update to ensure all changes are reflected
      if (mounted) {
        setState(() {
          // This ensures the UI reflects the latest step progression
        });

        // Add a small delay and force another rebuild to ensure UI updates
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              // Force another rebuild
            });
            _debugCurrentState();
          }
        });
      }
    } catch (e) {
      Log.e('ERROR in _loadJobProgress: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarUtils.showError(context, 'Failed to load job progress: $e');
      }
    }
  }

  void _updateStepStatus() {
    if (_jobProgress == null) return;

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
          break;
        case 'pickup_arrival':
          // Pickup arrival is completed if any trip has pickup_arrived_at
          // Once completed, it cannot be undone
          isCompleted =
              _tripProgress?.any((trip) => trip['pickup_arrived_at'] != null) ??
              false;
          break;
        case 'passenger_onboard':
          // Passenger onboard is completed if any trip has passenger_onboard_at
          // Once completed, it cannot be undone
          isCompleted =
              _tripProgress?.any(
                (trip) => trip['passenger_onboard_at'] != null,
              ) ??
              false;
          break;
        case 'dropoff_arrival':
          // Dropoff arrival is completed if any trip has dropoff_arrived_at
          // Once completed, it cannot be undone
          isCompleted =
              _tripProgress?.any(
                (trip) => trip['dropoff_arrived_at'] != null,
              ) ??
              false;
          break;
        case 'trip_complete':
          // Trip complete is completed if any trip has status 'completed'
          // Once completed, it cannot be undone
          isCompleted =
              _tripProgress?.any((trip) => trip['status'] == 'completed') ??
              false;
          break;
        case 'vehicle_return':
          // Vehicle return is completed if job_closed_time is set
          // Once completed, it cannot be undone
          isCompleted = _jobProgress!['job_closed_time'] != null;
          break;
        case 'completed':
          // Job completion step is always completed when reached
          isCompleted = true;
          break;
      }

      // Update the step completion status
      _jobSteps[i] = step.copyWith(isCompleted: isCompleted);

      // Debug logging for step completion
      Log.d('Step ${step.id}: isCompleted = $isCompleted');
    }

    // Update step titles with addresses
    _updateStepTitlesWithAddresses();
  }

  void _updateStepTitlesWithAddresses() {
    for (int i = 0; i < _jobSteps.length; i++) {
      final step = _jobSteps[i];
      String newTitle = step.title;

      switch (step.id) {
        case 'pickup_arrival':
          final pickupAddress = _jobAddresses['pickup'];
          if (pickupAddress != null && pickupAddress.isNotEmpty) {
            newTitle = 'Arrive at Pickup - $pickupAddress';
          }
          break;
        case 'dropoff_arrival':
          final dropoffAddress = _jobAddresses['dropoff'];
          if (dropoffAddress != null && dropoffAddress.isNotEmpty) {
            newTitle = 'Arrive at Dropoff - $dropoffAddress';
          }
          break;
      }

      if (newTitle != step.title) {
        _jobSteps[i] = step.copyWith(title: newTitle);
      }
    }
  }

  void _determineCurrentStep() {
    if (_jobProgress == null) return;

    // Debug logging
    Log.d('=== DETERMINING CURRENT STEP ===');
    Log.d('Vehicle collected: ${_jobProgress!['vehicle_collected']}');
    Log.d('Current step from DB: ${_jobProgress!['current_step']}');
    Log.d('Trip progress: $_tripProgress');
    Log.d('Job closed time: ${_jobProgress!['job_closed_time']}');

    String newCurrentStep = 'not_started'; // Default to not started

    // Priority 1: Check if job has actually started
    if (_jobProgress!['vehicle_collected'] == false &&
        _jobProgress!['current_step'] == null) {
      newCurrentStep = 'not_started';
      Log.d('Job has not started yet - showing as not started');
    }
    // Priority 2: Trust the database current_step if it exists and is valid
    else if (_jobProgress!['current_step'] != null &&
        _jobProgress!['current_step'].toString().isNotEmpty &&
        _jobProgress!['current_step'].toString() != 'null' &&
        _jobProgress!['current_step'].toString() != 'completed') {
      newCurrentStep = _jobProgress!['current_step'].toString();
      Log.d('Using current step from DB: $newCurrentStep');
    } else {
      // Priority 3: Determine step based on completion status
      Log.d('No valid current_step in DB, using completion-based logic');

      if (_jobProgress!['job_closed_time'] != null) {
        newCurrentStep = 'completed';
        Log.d('Job is completed');
      } else if (_tripProgress?.any((trip) => trip['status'] == 'completed') ==
          true) {
        newCurrentStep = 'vehicle_return';
        Log.d('Trip completed, moving to vehicle return');
      } else if (_tripProgress?.any(
            (trip) => trip['dropoff_arrived_at'] != null,
          ) ==
          true) {
        newCurrentStep = 'trip_complete';
        Log.d('Dropoff arrived, moving to trip complete');
      } else if (_tripProgress?.any(
            (trip) => trip['passenger_onboard_at'] != null,
          ) ==
          true) {
        newCurrentStep = 'dropoff_arrival';
        Log.d('Passenger onboard, moving to dropoff arrival');
      } else if (_tripProgress?.any(
            (trip) => trip['pickup_arrived_at'] != null,
          ) ==
          true) {
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
      Log.d('Step changed from $_currentStep to $newCurrentStep');
      setState(() {
        _currentStep = newCurrentStep;
      });
    } else {
      Log.d('Step unchanged: $_currentStep');
    }

    // Force a rebuild of the step status to ensure UI updates
    _updateStepStatus();
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
              }) async {
                // Store the modal context before any async operations
                final modalContext = context;

                try {
                  setState(() => _isUpdating = true);

                  Log.d('=== STARTING JOB ===');
                  Log.d('Job ID: ${widget.jobId}');
                  Log.d('Odometer: $odometerReading');
                  Log.d('Image URL: $odometerImageUrl');
                  Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

                  await DriverFlowApiService.startJob(
                    int.parse(widget.jobId),
                    odoStartReading: odometerReading,
                    pdpStartImage: odometerImageUrl,
                    gpsLat: gpsLat,
                    gpsLng: gpsLng,
                    gpsAccuracy: gpsAccuracy,
                  );

                  Log.d('=== JOB STARTED SUCCESSFULLY ===');
                  Log.d('Now loading job progress...');

                  // Add a longer delay to ensure database update is reflected
                  await Future.delayed(const Duration(milliseconds: 1000));

                  if (mounted) {
                    await _loadJobProgress();
                    Log.d('=== JOB PROGRESS LOADED ===');
                    Log.d('Current step after reload: $_currentStep');

                    // Force a UI rebuild to ensure step progression is visible
                    if (mounted) {
                      setState(() {
                        // This will trigger a rebuild and ensure the UI updates
                        // Force rebuild by updating a dummy variable
                        _isLoading = _isLoading;
                      });
                    }

                    // Add another small delay to ensure UI updates are processed
                    await Future.delayed(const Duration(milliseconds: 200));

                    // Force another reload to ensure we have the latest data
                    if (mounted) {
                      await _loadJobProgress();
                      Log.d('=== SECOND RELOAD COMPLETE ===');
                      Log.d('Final current step: $_currentStep');
                    }

                    // Close the modal using the stored context
                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop();
                    }

                    // Show success message after modal is closed and widget is still mounted
                    if (mounted) {
                      SnackBarUtils.showSuccess(
                        context,
                        'Job started successfully!',
                      );
                    }
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
      setState(() => _isUpdating = true);

      final position = await _getCurrentLocation();

      await DriverFlowApiService.collectVehicle(
        int.parse(widget.jobId),
        gpsLat: position.latitude,
        gpsLng: position.longitude,
        gpsAccuracy: position.accuracy,
      );

      if (mounted) {
        await _loadJobProgress();
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
      setState(() => _isUpdating = true);

      // Get current location
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
        await _loadJobProgress();
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

      await DriverFlowApiService.passengerOnboard(
        int.parse(widget.jobId),
        _currentTripIndex,
      );

      if (mounted) {
        await _loadJobProgress();
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
        await _loadJobProgress();
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

      await DriverFlowApiService.completeTrip(
        int.parse(widget.jobId),
        _currentTripIndex,
      );

      if (mounted) {
        await _loadJobProgress();
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
                required String pdpEndImage,
                required double gpsLat,
                required double gpsLng,
                required double gpsAccuracy,
              }) async {
                try {
                  setState(() => _isUpdating = true);

                  Log.d('=== RETURNING VEHICLE ===');
                  Log.d('Job ID: ${widget.jobId}');
                  Log.d('Odometer: $odoEndReading');
                  Log.d('Image: $pdpEndImage');
                  Log.d('GPS: $gpsLat, $gpsLng, $gpsAccuracy');

                  await DriverFlowApiService.returnVehicle(
                    int.parse(widget.jobId),
                    odoEndReading: odoEndReading,
                    pdpEndImage: pdpEndImage,
                    gpsLat: gpsLat,
                    gpsLng: gpsLng,
                    gpsAccuracy: gpsAccuracy,
                  );

                  Log.d('=== VEHICLE RETURN COMPLETED ===');

                  if (mounted) {
                    await _loadJobProgress();

                    // Close the modal using the stored context
                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop();
                    }

                    // Show success message after modal is closed and widget is still mounted
                    if (mounted) {
                      // Refresh jobs list to update job card status
                      ref.invalidate(jobsProvider);

                      // Show job completion dialog
                      showJobCompletionDialog(
                        context,
                        jobNumber: widget.job.jobNumber ?? 'Unknown',
                        passengerName: widget.job.passengerName,
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
    try {
      setState(() => _isUpdating = true);

      await DriverFlowApiService.closeJob(int.parse(widget.jobId));

      await _loadJobProgress();

      // Refresh jobs list to update job card status
      ref.invalidate(jobsProvider);

      // Show job completion dialog
      showJobCompletionDialog(
        context,
        jobNumber: widget.job.jobNumber ?? 'Unknown',
        passengerName: widget.job.passengerName,
      );
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to close job: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
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
        await _loadJobProgress();

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
      await _loadJobProgress();

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
            onPressed: _arriveAtPickup,
            icon: Icons.location_on_rounded,
            label: 'Arrive at Pickup',
            isPrimary: false,
          );
        } else if (!_isPreviousStepCompleted('vehicle_collection')) {
          return _buildStepLockedMessage('Complete vehicle collection first');
        }
        break;

      case 'passenger_onboard':
        // Only show button if previous step (pickup_arrival) is completed
        if (!step.isCompleted && _isPreviousStepCompleted('pickup_arrival')) {
          return _buildLuxuryButton(
            onPressed: _passengerOnboard,
            icon: Icons.person_add_rounded,
            label: 'Passenger Onboard',
            isPrimary: false,
          );
        } else if (!_isPreviousStepCompleted('pickup_arrival')) {
          return _buildStepLockedMessage('Arrive at pickup location first');
        }
        break;

      case 'dropoff_arrival':
        // Only show button if previous step (passenger_onboard) is completed
        if (!step.isCompleted &&
            _isPreviousStepCompleted('passenger_onboard')) {
          return _buildLuxuryButton(
            onPressed: _arriveAtDropoff,
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
            onPressed: _completeTrip,
            icon: Icons.check_circle_rounded,
            label: 'Complete Trip',
            isPrimary: false,
          );
        } else if (!_isPreviousStepCompleted('dropoff_arrival')) {
          return _buildStepLockedMessage('Arrive at dropoff location first');
        }
        break;

      case 'vehicle_return':
        // Only show button if previous step (trip_complete) is completed
        if (!step.isCompleted && _isPreviousStepCompleted('trip_complete')) {
          return _buildLuxuryButton(
            onPressed: _returnVehicle,
            icon: Icons.home_rounded,
            label: 'Return Vehicle',
            isPrimary: false,
          );
        } else if (!_isPreviousStepCompleted('trip_complete')) {
          return _buildStepLockedMessage('Complete trip first');
        } else {
          return _buildLuxuryButton(
            onPressed: _closeJob,
            icon: Icons.done_all_rounded,
            label: 'Close Job',
            isPrimary: true,
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
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChoiceLuxTheme.richGold,
              ChoiceLuxTheme.richGold.withOpacity(0.9),
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
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.black, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
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
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
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
                  'Job Progress - ${widget.job.jobNumber}',
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
                        'Status: ${_jobProgress?['job_status'] ?? 'Unknown'}',
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

    final currentStep = _jobSteps.firstWhere(
      (step) => step.id == _currentStep,
      orElse: () => _jobSteps.first,
    );

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
    return Scaffold(
      backgroundColor: ChoiceLuxTheme.jetBlack,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildLuxuryAppBar(),
      ),
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: ChoiceLuxTheme.backgroundGradient,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ChoiceLuxTheme.richGold,
                  ),
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: ChoiceLuxTheme.backgroundGradient,
              ),
              child: RefreshIndicator(
                onRefresh: _loadJobProgress,
                color: ChoiceLuxTheme.richGold,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLuxuryJobInfoCard(),
                      const SizedBox(height: 24),
                      _buildLuxuryCurrentStepCard(),
                      const SizedBox(height: 24),
                      _buildLuxuryTimeline(),
                      const SizedBox(height: 24),

                      // Trip Progress (if available)
                      if (_tripProgress != null &&
                          _tripProgress!.isNotEmpty) ...[
                        Container(
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
                                      Icons.route_rounded,
                                      color: ChoiceLuxTheme.richGold,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Trip Progress',
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
                                ..._tripProgress!.map((trip) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: ChoiceLuxTheme.jetBlack
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: ChoiceLuxTheme.platinumSilver
                                            .withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: ChoiceLuxTheme.richGold
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${trip['trip_index']}',
                                              style: const TextStyle(
                                                color: ChoiceLuxTheme.richGold,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Trip ${trip['trip_index']}',
                                                style: const TextStyle(
                                                  color:
                                                      ChoiceLuxTheme.softWhite,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Status: ${trip['status'] ?? 'pending'}',
                                                style: TextStyle(
                                                  color: ChoiceLuxTheme
                                                      .platinumSilver,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          _getTripStatusIcon(trip['status']),
                                          color: _getTripStatusColor(
                                            trip['status'],
                                          ),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  IconData _getTripStatusIcon(String? status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'onboard':
        return Icons.person_rounded;
      case 'dropoff_arrived':
        return Icons.location_on_rounded;
      case 'pickup_arrived':
        return Icons.location_on_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  Color _getTripStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return ChoiceLuxTheme.successColor;
      case 'onboard':
        return ChoiceLuxTheme.richGold;
      case 'dropoff_arrived':
        return ChoiceLuxTheme.richGold;
      case 'pickup_arrived':
        return ChoiceLuxTheme.richGold;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }
}
