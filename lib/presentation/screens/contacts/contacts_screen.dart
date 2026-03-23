import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/emergency_contact.dart';
import '../../blocs/contacts/contacts_cubit.dart';
import '../../blocs/contacts/contacts_state.dart';
import '../../widgets/ad_banner_widget.dart';

/// Emergency contacts list screen with CRUD operations.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ContactsCubit>().loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      bottomNavigationBar: AdBanner(adUnitId: AdService.bannerContacts),
      appBar: AppBar(title: Text(l.emergencyContacts)),
      floatingActionButton: BlocBuilder<ContactsCubit, ContactsState>(
        builder: (context, state) {
          final isLimit = state is ContactsLoaded && state.isLimitReached;
          return FloatingActionButton.extended(
            onPressed: isLimit
                ? () => _showLimitDialog(context)
                : () => context.push('/contacts/add'),
            icon: const Icon(Icons.person_add_rounded),
            label: Text(l.addContact),
            backgroundColor: isLimit ? AppColors.textDisabled : null,
          );
        },
      ),
      body: BlocConsumer<ContactsCubit, ContactsState>(
        listener: (context, state) {
          if (state is ContactsLimitReached) {
            _showLimitDialog(context);
          }
          if (state is ContactsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ContactsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = switch (state) {
            final ContactsLoaded s => s.contacts,
            final ContactsLimitReached s => s.contacts,
            _ => <EmergencyContact>[],
          };

          if (contacts.isEmpty) {
            return _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _ContactCard(
                contact: contact,
                onEdit: () => context.push('/contacts/edit', extra: contact),
                onDelete: () => _confirmDelete(context, contact),
                onSetPrimary: () {
                  if (contact.id != null) {
                    context.read<ContactsCubit>().setPrimary(contact.id!);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showLimitDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.contactLimitReached),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.contactLimitMessage),
            const SizedBox(height: 12),
            Text(
              l.premiumRoadmap,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EmergencyContact contact) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.removeContact),
        content: Text(l.removeContactConfirm(contact.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (contact.id != null) {
                context.read<ContactsCubit>().deleteContact(contact.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l.remove),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Lottie.asset(
                'assets/lottie/empty_state.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.noEmergencyContacts,
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.addContactsHint,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary
              ? AppColors.primary
              : AppColors.secondary.withValues(alpha: 0.1),
          child: Icon(
            contact.isPrimary ? Icons.star_rounded : Icons.person_rounded,
            color: contact.isPrimary ? Colors.white : AppColors.secondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(contact.name, style: AppTypography.titleSmall),
            ),
            if (contact.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.primary,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phone),
            if (contact.relationship != null &&
                contact.relationship!.isNotEmpty)
              Text(
                contact.relationship!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'primary':
                onSetPrimary();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(l.edit),
                ],
              ),
            ),
            if (!contact.isPrimary)
              PopupMenuItem(
                value: 'primary',
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(l.setAsPrimary),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.remove,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
