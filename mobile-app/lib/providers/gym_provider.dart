import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../models/gym_model.dart';

enum GymLoadState { idle, loading, loaded, error }

class GymProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final LocationService _locationService = LocationService();

  GymLoadState _state = GymLoadState.idle;
  String _errorMessage = '';
  String _selectedCategory = '';
  double _radius = 15.0;

  List<GymModel> _nearbyGyms = [];
  List<GymModel> _searchResults = [];
  List<GymModel> _savedGyms = [];
  GymModel? _selectedGym;

  double _userLat = LocationService.fallbackLatitude;
  double _userLng = LocationService.fallbackLongitude;
  String _locationLabel = 'Washington DC';
  bool _useDeviceLocation = true;
  bool _locationLoaded = false;
  LocationPermissionStatus _locationPermissionStatus = LocationPermissionStatus.unknown;
  bool _usingFallbackLocation = false;

  // ── Search history ──────────────────────────────────────────────────────
  List<String> _searchHistory = [];
  static const _historyKey = 'search_history';
  static const _maxHistory = 8;

  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  GymLoadState get state => _state;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  double get radius => _radius;
  List<GymModel> get nearbyGyms => _nearbyGyms;
  List<GymModel> get searchResults => _searchResults;
  List<GymModel> get savedGyms => _savedGyms;
  GymModel? get selectedGym => _selectedGym;
  double get userLat => _userLat;
  double get userLng => _userLng;
  String get locationLabel => _locationLabel;
  bool get useDeviceLocation => _useDeviceLocation;
  bool get isLoading => _state == GymLoadState.loading;
  LocationPermissionStatus get locationPermissionStatus => _locationPermissionStatus;
  bool get usingFallbackLocation => _usingFallbackLocation;

  GymProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _radius        = prefs.getDouble('location_radius_km') ?? _radius;
    _locationLabel = prefs.getString('location_label')     ?? _locationLabel;
    _useDeviceLocation = prefs.getBool('use_device_location') ?? _useDeviceLocation;
    _userLat       = prefs.getDouble('location_lat')       ?? _userLat;
    _userLng       = prefs.getDouble('location_lng')       ?? _userLng;
    _searchHistory = prefs.getStringList(_historyKey)      ?? [];
    notifyListeners();
  }

  Future<void> _saveLocationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('location_radius_km', _radius);
    await prefs.setString('location_label', _locationLabel);
    await prefs.setBool('use_device_location', _useDeviceLocation);
    await prefs.setDouble('location_lat', _userLat);
    await prefs.setDouble('location_lng', _userLng);
  }

  // ── Search history helpers ───────────────────────────────────────────────

  Future<void> addToHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    _searchHistory.removeWhere((h) => h.toLowerCase() == q.toLowerCase());
    _searchHistory.insert(0, q);
    if (_searchHistory.length > _maxHistory) {
      _searchHistory = _searchHistory.take(_maxHistory).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _searchHistory);
    notifyListeners();
  }

  Future<void> removeFromHistory(String query) async {
    _searchHistory.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _searchHistory);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    notifyListeners();
  }

  // ── Geocoding: search by city/location name ──────────────────────────────

  /// Geocode a location name using Nominatim via backend proxy (avoids CORS).
  Future<Map<String, double>?> geocodeLocation(String locationName) async {
    // Try 3 different approaches in order
    
    // Approach 1: Direct Nominatim (works on Android/iOS native)
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'User-Agent': 'GYMatchApp/1.0 (contact@gymatch.com)',
          'Accept': 'application/json',
        },
      ));
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': locationName.trim(),
          'format': 'json',
          'limit': '1',
          'addressdetails': '0',
        },
      );
      final results = response.data;
      if (results is List && results.isNotEmpty) {
        final first = results[0] as Map;
        final lat = double.tryParse(first['lat']?.toString() ?? '');
        final lng = double.tryParse(first['lon']?.toString() ?? '');
        if (lat != null && lng != null) return {'lat': lat, 'lng': lng};
      }
    } catch (_) {
      // Fall through to next approach
    }

    // Approach 2: Photon geocoder (alternative free service, CORS-friendly)
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final response = await dio.get(
        'https://photon.komoot.io/api/',
        queryParameters: {'q': locationName.trim(), 'limit': '1'},
      );
      final features = response.data?['features'];
      if (features is List && features.isNotEmpty) {
        final coords = features[0]?['geometry']?['coordinates'];
        if (coords is List && coords.length >= 2) {
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          return {'lat': lat, 'lng': lng};
        }
      }
    } catch (_) {
      // Fall through
    }

    // Approach 3: Our own backend proxy (works everywhere, no CORS)
    try {
      final response = await _api.dio.get('/geocode', queryParameters: {'q': locationName.trim()});
      final data = response.data;
      if (data?['found'] == true) {
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        return {'lat': lat, 'lng': lng};
      }
    } catch (_) {
      // All approaches failed
    }

    return null;
  }

  /// Search by location name — geocodes then fetches gyms at that location.
  Future<bool> searchByLocation(String locationName) async {
    final coords = await geocodeLocation(locationName);
    if (coords == null) return false;

    _userLat = coords['lat']!;
    _userLng = coords['lng']!;
    _locationLabel = locationName;
    _useDeviceLocation = false;
    await _saveLocationPreferences();
    notifyListeners();
    await fetchNearbyGyms();
    return true;
  }

  /// Load user GPS position, then fetch nearby gyms.
  Future<void> initLocation() async {
    if (_locationLoaded) return;
    if (_useDeviceLocation) {
      try {
        final result = await _locationService.getCurrentPosition(requestIfDenied: false);
        _applyLocationResult(result);
        await _saveLocationPreferences();
      } catch (_) {
        // Use saved/fallback coordinates silently
      }
    }
    _locationLoaded = true;
    await fetchNearbyGyms();
  }

  Future<void> refreshDeviceLocation({bool requestPermission = true}) async {
    final result = await _locationService.getCurrentPosition(
      requestIfDenied: requestPermission,
    );
    _applyLocationResult(result);
    _useDeviceLocation = true;
    _locationLoaded = true;
    await _saveLocationPreferences();
    notifyListeners();
    await fetchNearbyGyms();
  }

  Future<void> retryLocationPermission() async {
    final status = await _locationService.requestPermission();
    _locationPermissionStatus = status;
    if (status == LocationPermissionStatus.granted) {
      await refreshDeviceLocation(requestPermission: false);
    } else {
      notifyListeners();
    }
  }

  Future<void> openLocationSettings() async {
    await _locationService.openAppSettings();
  }

  void _applyLocationResult(LocationResult result) {
    _userLat = result.position.latitude;
    _userLng = result.position.longitude;
    _locationPermissionStatus = result.status;
    _usingFallbackLocation = result.isFallback;
    if (!result.isFallback) {
      _locationLabel = 'Current Location';
    }
  }

  Future<void> updateLocationPreferences({
    required String label,
    required double latitude,
    required double longitude,
    required double radius,
    required bool useDeviceLocation,
  }) async {
    _locationLabel = label;
    _userLat = latitude;
    _userLng = longitude;
    _radius = radius;
    _useDeviceLocation = useDeviceLocation;
    _locationLoaded = true;
    await _saveLocationPreferences();
    notifyListeners();
    await fetchNearbyGyms();
  }

  /// Fetch gyms near current user location.
  Future<void> fetchNearbyGyms({String search = '', String? category, bool featuredOnly = false}) async {
    _state = GymLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final cat = category ?? _selectedCategory;
      final response = await _api.dio.get('/gyms', queryParameters: {
        'lat': _userLat,
        'lng': _userLng,
        'radius': _radius,
        if (search.isNotEmpty) 'search': search,
        if (cat.isNotEmpty && cat != 'GYM' && cat.toUpperCase() != 'ALL') 'category': cat,
        if (featuredOnly) 'featured': 'true',
      });

      final List<dynamic> data = response.data['gyms'] ?? [];
      _nearbyGyms = data.map((j) => GymModel.fromJson(j)).toList();
      _state = GymLoadState.loaded;
    } on DioException catch (e) {
      _state = GymLoadState.error;
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to load nearby gyms.';
    } catch (e) {
      _state = GymLoadState.error;
      _errorMessage = 'An unexpected error occurred.';
    }

    notifyListeners();
  }

  /// Set category filter and refresh.
  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    notifyListeners();
    await fetchNearbyGyms(category: category);
  }

  /// Search gyms by name/location text.
  Future<void> searchGyms(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _state = GymLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _api.dio.get('/gyms', queryParameters: {
        'lat': _userLat,
        'lng': _userLng,
        'radius': 50, // wider radius for search
        'search': query.trim(),
      });
      final List<dynamic> data = response.data['gyms'] ?? [];
      _searchResults = data.map((j) => GymModel.fromJson(j)).toList();
      _state = GymLoadState.loaded;
    } on DioException catch (e) {
      _state = GymLoadState.error;
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to search gyms.';
    } catch (e) {
      _state = GymLoadState.error;
      _errorMessage = 'An unexpected error occurred.';
    }

    notifyListeners();
  }

  /// Fetch full gym details by ID.
  Future<GymModel?> fetchGymDetail(int gymId) async {
    try {
      final response = await _api.dio.get('/gyms/$gymId');
      final gym = GymModel.fromJson(response.data);
      _selectedGym = gym;
      notifyListeners();
      return gym;
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to load gym details.';
      notifyListeners();
      return null;
    }
  }

  /// Toggle save/favorite for a gym (requires auth token).
  Future<bool?> toggleSaved(int gymId) async {
    try {
      final response = await _api.dio.post('/gyms/$gymId/favorite');
      final saved = response.data['saved'] as bool? ?? false;

      // Update in list
      _nearbyGyms = _nearbyGyms.map((g) {
        return g.id == gymId ? g.copyWith(isSaved: saved) : g;
      }).toList();

      if (_selectedGym?.id == gymId) {
        _selectedGym = _selectedGym!.copyWith(isSaved: saved);
      }

      // Refresh saved list
      await fetchSavedGyms();
      notifyListeners();
      return saved;
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to update saved gym.';
      notifyListeners();
      return null;
    }
  }

  /// Fetch all saved/favorite gyms for the logged-in user.
  Future<void> fetchSavedGyms() async {
    try {
      final response = await _api.dio.get('/gyms/favorites');
      final List<dynamic> data = response.data['gyms'] ?? [];
      _savedGyms = data.map((j) => GymModel.fromJson(j)).toList();
      notifyListeners();
    } on DioException catch (_) {
      // Non-fatal; saved gyms simply won't show
    }
  }

  /// Apply filter params and refresh nearby gyms.
  Future<void> applyFilters({
    required double radius,
    required String category,
    required bool openNow,
    required String rating,
    bool featuredOnly = false,
  }) async {
    _radius = radius;
    _selectedCategory = category;
    notifyListeners();

    await fetchNearbyGyms(category: category, featuredOnly: featuredOnly);

    // Client-side open/rating filter
    if (openNow) {
      _nearbyGyms = _nearbyGyms.where((g) => g.isOpen).toList();
    }
    final minRating = double.tryParse(rating.replaceAll('+', '').trim()) ?? 0;
    if (minRating > 0) {
      _nearbyGyms = _nearbyGyms.where((g) => g.rating >= minRating).toList();
    }
    notifyListeners();
  }

  /// Returns coordinate-normalized pins for the map canvas.
  /// Each pin has {x, y, type, gym}.
  List<Map<String, dynamic>> getMapPins() {
    if (_nearbyGyms.isEmpty) return [];

    final lats = _nearbyGyms.map((g) => g.latitude).toList();
    final lngs = _nearbyGyms.map((g) => g.longitude).toList();

    final minLat = lats.reduce((a, b) => a < b ? a : b) - 0.02;
    final maxLat = lats.reduce((a, b) => a > b ? a : b) + 0.02;
    final minLng = lngs.reduce((a, b) => a < b ? a : b) - 0.02;
    final maxLng = lngs.reduce((a, b) => a > b ? a : b) + 0.02;

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    return _nearbyGyms.take(8).map((gym) {
      final x = lngRange > 0 ? (gym.longitude - minLng) / lngRange : 0.5;
      // Invert y because screen y increases downward
      final y = latRange > 0 ? 1.0 - (gym.latitude - minLat) / latRange : 0.5;
      return {
        'x': x.clamp(0.05, 0.95),
        'y': y.clamp(0.05, 0.95),
        'type': 'gym',
        'gym': gym,
      };
    }).toList();
  }

  // Active workout partners state
  List<Map<String, dynamic>> _activePartners = [];
  List<Map<String, dynamic>> get activePartners => _activePartners;

  /// Fetch active workout partners at a gym.
  Future<List<Map<String, dynamic>>> fetchActivePartners(int gymId) async {
    try {
      final response = await _api.dio.get('/gyms/$gymId/active-partners');
      final List<dynamic> data = response.data['partners'] ?? [];
      _activePartners = data.map((item) => Map<String, dynamic>.from(item)).toList();
      notifyListeners();
      return _activePartners;
    } catch (e) {
      _errorMessage = 'Failed to load active workout partners.';
      notifyListeners();
      return [];
    }
  }

  /// Toggle active workout partner status for logged-in user at a gym.
  Future<bool?> togglePartnerStatus(int gymId, {String? status, String? workoutType, String? experienceLevel}) async {
    try {
      final response = await _api.dio.post(
        '/gyms/$gymId/partner-toggle',
        data: {
          if (status != null) 'status': status,
          if (workoutType != null) 'workout_type': workoutType,
          if (experienceLevel != null) 'experience_level': experienceLevel,
        },
      );
      final isActive = response.data['active'] as bool? ?? false;
      
      // Update selected gym active count locally
      if (_selectedGym?.id == gymId) {
        final currentCount = _selectedGym!.activePartnersCount;
        _selectedGym = _selectedGym!.copyWith(
          activePartnersCount: isActive ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0),
        );
      }

      await fetchActivePartners(gymId);
      notifyListeners();
      return isActive;
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to toggle active partner status.';
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
      return null;
    }
  }
}
