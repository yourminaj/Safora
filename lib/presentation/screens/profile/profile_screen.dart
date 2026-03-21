import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/profile/profile_state.dart';

/// Medical profile screen — shows blood type, allergies, conditions.
///
/// BLoC-driven with real data from Hive storage.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Profile')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoaded && state.profile != null) {
            final p = state.profile!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical ID Card.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medical_information_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.fullName,
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Blood Type',
                          value: p.bloodType ?? 'Not set',
                        ),
                        _InfoRow(
                          label: 'Allergies',
                          value: p.allergies.isEmpty
                              ? 'None listed'
                              : p.allergies.join(', '),
                        ),
                        _InfoRow(
                          label: 'Conditions',
                          value: p.medicalConditions.isEmpty
                              ? 'None listed'
                              : p.medicalConditions.join(', '),
                        ),
                        _InfoRow(
                          label: 'Medications',
                          value: p.medications.isEmpty
                              ? 'None listed'
                              : p.medications.join(', '),
                        ),
                        if (p.weight != null || p.height != null)
                          _InfoRow(
                            label: 'Body',
                            value: [
                              if (p.weight != null) '${p.weight} kg',
                              if (p.height != null) '${p.height} cm',
                            ].join(' · '),
                          ),
                        if (p.organDonor)
                          _InfoRow(
                            label: 'Organ Donor',
                            value: '✅ Yes',
                          ),
                      ],
                    ),
                  ),

                  if (p.emergencyNotes != null &&
                      p.emergencyNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 Emergency Notes',
                            style: AppTypography.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.emergencyNotes!,
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final cubit = context.read<ProfileCubit>();
                      await context.push(
                        '/profile/edit',
                        extra: p,
                      );
                      if (mounted) cubit.loadProfile();
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Medical Profile'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            );
          }

          // Empty state — no profile yet.
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_information_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Medical Profile',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your medical profile so first responders '
                    'can access your vital information in emergencies.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      final cubit = context.read<ProfileCubit>();
                      await context.push('/profile/edit');
                      if (mounted) cubit.loadProfile();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Profile'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
