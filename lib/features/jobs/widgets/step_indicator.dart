import 'package:flutter/material.dart';
import '../models/job_step.dart';

class StepIndicator extends StatelessWidget {
  final List<JobStep> steps;
  final String currentStep;

  const StepIndicator({
    Key? key,
    required this.steps,
    required this.currentStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrentStep = step.id == currentStep;
              final isCompleted = step.isCompleted;
              final isLast = index == steps.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      // Step indicator circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStepColor(isCompleted, isCurrentStep),
                          border: Border.all(
                            color: _getStepBorderColor(isCompleted, isCurrentStep),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getStepIcon(isCompleted, isCurrentStep),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Step content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getStepTextColor(isCompleted, isCurrentStep),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _getStepDescriptionColor(isCompleted, isCurrentStep),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Step status indicator
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        )
                      else if (isCurrentStep)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Connector line (except for last step)
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 19, top: 8, bottom: 8),
                      child: Container(
                        width: 2,
                        height: 20,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getStepColor(bool isCompleted, bool isCurrentStep) {
    if (isCompleted) return Colors.green;
    if (isCurrentStep) return Colors.blue;
    return Colors.grey[300]!;
  }

  Color _getStepBorderColor(bool isCompleted, bool isCurrentStep) {
    if (isCompleted) return Colors.green;
    if (isCurrentStep) return Colors.blue;
    return Colors.grey[400]!;
  }

  IconData _getStepIcon(bool isCompleted, bool isCurrentStep) {
    if (isCompleted) return Icons.check;
    if (isCurrentStep) return Icons.play_arrow;
    return Icons.radio_button_unchecked;
  }

  Color _getStepTextColor(bool isCompleted, bool isCurrentStep) {
    if (isCompleted) return Colors.green[700]!;
    if (isCurrentStep) return Colors.blue[700]!;
    return Colors.grey[600]!;
  }

  Color _getStepDescriptionColor(bool isCompleted, bool isCurrentStep) {
    if (isCompleted) return Colors.green[600]!;
    if (isCurrentStep) return Colors.blue[600]!;
    return Colors.grey[500]!;
  }
}


