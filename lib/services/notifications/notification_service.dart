import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          appLogger.i('Notification clicked: ${details.payload}');
        },
      );

      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // 0. Foreground Service Channel
        const foregroundChannel = AndroidNotificationChannel(
          'imn_foreground_channel',
          'خدمة الخلفية',
          description: 'إشعار تشغيل الخدمة في الخلفية 24/7',
          importance: Importance.low,
          playSound: false,
        );

        // 1. Calls Channel
        const callChannel = AndroidNotificationChannel(
          'imn_calls_channel',
          'المكالمات الواردة',
          description: 'إشعارات المكالمات الصوتية والفيديو الواردة',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        // 2. Chat Messages Channel
        const messageChannel = AndroidNotificationChannel(
          'imn_messages_channel',
          'الرسائل الجديدة',
          description: 'إشعارات الرسائل والوسائط الجديدة',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        // 3. Contact Requests Channel
        const requestChannel = AndroidNotificationChannel(
          'imn_requests_channel',
          'طلبات المراسلة',
          description: 'إشعارات طلبات إضافة جهات الاتصال الجديدة',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await androidImplementation.createNotificationChannel(foregroundChannel);
        await androidImplementation.createNotificationChannel(callChannel);
        await androidImplementation.createNotificationChannel(messageChannel);
        await androidImplementation.createNotificationChannel(requestChannel);
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
      appLogger.i('NotificationService initialized successfully');
    } catch (e) {
      appLogger.e('NotificationService init error', error: e);
    }
  }

  // ── Show Call Notification (System Ringtone Sound, Heads-up) ──

  Future<void> showIncomingCallNotification({
    required int notificationId,
    required String callerName,
    required String callId,
    required bool isVideo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'imn_calls_channel',
      'المكالمات الواردة',
      channelDescription: 'إشعارات المكالمات الصوتية والفيديو الواردة',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
    );

    const details = NotificationDetails(android: androidDetails);
    final callType = isVideo ? 'مكالمة فيديو' : 'مكالمة صوتية';

    await _notificationsPlugin.show(
      notificationId,
      '📞 $callType واردة',
      'يتصل بك $callerName',
      details,
      payload: callId,
    );
  }

  // ── Show Chat Message Notification ───────────────────────────

  Future<void> showChatMessageNotification({
    required int notificationId,
    required String senderName,
    required String messageText,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'imn_messages_channel',
      'الرسائل الجديدة',
      channelDescription: 'إشعارات الرسائل والوسائط الجديدة',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.private,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      notificationId,
      senderName,
      messageText,
      details,
    );
  }

  // ── Show Contact Request Notification ────────────────────────

  Future<void> showContactRequestNotification({
    required int notificationId,
    required String senderName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'imn_requests_channel',
      'طلبات المراسلة',
      channelDescription: 'إشعارات طلبات إضافة جهات الاتصال الجديدة',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      notificationId,
      '📩 طلب مراسلة جديد',
      'ويرغب $senderName بالتواصل معك',
      details,
    );
  }

  // ── Cancel Notification ──────────────────────────────────────

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
