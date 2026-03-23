import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../data/models/user_profile.dart';
import '../../blocs/profile/profile_cubit.dart';


/// Form screen for editing the medical profile.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.existingProfile});

  final UserProfile? existingProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _notesController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;

  String? _selectedBloodType;
  bool _organDonor = false;

  static const List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _allergiesController =
        TextEditingController(text: p?.allergies.join(', ') ?? '');
    _conditionsController =
        TextEditingController(text: p?.medicalConditions.join(', ') ?? '');
    _medicationsController =
        TextEditingController(text: p?.medications.join(', ') ?? '');
    _notesController =
        TextEditingController(text: p?.emergencyNotes ?? '');
    _weightController =
        TextEditingController(text: p?.weight?.toString() ?? '');
    _heightController =
        TextEditingController(text: p?.height?.toString() ?? '');
    _selectedBloodType = p?.bloodType;
    _organDonor = p?.organDonor ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  List<String> _parseList(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      fullName: _nameController.text.trim(),
      bloodType: _selectedBloodType,
      allergies: _parseList(_allergiesController.text),
      medicalConditions: _parseList(_conditionsController.text),
      medications: _parseList(_medicationsController.text),
      emergencyNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      weight: double.tryParse(_weightController.text),
      height: double.tryParse(_heightController.text),
      organDonor: _organDonor,
    );

    context.read<ProfileCubit>().saveProfile(profile);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProfile != null
            ? l.editMedicalProfile
            : l.createMedicalProfile),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Full name.
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${l.fullName} *',
                prefixIcon: const Icon(Icons.person_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.nameRequired : null,
            ),
            const SizedBox(height: 16),

            // Blood type dropdown.
            DropdownButtonFormField<String>(
              initialValue: _selectedBloodType,
              decoration: InputDecoration(
                labelText: l.bloodType,
                prefixIcon: const Icon(Icons.bloodtype_rounded),
              ),
              items: _bloodTypes
                  .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBloodType = v),
            ),
            const SizedBox(height: 16),

            // Weight & Height in a row.
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: l.weight,
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      labelText: l.height,
                      prefixIcon: const Icon(Icons.height_rounded),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Allergies.
            TextFormField(
              controller: _allergiesController,
              decoration: InputDecoration(
                labelText: l.allergies,
                helperText: l.separateWithCommas,
                prefixIcon: const Icon(Icons.warning_amber_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Medical conditions.
            TextFormField(
              controller: _conditionsController,
              decoration: InputDecoration(
                labelText: l.medicalConditions,
                helperText: l.separateWithCommas,
                prefixIcon: const Icon(Icons.medical_services_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Medications.
            TextFormField(
              controller: _medicationsController,
              decoration: InputDecoration(
                labelText: l.medications,
                helperText: l.separateWithCommas,
                prefixIcon: const Icon(Icons.medication_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Emergency notes.
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l.emergencyNotes,
                prefixIcon: const Icon(Icons.note_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Organ donor toggle.
            SwitchListTile(
              title: Text(l.organDonor),
              subtitle: Text(l.shareWithFirstResponders),
              value: _organDonor,
              onChanged: (v) => setState(() => _organDonor = v),
              secondary: const Icon(Icons.favorite_rounded),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
