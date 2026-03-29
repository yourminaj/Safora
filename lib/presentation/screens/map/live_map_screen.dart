import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/geofence_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/colors.dart';
import '../shell/main_shell.dart';

/// Live tracking map screen.
///
/// Shows the user's real-time GPS position with geofence safe zone overlays.
/// Uses flutter_map + OpenStreetMap (free, no API key).
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _location = GetIt.instance<LocationService>();
  final GeofenceService _geofence = GetIt.instance<GeofenceService>();

  StreamSubscription<Position>? _positionSub;
  LatLng? _userPosition;
  String? _address;
  bool _showSafeZones = true;
  bool _isLocating = true;
  bool _followUser = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Get initial position.
    final pos = await _location.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _userPosition = LatLng(pos.latitude, pos.longitude);
        _isLocating = false;
      });
      _reverseGeocode(pos);
    } else if (mounted) {
      setState(() => _isLocating = false);
    }

    // Start streaming position updates.
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Meters — don't update for trivial movements.
      ),
    ).listen(
      _onPositionUpdate,
      onError: (_) {
        // Silently handle stream errors (permissions revoked, etc.).
      },
    );
  }

  void _onPositionUpdate(Position pos) {
    if (!mounted) return;
    final newPos = LatLng(pos.latitude, pos.longitude);
    setState(() => _userPosition = newPos);

    if (_followUser) {
      _animateMapTo(newPos);
    }

    _reverseGeocode(pos);
  }

  Future<void> _reverseGeocode(Position pos) async {
    final addr = await _location.getAddress(pos);
    if (mounted && addr != null) {
      setState(() => _address = addr);
    }
  }

  void _animateMapTo(LatLng target) {
    try {
      _mapController.move(target, _mapController.camera.zoom);
    } catch (_) {
      // MapController might not be ready yet.
    }
  }

  void _recenterOnUser() {
    if (_userPosition != null) {
      setState(() => _followUser = true);
      _animateMapTo(_userPosition!);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const defaultCenter = LatLng(23.8103, 90.4125); // Dhaka

    return Scaffold(
      appBar: AppBar(
        title: Text(l.liveMap),
        actions: [
          // Toggle safe zones visibility.
          IconButton(
            icon: Icon(
              _showSafeZones
                  ? Icons.shield_rounded
                  : Icons.shield_outlined,
            ),
            tooltip: _showSafeZones ? l.hideSafeZones : l.showSafeZones,
            onPressed: () => setState(() => _showSafeZones = !_showSafeZones),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition ?? defaultCenter,
              initialZoom: 15.0,
              maxZoom: 19.0,
              minZoom: 3.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  // User dragged the map — stop auto-following.
                  _followUser = false;
                }
              },
            ),
            children: [
              // OSM tile layer (free, no API key).
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.digitaldrive.safora',
                maxZoom: 19,
              ),

              // Geofence safe zone circles.
              if (_showSafeZones && _geofence.zones.isNotEmpty)
                CircleLayer(
                  circles: _geofence.zones.map((zone) {
                    return CircleMarker(
                      point: LatLng(zone.latitude, zone.longitude),
                      radius: zone.radiusMeters,
                      useRadiusInMeter: true,
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderColor: AppColors.success.withValues(alpha: 0.6),
                      borderStrokeWidth: 2,
                    );
                  }).toList(),
                ),

              // Safe zone center markers.
              if (_showSafeZones && _geofence.zones.isNotEmpty)
                MarkerLayer(
                  markers: _geofence.zones.map((zone) {
                    return Marker(
                      point: LatLng(zone.latitude, zone.longitude),
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // User location marker.
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 36,
                      height: 36,
                      child: _UserLocationDot(),
                    ),
                  ],
                ),
            ],
          ),

          // ── Loading overlay ────────────────────────────────────
          if (_isLocating)
            Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        l.myLocation,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom info card ─────────────────────────────────
          if (_userPosition != null && !_isLocating)
            Positioned(
              bottom: saforaBottomInset(context) + 8,
              left: 16,
              right: 16,
              child: _LocationInfoCard(
                position: _userPosition!,
                address: _address,
                safeZoneCount: _geofence.zones.length,
              ),
            ),
          // ── Premium re-center button — bottom-right ───────
          if (_userPosition != null && !_followUser)
            Positioned(
              bottom: saforaBottomInset(context) + 12,
              right: 20,
              child: GestureDetector(
                onTap: _recenterOnUser,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF5252),
                        Color(0xFFC62828),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  USER LOCATION DOT
// ═════════════════════════════════════════════════════════════════════

class _UserLocationDot extends StatefulWidget {
  @override
  State<_UserLocationDot> createState() => _UserLocationDotState();
}

class _UserLocationDotState extends State<_UserLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.2 * _pulse.value),
          ),
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  LOCATION INFO CARD
// ═════════════════════════════════════════════════════════════════════

class _LocationInfoCard extends StatelessWidget {
  const _LocationInfoCard({
    required this.position,
    this.address,
    required this.safeZoneCount,
  });

  final LatLng position;
  final String? address;
  final int safeZoneCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.myLocation,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        address ?? l.locationUnavailable,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.gps_fixed_rounded,
                  label:
                      '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(width: 8),
                if (safeZoneCount > 0)
                  _InfoChip(
                    icon: Icons.shield_rounded,
                    label: '$safeZoneCount ${l.safeZones}',
                    color: AppColors.success,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: chipColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
