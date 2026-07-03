import '../utils/distance_format.dart';

/// GymModel - data class representing a Gym from the backend API.
class GymModel {
  final int id;
  final String name;
  final String subName;
  final String locationName;
  final String nearLocation;
  final double latitude;
  final double longitude;
  final double rating;
  final bool isOpen;
  final String openHours;
  final String contactPhone;
  final String category;
  final double distanceKm;
  final String? coverImage;
  final int activePartnersCount;
  final bool isFeatured;

  // Detail-only fields (populated by getById)
  final List<String> images;
  final List<String> amenities;
  final List<GymPlan> plans;
  final bool isSaved;
  final bool isActivePartner;

  GymModel({
    required this.id,
    required this.name,
    required this.subName,
    required this.locationName,
    required this.nearLocation,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.isOpen,
    required this.openHours,
    required this.contactPhone,
    required this.category,
    required this.distanceKm,
    this.coverImage,
    this.activePartnersCount = 0,
    this.isFeatured = false,
    this.images = const [],
    this.amenities = const [],
    this.plans = const [],
    this.isSaved = false,
    this.isActivePartner = false,
  });

  String get distanceLabel => formatDistanceKm(distanceKm);

  /// True when a real phone number is available (not a placeholder).
  bool get hasContactPhone {
    if (contactPhone.isEmpty) return false;
    if (contactPhone.contains('555-0199')) return false;
    return contactPhone.replaceAll(RegExp(r'[^\d]'), '').length >= 7;
  }

  bool get hasRating => rating > 0;

  bool get hasOpenHours => openHours.isNotEmpty;

  static bool isPlaceholderImage(String url) {
    return url.contains('unsplash.com') || url.contains('placeholder');
  }

  /// Real image URLs only — excludes stock/placeholder images.
  List<String> get displayImages {
    final seen = <String>{};
    final urls = <String>[];
    for (final url in [...images, if (coverImage != null) coverImage!]) {
      final key = _imageIdentity(url);
      if (url.isNotEmpty &&
          !isPlaceholderImage(url) &&
          seen.add(key)) {
        urls.add(url);
        if (urls.length == 4) break;
      }
    }
    return urls;
  }

  static String _imageIdentity(String url) {
    // For base64 data URIs, use the full URL as identity
    if (url.startsWith('data:image')) {
      return url;
    }
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['photo_reference'] ?? url;
    } catch (_) {
      return url;
    }
  }

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      subName: json['sub_name'] as String? ?? '',
      locationName: json['location_name'] as String? ?? '',
      nearLocation: json['near_location'] as String? ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      rating: _toDouble(json['rating']),
      isOpen: (json['is_open'] == 1 || json['is_open'] == true),
      openHours: json['open_hours'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      category: json['category'] as String? ?? 'GYM',
      distanceKm: _toDouble(json['distance_km']),
      coverImage: json['cover_image'] as String?,
      activePartnersCount: (json['active_partners_count'] as num?)?.toInt() ?? 0,
      isFeatured: (json['is_featured'] == 1 || json['is_featured'] == true),
      images: (json['images'] as List?)?.cast<String>() ?? [],
      amenities: (json['amenities'] as List?)?.cast<String>() ?? [],
      plans: (json['plans'] as List?)
              ?.map((p) => GymPlan.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      isSaved: json['is_saved'] as bool? ?? false,
      isActivePartner: json['is_active_partner'] as bool? ?? false,
    );
  }

  GymModel copyWith({bool? isSaved, bool? isActivePartner, int? activePartnersCount}) {
    return GymModel(
      id: id,
      name: name,
      subName: subName,
      locationName: locationName,
      nearLocation: nearLocation,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      isOpen: isOpen,
      openHours: openHours,
      contactPhone: contactPhone,
      category: category,
      distanceKm: distanceKm,
      coverImage: coverImage,
      activePartnersCount: activePartnersCount ?? this.activePartnersCount,
      isFeatured: isFeatured,
      images: images,
      amenities: amenities,
      plans: plans,
      isSaved: isSaved ?? this.isSaved,
      isActivePartner: isActivePartner ?? this.isActivePartner,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class GymPlan {
  final int id;
  final int gymId;
  final String name;
  final double price;
  final String billingPeriod;
  final List<String> features;
  final bool isPremium;

  GymPlan({
    required this.id,
    required this.gymId,
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.features,
    required this.isPremium,
  });

  factory GymPlan.fromJson(Map<String, dynamic> json) {
    List<String> featureList = [];
    final raw = json['features'];
    if (raw is List) {
      featureList = raw.cast<String>();
    }

    return GymPlan(
      id: json['id'] as int? ?? 0,
      gymId: json['gym_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: GymModel._toDouble(json['price']),
      billingPeriod: json['billing_period'] as String? ?? 'mo',
      features: featureList,
      isPremium: (json['is_premium'] == 1 || json['is_premium'] == true),
    );
  }
}

/// A preset "preferred area" option for the Location Preferences screen,
/// admin-managed via the /api/locations endpoint.
class LocationPresetModel {
  final int id;
  final String label;
  final String subtitle;
  final double latitude;
  final double longitude;

  LocationPresetModel({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  factory LocationPresetModel.fromJson(Map<String, dynamic> json) {
    return LocationPresetModel(
      id: json['id'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      latitude: GymModel._toDouble(json['latitude']),
      longitude: GymModel._toDouble(json['longitude']),
    );
  }
}
