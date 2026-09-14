import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/app_theme.dart';
import 'app.dart';
import 'core/providers.dart';
import 'services/notifications/notification_service.dart';
import 'services/background/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Notifications and 24/7 Background Service
  try {
    await NotificationService().initialize();
    await ImnBackgroundService().initialize();
  } catch (_) {}

  runApp(const ProviderScope(child: ImnApp()));
}

class ImnApp extends ConsumerStatefulWidget {
  const ImnApp({super.key});

  @override
  ConsumerState<ImnApp> createState() => _ImnAppState();
}

class _ImnAppState extends ConsumerState<ImnApp> {
  @override
  void initState() {
    super.initState();
    _initNetworkMonitor();
  }

  Future<void> _initNetworkMonitor() async {
    final monitor = ref.read(networkMonitorProvider);
    await monitor.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AppRoot(),
    );
  }
}
