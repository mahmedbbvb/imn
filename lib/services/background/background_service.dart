import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../core/providers.dart';
import '../notifications/notification_service.dart';
import '../signaling/signaling_service.dart';

class ImnBackgroundService {
  static final ImnBackgroundService _instance =
      ImnBackgroundService._internal();
  factory ImnBackgroundService() => _instance;
  ImnBackgroundService._internal();

  Future<void> initialize() async {
    try {
      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'imn_foreground_channel',
          initialNotificationTitle: 'Imn - متصل في الخلفية',
          initialNotificationContent: 'خدمة التشفير التلقائي تعمل على مدار 24 ساعة',
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
      );
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService().initialize();

    // Signaling Connection in Background Isolate
    final signaling = SignalingService(serverUrl: signalingServerUrl);
    await signaling.connect();

    signaling.messages?.listen((msg) async {
      try {
        switch (msg.type) {
          case SignalingMessageType.chatMessage:
            final data = msg.data;
            if (data != null) {
              final sender = msg.fromDeviceId ?? 'مستخدم';
              final messageId = data['messageId'] as String? ?? 'msg';
              await NotificationService().showChatMessageNotification(
                notificationId: messageId.hashCode,
                senderName: 'رسالة مشفرة جديدة',
                messageText: 'تلقيت رسالة من $sender',
              );
            }
            break;

          case SignalingMessageType.contactRequest:
            final data = msg.data;
            final name = data?['fromDisplayName'] as String? ?? 'مستخدم';
            await NotificationService().showContactRequestNotification(
              notificationId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              senderName: name,
            );
            break;

          case SignalingMessageType.callSignal:
            final data = msg.data;
            if (data != null && data['action'] == 'offer') {
              final callerName = data['callerName'] as String? ?? 'مستخدم';
              final callId = data['callId'] as String? ?? 'call';
              final isVideo = data['isVideo'] as bool? ?? false;
              await NotificationService().showIncomingCallNotification(
                notificationId: callId.hashCode,
                callerName: callerName,
                callId: callId,
                isVideo: isVideo,
              );
            } else if (data != null &&
                (data['action'] == 'ended' || data['action'] == 'reject')) {
              final callId = data['callId'] as String? ?? 'call';
              await NotificationService().cancelNotification(callId.hashCode);
            }
            break;

          default:
            break;
        }
      } catch (_) {}
    });

    service.on('stopService').listen((event) {
      signaling.disconnect();
      service.stopSelf();
    });
  } catch (_) {}
}
