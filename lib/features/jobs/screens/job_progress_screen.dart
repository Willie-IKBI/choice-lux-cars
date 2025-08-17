import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/driver_flow_api_service.dart';
import '../models/job.dart';
import '../models/trip.dart';
import '../widgets/step_indicator.dart';
import '../widgets/progress_bar.dart';
import '../widgets/gps_capture_widget.dart';
import '../widgets/odometer_capture_widget.dart';
import '../widgets/vehicle_collection_modal.dart';
import '../widgets/pickup_arrival_modal.dart';
import '../models/job_step.dart';
import '../providers/jobs_provider.dart';
import '../../../app/theme.dart';

class JobProgressScreen extends ConsumerStatefulWidget {
  final String jobId;
  final Job job;

  const JobProgressScreen({
    Key? key,
    required this.jobId,
    required this.job,
  }) : super(key: key);

  @override
  ConsumerState<JobProgressScreen> createState() => _JobProgressScreenState();
}

class _JobProgressScreenState extends ConsumerState<JobProgressScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;
  Map<String, dynamic>? _jobProgress;
  List<Map<String, dynamic>>? _tripProgress;
  String _currentStep = 'vehicle_collection';
  int _currentTripIndex = 1;
  int _progressPercentage = 0;
  
  // Store references to avoid ancestor lookup issues
  JobsNotifier? _jobsNotifier;

  final List<JobStep> _jobSteps = [
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
      print('=== LOADED JOB PROGRESS ===');
      print('Progress data: $progress');
      print('Vehicle collected: ${progress['vehicle_collected']}');
      print('Current step from DB: ${progress['current_step']}');
      print('Job status: ${progress['job_status']}');
      
      // Load trip progress
      final trips = await DriverFlowApiService.getTripProgress(jobIdInt);
      print('=== LOADED TRIP PROGRESS ===');
      print('Trip data: $trips');
      
      setState(() {
        _jobProgress = progress;
        _tripProgress = trips;
        _currentTripIndex = progress['current_trip_index'] ?? 1;
        _progressPercentage = progress['progress_percentage'] ?? 0;
        _isLoading = false;
      });
      
      // Update step status and determine current step
      print('=== UPDATING STEP STATUS ===');
      _updateStepStatus();
      print('=== DETERMINING CURRENT STEP ===');
      _determineCurrentStep();
      print('=== FINAL STATE ===');
      print('Current step: $_currentStep');
      print('Vehicle collection completed: ${_jobSteps.firstWhere((step) => step.id == 'vehicle_collection').isCompleted}');
      print('Pickup arrival completed: ${_jobSteps.firstWhere((step) => step.id == 'pickup_arrival').isCompleted}');
      
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
      print('ERROR in _loadJobProgress: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load job progress: $e');
    }
  }

  void _updateStepStatus() {
    if (_jobProgress == null) return;

    // Update step completion status based on job progress
    for (int i = 0; i < _jobSteps.length; i++) {
      final step = _jobSteps[i];
      bool isCompleted = false;

      switch (step.id) {
        case 'vehicle_collection':
          // Vehicle collection is completed only if vehicle_collected is true
          isCompleted = _jobProgress!['vehicle_collected'] == true;
          break;
        case 'pickup_arrival':
          isCompleted = _tripProgress?.any((trip) => 
            trip['pickup_arrived_at'] != null) ?? false;
          break;
        case 'passenger_onboard':
          isCompleted = _tripProgress?.any((trip) => 
            trip['passenger_onboard_at'] != null) ?? false;
          break;
        case 'dropoff_arrival':
          isCompleted = _tripProgress?.any((trip) => 
            trip['dropoff_arrived_at'] != null) ?? false;
          break;
        case 'trip_complete':
          isCompleted = _tripProgress?.any((trip) => 
            trip['status'] == 'completed') ?? false;
          break;
        case 'vehicle_return':
          isCompleted = _jobProgress!['job_closed_time'] != null;
          break;
      }

      _jobSteps[i] = step.copyWith(isCompleted: isCompleted);
    }
  }

  void _determineCurrentStep() {
    if (_jobProgress == null) return;

    // Debug logging
    print('=== DETERMINING CURRENT STEP ===');
    print('Vehicle collected: ${_jobProgress!['vehicle_collected']}');
    print('Current step from DB: ${_jobProgress!['current_step']}');
    print('Trip progress: $_tripProgress');
    print('Job closed time: ${_jobProgress!['job_closed_time']}');

    String newCurrentStep = 'vehicle_collection'; // Default

    // Priority 1: Trust the database current_step if it exists and is valid
    if (_jobProgress!['current_step'] != null && 
        _jobProgress!['current_step'].toString().isNotEmpty &&
        _jobProgress!['current_step'].toString() != 'null') {
      newCurrentStep = _jobProgress!['current_step'].toString();
      print('Using current step from DB: $newCurrentStep');
    } else {
      // Priority 2: Simple fallback logic based on vehicle collection status
      print('No valid current_step in DB, using simple fallback logic');
      
      if (_jobProgress!['vehicle_collected'] == true) {
        newCurrentStep = 'pickup_arrival';
        print('Vehicle collected, setting to pickup_arrival');
      } else {
        newCurrentStep = 'vehicle_collection';
        print('Vehicle not collected, setting to vehicle_collection');
      }
    }

    print('Final current step: $newCurrentStep');
    
    // Update the current step if it changed
    if (_currentStep != newCurrentStep) {
      print('Step changed from $_currentStep to $newCurrentStep');
      setState(() {
        _currentStep = newCurrentStep;
      });
    } else {
      print('Step unchanged: $_currentStep');
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
          onConfirm: (({
            required double odometerReading,
            required String odometerImageUrl,
            required double gpsLat,
            required double gpsLng,
            required double gpsAccuracy,
          }) async {
            try {
              setState(() => _isUpdating = true);
              
              print('=== STARTING JOB ===');
              print('Job ID: ${widget.jobId}');
              print('Odometer: $odometerReading');
              print('Image URL: $odometerImageUrl');
              print('GPS: $gpsLat, $gpsLng, $gpsAccuracy');
               
              await DriverFlowApiService.startJob(
                int.parse(widget.jobId),
                odoStartReading: odometerReading,
                pdpStartImage: odometerImageUrl,
                gpsLat: gpsLat,
                gpsLng: gpsLng,
                gpsAccuracy: gpsAccuracy,
                onJobStarted: () {
                  // Refresh the jobs list so the job appears in "In Progress" filter
                  if (mounted && _jobsNotifier != null) {
                    _jobsNotifier!.fetchJobs();
                  }
                },
              );
               
              print('=== JOB STARTED SUCCESSFULLY ===');
              print('Now loading job progress...');
               
              if (mounted) {
                // Add a small delay to ensure database update is reflected
                await Future.delayed(const Duration(milliseconds: 500));
                
                await _loadJobProgress();
                print('=== JOB PROGRESS LOADED ===');
                print('Current step after reload: $_currentStep');
                
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
                  print('=== SECOND RELOAD COMPLETE ===');
                  print('Final current step: $_currentStep');
                }
                
                // Close the modal first
                Navigator.of(context).pop();
                
                // Show success message after modal is closed and widget is still mounted
                if (mounted) {
                  _showSuccessSnackBar('Job started successfully!');
                }
              }
            } catch (e) {
              if (mounted) {
                // Close the modal first
                Navigator.of(context).pop();
                
                // Show error message after modal is closed and widget is still mounted
                if (mounted) {
                  _showErrorSnackBar('Failed to start job: $e');
                }
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
        _showSuccessSnackBar('Vehicle collected successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to collect vehicle: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _arriveAtPickup() async {
    if (!mounted) return;
    
    // Show the pickup arrival modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PickupArrivalModal(
          onConfirm: (({
            required double gpsLat,
            required double gpsLng,
            required double gpsAccuracy,
          }) async {
            try {
              setState(() => _isUpdating = true);
              
              await DriverFlowApiService.arriveAtPickup(
                int.parse(widget.jobId),
                _currentTripIndex,
                gpsLat: gpsLat,
                gpsLng: gpsLng,
                gpsAccuracy: gpsAccuracy,
              );
              
              if (mounted) {
                await _loadJobProgress();
                
                // Close the modal first
                Navigator.of(context).pop();
                
                // Show success message after modal is closed and widget is still mounted
                if (mounted) {
                  _showSuccessSnackBar('Arrived at pickup location!');
                }
              }
            } catch (e) {
              if (mounted) {
                // Close the modal first
                Navigator.of(context).pop();
                
                // Show error message after modal is closed and widget is still mounted
                if (mounted) {
                  _showErrorSnackBar('Failed to record pickup arrival: $e');
                }
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
        _showSuccessSnackBar('Passenger onboard!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to record passenger onboard: $e');
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
        _showSuccessSnackBar('Arrived at dropoff location!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to record dropoff arrival: $e');
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
        _showSuccessSnackBar('Trip completed!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to complete trip: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _returnVehicle() async {
    try {
      setState(() => _isUpdating = true);
      
      final position = await _getCurrentLocation();
      final odometerImage = await _captureOdometerImage();
      
      await DriverFlowApiService.returnVehicle(
        int.parse(widget.jobId),
        odoEndReading: 0.0, // This should be captured from odometer widget
        pdpEndImage: odometerImage,
        gpsLat: position.latitude,
        gpsLng: position.longitude,
        gpsAccuracy: position.accuracy,
      );
      
      await _loadJobProgress();
      _showSuccessSnackBar('Vehicle returned!');
    } catch (e) {
      _showErrorSnackBar('Failed to return vehicle: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _closeJob() async {
    try {
      setState(() => _isUpdating = true);
      
      await DriverFlowApiService.closeJob(int.parse(widget.jobId));
      
      await _loadJobProgress();
      _showSuccessSnackBar('Job closed successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to close job: $e');
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

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ChoiceLuxTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      print('Error showing success snackbar: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ChoiceLuxTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      print('Error showing error snackbar: $e');
    }
  }

  void _debugCurrentState() {
    print('=== DEBUG CURRENT STATE ===');
    print('Current step: $_currentStep');
    print('Job progress: $_jobProgress');
    print('Trip progress: $_tripProgress');
    print('Vehicle collected: ${_jobProgress?['vehicle_collected']}');
    print('Current step from DB: ${_jobProgress?['current_step']}');
    
    for (int i = 0; i < _jobSteps.length; i++) {
      final step = _jobSteps[i];
      print('Step ${i + 1}: ${step.id} - Completed: ${step.isCompleted}');
    }
    print('=== END DEBUG ===');
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

    switch (step.id) {
      case 'vehicle_collection':
        if (!step.isCompleted) {
          return _buildLuxuryButton(
            onPressed: _startJob,
            icon: Icons.play_arrow_rounded,
            label: 'Start Job',
            isPrimary: true,
          );
        }
        break;
        
      case 'pickup_arrival':
        if (!step.isCompleted) {
          return _buildLuxuryButton(
            onPressed: _arriveAtPickup,
            icon: Icons.location_on_rounded,
            label: 'Arrive at Pickup',
            isPrimary: false,
          );
        }
        break;
        
      case 'passenger_onboard':
        if (!step.isCompleted) {
          return _buildLuxuryButton(
            onPressed: _passengerOnboard,
            icon: Icons.person_add_rounded,
            label: 'Passenger Onboard',
            isPrimary: false,
          );
        }
        break;
        
      case 'dropoff_arrival':
        if (!step.isCompleted) {
          return _buildLuxuryButton(
            onPressed: _arriveAtDropoff,
            icon: Icons.location_on_rounded,
            label: 'Arrive at Dropoff',
            isPrimary: false,
          );
        }
        break;
        
      case 'trip_complete':
        if (!step.isCompleted) {
          return _buildLuxuryButton(
            onPressed: _completeTrip,
            icon: Icons.check_circle_rounded,
            label: 'Complete Trip',
            isPrimary: false,
          );
        }
        break;
        
      case 'vehicle_return':
        if (!step.isCompleted) {
          return _buildLuxuryButton(
            onPressed: _returnVehicle,
            icon: Icons.home_rounded,
            label: 'Return Vehicle',
            isPrimary: false,
          );
        } else {
          return _buildLuxuryButton(
            onPressed: _closeJob,
            icon: Icons.done_all_rounded,
            label: 'Close Job',
            isPrimary: true,
          );
        }
    }

    return const SizedBox.shrink();
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
            ProgressBar(
              progress: _progressPercentage,
              height: 8,
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
                               ? LinearGradient(
                                   colors: [
                                     ChoiceLuxTheme.richGold,
                                     ChoiceLuxTheme.richGold.withOpacity(0.8),
                                   ],
                                 )
                               : isCompleted
                                   ? LinearGradient(
                                       colors: [
                                         ChoiceLuxTheme.successColor,
                                         ChoiceLuxTheme.successColor.withOpacity(0.8),
                                       ],
                                     )
                                   : null,
                          color: isCurrentStep || isCompleted
                              ? null
                              : ChoiceLuxTheme.charcoalGray,
                          border: Border.all(
                            color: isCurrentStep
                                ? ChoiceLuxTheme.richGold
                                : isCompleted
                                    ? ChoiceLuxTheme.successColor
                                    : ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_rounded
                              : step.icon,
                          color: isCurrentStep || isCompleted
                              ? Colors.black
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
                                        ? ChoiceLuxTheme.richGold
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
                                      color: ChoiceLuxTheme.richGold,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
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
    final currentStep = _jobSteps.firstWhere(
      (step) => step.id == _currentStep,
      orElse: () => _jobSteps.first,
    );

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
                  child: Icon(
                    currentStep.icon,
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
                  valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
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
                      _buildLuxuryTimeline(),
                      const SizedBox(height: 24),
                      _buildLuxuryCurrentStepCard(),
                      const SizedBox(height: 24),
                      
                      // Trip Progress (if available)
                      if (_tripProgress != null && _tripProgress!.isNotEmpty) ...[
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
                                      color: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Trip ${trip['trip_index']}',
                                                style: const TextStyle(
                                                  color: ChoiceLuxTheme.softWhite,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Status: ${trip['status'] ?? 'pending'}',
                                                style: TextStyle(
                                                  color: ChoiceLuxTheme.platinumSilver,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          _getTripStatusIcon(trip['status']),
                                          color: _getTripStatusColor(trip['status']),
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


