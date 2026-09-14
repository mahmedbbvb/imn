import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/utils/app_logger.dart';

enum NetworkType { wifi, mobile, ethernet, none }

class NetworkStatus {
  final NetworkType type;
  final bool isConnected;

  const NetworkStatus({required this.type, required this.isConnected});

  @override
  String toString() => 'NetworkStatus(type: $type, connected: $isConnected)';
}

/// Monitors network connectivity and reports changes.
class NetworkMonitorService {
  final Connectivity _connectivity;
  final _statusController =
      StreamController<NetworkStatus>.broadcast();
  NetworkStatus _current =
      const NetworkStatus(type: NetworkType.none, isConnected: false);
  StreamSubscription? _subscription;

  NetworkMonitorService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  NetworkStatus get currentStatus => _current;
  Stream<NetworkStatus> get onStatusChange => _statusController.stream;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _current = _fromResults(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final newStatus = _fromResults(results);
      if (newStatus.type != _current.type ||
          newStatus.isConnected != _current.isConnected) {
        appLogger.i(
            'Network changed: ${_current.type} → ${newStatus.type}');
        _current = newStatus;
        _statusController.add(_current);
      }
    });
    appLogger.i('Network monitor initialized: $_current');
  }

  NetworkStatus _fromResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return const NetworkStatus(type: NetworkType.wifi, isConnected: true);
    } else if (results.contains(ConnectivityResult.mobile)) {
      return const NetworkStatus(
          type: NetworkType.mobile, isConnected: true);
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return const NetworkStatus(
          type: NetworkType.ethernet, isConnected: true);
    }
    return const NetworkStatus(type: NetworkType.none, isConnected: false);
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
