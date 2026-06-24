import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'api_client.dart';

/// Represents a gym/fitness place result from Google Places API.
class PlaceResult {
  final String placeId;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int userRatingsTotal;
  final bool? isOpenNow;
  final String address;
  final List<String> types;
  final String? photoReference;

  const PlaceResult({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    this.isOpenNow,
    this.address = '',
    this.types = const [],
    this.photoReference,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;
    final photos = json['photos'] as List<dynamic>?;

    return PlaceResult(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: _toDouble(location?['lat']),
      longitude: _toDouble(location?['lng']),
      rating: _toDouble(json['rating']),
      userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt() ?? 0,
      isOpenNow: openingHours?['open_now'] as bool?,
      address: json['vicinity'] as String? ?? '',
      types: (json['types'] as List<dynamic>?)?.cast<String>() ?? [],
      photoReference: photos?.isNotEmpty == true
          ? (photos!.first as Map<String, dynamic>)['photo_reference'] as String?
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// Maps GYMATCH category names to Google Places API search keywords.
class CategoryKeyword {
  static const Map<String, String> _map = {
    'all':                  'gym fitness center',
    'crossfit':             'CrossFit gym',
    'mma':                  'MMA gym martial arts',
    'yoga':                 'yoga studio',
    'strength training':    'strength training gym',
    'bodybuilding':         'bodybuilding gym',
    'powerlifting':         'powerlifting gym',
    'cardio training':      'cardio fitness center',
    'hiit':                 'HIIT fitness gym',
    'functional fitness':   'functional fitness gym',
    'boxing':               'boxing gym',
    'kickboxing':           'kickboxing gym',
    'pilates':              'pilates studio',
    'zumba':                'zumba fitness class',
    'cycling / spinning':   'spinning cycling studio',
    'calisthenics':         'calisthenics gym',
    'personal training':    'personal training gym',
    'circuit training':     'circuit training gym',
    'aerobics':             'aerobics fitness center',
    'dance fitness':        'dance fitness studio',
    'mobility & stretching':'mobility stretching studio',
  };

  static String forCategory(String category) {
    return _map[category.toLowerCase()] ?? '${category.toLowerCase()} gym';
  }
}

/// Service for calling the Google Places Nearby Search API.
class GooglePlacesService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  final String apiKey;
  final Dio _dio;
  final Dio? _backendDio;

  /// Last API status for debugging empty results (e.g. REQUEST_DENIED, ZERO_RESULTS).
  String? lastStatus;
  String? lastErrorMessage;

  GooglePlacesService({required this.apiKey, Dio? backendDio})
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        _backendDio = backendDio;

  /// Search for gyms near [lat], [lng] within [radiusMeters] for a given [category].
  Future<List<PlaceResult>> searchNearbyGyms({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
    String category = 'All',
    bool openNow = false,
  }) async {
    lastStatus = null;
    lastErrorMessage = null;

    // Web cannot call Google Places REST API directly (CORS). Use backend proxy.
    if (kIsWeb) {
      return _searchViaBackend(
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
        category: category,
        openNow: openNow,
      );
    }

    if (apiKey.isEmpty || apiKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      lastStatus = 'MISSING_API_KEY';
      lastErrorMessage = 'Google Maps API key is not configured.';
      return [];
    }

    return _searchDirect(
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters,
      category: category,
      openNow: openNow,
    );
  }

  Future<List<PlaceResult>> _searchViaBackend({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String category,
    required bool openNow,
  }) async {
    try {
      final dio = _backendDio ?? ApiClient().dio;
      final response = await dio.get('/gyms/places-nearby', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radiusMeters.toInt(),
        'category': category,
        'openNow': openNow.toString(),
      });
      return _parsePlacesResponse(response.data);
    } on DioException catch (e) {
      lastStatus = 'NETWORK_ERROR';
      lastErrorMessage = e.message ?? 'Backend places proxy failed.';
      if (kDebugMode) {
        // ignore: avoid_print
        print('[GooglePlacesService] backend proxy error: $lastErrorMessage');
      }
      return [];
    } catch (e) {
      lastStatus = 'ERROR';
      lastErrorMessage = e.toString();
      return [];
    }
  }

  Future<List<PlaceResult>> _searchDirect({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String category,
    required bool openNow,
  }) async {
    try {
      final params = <String, dynamic>{
        'location': '$lat,$lng',
        'radius': radiusMeters.toInt().toString(),
        'type': 'gym',
        'key': apiKey,
        if (openNow) 'opennow': 'true',
      };

      // For "All", use type=gym only — adding keyword can over-filter results.
      if (category.toLowerCase() != 'all') {
        params['keyword'] = CategoryKeyword.forCategory(category);
      }

      final response = await _dio.get(_baseUrl, queryParameters: params);
      return _parsePlacesResponse(response.data);
    } catch (e) {
      lastStatus = 'ERROR';
      lastErrorMessage = e.toString();
      return [];
    }
  }

  List<PlaceResult> _parsePlacesResponse(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      lastStatus = 'INVALID_RESPONSE';
      return [];
    }

    final status = raw['status'] as String? ?? '';
    lastStatus = status;

    if (status == 'OK' || status == 'ZERO_RESULTS') {
      final results = raw['results'] as List<dynamic>? ?? [];
      return results
          .map((r) => PlaceResult.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    lastErrorMessage = raw['error_message'] as String? ??
        raw['error'] as String? ??
        'Places API returned $status';
    if (kDebugMode) {
      // ignore: avoid_print
      print('[GooglePlacesService] $lastStatus: $lastErrorMessage');
    }
    return [];
  }

  /// Get a photo URL for a given photo reference.
  String photoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=$maxWidth'
        '&photoreference=$photoReference'
        '&key=$apiKey';
  }
}
