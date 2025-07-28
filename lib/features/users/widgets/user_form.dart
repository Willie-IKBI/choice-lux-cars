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
        return Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar + Header Section
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 44,
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
              // Sticky footer/button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.canDeactivate && widget.onDeactivate != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.block),
                      label: const Text('Deactivate'),
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: widget.onDeactivate,
                    ),
                  FilledButton(
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
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Basic Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: displayName,
              decoration: const InputDecoration(labelText: 'Full Name', filled: true),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => displayName = val ?? '',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: userEmail,
              decoration: const InputDecoration(labelText: 'Email', filled: true),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            isAdmin
                ? DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role', filled: true),
                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(_titleCase(r)))).toList(),
                    onChanged: (val) => setState(() => role = val),
                    onSaved: (val) => role = val,
                  )
                : TextFormField(
                    initialValue: _titleCase(role ?? ''),
                    decoration: const InputDecoration(labelText: 'Role', filled: true),
                    readOnly: true,
                  ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status', filled: true),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Contact Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: number,
              decoration: const InputDecoration(labelText: 'Contact Number', filled: true),
              onSaved: (val) => number = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: address,
              decoration: const InputDecoration(labelText: 'Address', filled: true),
              onSaved: (val) => address = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: kin,
              decoration: const InputDecoration(labelText: 'Emergency Contact Name', filled: true),
              onSaved: (val) => kin = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: kinNumber,
              decoration: const InputDecoration(labelText: 'Emergency Contact Number', filled: true),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🚗 Driver Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Driver License'),
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
                              print('Driver license image URL: $url');
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
                      Text('PDP'),
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
                              print('PDP image URL: $url');
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