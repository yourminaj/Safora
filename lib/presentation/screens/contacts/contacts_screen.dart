import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/emergency_contact.dart';
import '../../blocs/contacts/contacts_cubit.dart';
import '../../blocs/contacts/contacts_state.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      floatingActionButton: BlocBuilder<ContactsCubit, ContactsState>(
        builder: (context, state) {
          final isLimit = state is ContactsLoaded && state.isLimitReached;
          return FloatingActionButton.extended(
            onPressed: isLimit
                ? () => _showLimitDialog(context)
                : () => context.push('/contacts/add'),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Contact'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ContactsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = switch (state) {
            ContactsLoaded s => s.contacts,
            ContactsLimitReached s => s.contacts,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Limit Reached'),
        content: const Text(
          'Free users can add up to 3 emergency contacts.\n\n'
          'Upgrade to Premium to add unlimited contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium subscriptions coming soon!'),
                ),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text(
          'Are you sure you want to remove ${contact.name} '
          'from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (contact.id != null) {
                context.read<ContactsCubit>().deleteContact(contact.id!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contacts_rounded,
                size: 48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Emergency Contacts',
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to 3 trusted contacts who will be '
              'alerted during emergencies with your GPS location.',
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary
              ? AppColors.primary
              : AppColors.secondary.withValues(alpha: 0.1),
          child: Icon(
            contact.isPrimary
                ? Icons.star_rounded
                : Icons.person_rounded,
            color: contact.isPrimary
                ? Colors.white
                : AppColors.secondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.name,
                style: AppTypography.titleSmall,
              ),
            ),
            if (contact.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRIMARY',
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
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!contact.isPrimary)
              const PopupMenuItem(
                value: 'primary',
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Set as Primary'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded,
                      size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text('Remove',
                      style: TextStyle(color: AppColors.danger)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
