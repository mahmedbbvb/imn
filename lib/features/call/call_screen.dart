import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/providers.dart';
import '../../services/webrtc/call_service.dart';

class CallScreen extends ConsumerStatefulWidget {
  final CallInfo callInfo;
  final String? offerSdp;

  const CallScreen({
    super.key,
    required this.callInfo,
    this.offerSdp,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final webrtc = ref.read(webrtcServiceProvider);

    webrtc.onLocalStream.listen((stream) {
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = stream;
        });
      }
    });

    webrtc.onRemoteStream.listen((stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    });

    if (webrtc.localStream != null) {
      _localRenderer.srcObject = webrtc.localStream;
    }
    if (webrtc.remoteStream != null) {
      _remoteRenderer.srcObject = webrtc.remoteStream;
    }

    if (mounted) setState(() => _renderersInitialized = true);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callSvc = ref.read(callServiceProvider);
    final webrtc = ref.read(webrtcServiceProvider);
    final call = ref.watch(callServiceProvider).currentCall ?? widget.callInfo;
    final theme = Theme.of(context);

    if (call.state == CallState.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background / Video Views ──────────────────────────────────
            if (call.isVideo && _renderersInitialized) ...[
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                width: 120,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ] else ...[
              // Audio Call UI
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                      child: Text(
                        call.peerName.isNotEmpty
                            ? call.peerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      call.peerName,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      switch (call.state) {
                        CallState.outgoingRinging => 'جاري الاتصال...',
                        CallState.incomingRinging => 'مكالمة واردة...',
                        CallState.connected => 'المكالمة متصلة 🟢',
                        CallState.ended => 'انتهت المكالمة',
                        _ => '',
                      },
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            // ── Controls Bar ───────────────────────────────────────────────
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  if (call.state == CallState.connected) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mic Mute Toggle
                        _CallControlButton(
                          icon: webrtc.isMicMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          label: webrtc.isMicMuted ? 'مكتوم' : 'الميكروفون',
                          isActive: webrtc.isMicMuted,
                          activeColor: Colors.redAccent,
                          onTap: () {
                            setState(() {
                              webrtc.toggleMicrophone(!webrtc.isMicMuted);
                            });
                          },
                        ),
                        // Speakerphone Toggle
                        _CallControlButton(
                          icon: webrtc.isSpeakerphoneOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_down_rounded,
                          label: webrtc.isSpeakerphoneOn ? 'المكبر' : 'السماعة',
                          isActive: webrtc.isSpeakerphoneOn,
                          activeColor: theme.colorScheme.primary,
                          onTap: () {
                            setState(() {
                              webrtc.toggleSpeakerphone(!webrtc.isSpeakerphoneOn);
                            });
                          },
                        ),
                        // Camera Toggle (for Video Calls)
                        if (call.isVideo) ...[
                          _CallControlButton(
                            icon: webrtc.isCameraEnabled
                                ? Icons.videocam_rounded
                                : Icons.videocam_off_rounded,
                            label: webrtc.isCameraEnabled ? 'الكاميرا' : 'معطلة',
                            isActive: !webrtc.isCameraEnabled,
                            activeColor: Colors.redAccent,
                            onTap: () {
                              setState(() {
                                webrtc.toggleCamera(!webrtc.isCameraEnabled);
                              });
                            },
                          ),
                          _CallControlButton(
                            icon: Icons.cameraswitch_rounded,
                            label: 'تبديل',
                            onTap: () => webrtc.switchCamera(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // End or Accept/Reject Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (call.state == CallState.incomingRinging) ...[
                        // Reject Button
                        FloatingActionButton(
                          heroTag: 'reject_call',
                          backgroundColor: Colors.red,
                          onPressed: () async {
                            await callSvc.rejectCall();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white),
                        ),
                        // Accept Button
                        FloatingActionButton(
                          heroTag: 'accept_call',
                          backgroundColor: Colors.green,
                          onPressed: () async {
                            if (widget.offerSdp != null) {
                              await callSvc.answerCall(widget.offerSdp!);
                            }
                          },
                          child: const Icon(Icons.call_rounded,
                              color: Colors.white),
                        ),
                      ] else ...[
                        // End Call Button
                        FloatingActionButton.large(
                          heroTag: 'end_call',
                          backgroundColor: Colors.red,
                          onPressed: () async {
                            await callSvc.endCall();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white, size: 36),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: isActive
              ? (activeColor ?? Colors.blue)
              : Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
