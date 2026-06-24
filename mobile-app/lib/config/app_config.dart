import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Central place for Google Maps / Google Places API keys.
class AppConfig {
  AppConfig._();

  static const String googleMapsApiKeyAndroid =
      'AIzaSyAnat7KjNftq-ctwytsR317xVrs7BQ4OzA';
  static const String googleMapsApiKeyIos =
      'AIzaSyAaGohj2Cca0UhC0KWwdBhxAGVOpeCeHgk';

  /// Web uses the Maps JavaScript API (see web/index.html).
  static const String googleMapsApiKeyWeb = googleMapsApiKeyAndroid;

  /// Platform-appropriate key for Places API calls from Dart.
  static String get googleMapsApiKey {
    if (kIsWeb) return googleMapsApiKeyWeb;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return googleMapsApiKeyIos;
    }
    return googleMapsApiKeyAndroid;
  }
}
