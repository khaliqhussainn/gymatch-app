import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/gym_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock mobile builds to portrait. On web, orientation lock can trigger
  // browser resize/view-inset assertions in Flutter's web engine.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deepLinkService = DeepLinkService();
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _handleInitialDeepLink();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialDeepLink() async {
    // Handle initial deep link when app is launched from a link
    final initialUri = await _deepLinkService.getInitialAppLink();
    if (initialUri != null) {
      final route = _deepLinkService.handleDeepLink(initialUri);
      if (route != null) {
        // Navigate to the route
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final context = appRouter.routerDelegate.navigatorKey.currentContext;
            if (context != null) {
              context.go(route);
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Setup deep link listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_deepLinkSubscription == null) {
        _deepLinkSubscription = _deepLinkService.setupDeepLinkListener(context);
      }
    });

    return MaterialApp.router(
      title: 'GYMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
