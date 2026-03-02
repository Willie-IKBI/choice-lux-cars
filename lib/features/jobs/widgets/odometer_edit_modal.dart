import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';

class OdometerEditModal extends ConsumerStatefulWidget {
  final int jobId;
  final double? currentStartOdo;
  final double? currentEndOdo;
  final VoidCallback onSaved;

  const OdometerEditModal({
    super.key,
    required this.jobId,
    this.currentStartOdo,
    this.currentEndOdo,
    required this.onSaved,
  });

  @override
  ConsumerState<OdometerEditModal> createState() => _OdometerEditModalState();
}

class _OdometerEditModalState extends ConsumerState<OdometerEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startOdoController;
  late TextEditingController _endOdoController;
  late TextEditingController _reasonController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startOdoController = TextEditingController(
      text: widget.currentStartOdo?.toStringAsFixed(1) ?? '',
    );
    _endOdoController = TextEditingController(
      text: widget.currentEndOdo?.toStringAsFixed(1) ?? '',
    );
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _startOdoController.dispose();
    _endOdoController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double? get _startValue => double.tryParse(_startOdoController.text.trim());
  double? get _endValue => double.tryParse(_endOdoController.text.trim());

  String? get _calculatedDistance {
    final start = _startValue;
    final end = _endValue;
    if (start != null && end != null && end >= start) {
      return '${(end - start).toStringAsFixed(1)} km';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProfileProvider);
    final userId = currentUser?.id;
    if (userId == null) {
      SnackBarUtils.showError(context, 'User not authenticated');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DriverFlowApiService.updateOdometerReadings(
        widget.jobId,
        odoStartReading: _startValue,
        odoEndReading: _endValue,
        updatedByUserId: userId,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.showSuccess(context, 'Odometer readings updated');
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        SnackBarUtils.showError(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ChoiceLuxTheme.charcoalGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCurrentValuesInfo(),
                const SizedBox(height: 20),
                _buildStartOdoField(),
                const SizedBox(height: 16),
                _buildEndOdoField(),
                const SizedBox(height: 16),
                _buildCalculatedDistance(),
                const SizedBox(height: 20),
                _buildReasonField(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.edit,
            color: ChoiceLuxTheme.richGold,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Edit Odometer Readings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: ChoiceLuxTheme.platinumSilver),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildCurrentValuesInfo() {
    final hasStart = widget.currentStartOdo != null;
    final hasEnd = widget.currentEndOdo != null;
    if (!hasStart && !hasEnd) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.jetBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Values',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasStart)
                Expanded(
                  child: _buildInfoChip(
                    'Start',
                    '${widget.currentStartOdo!.toStringAsFixed(1)} km',
                  ),
                ),
              if (hasStart && hasEnd) const SizedBox(width: 12),
              if (hasEnd)
                Expanded(
                  child: _buildInfoChip(
                    'End',
                    '${widget.currentEndOdo!.toStringAsFixed(1)} km',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartOdoField() {
    return TextFormField(
      controller: _startOdoController,
      style: TextStyle(color: ChoiceLuxTheme.softWhite),
      decoration: _inputDecoration(
        label: 'Start Odometer (km)',
        icon: Icons.play_arrow,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }
        if (double.tryParse(value.trim()) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildEndOdoField() {
    return TextFormField(
      controller: _endOdoController,
      style: TextStyle(color: ChoiceLuxTheme.softWhite),
      decoration: _inputDecoration(
        label: 'End Odometer (km)',
        icon: Icons.stop,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }
        final endVal = double.tryParse(value.trim());
        if (endVal == null) {
          return 'Enter a valid number';
        }
        final startVal = _startValue;
        if (startVal != null && endVal < startVal) {
          return 'End must be >= Start';
        }
        return null;
      },
    );
  }

  Widget _buildCalculatedDistance() {
    final distance = _calculatedDistance;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: distance != null
            ? ChoiceLuxTheme.richGold.withValues(alpha: 0.1)
            : ChoiceLuxTheme.jetBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: distance != null
              ? ChoiceLuxTheme.richGold.withValues(alpha: 0.3)
              : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route,
            color: distance != null
                ? ChoiceLuxTheme.richGold
                : ChoiceLuxTheme.platinumSilver,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculated Distance',
                  style: TextStyle(
                    fontSize: 12,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  distance ?? '—',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: distance != null
                        ? ChoiceLuxTheme.richGold
                        : ChoiceLuxTheme.platinumSilver,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      style: TextStyle(color: ChoiceLuxTheme.softWhite),
      decoration: _inputDecoration(
        label: 'Reason for change *',
        icon: Icons.comment,
        hint: 'e.g. Driver entered incorrect reading',
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Reason is required for audit purposes';
        }
        if (value.trim().length < 10) {
          return 'Please provide a more detailed reason';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver),
      hintStyle: TextStyle(
        color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.5),
      ),
      prefixIcon: Icon(icon, color: ChoiceLuxTheme.richGold),
      filled: true,
      fillColor: ChoiceLuxTheme.jetBlack,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChoiceLuxTheme.richGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChoiceLuxTheme.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChoiceLuxTheme.errorColor, width: 2),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: ChoiceLuxTheme.platinumSilver,
              side: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
