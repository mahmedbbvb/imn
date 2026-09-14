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

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        appLogger.i('Notification clicked: ${details.payload}');
      },
    );

    // Create Notification Channels
    final androidPlugin = FlutterLocalNotificationsPlugin();

    // 1. Calls Channel (Default Phone Ringtone, Heads-Up Banner, Max Importance)
    const callChannel = AndroidNotificationChannel(
      'imn_calls_channel',
      'المكالمات الواردة',
      description: 'إشعارات المكالمات الصوتية والفيديو الواردة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // 2. Chat Messages Channel (Default Notification Sound)
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

    final androidImplementation =
        androidPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(callChannel);
      await androidImplementation.createNotificationChannel(messageChannel);
      await androidImplementation.createNotificationChannel(requestChannel);
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
    appLogger.i('NotificationService initialized successfully');
  }

  // ── Show Call Notification (Ringtone Sound, Heads-up) ────────

  Future<void> showIncomingCallNotification({
    required int notificationId,
    required String callerName,
    required String callId,
    required bool isVideo,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'imn_calls_channel',
      'المكالمات الواردة',
      channelDescription: 'إشعارات المكالمات الصوتية والفيديو الواردة',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      sound: const RawResourceAndroidNotificationSound('ringtone'),
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
    );

    final details = NotificationDetails(android: androidDetails);
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
