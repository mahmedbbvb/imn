import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/utils/app_logger.dart';

enum SignalingMessageType {
  // Lifecycle
  ping,
  pong,
  // Device registration
  register,
  registered,
  // Session-based WebRTC signaling
  createSession,
  joinSession,
  sessionReady,
  sessionClosed,
  offer,
  answer,
  iceCandidate,
  // Contact requests (device-id-based routing)
  contactRequest,
  contactRequestResponse,
  contactRequestStatus,
  // Encrypted Chat Relay & Call Signaling
  chatMessage,
  chatMessageStatus,
  callSignal,
  callSignalStatus,
  // Errors
  error,
}

class SignalingMessage {
  final SignalingMessageType type;
  final String? sessionId;
  final String? deviceId;
  final String? targetDeviceId;
  final String? fromDeviceId;
  final Map<String, dynamic>? data;

  SignalingMessage({
    required this.type,
    this.sessionId,
    this.deviceId,
    this.targetDeviceId,
    this.fromDeviceId,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (sessionId != null) 'sessionId': sessionId,
        if (deviceId != null) 'deviceId': deviceId,
        if (targetDeviceId != null) 'targetDeviceId': targetDeviceId,
        if (fromDeviceId != null) 'fromDeviceId': fromDeviceId,
        if (data != null) 'data': data,
      };

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: SignalingMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SignalingMessageType.error,
      ),
      sessionId: json['sessionId'] as String?,
      deviceId: json['deviceId'] as String?,
      targetDeviceId: json['targetDeviceId'] as String?,
      fromDeviceId: json['fromDeviceId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// WebSocket-based signaling client.
/// Used for:
///  1. Device registration (routing contact requests)
///  2. WebRTC handshake (offer/answer/ICE)
class SignalingService {
  final String serverUrl;
  WebSocketChannel? _channel;
  StreamController<SignalingMessage>? _messageController;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _connected = false;
  bool _disposed = false;
  String? _registeredDeviceId;
  int _reconnectAttempts = 0;

  SignalingService({required this.serverUrl});

  bool get isConnected => _connected;
  Stream<SignalingMessage>? get messages => _messageController?.stream;

  // ── Connection ───────────────────────────────────────────────

  Future<void> connect() async {
    if (_disposed) return;
    try {
      _messageController ??= StreamController<SignalingMessage>.broadcast();
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      _reconnectAttempts = 0;
      appLogger.i('Signaling connected: $serverUrl');
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      _startPing();

      // Re-register device if we had a previous registration
      if (_registeredDeviceId != null) {
        _doRegister(_registeredDeviceId!);
      }
    } catch (e) {
      appLogger.e('Signaling connect failed', error: e);
      _connected = false;
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController?.close();
    _messageController = null;
    _connected = false;
    appLogger.i('Signaling disconnected');
  }

  // ── Device Registration ──────────────────────────────────────

  Future<void> registerDevice(String deviceId) async {
    _registeredDeviceId = deviceId;
    if (!_connected) {
      await connect();
    } else {
      _doRegister(deviceId);
    }
  }

  void _doRegister(String deviceId) {
    send(SignalingMessage(
      type: SignalingMessageType.register,
      deviceId: deviceId,
    ));
  }

  // ── Contact Requests ─────────────────────────────────────────

  void sendContactRequest(String targetDeviceId, Map<String, dynamic> data) {
    send(SignalingMessage(
      type: SignalingMessageType.contactRequest,
      targetDeviceId: targetDeviceId,
      data: data,
    ));
  }

  void sendContactRequestResponse(
      String targetDeviceId, bool accepted, {Map<String, dynamic>? extra}) {
    send(SignalingMessage(
      type: SignalingMessageType.contactRequestResponse,
      targetDeviceId: targetDeviceId,
      data: {'accepted': accepted, ...?extra},
    ));
  }

  // ── WebRTC Session Signaling ─────────────────────────────────

  void createSession(String sessionId) {
    send(SignalingMessage(
      type: SignalingMessageType.createSession,
      sessionId: sessionId,
    ));
  }

  void joinSession(String sessionId) {
    send(SignalingMessage(
      type: SignalingMessageType.joinSession,
      sessionId: sessionId,
    ));
  }

  void sendOffer(String sessionId, String sdp) {
    send(SignalingMessage(
      type: SignalingMessageType.offer,
      sessionId: sessionId,
      data: {'sdp': sdp},
    ));
  }

  void sendAnswer(String sessionId, String sdp) {
    send(SignalingMessage(
      type: SignalingMessageType.answer,
      sessionId: sessionId,
      data: {'sdp': sdp},
    ));
  }

  void sendIceCandidate(
      String sessionId, Map<String, dynamic> candidate) {
    send(SignalingMessage(
      type: SignalingMessageType.iceCandidate,
      sessionId: sessionId,
      data: candidate,
    ));
  }

  // ── Encrypted Chat Relay ──────────────────────────────────────

  void sendChatMessage(String targetDeviceId, Map<String, dynamic> data) {
    send(SignalingMessage(
      type: SignalingMessageType.chatMessage,
      targetDeviceId: targetDeviceId,
      data: data,
    ));
  }

  // ── Call Signaling Relay ──────────────────────────────────────

  void sendCallSignal(String targetDeviceId, Map<String, dynamic> data) {
    send(SignalingMessage(
      type: SignalingMessageType.callSignal,
      targetDeviceId: targetDeviceId,
      data: data,
    ));
  }

  // ── Generic Send ─────────────────────────────────────────────

  void send(SignalingMessage msg) {
    if (!_connected) {
      appLogger.w('Signaling not connected, dropping: ${msg.type.name}');
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(msg.toJson()));
    } catch (e) {
      appLogger.e('Signaling send error', error: e);
    }
  }

  // ── Internal ─────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final msg = SignalingMessage.fromJson(json);
      if (msg.type == SignalingMessageType.pong) return;
      appLogger.d('Signaling ← ${msg.type.name}');
      _messageController?.add(msg);
    } catch (e) {
      appLogger.e('Signaling parse error', error: e);
    }
  }

  void _onError(dynamic error) {
    appLogger.e('Signaling error', error: error);
    _connected = false;
    if (!_disposed) _scheduleReconnect();
  }

  void _onDone() {
    appLogger.i('Signaling connection closed');
    _connected = false;
    _pingTimer?.cancel();
    if (!_disposed) _scheduleReconnect();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_connected) {
        send(SignalingMessage(type: SignalingMessageType.ping));
      }
    });
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = Duration(
      seconds: (_reconnectAttempts * 2).clamp(2, 30),
    );
    appLogger.i('Signaling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(delay, () async {
      if (!_disposed && !_connected) {
        await connect();
      }
    });
  }
}
