import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();

  Stream<Uri> get linkStream => _appLinks.uriLinkStream;

  /// Handles deep link URLs and converts them to app routes
  String? handleDeepLink(Uri uri) {
    if (uri.path.startsWith('/reset-password')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        return '/reset-password?token=$token';
      }
    }
    return null;
  }

  /// Launch a URL (handles both http/https and app schemes)
  Future<bool> launchAppUrl(String url, {LaunchMode mode = LaunchMode.externalApplication}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    
    return await launchUrl(uri, mode: mode);
  }

  /// Check if a URL can be launched
  Future<bool> canLaunch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return await canLaunchUrl(uri);
  }

  /// Get initial link when app is launched from a deep link
  Future<Uri?> getInitialAppLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      return null;
    }
  }

  /// Setup deep link listener
  StreamSubscription<Uri> setupDeepLinkListener(BuildContext context) {
    return linkStream.listen((uri) {
      final route = handleDeepLink(uri);
      if (route != null) {
        context.go(route);
      }
    });
  }
}