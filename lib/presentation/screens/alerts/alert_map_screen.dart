import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/services/location_service.dart';
import '../../../data/datasources/overpass_api_client.dart';
import '../../../data/models/alert_event.dart';
import '../../../data/models/emergency_poi.dart';
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

  /// Nearby emergency POIs (hospitals, police, fire stations).
  List<EmergencyPoi> _pois = [];
  bool _poisLoading = false;

  /// Whether to show POI markers.
  bool _showPois = true;

  @override
  void initState() {
    super.initState();
    // Refresh alerts on entry.
    context.read<AlertsCubit>().loadAlerts();
    // Fetch nearby emergency POIs.
    _fetchNearbyPois();
  }

  Future<void> _fetchNearbyPois() async {
    setState(() => _poisLoading = true);
    try {
      final location = GetIt.instance<LocationService>();
      final pos = await location.getCurrentPosition();
      if (pos != null) {
        final client = GetIt.instance<OverpassApiClient>();
        final pois = await client.fetchNearbyPois(
          latitude: pos.latitude,
          longitude: pos.longitude,
          radiusMeters: 10000, // 10 km radius
        );
        if (mounted) {
          setState(() => _pois = pois);
        }
      }
    } catch (_) {
      // Silently fail — POIs are supplementary.
    } finally {
      if (mounted) {
        setState(() => _poisLoading = false);
      }
    }
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
                    userAgentPackageName: 'com.safora.safora',
                    maxZoom: 19,
                  ),
                  // Alert markers.
                  MarkerLayer(
                    markers: filteredAlerts.map(_buildMarker).toList(),
                  ),
                  // Emergency POI markers.
                  if (_showPois && _pois.isNotEmpty)
                    MarkerLayer(
                      markers: _pois.map(_buildPoiMarker).toList(),
                    ),
                ],
              ),

              if (isLoading)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(l.loadingAlerts),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                bottom: 16,
                left: 8,
                right: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // POI toggle + loading indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_poisLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: Icon(
                            Icons.local_hospital_rounded,
                            size: 16,
                            color: _showPois ? Colors.white : AppColors.accent,
                          ),
                          label: Text(
                            'Nearby (${_pois.length})',
                            style: TextStyle(
                              color: _showPois ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: _showPois,
                          onSelected: (v) => setState(() => _showPois = v),
                          selectedColor: AppColors.accent,
                          checkmarkColor: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _FilterBar(
                      selectedType: _selectedType,
                      alertCounts: _alertCounts(allAlerts),
                      onSelected: (type) {
                        setState(() {
                          _selectedType = _selectedType == type ? null : type;
                        });
                      },
                    ),
                  ],
                ),
              ),

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

  /// Build a map marker for a nearby emergency POI.
  Marker _buildPoiMarker(EmergencyPoi poi) {
    final color = _poiColor(poi.type);
    final icon = _poiIcon(poi.type);

    return Marker(
      point: LatLng(poi.latitude, poi.longitude),
      width: 34,
      height: 34,
      child: GestureDetector(
        onTap: () => _showPoiDetail(poi),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Color _poiColor(EmergencyPoiType type) => switch (type) {
    EmergencyPoiType.hospital => const Color(0xFF2196F3),
    EmergencyPoiType.policeStation => const Color(0xFF1565C0),
    EmergencyPoiType.fireStation => const Color(0xFFFF5722),
    EmergencyPoiType.pharmacy => const Color(0xFF4CAF50),
    EmergencyPoiType.shelter => const Color(0xFF9C27B0),
  };

  IconData _poiIcon(EmergencyPoiType type) => switch (type) {
    EmergencyPoiType.hospital => Icons.local_hospital_rounded,
    EmergencyPoiType.policeStation => Icons.local_police_rounded,
    EmergencyPoiType.fireStation => Icons.local_fire_department_rounded,
    EmergencyPoiType.pharmacy => Icons.local_pharmacy_rounded,
    EmergencyPoiType.shelter => Icons.night_shelter_rounded,
  };

  void _showPoiDetail(EmergencyPoi poi) {
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
            Row(
              children: [
                Icon(_poiIcon(poi.type), color: _poiColor(poi.type), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(poi.name, style: AppTypography.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(poi.type.label, style: AppTypography.bodyMedium),
            if (poi.phone != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(poi.phone!, style: AppTypography.bodyMedium),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${poi.latitude.toStringAsFixed(4)}, ${poi.longitude.toStringAsFixed(4)}',
              style: AppTypography.bodySmall,
            ),
          ],
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
      AlertPriority.danger => AppColors.high,
      AlertPriority.warning => AppColors.warning,
      AlertPriority.advisory => AppColors.success,
      AlertPriority.info => AppColors.secondaryLight,
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
      AlertCategory.militaryDefense => Icons.military_tech_rounded,
      AlertCategory.infrastructure => Icons.domain_rounded,
      AlertCategory.spaceAstronomical => Icons.satellite_alt_rounded,
      AlertCategory.maritimeAviation => Icons.flight_rounded,
    };
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

//  FILTER BAR WIDGET

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

//  DETAIL CHIP WIDGET

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
            style: AppTypography.bodySmall.copyWith(
              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textSecondary),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(value, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}
