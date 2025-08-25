import 'package:flutter/material.dart';
import 'features/jobs/services/job_assignment_service.dart';

// Example usage of the new JobAssignmentService
class JobAssignmentTest extends StatefulWidget {
  const JobAssignmentTest({super.key});

  @override
  State<JobAssignmentTest> createState() => _JobAssignmentTestState();
}

class _JobAssignmentTestState extends State<JobAssignmentTest> {
  bool _isLoading = false;
  String _status = 'Ready to test';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Assignment Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test job assignment
            ElevatedButton(
              onPressed: _isLoading ? null : _testJobAssignment,
              child: const Text('Test Job Assignment'),
            ),
            
            const SizedBox(height: 10),
            
            // Test job confirmation
            ElevatedButton(
              onPressed: _isLoading ? null : _testJobConfirmation,
              child: const Text('Test Job Confirmation'),
            ),
            
            const SizedBox(height: 10),
            
            // Test get jobs for driver
            ElevatedButton(
              onPressed: _isLoading ? null : _testGetJobsForDriver,
              child: const Text('Get Jobs for Driver'),
            ),
            
            const SizedBox(height: 10),
            
            // Test get unassigned jobs
            ElevatedButton(
              onPressed: _isLoading ? null : _testGetUnassignedJobs,
              child: const Text('Get Unassigned Jobs'),
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testJobAssignment() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing job assignment...';
    });

    try {
      // You'll need to replace these with actual values from your database
      const int jobId = 1; // Replace with actual job ID
      const String driverId = 'driver-uuid'; // Replace with actual driver UUID
      
      await JobAssignmentService.assignJobToDriver(
        jobId: jobId,
        driverId: driverId,
        isReassignment: false,
      );

      setState(() {
        _status = 'Job assignment successful! Check notifications.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testJobConfirmation() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing job confirmation...';
    });

    try {
      // You'll need to replace these with actual values from your database
      const int jobId = 1; // Replace with actual job ID
      const String driverId = 'driver-uuid'; // Replace with actual driver UUID
      
      await JobAssignmentService.confirmJobAssignment(
        jobId: jobId,
        driverId: driverId,
      );

      setState(() {
        _status = 'Job confirmation successful!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetJobsForDriver() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting jobs for driver...';
    });

    try {
      const String driverId = 'driver-uuid'; // Replace with actual driver UUID
      
      final jobs = await JobAssignmentService.getJobsForDriver(driverId);

      setState(() {
        _status = 'Found ${jobs.length} jobs for driver';
      });
      
      // Print job details
      for (final job in jobs) {
        print('Job: ${job['job_number']} - ${job['passenger_name']}');
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetUnassignedJobs() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting unassigned jobs...';
    });

    try {
      final jobs = await JobAssignmentService.getUnassignedJobs();

      setState(() {
        _status = 'Found ${jobs.length} unassigned jobs';
      });
      
      // Print job details
      for (final job in jobs) {
        print('Unassigned Job: ${job['job_number']} - ${job['passenger_name']}');
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Example of how to use JobAssignmentService in your app
class ExampleUsage {
  static Future<void> assignJobExample() async {
    try {
      // When an admin assigns a job to a driver
      await JobAssignmentService.assignJobToDriver(
        jobId: 123,
        driverId: 'driver-uuid-here',
        isReassignment: false,
      );
      
      print('Job assigned successfully!');
    } catch (e) {
      print('Failed to assign job: $e');
    }
  }

  static Future<void> confirmJobExample() async {
    try {
      // When a driver confirms a job assignment
      await JobAssignmentService.confirmJobAssignment(
        jobId: 123,
        driverId: 'driver-uuid-here',
      );
      
      print('Job confirmed successfully!');
    } catch (e) {
      print('Failed to confirm job: $e');
    }
  }
}
