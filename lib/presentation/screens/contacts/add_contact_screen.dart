import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/typography.dart';
import '../../blocs/contacts/contacts_cubit.dart';

/// Screen to add a new emergency contact.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  bool _isPrimary = false;
  bool _isSaving = false;

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

    await context.read<ContactsCubit>().addContact(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationController.text.trim().isNotEmpty
              ? _relationController.text.trim()
              : null,
          isPrimary: _isPrimary,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    // Show interstitial after save (non-intrusive, natural pause point).
    AdService.instance.showInterstitial();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.addContact),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveContact,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving ? l.save : l.save,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
