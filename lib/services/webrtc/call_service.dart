import 'dart:async';
import '../../core/utils/app_logger.dart';
import '../signaling/signaling_service.dart';
import 'webrtc_service.dart';

enum CallState {
  idle,
  outgoingRinging,
  incomingRinging,
  connected,
  ended,
}

class CallInfo {
  final String callId;
  final String peerDeviceId;
  final String peerName;
  final bool isVideo;
  final CallState state;

  CallInfo({
    required this.callId,
    required this.peerDeviceId,
    required this.peerName,
    required this.isVideo,
    required this.state,
  });

  CallInfo copyWith({CallState? state}) => CallInfo(
        callId: callId,
        peerDeviceId: peerDeviceId,
        peerName: peerName,
        isVideo: isVideo,
        state: state ?? this.state,
      );
}

class CallService {
  final WebRTCService _webrtc;
  final SignalingService _signaling;

  final _callStateController = StreamController<CallInfo?>.broadcast();
  CallInfo? _currentCall;
  StreamSubscription? _signalingSub;

  CallService({
    required WebRTCService webrtc,
    required SignalingService signaling,
  })  : _webrtc = webrtc,
        _signaling = signaling {
    _listenToSignaling();
  }

  Stream<CallInfo?> get callStream => _callStateController.stream;
  CallInfo? get currentCall => _currentCall;

  // ── Listen for Signaling Call Events ──────────────────────────

  void _listenToSignaling() {
    _signalingSub = _signaling.messages?.listen((msg) async {
      if (msg.type == SignalingMessageType.callSignal) {
        final data = msg.data;
        if (data == null) return;
        final action = data['action'] as String?;
        final fromDeviceId = msg.fromDeviceId ?? data['fromDeviceId'] as String?;
        final callId = data['callId'] as String?;
        final isVideo = data['isVideo'] as bool? ?? false;
        final peerName = data['callerName'] as String? ?? 'مكالمة واردة';

        switch (action) {
          case 'offer':
            if (_currentCall == null && fromDeviceId != null && callId != null) {
              _currentCall = CallInfo(
                callId: callId,
                peerDeviceId: fromDeviceId,
                peerName: peerName,
                isVideo: isVideo,
                state: CallState.incomingRinging,
              );
              _callStateController.add(_currentCall);
            }
            break;

          case 'answer':
            if (_currentCall != null && _currentCall!.callId == callId) {
              final sdp = data['sdp'] as String?;
              if (sdp != null) {
                await _webrtc.setRemoteAnswer(sdp);
                _currentCall = _currentCall!.copyWith(state: CallState.connected);
                _callStateController.add(_currentCall);
              }
            }
            break;

          case 'reject':
          case 'ended':
            if (_currentCall != null && _currentCall!.callId == callId) {
              await _cleanUpCall();
            }
            break;

          case 'iceCandidate':
            if (_currentCall != null && _currentCall!.callId == callId) {
              final candidate = data['candidate'] as Map<String, dynamic>?;
              if (candidate != null) {
                await _webrtc.addIceCandidate(candidate);
              }
            }
            break;
        }
      }
    });
  }

  // ── Call Actions ─────────────────────────────────────────────

  Future<void> startCall({
    required String targetDeviceId,
    required String peerName,
    required bool isVideo,
    required String localName,
  }) async {
    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    _currentCall = CallInfo(
      callId: callId,
      peerDeviceId: targetDeviceId,
      peerName: peerName,
      isVideo: isVideo,
      state: CallState.outgoingRinging,
    );
    _callStateController.add(_currentCall);

    try {
      final offerSdp = await _webrtc.createOffer(callId, enableMedia: true, isVideo: isVideo);
      _signaling.sendCallSignal(targetDeviceId, {
        'action': 'offer',
        'callId': callId,
        'sdp': offerSdp,
        'isVideo': isVideo,
        'callerName': localName,
      });
    } catch (e) {
      appLogger.e('Start call error', error: e);
      await _cleanUpCall();
    }
  }

  Future<void> answerCall(String offerSdp) async {
    if (_currentCall == null) return;
    try {
      final answerSdp = await _webrtc.createAnswer(_currentCall!.callId, offerSdp, enableMedia: true, isVideo: _currentCall!.isVideo);
      _signaling.sendCallSignal(_currentCall!.peerDeviceId, {
        'action': 'answer',
        'callId': _currentCall!.callId,
        'sdp': answerSdp,
      });
      _currentCall = _currentCall!.copyWith(state: CallState.connected);
      _callStateController.add(_currentCall);
    } catch (e) {
      appLogger.e('Answer call error', error: e);
      await _cleanUpCall();
    }
  }

  Future<void> rejectCall() async {
    if (_currentCall == null) return;
    _signaling.sendCallSignal(_currentCall!.peerDeviceId, {
      'action': 'reject',
      'callId': _currentCall!.callId,
    });
    await _cleanUpCall();
  }

  Future<void> endCall() async {
    if (_currentCall == null) return;
    _signaling.sendCallSignal(_currentCall!.peerDeviceId, {
      'action': 'ended',
      'callId': _currentCall!.callId,
    });
    await _cleanUpCall();
  }

  Future<void> _cleanUpCall() async {
    await _webrtc.close();
    _currentCall = _currentCall?.copyWith(state: CallState.ended);
    _callStateController.add(_currentCall);
    await Future.delayed(const Duration(milliseconds: 500));
    _currentCall = null;
    _callStateController.add(null);
  }

  void dispose() {
    _signalingSub?.cancel();
    _callStateController.close();
  }
}
