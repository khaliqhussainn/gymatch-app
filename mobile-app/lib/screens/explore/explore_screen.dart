import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/google_places_service.dart';
import '../../models/gym_model.dart';
import '../../config/app_config.dart';
import '../../widgets/featured_badge.dart';
import '../../widgets/location_permission_dialog.dart';
import '../../services/location_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Google Maps Dark Style JSON
// ──────────────────────────────────────────────────────────────────────────────
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a0a0a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0a0a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0f1a0f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#4a6741"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#1e1e1e"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#242424"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#323232"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#050a0e"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';

// ──────────────────────────────────────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  GoogleMapController? _mapController;
  int _selectedFilterIndex = -1;
  bool _isOpenNow = false;
  String _selectedDistance = '15 KM';
  String _selectedCategory = 'All';
  String _selectedRating = '4.0+';
  bool _featuredOnly = false;
  bool _isLocating = false;
  GymModel? _selectedPin;               // backend gym pin
  PlaceResult? _selectedPlacePin;       // Google Places real gym pin
  GymProvider? _gymProvider;

  // Selected partner pin state
  Map<String, dynamic>? _selectedPartner;
  GymModel? _selectedPartnerGym;
  bool _partnerCardLoading = false;

  // Track last known location to detect external changes
  double _lastLat = 0;
  double _lastLng = 0;

  // Google Maps markers
  final Map<MarkerId, Marker> _markers = {};

  // Google Places results
  List<PlaceResult> _placeResults = [];
  bool _placesLoading = false;

  final GooglePlacesService _placesService = GooglePlacesService(
    apiKey: AppConfig.googleMapsApiKey,
  );

  final List<String> _quickFilters = [
    'Open Now', 'Near me', 'CrossFit', 'Boxing', 'HIIT', 'Yoga'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gymProvider = Provider.of<GymProvider>(context, listen: false);
      _gymProvider!.addListener(_onProviderLocationChanged);
      _gymProvider!.initLocation();
      _lastLat = _gymProvider!.userLat;
      _lastLng = _gymProvider!.userLng;
      // Trigger initial Google Places search after location is loaded
      _searchGooglePlaces();
    });
  }

  @override
  void dispose() {
    _gymProvider?.removeListener(_onProviderLocationChanged);
    _mapController?.dispose();
    super.dispose();
  }

  /// Called whenever GymProvider notifies — check if location changed externally
  void _onProviderLocationChanged() {
    final gymProvider = _gymProvider;
    if (gymProvider == null || !mounted) return;

    final newLat = gymProvider.userLat;
    final newLng = gymProvider.userLng;

    if ((newLat - _lastLat).abs() > 0.0001 || (newLng - _lastLng).abs() > 0.0001) {
      _lastLat = newLat;
      _lastLng = newLng;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(newLat, newLng)),
          );
          setState(() {
            _selectedPin = null;
            _selectedPlacePin = null;
          });
          _searchGooglePlaces();
        }
      });
    }
  }

  // ── Google Places search ────────────────────────────────────────────────────
  Future<void> _searchGooglePlaces({String? category, bool? openNow}) async {
    final gymProvider = _gymProvider;
    if (gymProvider == null) return;

    final cat = category ?? _selectedCategory;
    final isOpen = openNow ?? _isOpenNow;
    final radiusKm = double.tryParse(_selectedDistance.replaceAll(' KM', '')) ?? 15.0;
    final radiusMeters = (radiusKm * 1000).toInt().clamp(500, 50000);

    setState(() => _placesLoading = true);

    final results = await _placesService.searchNearbyGyms(
      lat: gymProvider.userLat,
      lng: gymProvider.userLng,
      radiusMeters: radiusMeters.toDouble(),
      category: cat,
      openNow: isOpen,
    );

    if (!mounted) return;
    setState(() {
      _placeResults = results;
      _placesLoading = false;
    });

    _buildMarkers(gymProvider);
  }

  // ── Build Google Map markers ────────────────────────────────────────────────
  void _buildMarkers(GymProvider gymProvider) {
    if (!mounted) return;
    final newMarkers = <MarkerId, Marker>{};

    // 1. Google Places real gym markers (neon green)
    for (int i = 0; i < _placeResults.length; i++) {
      final place = _placeResults[i];
      final markerId = MarkerId('place_${place.placeId}');
      newMarkers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(place.latitude, place.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.rating > 0
              ? '⭐ ${place.rating.toStringAsFixed(1)} · ${place.address}'
              : place.address,
        ),
        onTap: () {
          setState(() {
            _selectedPlacePin = place;
            _selectedPin = null;
            _selectedPartner = null;
            _selectedPartnerGym = null;
          });
        },
      );
    }

    // 2. Backend gym markers (neon yellow — featured/saved gyms)
    for (final gym in gymProvider.nearbyGyms) {
      final markerId = MarkerId('gym_${gym.id}');
      final isFeatured = gym.isFeatured;
      newMarkers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(gym.latitude, gym.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isFeatured ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueCyan,
        ),
        infoWindow: InfoWindow(
          title: gym.name,
          snippet: '(${gym.distanceLabel}) ⭐ ${gym.rating.toStringAsFixed(1)}',
        ),
        onTap: () {
          setState(() {
            _selectedPin = gym;
            _selectedPlacePin = null;
            _selectedPartner = null;
            _selectedPartnerGym = null;
          });
        },
      );
    }

    // 3. Partner markers (neon green person icon)
    final rand = math.Random(42);
    for (final gym in gymProvider.nearbyGyms) {
      if (gym.activePartnersCount <= 0) continue;
      final count = math.min(gym.activePartnersCount, 3);
      for (int i = 0; i < count; i++) {
        final latOffset = (rand.nextDouble() - 0.5) * 0.006;
        final lngOffset = (rand.nextDouble() - 0.5) * 0.006;
        final markerId = MarkerId('partner_${gym.id}_$i');
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        newMarkers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(gym.latitude + latOffset, gym.longitude + lngOffset),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueMagenta,
          ),
          infoWindow: InfoWindow(
            title: 'Active Partner',
            snippet: 'At ${gym.name}',
          ),
          onTap: () async {
            if (authProvider.isGuest) {
              _showUnlockCommunityModal();
              return;
            }
            setState(() {
              _selectedPin = null;
              _selectedPlacePin = null;
              _selectedPartner = null;
              _selectedPartnerGym = null;
              _partnerCardLoading = true;
            });
            try {
              final gymProvider = Provider.of<GymProvider>(context, listen: false);
              final partners = await gymProvider.fetchActivePartners(gym.id);
              if (!mounted) return;
              final idx = i < partners.length ? i : partners.length - 1;
              final partner = idx >= 0 ? partners[idx] : null;
              if (partner != null) {
                Map<String, dynamic> enriched = {...partner, 'gymId': gym.id, 'gymName': gym.name};
                try {
                  final uid = (partner['userId'] as num?)?.toInt();
                  if (uid != null) {
                    final resp = await ApiClient().dio.get('/users/$uid/profile');
                    enriched = {
                      ...enriched,
                      ...Map<String, dynamic>.from(resp.data),
                      'gymId': gym.id,
                      'gymName': gym.name,
                      'workoutType': partner['workoutType'] ?? '',
                    };
                  }
                } catch (_) {}
                if (mounted) {
                  setState(() {
                    _selectedPartner = enriched;
                    _selectedPartnerGym = gym;
                    _partnerCardLoading = false;
                  });
                }
              } else {
                if (mounted) {
                  setState(() => _partnerCardLoading = false);
                  context.push(AppRoutes.gymDetail, extra: gym.id);
                }
              }
            } catch (_) {
              if (mounted) setState(() => _partnerCardLoading = false);
            }
          },
        );
      }
    }

    // 4. User location marker
    final userMarkerId = const MarkerId('user_location');
    newMarkers[userMarkerId] = Marker(
      markerId: userMarkerId,
      position: LatLng(gymProvider.userLat, gymProvider.userLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'You are here'),
    );

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  // ── Quick filter handler ────────────────────────────────────────────────────
  Future<void> _applyQuickFilter(int index, GymProvider gymProvider) async {
    setState(() {
      _selectedFilterIndex = index;
      _selectedPin = null;
      _selectedPlacePin = null;
    });

    String cat = 'All';
    bool open = false;
    double rad = gymProvider.radius;

    switch (index) {
      case 0: // Open Now
        setState(() { _selectedDistance = '${rad.toInt()} KM'; _selectedCategory = 'All'; _selectedRating = ''; _isOpenNow = true; });
        cat = 'All'; open = true;
        break;
      case 1: // Near Me
        setState(() { _selectedDistance = '5 KM'; _selectedCategory = 'All'; _selectedRating = ''; _isOpenNow = false; });
        cat = 'All'; open = false; rad = 5;
        break;
      case 2: // CrossFit
        setState(() { _selectedDistance = '15 KM'; _selectedCategory = 'CrossFit'; _selectedRating = ''; _isOpenNow = false; });
        cat = 'CrossFit'; open = false;
        break;
      case 3: // Boxing
        setState(() { _selectedDistance = '15 KM'; _selectedCategory = 'Boxing'; _selectedRating = ''; _isOpenNow = false; });
        cat = 'Boxing'; open = false;
        break;
      case 4: // HIIT
        setState(() { _selectedDistance = '15 KM'; _selectedCategory = 'HIIT'; _selectedRating = ''; _isOpenNow = false; });
        cat = 'HIIT'; open = false;
        break;
      case 5: // Yoga
        setState(() { _selectedDistance = '15 KM'; _selectedCategory = 'Yoga'; _selectedRating = ''; _isOpenNow = false; });
        cat = 'Yoga'; open = false;
        break;
    }

    await gymProvider.applyFilters(
      radius: rad,
      category: cat == 'All' ? '' : cat,
      openNow: open,
      rating: _selectedRating,
      featuredOnly: _featuredOnly,
    );

    await _searchGooglePlaces(category: cat, openNow: open);
    _moveMapToProviderLocation(gymProvider);
  }

  void _showFilterBottomSheet(GymProvider gymProvider) {
    bool localFeaturedOnly = _featuredOnly;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48, height: 5,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('FILTERS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                        TextButton(
                          onPressed: () => setModalState(() {
                            _selectedDistance = '15 KM';
                            _selectedCategory = 'All';
                            _selectedRating = '';
                            _isOpenNow = false;
                            localFeaturedOnly = false;
                          }),
                          child: const Text('Clear All', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Distance Filter
                    const Text('Distance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['1 KM', '3 KM', '5 KM', '10 KM', '15 KM'].map((dist) {
                          final isSelected = dist == _selectedDistance;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(dist),
                              selected: isSelected,
                              onSelected: (_) => setModalState(() => _selectedDistance = dist),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.white12)),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Filter
                    const Text('Category', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          'All', 'CrossFit', 'MMA', 'Yoga', 'Strength Training',
                          'Bodybuilding', 'Powerlifting', 'Cardio Training', 'HIIT',
                          'Functional Fitness', 'Boxing', 'Kickboxing', 'Pilates',
                          'Zumba', 'Cycling / Spinning', 'Calisthenics',
                          'Personal Training', 'Circuit Training', 'Aerobics',
                          'Dance Fitness', 'Mobility & Stretching',
                        ].map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => setModalState(() => _selectedCategory = cat),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.white12)),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rating Filter
                    const Text('Rating', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['Any', '5.0', '4.0+', '3.0+', '2.0+', '1.0+'].map((rate) {
                          final ratingValue = rate == 'Any' ? '' : rate;
                          final isSelected = ratingValue == _selectedRating;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(rate),
                              selected: isSelected,
                              onSelected: (_) => setModalState(() => _selectedRating = ratingValue),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.white12)),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Open Now Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Open Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(_isOpenNow ? 'ON' : 'OFF', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Switch(
                              value: _isOpenNow,
                              onChanged: (val) => setModalState(() => _isOpenNow = val),
                              activeColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white12,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Featured Only Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('FEATURED', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            const Text(' Only', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            Text(localFeaturedOnly ? 'ON' : 'OFF', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Switch(
                              value: localFeaturedOnly,
                              onChanged: (val) => setModalState(() => localFeaturedOnly = val),
                              activeColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white12,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Apply Button
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final radius = double.tryParse(_selectedDistance.replaceAll(' KM', '')) ?? 15.0;
                          setState(() {
                            _selectedFilterIndex = -1;
                            _selectedPin = null;
                            _selectedPlacePin = null;
                            _featuredOnly = localFeaturedOnly;
                          });
                          await gymProvider.applyFilters(
                            radius: radius,
                            category: _selectedCategory,
                            openNow: _isOpenNow,
                            rating: _selectedRating,
                            featuredOnly: localFeaturedOnly,
                          );
                          await _searchGooglePlaces();
                          _moveMapToProviderLocation(gymProvider);
                        },
                        child: const Text('APPLY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUnlockCommunityModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFA151515),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                child: const Center(child: Icon(Icons.person_rounded, color: Colors.black, size: 38)),
              ),
              const SizedBox(height: 20),
              const Text('UNLOCK THE COMMUNITY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              const Text(
                'Sign up for a free account to turn on your active status and see who is looking for a workout partner right now.',
                style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), elevation: 0),
                  onPressed: () { Navigator.pop(context); context.go(AppRoutes.register); },
                  child: const Text('Create Free Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  GestureDetector(
                    onTap: () { Navigator.pop(context); context.go(AppRoutes.login); },
                    child: Text('Log In', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveMapToProviderLocation(GymProvider gymProvider) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(gymProvider.userLat, gymProvider.userLng)),
    );
  }

  Future<void> _refreshCurrentLocation(GymProvider gymProvider) async {
    if (_isLocating) return;

    if (gymProvider.locationPermissionStatus != LocationPermissionStatus.granted) {
      final shouldContinue = await showLocationPermissionRationale(context);
      if (!shouldContinue) return;
    }

    setState(() { _isLocating = true; _selectedPin = null; _selectedPlacePin = null; });
    try {
      await gymProvider.refreshDeviceLocation();
      if (mounted) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(gymProvider.userLat, gymProvider.userLng), 14.0),
        );
        await _searchGooglePlaces();
        _buildMarkers(gymProvider);
        if (mounted) {
          final msg = gymProvider.usingFallbackLocation
              ? 'Location unavailable. Showing default area.'
              : 'Location updated.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<GymProvider, AuthProvider>(
        builder: (context, gymProvider, authProvider, _) {
          final centerLat = gymProvider.userLat;
          final centerLng = gymProvider.userLng;

          // Rebuild markers when backend gyms update
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _buildMarkers(gymProvider);
          });

          return Stack(
            children: [
              // ── GOOGLE MAP ────────────────────────────────────────────
              Positioned.fill(
                child: GoogleMap(
                  style: _darkMapStyle,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(centerLat, centerLng),
                    zoom: 14.0,
                  ),
                  markers: Set<Marker>.of(_markers.values),
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _buildMarkers(gymProvider);
                  },
                  onTap: (LatLng _) => setState(() {
                    _selectedPin = null;
                    _selectedPlacePin = null;
                    _selectedPartner = null;
                    _selectedPartnerGym = null;
                  }),
                ),
              ),

              // ── TOP HUD: Search + Quick Filters ──────────────────────
              Positioned(
                left: 20, right: 20, top: 60,
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFA161616),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(Icons.search_rounded, color: Colors.white38, size: 22),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push(AppRoutes.search),
                              child: const AbsorbPointer(
                                child: TextField(
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search gyms, partners, locations',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showFilterBottomSheet(gymProvider),
                            icon: Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick filter chips
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickFilters.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedFilterIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _applyQuickFilter(index, gymProvider),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? AppColors.primary : Colors.white12),
                                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)] : null,
                                ),
                                child: Text(
                                  _quickFilters[index],
                                  style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, fontSize: 13),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              // ── Places loading indicator ──────────────────────────────
              if (_placesLoading)
                Positioned(
                  top: 175,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFA141414),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                          const SizedBox(width: 8),
                          const Text('Finding gyms...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Google Places result count badge ──────────────────────
              if (!_placesLoading && _placeResults.isNotEmpty)
                Positioned(
                  top: 175,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded, color: Colors.black, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '${_placeResults.length} real gyms found',
                            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Featured-only active indicator chip ───────────────────
              if (_featuredOnly)
                Positioned(
                  left: 20, top: 170,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.black, size: 14),
                        SizedBox(width: 4),
                        Text('Featured Only', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),

              // ── Legend ────────────────────────────────────────────────
              Positioned(
                left: 16, bottom: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(Colors.green, 'Real Gyms (Google)'),
                    const SizedBox(height: 4),
                    _buildLegendItem(Colors.cyan, 'Saved Gyms'),
                    const SizedBox(height: 4),
                    _buildLegendItem(Colors.yellow, 'Featured Gyms'),
                    const SizedBox(height: 4),
                    _buildLegendItem(Colors.purple, 'Active Partners'),
                  ],
                ),
              ),

              // ── Google Place Pin Preview Card ─────────────────────────
              if (_selectedPlacePin != null)
                Positioned(
                  left: 16, right: 16, bottom: 180,
                  child: _buildPlaceCard(_selectedPlacePin!),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2),

              // ── Backend Gym Pin Preview Card ──────────────────────────
              if (_selectedPin != null && _selectedPlacePin == null)
                Positioned(
                  left: 16, right: 16, bottom: 180,
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.gymDetail, extra: _selectedPin!.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFA141414),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedPin!.isFeatured ? AppColors.primary.withOpacity(0.6) : Colors.white10,
                          width: _selectedPin!.isFeatured ? 1.5 : 1,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedPin!.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedPin!.isFeatured) ...[
                                const SizedBox(width: 8),
                                const FeaturedBadge(fontSize: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('(${_selectedPin!.distanceLabel})', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                              const Icon(Icons.people_alt_rounded, color: Colors.white38, size: 14),
                              const SizedBox(width: 4),
                              Text('${_selectedPin!.activePartnersCount} live partners', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              const Spacer(),
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(_selectedPin!.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Tap to view full details →', style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2),

              // ── Partner pin loading indicator ─────────────────────────
              if (_partnerCardLoading)
                Positioned(
                  left: 16, right: 16, bottom: 180,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFA141414),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFCBF135), strokeWidth: 2.5)),
                        SizedBox(width: 12),
                        Text('Loading partner...', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 150.ms),

              // ── Partner Pin Preview Card ──────────────────────────────
              if (_selectedPartner != null && _selectedPartnerGym != null)
                Positioned(
                  left: 16, right: 16, bottom: 180,
                  child: _buildPartnerPinCard(authProvider: authProvider),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2),

              // ── Location permission banner ────────────────────────────
              if (gymProvider.usingFallbackLocation &&
                  gymProvider.useDeviceLocation)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 170,
                  child: LocationPermissionBanner(
                    status: gymProvider.locationPermissionStatus,
                    onOpenSettings: () => gymProvider.openLocationSettings(),
                    onRetry: () => _refreshCurrentLocation(gymProvider),
                  ),
                ),

              // ── Empty state when no gyms found ──────────────────────
              if (!gymProvider.isLoading &&
                  gymProvider.nearbyGyms.isEmpty &&
                  _placeResults.isEmpty &&
                  !_placesLoading)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 200,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFA141414),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      _buildEmptyStateMessage(gymProvider),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                    ),
                  ),
                ),

              // ── Location refresh button ───────────────────────────────
              Positioned(
                right: 20, bottom: 100,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _refreshCurrentLocation(gymProvider),
                    borderRadius: BorderRadius.circular(30),
                    child: Ink(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.45), blurRadius: 14, spreadRadius: 2)],
                      ),
                      child: Center(
                        child: _isLocating
                            ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                            : const Icon(Icons.my_location_rounded, color: Colors.black, size: 28),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ],
          );
        },
      ),
    );
  }

  String _buildEmptyStateMessage(GymProvider gymProvider) {
    if (gymProvider.state == GymLoadState.error && gymProvider.errorMessage.isNotEmpty) {
      return 'Could not load gyms from server: ${gymProvider.errorMessage}';
    }
    if (_placesService.lastStatus == 'REQUEST_DENIED') {
      return 'Google Places access denied. Enable Places API on your API key '
          'and set GOOGLE_MAPS_API_KEY on the backend server.';
    }
    if (_isOpenNow) {
      return 'No gyms open right now in this area. Turn off the "Open Now" filter '
          'or try increasing your search radius.';
    }
    if (_placesService.lastErrorMessage != null) {
      return 'No gyms found. ${_placesService.lastErrorMessage}';
    }
    return 'No gyms found in this area. Try increasing your search radius, '
        'turning off filters, or changing location.';
  }

  Future<void> _openDirections(double lat, double lng) async {
    final googleMapsApp = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final browserFallback = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    try {
      if (await url_launcher.canLaunchUrl(googleMapsApp)) {
        await url_launcher.launchUrl(googleMapsApp);
      } else {
        await url_launcher.launchUrl(browserFallback, mode: url_launcher.LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions.')),
        );
      }
    }
  }

  // ── Google Place Preview Card ───────────────────────────────────────────────
  Widget _buildPlaceCard(PlaceResult place) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFA141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place.address.isNotEmpty)
                      Text(
                        place.address,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Powered by Google badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Google',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              if (place.rating > 0) ...[
                const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                const SizedBox(width: 3),
                Text(
                  '${place.rating.toStringAsFixed(1)} (${place.userRatingsTotal} reviews)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
              ],
              if (place.isOpenNow != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: place.isOpenNow! ? const Color(0xFF0D2B1A) : const Color(0xFF2B0D0D),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    place.isOpenNow! ? 'Open Now' : 'Closed',
                    style: TextStyle(
                      color: place.isOpenNow! ? const Color(0xFF4DFF91) : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Category tags
          if (place.types.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: place.types
                  .where((t) => !['gym', 'point_of_interest', 'establishment', 'health'].contains(t))
                  .take(3)
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t.replaceAll('_', ' '),
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _openDirections(place.latitude, place.longitude),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap marker for details • Real data from Google Maps',
            style: TextStyle(color: AppColors.primary.withOpacity(0.5), fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Legend item ─────────────────────────────────────────────────────────────
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ),
      ],
    );
  }

  // ── Match score ─────────────────────────────────────────────────────────────
  int _calcMatchScore(AuthProvider auth, Map<String, dynamic> profile) {
    final my = auth.userProfile;
    if (my == null) return 72;
    final myW = (my['workoutTypes'] ?? '').toString().toLowerCase().trim();
    final thW = (profile['workoutTypes'] ?? profile['workoutType'] ?? '').toString().toLowerCase().trim();
    final myG = (my['fitnessGoals'] ?? '').toString().toLowerCase().trim();
    final thG = (profile['fitnessGoals'] ?? '').toString().toLowerCase().trim();
    int score = 50;
    if (myW.isNotEmpty && thW.isNotEmpty) {
      if (myW == thW) { score += 30; }
      else {
        final mW = myW.split(RegExp(r'[\s,/]+')); final tW = thW.split(RegExp(r'[\s,/]+'));
        if (mW.any((w) => w.length > 3 && tW.any((t) => t.contains(w) || w.contains(t)))) score += 15;
      }
    }
    if (myG.isNotEmpty && thG.isNotEmpty) {
      if (myG == thG) { score += 20; }
      else {
        final mG = myG.split(RegExp(r'[\s,/]+')); final tG = thG.split(RegExp(r'[\s,/]+'));
        if (mG.any((w) => w.length > 3 && tG.any((t) => t.contains(w) || w.contains(t)))) score += 10;
      }
    }
    return score.clamp(50, 99).toInt();
  }

  // ── Partner pin preview card ─────────────────────────────────────────────────
  Widget _buildPartnerPinCard({required AuthProvider authProvider}) {
    final partner = _selectedPartner!;
    final gym = _selectedPartnerGym!;
    final name = (partner['name'] as String?)?.isNotEmpty == true ? partner['name'] as String : 'Athlete';
    final imgB64 = partner['profileImage'] as String?;
    final workoutTypes = (partner['workoutTypes'] as String?)?.isNotEmpty == true
        ? partner['workoutTypes'] as String
        : (partner['workoutType'] as String? ?? 'General');
    final tags = workoutTypes.split(RegExp(r'[,/]')).map((t) => t.trim()).where((t) => t.isNotEmpty).take(2).toList();
    final matchScore = _calcMatchScore(authProvider, partner);
    final gymId = (partner['gymId'] as num?)?.toInt() ?? gym.id;
    final gymName = partner['gymName'] as String? ?? gym.name;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.partnerProfile, extra: {
        'partner': partner,
        'gymId': gymId,
        'gymName': gymName,
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFA141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: imgB64 != null && imgB64.isNotEmpty
                    ? Image.memory(base64Decode(imgB64), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _partnerAvatarFallback())
                    : _partnerAvatarFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF2A4A1E), borderRadius: BorderRadius.circular(20)),
                        child: Text('$matchScore% Match', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      ...tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(20)),
                            child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white38, size: 12),
                    const SizedBox(width: 3),
                    Expanded(child: Text(gym.name, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => context.push(AppRoutes.partnerProfile, extra: {
                'partner': partner,
                'gymId': gymId,
                'gymName': gymName,
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Text('View Profile', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerAvatarFallback() => Container(
    color: const Color(0xFF1A1A1A),
    child: const Icon(Icons.person_rounded, color: Colors.white38, size: 26),
  );
}
