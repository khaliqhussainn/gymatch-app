import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:share_plus/share_plus.dart' show Share;
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../models/gym_model.dart';
// app_config and featured_badge not used in this screen
import '../../widgets/location_permission_dialog.dart';
import '../../services/location_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Google Maps Dark Style JSON (defined once as a const — never re-parsed)
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
// ExploreScreen
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
  String _selectedRating = '';
  bool _featuredOnly = false;
  bool _isLocating = false;

  // Selected Gym & Map Popup state
  GymModel? _selectedPin;
  bool _showMapPopup = false;

  // Selected Partner state
  Map<String, dynamic>? _selectedPartner;
  GymModel? _selectedPartnerGym;
  bool _partnerCardLoading = false;

  // Track last known location to detect changes
  double _lastLat = 0;
  double _lastLng = 0;

  // Google Maps markers
  final Map<MarkerId, Marker> _markers = {};

  // Gym loading state
  bool _gymsLoading = false;
  GymProvider? _gymProvider;

  final List<String> _quickFilters = [
    'Open Now',
    'Near me',
    'CrossFit',
    'MMA',
    'Boxing',
    'HIIT',
    'Yoga'
  ];

  // Cache custom bitmap descriptors so we don't re-render on every rebuild
  final Map<String, BitmapDescriptor> _markerCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gymProvider = Provider.of<GymProvider>(context, listen: false);
      _gymProvider!.addListener(_onGymProviderNotification);
      _gymProvider!.initLocation();
      _lastLat = _gymProvider!.userLat;
      _lastLng = _gymProvider!.userLng;
    });
  }

  @override
  void dispose() {
    _gymProvider?.removeListener(_onGymProviderNotification);
    _mapController?.dispose();
    super.dispose();
  }

  // ── GymProvider listener ────────────────────────────────────────────────────
  void _onGymProviderNotification() {
    final gymProvider = _gymProvider;
    if (gymProvider == null || !mounted) return;

    final newLat = gymProvider.userLat;
    final newLng = gymProvider.userLng;

    // Animate camera when location changed significantly
    if ((newLat - _lastLat).abs() > 0.0001 ||
        (newLng - _lastLng).abs() > 0.0001) {
      _lastLat = newLat;
      _lastLng = newLng;
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(newLat, newLng)),
      );
      setState(() {
        _selectedPin = null;
        _showMapPopup = false;
        _selectedPartner = null;
        _selectedPartnerGym = null;
      });
    }

    // Rebuild markers based on provider's nearby gyms list
    _buildMarkers(gymProvider);
  }

  // ── Custom vector marker builder (cached) ───────────────────────────────────
  Future<BitmapDescriptor> _getCustomMarker(
    Color color,
    IconData icon, {
    double size = 120.0,
    bool selected = false,
  }) async {
    final key = '${color.toARGB32()}_${icon.codePoint}_${size}_$selected';
    if (_markerCache.containsKey(key)) {
      return _markerCache[key]!;
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 8.0 : 6.0;

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path pinPath = Path();
    final double radius = size * 0.35;
    final Offset center = Offset(size / 2, size * 0.38);

    pinPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      0.15 * math.pi,
      1.7 * math.pi,
    );
    pinPath.lineTo(size / 2, size * 0.95);
    pinPath.close();

    if (selected) {
      canvas.drawPath(
        pinPath,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0),
      );
    }

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    canvas.drawPath(pinPath, borderPaint);
    canvas.drawPath(pinPath, fillPaint);
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 5.0 : 4.0,
    );

    canvas.drawCircle(
      center,
      radius * 0.75,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius * 0.75,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: radius * 0.95,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: AppColors.primary,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final ui.Image image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return BitmapDescriptor.defaultMarker;

    final descriptor = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    _markerCache[key] = descriptor;
    return descriptor;
  }

  Future<BitmapDescriptor> _getSelectedGymMarker() async {
    const key = 'selected_gym_logo';
    if (_markerCache.containsKey(key)) {
      return _markerCache[key]!;
    }

    const double size = 150.0;
    const color = AppColors.primary;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Path pinPath = Path();
    const double radius = size * 0.35;
    const Offset center = Offset(size / 2, size * 0.38);

    pinPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      0.15 * math.pi,
      1.7 * math.pi,
    );
    pinPath.lineTo(size / 2, size * 0.95);
    pinPath.close();

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0),
    );
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0,
    );
    canvas.drawCircle(
      center,
      radius * 0.75,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.fill,
    );

    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo.PNG');
      final ui.Codec codec = await ui.instantiateImageCodec(
        logoData.buffer.asUint8List(),
        targetWidth: (radius * 1.2).toInt(),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image logo = frame.image;
      canvas.drawImage(
        logo,
        Offset(center.dx - logo.width / 2, center.dy - logo.height / 2),
        Paint(),
      );
    } catch (_) {
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = const TextSpan(
        text: 'M',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2),
      );
    }

    final ui.Image image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;

    final descriptor = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    _markerCache[key] = descriptor;
    return descriptor;
  }

  // ── Build map markers (gyms + partners + user) ──────────────────────────────
  Future<BitmapDescriptor> _getAssetMarker(
    String assetPath, {
    double height = 56,
  }) async {
    final key = 'asset_${assetPath}_$height';
    if (_markerCache.containsKey(key)) {
      return _markerCache[key]!;
    }

    final markerData = await rootBundle.load(assetPath);
    final sourceCodec = await ui.instantiateImageCodec(
      markerData.buffer.asUint8List(),
    );
    final sourceFrame = await sourceCodec.getNextFrame();
    final aspectRatio = sourceFrame.image.width / sourceFrame.image.height;
    final codec = await ui.instantiateImageCodec(
      markerData.buffer.asUint8List(),
      targetWidth: (height * aspectRatio).round(),
      targetHeight: height.round(),
    );
    final frame = await codec.getNextFrame();
    final byteData =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;

    final descriptor = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    _markerCache[key] = descriptor;
    return descriptor;
  }

  Future<void> _buildMarkers(GymProvider gymProvider) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newMarkers = <MarkerId, Marker>{};

    final gymIcon = await _getAssetMarker(
      'assets/images/gym-pin.png',
      height: 54,
    );
    final partnerIcon = await _getAssetMarker(
      'assets/images/user-pin.png',
      height: 52,
    );
    final selectedGymIcon = gymIcon;
    final userIcon = await _getAssetMarker(
      'assets/images/user-pin.png',
      height: 50,
    );

    // 1. Real gyms from Google Places (via backend sync)
    for (final gym in gymProvider.nearbyGyms) {
      final markerId = MarkerId('gym_${gym.id}');
      final isSelected = _selectedPin?.id == gym.id;
      newMarkers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(gym.latitude, gym.longitude),
        icon: isSelected ? selectedGymIcon : gymIcon,
        zIndexInt: isSelected ? 2 : 1,
        onTap: () {
          setState(() {
            _selectedPin = gym;
            _showMapPopup = true;
            _selectedPartner = null;
            _selectedPartnerGym = null;
          });
          _buildMarkers(gymProvider);
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(gym.latitude, gym.longitude)),
          );
        },
      );
    }

    // 2. Active workout partner pins (near gym, slight random offset)
    final rand = math.Random(42);
    for (final gym in gymProvider.nearbyGyms) {
      if (gym.activePartnersCount <= 0) continue;
      final count = math.min(gym.activePartnersCount, 3);
      for (int i = 0; i < count; i++) {
        final latOffset = (rand.nextDouble() - 0.5) * 0.003;
        final lngOffset = (rand.nextDouble() - 0.5) * 0.003;
        final markerId = MarkerId('partner_${gym.id}_$i');
        newMarkers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(gym.latitude + latOffset, gym.longitude + lngOffset),
          icon: partnerIcon,
          onTap: () async {
            if (authProvider.isGuest) {
              _showUnlockCommunityModal();
              return;
            }
            setState(() {
              _selectedPin = null;
              _showMapPopup = false;
              _selectedPartner = null;
              _selectedPartnerGym = null;
              _partnerCardLoading = true;
            });
            try {
              // Use the pre-captured field (avoids BuildContext-across-async-gap)
              final gp = _gymProvider;
              if (gp == null) return;
              final partners = await gp.fetchActivePartners(gym.id);
              if (!mounted) return;
              final idx = i < partners.length ? i : partners.length - 1;
              final partner = idx >= 0 ? partners[idx] : null;
              if (partner != null) {
                Map<String, dynamic> enriched = {
                  ...partner,
                  'gymId': gym.id,
                  'gymName': gym.name,
                };
                try {
                  final uid = (partner['userId'] as num?)?.toInt();
                  if (uid != null) {
                    final resp =
                        await ApiClient().dio.get('/users/$uid/profile');
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

    // 3. User location marker
    const userMarkerId = MarkerId('user_location');
    newMarkers[userMarkerId] = Marker(
      markerId: userMarkerId,
      position: LatLng(gymProvider.userLat, gymProvider.userLng),
      icon: userIcon,
    );

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  // ── Quick filter chip handler ────────────────────────────────────────────────
  Future<void> _applyQuickFilter(int index, GymProvider gymProvider) async {
    setState(() {
      _selectedFilterIndex = index;
      _selectedPin = null;
      _showMapPopup = false;
      _gymsLoading = true;
    });

    String cat = 'All';
    bool open = false;
    double rad = gymProvider.radius;

    switch (index) {
      case 0: // Open Now
        setState(() {
          _selectedDistance = '${rad.toInt()} KM';
          _selectedCategory = 'All';
          _selectedRating = '';
          _isOpenNow = true;
        });
        cat = 'All';
        open = true;
        break;
      case 1: // Near Me
        setState(() {
          _selectedDistance = '5 KM';
          _selectedCategory = 'All';
          _selectedRating = '';
          _isOpenNow = false;
        });
        cat = 'All';
        open = false;
        rad = 5;
        break;
      case 2:
        setState(() {
          _selectedDistance = '15 KM';
          _selectedCategory = 'CrossFit';
          _selectedRating = '';
          _isOpenNow = false;
        });
        cat = 'CrossFit';
        break;
      case 3:
        setState(() {
          _selectedDistance = '15 KM';
          _selectedCategory = 'MMA';
          _selectedRating = '';
          _isOpenNow = false;
        });
        cat = 'MMA';
        break;
      case 4:
        setState(() {
          _selectedDistance = '15 KM';
          _selectedCategory = 'Boxing';
          _selectedRating = '';
          _isOpenNow = false;
        });
        cat = 'Boxing';
        break;
      case 5:
        setState(() {
          _selectedDistance = '15 KM';
          _selectedCategory = 'HIIT';
          _selectedRating = '';
          _isOpenNow = false;
        });
        cat = 'HIIT';
        break;
      case 6:
        setState(() {
          _selectedDistance = '15 KM';
          _selectedCategory = 'Yoga';
          _selectedRating = '';
          _isOpenNow = false;
        });
        cat = 'Yoga';
        break;
    }

    try {
      await gymProvider.applyFilters(
        radius: rad,
        category: cat == 'All' ? '' : cat,
        openNow: open,
        rating: _selectedRating,
        featuredOnly: _featuredOnly,
      );
    } catch (_) {}

    if (mounted) setState(() => _gymsLoading = false);
    _moveMapToProviderLocation(gymProvider);
  }

  // ── Filter bottom sheet ──────────────────────────────────────────────────────
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
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FILTERS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setModalState(() {
                            _selectedDistance = '15 KM';
                            _selectedCategory = 'All';
                            _selectedRating = '';
                            _isOpenNow = false;
                            localFeaturedOnly = false;
                          }),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Distance
                    const Text('Distance',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['1 KM', '3 KM', '5 KM', '10 KM', '15 KM']
                            .map((dist) {
                          final isSelected = dist == _selectedDistance;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(dist),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => _selectedDistance = dist),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white12,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    const Text('Category',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          'All',
                          'CrossFit',
                          'MMA',
                          'Yoga',
                          'Strength Training',
                          'Bodybuilding',
                          'Powerlifting',
                          'Cardio Training',
                          'HIIT',
                          'Functional Fitness',
                          'Boxing',
                          'Kickboxing',
                          'Pilates',
                          'Zumba',
                          'Cycling / Spinning',
                          'Calisthenics',
                          'Personal Training',
                          'Circuit Training',
                          'Aerobics',
                          'Dance Fitness',
                          'Mobility & Stretching',
                        ].map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => _selectedCategory = cat),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white12,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rating
                    const Text('Rating',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['Any', '5.0', '4.0+', '3.0+', '2.0+', '1.0+']
                            .map((rate) {
                          final ratingValue = rate == 'Any' ? '' : rate;
                          final isSelected = ratingValue == _selectedRating;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(rate),
                              selected: isSelected,
                              onSelected: (_) => setModalState(
                                  () => _selectedRating = ratingValue),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white12,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Open Now toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Open Now',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(
                              _isOpenNow ? 'ON' : 'OFF',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _isOpenNow,
                              onChanged: (val) =>
                                  setModalState(() => _isOpenNow = val),
                              activeThumbColor: AppColors.primary,
                              activeTrackColor:
                                  AppColors.primary.withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white12,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Featured Only toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'FEATURED',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              ' Only',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              localFeaturedOnly ? 'ON' : 'OFF',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: localFeaturedOnly,
                              onChanged: (val) =>
                                  setModalState(() => localFeaturedOnly = val),
                              activeThumbColor: AppColors.primary,
                              activeTrackColor:
                                  AppColors.primary.withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white12,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final radius = double.tryParse(
                                  _selectedDistance.replaceAll(' KM', '')) ??
                              15.0;
                          setState(() {
                            _selectedFilterIndex = -1;
                            _selectedPin = null;
                            _showMapPopup = false;
                            _featuredOnly = localFeaturedOnly;
                            _gymsLoading = true;
                          });
                          try {
                            await gymProvider.applyFilters(
                              radius: radius,
                              category: _selectedCategory,
                              openNow: _isOpenNow,
                              rating: _selectedRating,
                              featuredOnly: localFeaturedOnly,
                            );
                          } catch (_) {}
                          if (mounted) setState(() => _gymsLoading = false);
                          _moveMapToProviderLocation(gymProvider);
                        },
                        child: const Text(
                          'APPLY',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1),
                        ),
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

  // ── Guest upsell modal ───────────────────────────────────────────────────────
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
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Center(
                  child:
                      Icon(Icons.person_rounded, color: Colors.black, size: 38),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'UNLOCK THE COMMUNITY',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'Sign up for a free account to turn on your active status and see who is looking for a workout partner right now.',
                style:
                    TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRoutes.register);
                  },
                  child: const Text(
                    'Create Free Account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.login);
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _moveMapToProviderLocation(GymProvider gymProvider) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(gymProvider.userLat, gymProvider.userLng)),
    );
  }

  Future<void> _refreshCurrentLocation(GymProvider gymProvider) async {
    if (_isLocating) return;

    if (gymProvider.locationPermissionStatus !=
        LocationPermissionStatus.granted) {
      final shouldContinue = await showLocationPermissionRationale(context);
      if (!shouldContinue) return;
    }

    setState(() {
      _isLocating = true;
      _selectedPin = null;
      _showMapPopup = false;
    });
    try {
      await gymProvider.refreshDeviceLocation();
      if (mounted) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(gymProvider.userLat, gymProvider.userLng),
            14.0,
          ),
        );
        final msg = gymProvider.usingFallbackLocation
            ? 'Location unavailable. Showing default area.'
            : 'Location updated.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
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

  Future<void> _openDirections(double lat, double lng) async {
    final googleMapsApp = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final browserFallback = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    try {
      if (await url_launcher.canLaunchUrl(googleMapsApp)) {
        await url_launcher.launchUrl(googleMapsApp);
      } else {
        await url_launcher.launchUrl(browserFallback,
            mode: url_launcher.LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions.')),
        );
      }
    }
  }

  Future<void> _callGymPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty ||
        phone.contains('555-0199') ||
        digits.replaceAll(RegExp(r'[^\d]'), '').length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$digits');
    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phone')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phone')),
        );
      }
    }
  }

  Future<void> _toggleSaveGym(GymModel gym) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isGuest) {
      _showUnlockCommunityModal();
      return;
    }
    final gymProvider = Provider.of<GymProvider>(context, listen: false);
    final saved = await gymProvider.toggleSaved(gym.id);
    if (mounted && saved != null) {
      setState(() {
        _selectedPin = _selectedPin?.copyWith(isSaved: saved);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved
              ? 'Gym saved to favorites.'
              : 'Gym removed from favorites.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareGymDetails(GymModel gym) async {
    final lines = [
      '🏋️ ${gym.name}',
      '⭐ ${gym.rating.toStringAsFixed(1)} • ${gym.distanceLabel} away',
      '📍 ${gym.locationName}',
      '🕐 ${gym.openHours}',
      if (gym.hasContactPhone) '📞 ${gym.contactPhone}',
      '',
      'Find your perfect workout partner on GYMatch!',
    ];
    try {
      await Share.share(
        lines.join('\n'),
        subject: 'Check out ${gym.name} on GYMatch',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share gym details.')),
        );
      }
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<GymProvider, AuthProvider>(
        builder: (context, gymProvider, authProvider, _) {
          final centerLat = gymProvider.userLat;
          final centerLng = gymProvider.userLng;

          return Stack(
            children: [
              // ── GOOGLE MAP (style set once in onMapCreated — no rebuild lag) ──
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(centerLat, centerLng),
                    zoom: 14.0,
                  ),
                  markers: Set<Marker>.of(_markers.values),
                  mapType: MapType.normal,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  style: _darkMapStyle,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Markers built after map controller is ready
                    _buildMarkers(gymProvider);
                  },
                  onTap: (_) {
                    setState(() {
                      _selectedPin = null;
                      _showMapPopup = false;
                      _selectedPartner = null;
                      _selectedPartnerGym = null;
                    });
                    _buildMarkers(gymProvider);
                  },
                  onCameraMove: (_) {
                    // Hide popup immediately on drag to avoid visual drift
                    if (_showMapPopup) {
                      setState(() => _showMapPopup = false);
                    }
                  },
                ),
              ),

              // ── TOP HUD: Search bar + quick filter chips ──────────────────
              Positioned(
                left: 20,
                right: 20,
                top: 60,
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
                            child: Icon(Icons.search_rounded,
                                color: Colors.white38, size: 22),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push(AppRoutes.search),
                              child: const AbsorbPointer(
                                child: TextField(
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search gyms, categories',
                                    hintStyle: TextStyle(
                                        color: Colors.white38, fontSize: 15),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showFilterBottomSheet(gymProvider),
                            icon: const Icon(Icons.tune_rounded,
                                color: AppColors.primary, size: 24),
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
                              onTap: () =>
                                  _applyQuickFilter(index, gymProvider),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white12,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  _quickFilters[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
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

              // ── Loading pill ──────────────────────────────────────────────
              if (gymProvider.isLoading || _gymsLoading)
                Positioned(
                  top: 175,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFA141414),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Finding gyms...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Featured-only active indicator ────────────────────────────
              if (_featuredOnly)
                Positioned(
                  left: 20,
                  top: 170,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.black, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Featured Only',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Legend (hidden when a pin or partner card is showing) ──────
              if (_selectedPin == null && _selectedPartner == null)
                Positioned(
                  left: 16,
                  bottom: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendItem(AppColors.primary, 'Gyms'),
                      const SizedBox(height: 4),
                      _buildLegendItem(AppColors.primary, 'Active Partners'),
                    ],
                  ),
                ),

              // ── Speech-bubble map popup (shown when a pin is tapped) ──────
              if (_showMapPopup && _selectedPin != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).size.height / 2 + 50,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.gymDetail,
                          extra: _selectedPin!.id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedPin!.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${_selectedPin!.distanceLabel})',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedPin!.hasRating) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.primary, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        _selectedPin!.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedPin!.activePartnersCount} live partners active now',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Beak pointing down toward the pin
                          Transform.translate(
                            offset: const Offset(0, -3),
                            child: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 150.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 150.ms),

              // ── Premium bottom card (shows gym quick-actions) ─────────────
              if (_selectedPin != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border.all(color: Colors.white10, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Gym name + rating (tappable → gym detail)
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.gymDetail,
                              extra: _selectedPin!.id),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedPin!.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (_selectedPin!.hasRating) ...[
                                    const Icon(Icons.star_rounded,
                                        color: AppColors.primary, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedPin!.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_selectedPin!.locationName} | ${_selectedPin!.distanceLabel} Away',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Action buttons
                        Row(
                          children: [
                            _buildBottomActionButton(
                              label: 'Direction',
                              icon: Icons.near_me_rounded,
                              isPrimary: true,
                              onTap: () => _openDirections(
                                  _selectedPin!.latitude,
                                  _selectedPin!.longitude),
                            ),
                            const SizedBox(width: 8),
                            _buildBottomActionButton(
                              label: 'Call',
                              icon: Icons.call_rounded,
                              isPrimary: false,
                              onTap: () =>
                                  _callGymPhone(_selectedPin!.contactPhone),
                            ),
                            const SizedBox(width: 8),
                            _buildBottomActionButton(
                              label: 'Save',
                              icon: _selectedPin!.isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              isPrimary: false,
                              onTap: () => _toggleSaveGym(_selectedPin!),
                            ),
                            const SizedBox(width: 8),
                            _buildBottomActionButton(
                              label: 'Share',
                              icon: Icons.share_rounded,
                              isPrimary: false,
                              onTap: () => _shareGymDetails(_selectedPin!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.2, duration: 200.ms),

              // ── Partner card loading indicator ────────────────────────────
              if (_partnerCardLoading)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 180,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFA141414),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Loading partner...',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 150.ms),

              // ── Partner pin preview card ──────────────────────────────────
              if (_selectedPartner != null && _selectedPartnerGym != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 180,
                  child: _buildPartnerPinCard(authProvider: authProvider),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2),

              // ── Location permission banner ─────────────────────────────────
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

              // ── Empty state when no gyms found ────────────────────────────
              if (!gymProvider.isLoading &&
                  gymProvider.nearbyGyms.isEmpty &&
                  !_gymsLoading)
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
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13, height: 1.4),
                    ),
                  ),
                ),

              // ── My Location FAB (hidden when gym drawer is open) ──────────
              if (_selectedPin == null && _selectedPartner == null)
                Positioned(
                  right: 20,
                  bottom: 100,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _refreshCurrentLocation(gymProvider),
                      borderRadius: BorderRadius.circular(30),
                      child: Ink(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Center(
                          child: _isLocating
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2.5),
                                )
                              : const Icon(Icons.my_location_rounded,
                                  color: Colors.black, size: 28),
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

  // ── Helper: empty state message ──────────────────────────────────────────────
  String _buildEmptyStateMessage(GymProvider gymProvider) {
    if (gymProvider.state == GymLoadState.error &&
        gymProvider.errorMessage.isNotEmpty) {
      return 'Could not load gyms from server: ${gymProvider.errorMessage}';
    }
    if (_isOpenNow) {
      return 'No gyms open right now in this area. Turn off the "Open Now" filter or try increasing your search radius.';
    }
    return 'No gyms found in this area. Try increasing your search radius, turning off filters, or changing location.';
  }

  // ── Helper: action button ────────────────────────────────────────────────────
  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isPrimary ? AppColors.primary : Colors.white24,
              width: 1,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.black : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: isPrimary ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: legend dot + label ───────────────────────────────────────────────
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ),
      ],
    );
  }

  // ── Helper: match score from profile fields ──────────────────────────────────
  int _calcMatchScore(AuthProvider auth, Map<String, dynamic> profile) {
    final my = auth.userProfile;
    if (my == null) return 72;
    final myW = (my['workoutTypes'] ?? '').toString().toLowerCase().trim();
    final thW = (profile['workoutTypes'] ?? profile['workoutType'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final myG = (my['fitnessGoals'] ?? '').toString().toLowerCase().trim();
    final thG = (profile['fitnessGoals'] ?? '').toString().toLowerCase().trim();
    int score = 50;
    if (myW.isNotEmpty && thW.isNotEmpty) {
      if (myW == thW) {
        score += 30;
      } else {
        final mW = myW.split(RegExp(r'[\s,/]+'));
        final tW = thW.split(RegExp(r'[\s,/]+'));
        if (mW.any((w) =>
            w.length > 3 && tW.any((t) => t.contains(w) || w.contains(t)))) {
          score += 15;
        }
      }
    }
    if (myG.isNotEmpty && thG.isNotEmpty) {
      if (myG == thG) {
        score += 20;
      } else {
        final mG = myG.split(RegExp(r'[\s,/]+'));
        final tG = thG.split(RegExp(r'[\s,/]+'));
        if (mG.any((w) =>
            w.length > 3 && tG.any((t) => t.contains(w) || w.contains(t)))) {
          score += 10;
        }
      }
    }
    return score.clamp(50, 99).toInt();
  }

  // ── Partner pin card widget ───────────────────────────────────────────────────
  Widget _buildPartnerPinCard({required AuthProvider authProvider}) {
    final partner = _selectedPartner!;
    final gym = _selectedPartnerGym!;
    final name = (partner['name'] as String?)?.isNotEmpty == true
        ? partner['name'] as String
        : 'Athlete';
    final imgB64 = partner['profileImage'] as String?;
    final workoutTypes =
        (partner['workoutTypes'] as String?)?.isNotEmpty == true
            ? partner['workoutTypes'] as String
            : (partner['workoutType'] as String? ?? 'General');
    final tags = workoutTypes
        .split(RegExp(r'[,/]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(2)
        .toList();
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
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: imgB64 != null && imgB64.isNotEmpty
                    ? Image.memory(
                        base64Decode(imgB64),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _partnerAvatarFallback(),
                      )
                    : _partnerAvatarFallback(),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A4A1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$matchScore% Match',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          gym.name,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // View Profile button
            GestureDetector(
              onTap: () => context.push(AppRoutes.partnerProfile, extra: {
                'partner': partner,
                'gymId': gymId,
                'gymName': gymName,
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'View Profile',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerAvatarFallback() => Container(
        color: const Color(0xFF1A1A1A),
        child:
            const Icon(Icons.person_rounded, color: Colors.white38, size: 26),
      );
}
