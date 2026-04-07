import 'package:safora/presentation/widgets/safora_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../widgets/safora_animated_icons.dart';
import '../shell/main_shell.dart';

import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/datasources/contacts_cloud_sync.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../injection.dart';
import '../../../core/services/ad_service.dart';
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

  Future<void> _handleCloudSync(String action, BuildContext ctx) async {
    final cloudSync = getIt<ContactsCloudSync>();
    final messenger = ScaffoldMessenger.of(ctx);
    final l = AppLocalizations.of(ctx)!;

    // Show loading.
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (action == 'backup') {
        final state = ctx.read<ContactsCubit>().state;
        final contacts = state is ContactsLoaded
            ? state.contacts
            : <EmergencyContact>[];
        await cloudSync.syncToCloud(contacts);
        if (ctx.mounted) Navigator.pop(ctx);
        SaforaToast.showSuccess(ctx, '${contacts.length} contacts backed up successfully');
      } else if (action == 'restore') {
        final cloudContacts = await cloudSync.syncFromCloud();
        if (ctx.mounted) Navigator.pop(ctx);
        if (cloudContacts.isEmpty) {
          SaforaToast.showInfo(ctx, l.noContactsInCloud);
        } else {
          // Add each cloud contact locally.
          for (final contact in cloudContacts) {
            if (ctx.mounted) {
              ctx.read<ContactsCubit>().addContact(
                name: contact.name,
                phone: contact.phone,
                relationship: contact.relationship,
              );
            }
          }
          SaforaToast.showSuccess(ctx, '${cloudContacts.length} contacts restored successfully');
        }
      }
    } catch (e) {
      if (ctx.mounted) Navigator.pop(ctx);
      SaforaToast.showError(ctx, '${l.syncFailed}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.emergencyContacts),
        actions: [
          if (getIt<AuthService>().isSignedIn)
            PopupMenuButton<String>(
              icon: const Icon(Icons.cloud_outlined),
              tooltip: 'Cloud Sync',
              onSelected: (value) => _handleCloudSync(value, context),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'backup',
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l.backupToCloud),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_download_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l.restoreFromCloud),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: BlocConsumer<ContactsCubit, ContactsState>(
                  listener: (context, state) {
                    if (state is ContactsLimitReached) {
                      _showLimitDialog(context);
                    }
                    if (state is ContactsError) {
                      SaforaToast.showError(context, state.message);
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
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: saforaBottomInset(context),
                        ),
                        child: _EmptyState(),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom:
                            saforaBottomInset(context) +
                            72, // Clear button + nav bar
                      ),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return _ContactCard(
                          contact: contact,
                          onEdit: () =>
                              context.push('/contacts/edit', extra: contact),
                          onDelete: () => _confirmDelete(context, contact),
                          onSetPrimary: () {
                            if (contact.id != null) {
                              context.read<ContactsCubit>().setPrimary(
                                contact.id!,
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              // Banner ad at bottom.
              AdBanner(adUnitId: AdService.bannerContacts),
            ],
          ),

          Positioned(
            bottom: saforaBottomInset(context) + 2,
            right: 24,
            child: BlocBuilder<ContactsCubit, ContactsState>(
              builder: (context, state) {
                final isLimit = state is ContactsLoaded && state.isLimitReached;
                return GestureDetector(
                  onTap: isLimit
                      ? () => _showLimitDialog(context)
                      : () => context.push('/contacts/add'),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isLimit
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.textDisabled.withValues(alpha: 0.6),
                                AppColors.textDisabled.withValues(alpha: 0.4),
                              ],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF5252), Color(0xFFC62828)],
                            ),
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: isLimit
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                                spreadRadius: -4,
                              ),
                            ],
                    ),
                    child: Icon(
                      isLimit ? Icons.lock_rounded : Icons.person_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.proFeatureTitle,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          l.proFeatureMessage,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.paywall);
            },
            icon: const Icon(Icons.workspace_premium),
            label: Text(l.upgradeToPro),
          ),
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
            const SaforaEmptyState(size: 100),
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
