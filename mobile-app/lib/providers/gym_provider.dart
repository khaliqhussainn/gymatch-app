import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../models/gym_model.dart';

// NetworkException is declared in api_client.dart

enum GymLoadState { idle, loading, loaded, error }

class GymProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final LocationService _locationService = LocationService();

  // State
  GymLoadState _state = GymLoadState.idle;
  String _errorMessage = '';
  String _selectedCategory = 'GYM';
  double _radius = 15.0;

  // Data
  List<GymModel> _nearbyGyms = [];
  List<GymModel> _searchResults = [];
  List<GymModel> _savedGyms = [];
  GymModel? _selectedGym;

  // Location
  double _userLat = LocationService.fallbackLatitude;
  double _userLng = LocationService.fallbackLongitude;
  String _locationLabel = 'Karachi Central';
  bool _useDeviceLocation = true;
  bool _locationLoaded = false;

  // Getters
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

  GymProvider() {
    _loadLocationPreferences();
  }

  Future<void> _loadLocationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _radius = prefs.getDouble('location_radius_km') ?? _radius;
    _locationLabel = prefs.getString('location_label') ?? _locationLabel;
    _useDeviceLocation = prefs.getBool('use_device_location') ?? _useDeviceLocation;
    _userLat = prefs.getDouble('location_lat') ?? _userLat;
    _userLng = prefs.getDouble('location_lng') ?? _userLng;
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

  /// Load user GPS position, then fetch nearby gyms.
  Future<void> initLocation() async {
    if (_locationLoaded) return;
    if (_useDeviceLocation) {
      try {
        final position = await _locationService.getCurrentPosition();
        _userLat = position.latitude;
        _userLng = position.longitude;
        _locationLabel = 'Current Location';
        await _saveLocationPreferences();
      } catch (_) {
        // Use saved/fallback coordinates silently
      }
    }
    _locationLoaded = true;
    await fetchNearbyGyms();
  }

  Future<void> refreshDeviceLocation() async {
    final position = await _locationService.getCurrentPosition();
    _userLat = position.latitude;
    _userLng = position.longitude;
    _locationLabel = 'Current Location';
    _useDeviceLocation = true;
    _locationLoaded = true;
    await _saveLocationPreferences();
    notifyListeners();
    await fetchNearbyGyms();
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
  Future<void> fetchNearbyGyms({String search = '', String? category}) async {
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
        if (cat.isNotEmpty && cat != 'GYM') 'category': cat,
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
  }) async {
    _radius = radius;
    _selectedCategory = category;
    notifyListeners();

    await fetchNearbyGyms(category: category);

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
        'x': (x as double).clamp(0.05, 0.95),
        'y': (y as double).clamp(0.05, 0.95),
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
