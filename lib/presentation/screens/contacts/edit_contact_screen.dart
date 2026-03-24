import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/emergency_contact.dart';
import '../../blocs/contacts/contacts_cubit.dart';

/// Screen to edit an existing emergency contact.
class EditContactScreen extends StatefulWidget {
  const EditContactScreen({super.key, required this.contact});

  final EmergencyContact contact;

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationController;
  late bool _isPrimary;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone);
    _relationController =
        TextEditingController(text: widget.contact.relationship ?? '');
    _isPrimary = widget.contact.isPrimary;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.contact.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relationship: _relationController.text.trim().isNotEmpty
          ? _relationController.text.trim()
          : null,
      isPrimary: _isPrimary,
    );

    await context.read<ContactsCubit>().updateContact(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.editContact),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveContact,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.contactDetails, style: AppTypography.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l.fullName,
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? l.enterName
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_rounded),
                  hintText: '+880...',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.enterPhone;
                  }
                  // Strip spaces, dashes, and parens for validation.
                  final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
                  if (cleaned.length < 7 || cleaned.length > 15) {
                    return l.enterValidPhone;
                  }
                  // Must start with + or digit, contain only digits after optional +.
                  if (!RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned)) {
                    return l.enterValidPhone;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationController,
                decoration: InputDecoration(
                  labelText: l.relationship,
                  prefixIcon: const Icon(Icons.family_restroom_rounded),
                  hintText: l.relationshipHint,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isPrimary,
                onChanged: (val) => setState(() => _isPrimary = val),
                title: Text(l.setAsPrimaryContact),
                subtitle: Text(l.primaryContactNotify),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
