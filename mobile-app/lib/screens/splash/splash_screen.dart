import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_logo.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showSplashAnimation = false;

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final authProvider = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    final seenSplash = (prefs.getBool('splash_seen') ?? false) || seenOnboarding;

    final autoLogin = authProvider.tryAutoLogin();
    if (seenSplash) {
      await autoLogin;
    } else {
      if (mounted) {
        setState(() => _showSplashAnimation = true);
      }
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 2000)),
        autoLogin,
      ]);
      await prefs.setBool('splash_seen', true);
    }

    if (!mounted) return;

    // 1. Already logged in → go straight to home
    if (authProvider.isAuthenticated || authProvider.isGuest) {
      context.go(AppRoutes.home);
      return;
    }

    if (!mounted) return;

    if (seenOnboarding) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _showSplashAnimation
            ? const AppLogo(size: 100)
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                )
            : const SizedBox.shrink(),
      ),
    );
  }
}
