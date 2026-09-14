import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/utils/app_logger.dart';
import '../signaling/signaling_service.dart';

enum PeerConnectionState {
  idle,
  connecting,
  connected,
  reconnecting,
  failed,
  closed,
}

class WebRTCMessage {
  final String type; // 'msg' | 'ack' | 'typing' | 'file_chunk' | 'system'
  final String id;
  final dynamic payload;

  WebRTCMessage({required this.type, required this.id, required this.payload});

  Map<String, dynamic> toJson() =>
      {'type': type, 'id': id, 'payload': payload};

  factory WebRTCMessage.fromJson(Map<String, dynamic> json) => WebRTCMessage(
        type: json['type'] as String,
        id: json['id'] as String,
        payload: json['payload'],
      );
}

/// Manages WebRTC PeerConnection, DataChannel, and MediaStreams for voice/video calls.
class WebRTCService {
  static const _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final SignalingService _signaling;

  final _connectionStateController =
      StreamController<PeerConnectionState>.broadcast();
  final _messageController =
      StreamController<WebRTCMessage>.broadcast();
  final _remoteStreamController =
      StreamController<MediaStream>.broadcast();
  final _localStreamController =
      StreamController<MediaStream>.broadcast();

  PeerConnectionState _state = PeerConnectionState.idle;
  String? _currentSessionId;
  bool _isOffer = false;
  bool _isMicMuted = false;
  bool _isCameraEnabled = true;
  bool _isSpeakerphoneOn = false;

  WebRTCService({required SignalingService signaling})
      : _signaling = signaling;

  // ── Streams & Getters ────────────────────────────────────────
  Stream<PeerConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<WebRTCMessage> get messages => _messageController.stream;
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;
  Stream<MediaStream> get onLocalStream => _localStreamController.stream;

  PeerConnectionState get state => _state;
  bool get isConnected => _state == PeerConnectionState.connected;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isSpeakerphoneOn => _isSpeakerphoneOn;

  // ── Init PeerConnection ──────────────────────────────────────

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': _iceServers,
      'iceCandidatePoolSize': 10,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null &&
          candidate.candidate!.isNotEmpty &&
          _currentSessionId != null) {
        appLogger.d('ICE candidate: ${candidate.candidate}');
        _signaling.sendIceCandidate(_currentSessionId!, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      appLogger.d('ICE state: $state');
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _setState(PeerConnectionState.connected);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          _setState(PeerConnectionState.reconnecting);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _setState(PeerConnectionState.failed);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onDataChannel = (channel) {
      appLogger.i('Remote DataChannel received: ${channel.label}');
      _setupDataChannel(channel);
    };

    _peerConnection!.onTrack = (event) {
      appLogger.i('Remote track received: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      appLogger.d('PeerConnection state: $state');
    };
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    _dataChannel!.onMessage = (RTCDataChannelMessage msg) {
      try {
        final json = jsonDecode(msg.text) as Map<String, dynamic>;
        _messageController.add(WebRTCMessage.fromJson(json));
      } catch (e) {
        appLogger.e('DataChannel parse error', error: e);
      }
    };
    _dataChannel!.onDataChannelState = (state) {
      appLogger.d('DataChannel state: $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _setState(PeerConnectionState.connected);
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        _setState(PeerConnectionState.reconnecting);
      }
    };
  }

  // ── Media Stream Setup (Audio/Video Calls) ────────────────────

  Future<MediaStream> startLocalStream({required bool isVideo}) async {
    final mediaConstraints = {
      'audio': true,
      'video': isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    _localStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStreamController.add(_localStream!);

    if (_peerConnection != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _isMicMuted = false;
    _isCameraEnabled = isVideo;
    return _localStream!;
  }

  void toggleMicrophone(bool mute) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !mute;
      }
      _isMicMuted = mute;
    }
  }

  void toggleCamera(bool enable) {
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = enable;
      }
      _isCameraEnabled = enable;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      final track = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(track);
    }
  }

  void toggleSpeakerphone(bool enable) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enableSpeakerphone(enable);
      }
      _isSpeakerphoneOn = enable;
    }
  }

  // ── Offer (Initiator) ────────────────────────────────────────

  Future<String> createOffer(String sessionId, {bool enableMedia = false, bool isVideo = false}) async {
    _currentSessionId = sessionId;
    _isOffer = true;
    _setState(PeerConnectionState.connecting);
    await _createPeerConnection();

    if (enableMedia) {
      await startLocalStream(isVideo: isVideo);
    }

    // Create DataChannel as the initiator
    final dcInit = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 30;
    _dataChannel = await _peerConnection!.createDataChannel('imn-chat', dcInit);
    _setupDataChannel(_dataChannel!);

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': enableMedia ? true : false,
      'offerToReceiveVideo': isVideo ? true : false,
    });
    await _peerConnection!.setLocalDescription(offer);

    await Future.delayed(const Duration(milliseconds: 1000));
    final localDesc = await _peerConnection!.getLocalDescription();
    return localDesc?.sdp ?? offer.sdp!;
  }

  Future<void> setRemoteAnswer(String sdp) async {
    final answer = RTCSessionDescription(sdp, 'answer');
    await _peerConnection!.setRemoteDescription(answer);
  }

  // ── Answer (Responder) ───────────────────────────────────────

  Future<String> createAnswer(String sessionId, String offerSdp, {bool enableMedia = false, bool isVideo = false}) async {
    _currentSessionId = sessionId;
    _isOffer = false;
    _setState(PeerConnectionState.connecting);
    await _createPeerConnection();

    if (enableMedia) {
      await startLocalStream(isVideo: isVideo);
    }

    final offer = RTCSessionDescription(offerSdp, 'offer');
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);

    await Future.delayed(const Duration(milliseconds: 1000));
    final localDesc = await _peerConnection!.getLocalDescription();
    return localDesc?.sdp ?? answer.sdp!;
  }

  // ── ICE Candidates ───────────────────────────────────────────

  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    try {
      final candidate = RTCIceCandidate(
        candidateMap['candidate'] as String,
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int?,
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      appLogger.e('AddIceCandidate error', error: e);
    }
  }

  // ── Send Data ────────────────────────────────────────────────

  Future<void> sendMessage(WebRTCMessage message) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw StateError('DataChannel not open');
    }
    final json = jsonEncode(message.toJson());
    await _dataChannel!.send(RTCDataChannelMessage(json));
  }

  Future<void> sendBytes(Uint8List bytes) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw StateError('DataChannel not open');
    }
    await _dataChannel!.send(RTCDataChannelMessage.fromBinary(bytes));
  }

  // ── ICE Restart ──────────────────────────────────────────────

  Future<String?> restartIce() async {
    if (_peerConnection == null) return null;
    appLogger.i('ICE Restart initiated');
    _setState(PeerConnectionState.reconnecting);
    if (_isOffer) {
      final offer = await _peerConnection!.createOffer({'iceRestart': true});
      await _peerConnection!.setLocalDescription(offer);
      return offer.sdp;
    }
    return null;
  }

  // ── Cleanup ──────────────────────────────────────────────────

  Future<void> close() async {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _remoteStream?.getTracks().forEach((track) {
      track.stop();
    });
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    _localStream = null;
    _remoteStream = null;

    await _dataChannel?.close();
    await _peerConnection?.close();
    _dataChannel = null;
    _peerConnection = null;
    _currentSessionId = null;
    _setState(PeerConnectionState.closed);
  }

  void dispose() {
    close();
    _connectionStateController.close();
    _messageController.close();
    _remoteStreamController.close();
    _localStreamController.close();
  }

  void _setState(PeerConnectionState newState) {
    _state = newState;
    _connectionStateController.add(newState);
    appLogger.d('WebRTC state: $newState');
  }
}
