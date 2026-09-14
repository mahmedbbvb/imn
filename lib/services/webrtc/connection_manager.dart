import 'dart:async';
import 'dart:math';
import '../../core/utils/app_logger.dart';
import '../../services/webrtc/webrtc_service.dart';
import '../../services/signaling/signaling_service.dart';
import '../../services/network_monitor/network_monitor_service.dart';

enum ConnectionManagerState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Manages the full lifecycle of a P2P connection including automatic
/// reconnection with exponential backoff and ICE restart on network change.
class ConnectionManager {
  final WebRTCService _webrtc;
  final SignalingService _signaling;
  final NetworkMonitorService _networkMonitor;

  final _stateController =
      StreamController<ConnectionManagerState>.broadcast();

  ConnectionManagerState _state = ConnectionManagerState.disconnected;
  String? _sessionId;
  int _retryCount = 0;
  static const _maxRetries = 8;
  Timer? _retryTimer;
  StreamSubscription? _networkSub;
  StreamSubscription? _webrtcSub;
  bool _disposed = false;

  ConnectionManager({
    required WebRTCService webrtc,
    required SignalingService signaling,
    required NetworkMonitorService networkMonitor,
  })  : _webrtc = webrtc,
        _signaling = signaling,
        _networkMonitor = networkMonitor;

  Stream<ConnectionManagerState> get stateStream => _stateController.stream;
  ConnectionManagerState get state => _state;
  bool get isConnected => _state == ConnectionManagerState.connected;

  void initialize(String sessionId) {
    _sessionId = sessionId;

    // Watch WebRTC state
    _webrtcSub = _webrtc.connectionState.listen(_onWebRTCState);

    // Watch network changes
    _networkSub = _networkMonitor.onStatusChange.listen(_onNetworkChange);
  }

  void _onWebRTCState(PeerConnectionState state) {
    switch (state) {
      case PeerConnectionState.connected:
        _retryCount = 0;
        _retryTimer?.cancel();
        _setState(ConnectionManagerState.connected);
        break;
      case PeerConnectionState.reconnecting:
        _setState(ConnectionManagerState.reconnecting);
        _scheduleReconnect();
        break;
      case PeerConnectionState.failed:
        _setState(ConnectionManagerState.failed);
        _scheduleReconnect();
        break;
      default:
        break;
    }
  }

  void _onNetworkChange(NetworkStatus status) {
    appLogger.i('Network changed → ${status.type}');
    if (status.isConnected && _state == ConnectionManagerState.connected) {
      // Trigger ICE restart on network change
      _triggerIceRestart();
    } else if (!status.isConnected) {
      _setState(ConnectionManagerState.reconnecting);
    } else if (status.isConnected &&
        _state == ConnectionManagerState.reconnecting) {
      _scheduleReconnect(immediate: true);
    }
  }

  Future<void> _triggerIceRestart() async {
    appLogger.i('Triggering ICE restart...');
    _setState(ConnectionManagerState.reconnecting);
    try {
      final newSdp = await _webrtc.restartIce();
      if (newSdp != null && _sessionId != null && _signaling.isConnected) {
        _signaling.sendOffer(_sessionId!, newSdp);
      }
    } catch (e) {
      appLogger.e('ICE restart failed', error: e);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect({bool immediate = false}) {
    if (_disposed || _retryCount >= _maxRetries) {
      _setState(ConnectionManagerState.failed);
      appLogger.e('Max retries reached, giving up');
      return;
    }
    _retryTimer?.cancel();
    final delay = immediate
        ? Duration.zero
        : Duration(
            milliseconds:
                (1000 * pow(2, _retryCount)).clamp(1000, 30000).toInt());
    _retryCount++;
    appLogger.i(
        'Reconnect attempt $_retryCount in ${delay.inSeconds}s...');
    _retryTimer = Timer(delay, () async {
      if (!_disposed) {
        _setState(ConnectionManagerState.reconnecting);
        await _triggerIceRestart();
      }
    });
  }

  void _setState(ConnectionManagerState s) {
    if (_state == s) return;
    _state = s;
    _stateController.add(s);
    appLogger.d('ConnectionManager: $s');
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _networkSub?.cancel();
    _webrtcSub?.cancel();
    _stateController.close();
  }
}
