import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/users_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class UserForm extends StatefulWidget {
  final User? user;
  final void Function(User user) onSave;
  final VoidCallback? onDeactivate;
  final bool canDeactivate;

  const UserForm({Key? key, this.user, required this.onSave, this.onDeactivate, this.canDeactivate = false}) : super(key: key);

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  late String displayName;
  late String userEmail;
  String? role;
  String? status;
  String? driverLicence;
  DateTime? driverLicExp;
  String? pdp;
  DateTime? pdpExp;
  String? number;
  String? address;
  String? kin;
  String? kinNumber;
  String? profileImage;
  bool _uploading = false;

  final List<String> roles = [
    'administrator', 'manager', 'driver_manager', 'driver', 'agent', 'unassigned'
  ];
  final List<String> statuses = [
    'active', 'deactivated', 'unassigned'
  ];

  @override
  void initState() {
    super.initState();
    displayName = widget.user?.displayName ?? '';
    userEmail = widget.user?.userEmail ?? '';
    role = widget.user?.role ?? 'unassigned';
    status = widget.user?.status ?? 'unassigned';
    driverLicence = widget.user?.driverLicence;
    driverLicExp = widget.user?.driverLicExp;
    pdp = widget.user?.pdp;
    pdpExp = widget.user?.pdpExp;
    number = widget.user?.number;
    address = widget.user?.address;
    kin = widget.user?.kin;
    kinNumber = widget.user?.kinNumber;
    profileImage = widget.user?.profileImage;
  }

  Future<void> _pickAndUploadImage(WidgetRef ref, String userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked != null) {
      setState(() => _uploading = true);
      final url = await ref.read(usersProvider.notifier).uploadProfileImage(picked, userId);
      setState(() {
        profileImage = url;
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final userProfile = ref.watch(currentUserProfileProvider);
        final isAdmin = userProfile?.role?.toLowerCase() == 'administrator';
        final isWide = MediaQuery.of(context).size.width > 900;
        // Error summary state
        String? errorSummary;
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              if (errorSummary != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorSummary!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              // Avatar + Header Section
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: isWide ? 52 : 44,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: profileImage != null && profileImage!.isNotEmpty ? NetworkImage(profileImage!) : null,
                            child: profileImage == null || profileImage!.isEmpty ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32, color: Colors.white)) : null,
                          ),
                          if (_uploading)
                            const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Change Profile Image'),
                        onPressed: widget.user == null ? null : () => _pickAndUploadImage(ref, widget.user!.id),
                      ),
                    ],
                  ),
                ),
              ),
              // Responsive layout for form sections
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildBasicInfoSection(isAdmin)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildContactSection()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildDriverSection()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildBasicInfoSection(isAdmin),
                        const SizedBox(height: 24),
                        _buildContactSection(),
                        const SizedBox(height: 24),
                        _buildDriverSection(),
                      ],
                    ),
              const SizedBox(height: 32),
              // Responsive button row
              Builder(
                builder: (context) {
                  final isMobile = MediaQuery.of(context).size.width < 600;
                  if (isMobile) {
                    // Stack buttons vertically, full width
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.canDeactivate && widget.onDeactivate != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.block),
                            label: const Text('Deactivate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: widget.onDeactivate,
                          ),
                        if (widget.canDeactivate && widget.onDeactivate != null)
                          const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            elevation: 2,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              widget.onSave(User(
                                id: widget.user?.id ?? '',
                                displayName: displayName,
                                userEmail: userEmail,
                                role: role,
                                status: status,
                                driverLicence: driverLicence,
                                driverLicExp: driverLicExp,
                                pdp: pdp,
                                pdpExp: pdpExp,
                                number: number,
                                address: address,
                                kin: kin,
                                kinNumber: kinNumber,
                                profileImage: profileImage,
                              ));
                            } else {
                              setState(() {
                                errorSummary = 'Please correct the errors highlighted below.';
                              });
                            }
                          },
                          child: const Text('Save Changes'),
                        ),
                      ],
                    );
                  } else {
                    // Row, right-aligned, no infinity width
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.canDeactivate && widget.onDeactivate != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.block),
                              label: const Text('Deactivate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: widget.onDeactivate,
                            ),
                          ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            elevation: 2,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              widget.onSave(User(
                                id: widget.user?.id ?? '',
                                displayName: displayName,
                                userEmail: userEmail,
                                role: role,
                                status: status,
                                driverLicence: driverLicence,
                                driverLicExp: driverLicExp,
                                pdp: pdp,
                                pdpExp: pdpExp,
                                number: number,
                                address: address,
                                kin: kin,
                                kinNumber: kinNumber,
                                profileImage: profileImage,
                              ));
                            } else {
                              setState(() {
                                errorSummary = 'Please correct the errors highlighted below.';
                              });
                            }
                          },
                          child: const Text('Save Changes'),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection(bool isAdmin) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 22),
                const SizedBox(width: 8),
                Text('Basic Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: displayName,
              decoration: _modernInputDecoration('Full Name'),
              style: const TextStyle(fontSize: 15),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => displayName = val ?? '',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: userEmail,
              decoration: _modernInputDecoration('Email'),
              style: const TextStyle(fontSize: 15),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            isAdmin
                ? DropdownButtonFormField<String>(
                    value: role,
                    decoration: _modernInputDecoration('Role'),
                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(_titleCase(r)))).toList(),
                    onChanged: (val) => setState(() => role = val),
                    onSaved: (val) => role = val,
                  )
                : TextFormField(
                    initialValue: _titleCase(role ?? ''),
                    decoration: _modernInputDecoration('Role'),
                    style: const TextStyle(fontSize: 15),
                    readOnly: true,
                  ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: _modernInputDecoration('Status'),
              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(_titleCase(s)))).toList(),
              onChanged: (val) => setState(() => status = val),
              onSaved: (val) => status = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone, size: 22),
                const SizedBox(width: 8),
                Text('Contact Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: number,
              decoration: _modernInputDecoration('Contact Number'),
              style: const TextStyle(fontSize: 15),
              onSaved: (val) => number = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: address,
              decoration: _modernInputDecoration('Address'),
              style: const TextStyle(fontSize: 15),
              onSaved: (val) => address = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: kin,
              decoration: _modernInputDecoration('Emergency Contact Name'),
              style: const TextStyle(fontSize: 15),
              onSaved: (val) => kin = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: kinNumber,
              decoration: _modernInputDecoration('Emergency Contact Number'),
              style: const TextStyle(fontSize: 15),
              onSaved: (val) => kinNumber = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, size: 22),
                const SizedBox(width: 8),
                Text('Driver Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Driver License', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (driverLicence != null && driverLicence!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Image.network(driverLicence!, height: 60),
                        ),
                      Consumer(
                        builder: (context, ref, _) => TextButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: Text(driverLicence == null ? 'Upload' : 'Replace'),
                          onPressed: widget.user == null ? null : () async {
                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setState(() => _uploading = true);
                              final url = await ref.read(usersProvider.notifier).uploadDriverLicenseImage(
                                picked, widget.user!.id
                              );
                              setState(() {
                                driverLicence = url;
                                _uploading = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PDP', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (pdp != null && pdp!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Image.network(pdp!, height: 60),
                        ),
                      Consumer(
                        builder: (context, ref, _) => TextButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: Text(pdp == null ? 'Upload' : 'Replace'),
                          onPressed: widget.user == null ? null : () async {
                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setState(() => _uploading = true);
                              final url = await ref.read(usersProvider.notifier).uploadPdpImage(
                                picked, widget.user!.id
                              );
                              setState(() {
                                pdp = url;
                                _uploading = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DatePickerFormField(
              label: 'Driver Licence Expiry',
              initialDate: driverLicExp,
              onSaved: (val) => driverLicExp = val,
              helper: _expiryHelper(driverLicExp),
            ),
            const SizedBox(height: 12),
            _DatePickerFormField(
              label: 'PDP Expiry',
              initialDate: pdpExp,
              onSaved: (val) => pdpExp = val,
              helper: _expiryHelper(pdpExp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expiryHelper(DateTime? date) {
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 90));
    if (date.isBefore(now)) {
      return Row(children: [const Icon(Icons.error, color: Colors.red, size: 16), const SizedBox(width: 4), Text('Expired', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))]);
    } else if (date.isBefore(soon)) {
      return Row(children: [const Icon(Icons.warning, color: Colors.amber, size: 16), const SizedBox(width: 4), Text('Expiring Soon', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600))]);
    }
    return Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 16), const SizedBox(width: 4), Text('Valid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))]);
  }

  InputDecoration _modernInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      errorStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent),
    );
  }

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _DatePickerFormField extends FormField<DateTime> {
  _DatePickerFormField({
    required String label,
    DateTime? initialDate,
    FormFieldSetter<DateTime>? onSaved,
    Widget? helper,
  }) : super(
          initialValue: initialDate,
          onSaved: onSaved,
          builder: (FormFieldState<DateTime> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: state.context,
                      initialDate: state.value ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      state.didChange(picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: label,
                      filled: true,
                      errorText: state.errorText,
                    ),
                    child: Text(
                      state.value != null
                          ? '${state.value!.year}-${state.value!.month.toString().padLeft(2, '0')}-${state.value!.day.toString().padLeft(2, '0')}'
                          : 'Select date',
                      style: TextStyle(
                        color: state.value != null ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (helper != null) Padding(padding: const EdgeInsets.only(top: 4), child: helper),
              ],
            );
          },
        );
} 