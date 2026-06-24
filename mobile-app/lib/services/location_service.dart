import 'package:geolocator/geolocator.dart';

/// Result of a location access attempt.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

class LocationResult {
  final Position position;
  final LocationPermissionStatus status;
  final bool isFallback;

  const LocationResult({
    required this.position,
    required this.status,
    required this.isFallback,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  LocationService._internal();

  static const double fallbackLatitude = 38.8893;
  static const double fallbackLongitude = -77.0091;

  LocationPermissionStatus _lastStatus = LocationPermissionStatus.unknown;
  LocationPermissionStatus get lastPermissionStatus => _lastStatus;

  bool get hasLocationAccess =>
      _lastStatus == LocationPermissionStatus.granted;

  Future<LocationPermissionStatus> checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _lastStatus = LocationPermissionStatus.serviceDisabled;
      return _lastStatus;
    }

    final permission = await Geolocator.checkPermission();
    _lastStatus = _mapPermission(permission);
    return _lastStatus;
  }

  /// Request system location permission. Call only after the user has seen
  /// the app's explanatory dialog (Apple Guideline 5.1.1).
  Future<LocationPermissionStatus> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _lastStatus = LocationPermissionStatus.serviceDisabled;
      return _lastStatus;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _lastStatus = _mapPermission(permission);
    return _lastStatus;
  }

  Future<LocationResult> getCurrentPosition({bool requestIfDenied = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _lastStatus = LocationPermissionStatus.serviceDisabled;
      return LocationResult(
        position: _fallbackPosition(),
        status: _lastStatus,
        isFallback: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestIfDenied) {
      permission = await Geolocator.requestPermission();
    }

    _lastStatus = _mapPermission(permission);

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return LocationResult(
        position: _fallbackPosition(),
        status: _lastStatus,
        isFallback: true,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      _lastStatus = LocationPermissionStatus.granted;
      return LocationResult(
        position: position,
        status: _lastStatus,
        isFallback: false,
      );
    } catch (_) {
      return LocationResult(
        position: _fallbackPosition(),
        status: _lastStatus,
        isFallback: true,
      );
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  Position _fallbackPosition() {
    return Position(
      latitude: fallbackLatitude,
      longitude: fallbackLongitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}
