import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/alert_event.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';

/// Map screen showing disaster alert locations from USGS, GDACS, Open-Meteo.
///
/// Uses flutter_map + OpenStreetMap (free, no API key required).
class AlertMapScreen extends StatefulWidget {
  const AlertMapScreen({super.key});

  @override
  State<AlertMapScreen> createState() => _AlertMapScreenState();
}

class _AlertMapScreenState extends State<AlertMapScreen> {
  final MapController _mapController = MapController();

  /// Currently selected filter (null = show all).
  AlertType? _selectedType;

  @override
  void initState() {
    super.initState();
    // Refresh alerts on entry.
    context.read<AlertsCubit>().loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.alertMap),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context.read<AlertsCubit>().refreshAlerts(),
          ),
        ],
      ),
      body: BlocBuilder<AlertsCubit, AlertsState>(
        builder: (context, state) {
          // Extract alerts from sealed state.
          final allAlerts = switch (state) {
            AlertsLoaded(:final alerts) => alerts,
            _ => <AlertEvent>[],
          };
          final isLoading = state is AlertsLoading;
          final filteredAlerts = _filteredAlerts(allAlerts);

          return Stack(
            children: [
              // ── Map ────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter(filteredAlerts),
                  initialZoom: 3.0,
                  maxZoom: 18.0,
                  minZoom: 2.0,
                ),
                children: [
                  // OpenStreetMap tile layer (free, no API key).
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.digitaldrive.safora',
                    maxZoom: 19,
                  ),
                  // Alert markers.
                  MarkerLayer(
                    markers: filteredAlerts.map(_buildMarker).toList(),
                  ),
                ],
              ),

              // ── Loading indicator ──────────────────────────
              if (isLoading)
                const Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading alerts...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Filter chips ───────────────────────────────
              Positioned(
                bottom: 16,
                left: 8,
                right: 8,
                child: _FilterBar(
                  selectedType: _selectedType,
                  alertCounts: _alertCounts(allAlerts),
                  onSelected: (type) {
                    setState(() {
                      _selectedType = _selectedType == type ? null : type;
                    });
                  },
                ),
              ),

              // ── Error message ──────────────────────────────
              if (state is AlertsError)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: AppColors.error.withValues(alpha: 0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Build a map marker for an alert event.
  Marker _buildMarker(AlertEvent alert) {
    final color = _priorityColor(alert.type.priority);
    final icon = _categoryIcon(alert.type.category);

    return Marker(
      point: LatLng(alert.latitude, alert.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showAlertDetail(alert),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// Show alert details in a bottom sheet.
  void _showAlertDetail(AlertEvent alert) {
    final priorityColor = _priorityColor(alert.type.priority);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and priority badge.
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcon(alert.type.category),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${alert.source ?? "Unknown"} · ${alert.type.priority.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (alert.description != null)
              Text(alert.description!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            if (alert.magnitude != null)
              _DetailChip(
                label: 'Magnitude',
                value: alert.magnitude!.toStringAsFixed(1),
              ),
            _DetailChip(
              label: 'Coordinates',
              value:
                  '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
            ),
            _DetailChip(
              label: 'Time',
              value: _formatTime(alert.timestamp),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  List<AlertEvent> _filteredAlerts(List<AlertEvent> alerts) {
    if (_selectedType == null) return alerts;
    return alerts.where((a) => a.type == _selectedType).toList();
  }

  Map<AlertType, int> _alertCounts(List<AlertEvent> alerts) {
    final counts = <AlertType, int>{};
    for (final alert in alerts) {
      counts[alert.type] = (counts[alert.type] ?? 0) + 1;
    }
    return counts;
  }

  LatLng _mapCenter(List<AlertEvent> alerts) {
    if (alerts.isEmpty) return const LatLng(23.8, 90.4); // Default: Dhaka
    return LatLng(alerts.first.latitude, alerts.first.longitude);
  }

  Color _priorityColor(AlertPriority priority) {
    return switch (priority) {
      AlertPriority.critical => AppColors.error,
      AlertPriority.high => Colors.deepOrange,
      AlertPriority.medium => AppColors.warning,
      AlertPriority.low => AppColors.success,
    };
  }

  IconData _categoryIcon(AlertCategory category) {
    return switch (category) {
      AlertCategory.naturalDisaster => Icons.public_rounded,
      AlertCategory.weatherEmergency => Icons.thunderstorm_rounded,
      AlertCategory.waterMarine => Icons.water_rounded,
      AlertCategory.personalSafety => Icons.shield_rounded,
      AlertCategory.healthMedical => Icons.local_hospital_rounded,
      AlertCategory.vehicleTransport => Icons.directions_car_rounded,
      AlertCategory.homeDomestic => Icons.home_rounded,
      AlertCategory.workplace => Icons.engineering_rounded,
      AlertCategory.travelOutdoor => Icons.terrain_rounded,
      AlertCategory.environmentalChemical => Icons.science_rounded,
      AlertCategory.digitalCyber => Icons.phone_android_rounded,
      AlertCategory.childElder => Icons.family_restroom_rounded,
    };
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════
//  FILTER BAR WIDGET
// ═══════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedType,
    required this.alertCounts,
    required this.onSelected,
  });

  final AlertType? selectedType;
  final Map<AlertType, int> alertCounts;
  final void Function(AlertType) onSelected;

  @override
  Widget build(BuildContext context) {
    final types = [
      AlertType.earthquake,
      AlertType.cyclone,
      AlertType.flood,
      AlertType.wildfire,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = selectedType == type;
          final count = alertCounts[type] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(
                '${type.label} ($count)',
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(type),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DETAIL CHIP WIDGET
// ═══════════════════════════════════════════════════════════

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
