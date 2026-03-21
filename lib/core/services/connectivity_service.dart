import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring internet connectivity status.
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;

  /// Whether the device currently has internet connectivity.
  bool get isOnline => _isOnline;

  /// Start listening to connectivity changes.
  void startMonitoring({Function(bool isOnline)? onChanged}) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        onChanged?.call(_isOnline);
      }
    });

    // Check initial state.
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
  }

  /// Check connectivity once (non-streaming).
  Future<bool> checkOnce() async {
    await _checkConnectivity();
    return _isOnline;
  }

  /// Stop listening to connectivity changes.
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopMonitoring();
  }
}
