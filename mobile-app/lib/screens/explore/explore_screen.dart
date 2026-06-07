import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MapController _mapController = MapController();
  int _selectedFilterIndex = 0;
  bool _isOpenNow = true;
  String _selectedDistance = '15 KM';
  String _selectedCategory = 'GYM';
  String _selectedRating = '4.0+';
  bool _isLocating = false;
  GymModel? _selectedPin;

  final List<String> _quickFilters = ['Open Now', 'Near me', 'CrossFit', 'MMA'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gymProvider = Provider.of<GymProvider>(context, listen: false);
      gymProvider.initLocation();
    });
  }

  void _onQuickFilter(int index, GymProvider gymProvider) {
    setState(() => _selectedFilterIndex = index);
    switch (index) {
      case 0: // Open Now — filter client-side
        break;
      case 1: // Near me — fetch with tight radius
        gymProvider.applyFilters(radius: 5, category: 'GYM', openNow: false, rating: '');
        break;
      case 2: // CrossFit
        gymProvider.applyFilters(radius: 15, category: 'CrossFit', openNow: false, rating: '');
        break;
      case 3: // MMA
        gymProvider.applyFilters(radius: 15, category: 'MMA', openNow: false, rating: '');
        break;
    }
  }

  Future<void> _applyQuickFilter(int index, GymProvider gymProvider) async {
    setState(() {
      _selectedFilterIndex = index;
      _selectedPin = null;
    });

    switch (index) {
      case 0:
        setState(() {
          _selectedDistance = '${gymProvider.radius.toInt()} KM';
          _selectedCategory = 'GYM';
          _selectedRating = '';
          _isOpenNow = true;
        });
        await gymProvider.applyFilters(
          radius: gymProvider.radius,
          category: 'GYM',
          openNow: true,
          rating: '',
        );
        break;
      case 1:
        setState(() {
          _selectedDistance = '5 KM';
          _selectedCategory = 'GYM';
          _selectedRating = '';
          _isOpenNow = false;
        });
        await gymProvider.applyFilters(
          radius: 5,
          category: 'GYM',
          openNow: false,
          rating: '',
        );
        break;
      case 2:
        setState(() {
          _selectedDistance = '15 KM';
          _selectedCategory = 'CrossFit';
          _selectedRating = '';
          _isOpenNow = false;
        });
        await gymProvider.applyFilters(
          radius: 15,
          category: 'CrossFit',
          openNow: false,
          rating: '',
        );
        break;
      case 3:
        setState(() {
          _selectedDistance = '15 KM';
          _selectedCategory = 'MMA';
          _selectedRating = '';
          _isOpenNow = false;
        });
        await gymProvider.applyFilters(
          radius: 15,
          category: 'MMA',
          openNow: false,
          rating: '',
        );
        break;
    }

    _moveMapToProviderLocation(gymProvider);
  }

  void _showFilterBottomSheet(GymProvider gymProvider) {
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
                          _selectedCategory = 'GYM';
                          _selectedRating = '';
                          _isOpenNow = false;
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
                      children: ['GYM', 'CrossFit', 'Yoga', 'MMA', 'Women'].map((cat) {
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
                        });
                        await gymProvider.applyFilters(
                          radius: radius,
                          category: _selectedCategory,
                          openNow: _isOpenNow,
                          rating: _selectedRating,
                        );
                        _moveMapToProviderLocation(gymProvider);
                      },
                      child: const Text('APPLY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ],
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
    _mapController.move(
      LatLng(gymProvider.userLat, gymProvider.userLng),
      _mapController.camera.zoom,
    );
  }

  Future<void> _refreshCurrentLocation(GymProvider gymProvider) async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
      _selectedPin = null;
    });

    try {
      await gymProvider.refreshDeviceLocation();
      _moveMapToProviderLocation(gymProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated. Showing nearby gyms.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update location. Using saved area.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _showGymPreviewCard(GymModel gym) {
    setState(() => _selectedPin = gym);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<GymProvider>(
        builder: (context, gymProvider, _) {
          final centerLat = gymProvider.userLat;
          final centerLng = gymProvider.userLng;

          // Build markers for gyms
          final gymMarkers = gymProvider.nearbyGyms.map((gym) {
            return Marker(
              point: LatLng(gym.latitude, gym.longitude),
              width: 42,
              height: 51,
              child: GestureDetector(
                onTap: () => _showGymPreviewCard(gym),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.45),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: const Size(14, 9),
                      painter: _PinTrianglePainter(),
                    ),
                  ],
                ),
              ),
            );
          }).toList();

          // Add static user markers
          final staticUserMarkers = [
            _buildUserMarker(centerLat + 0.01, centerLng - 0.01),
            _buildUserMarker(centerLat - 0.015, centerLng + 0.02),
            _buildUserMarker(centerLat + 0.02, centerLng + 0.015),
            _buildUserMarker(centerLat - 0.005, centerLng - 0.025),
          ];

          return Stack(
            children: [
              // MAP with black theme
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLng),
                    initialZoom: 14.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                    onTap: (_, __) => setState(() => _selectedPin = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
                      userAgentPackageName: 'com.example.moovit_app',
                      tileBuilder: (context, widget, tile) {
                        return ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.2),
                            BlendMode.darken,
                          ),
                          child: widget,
                        );
                      },
                    ),
                    MarkerLayer(markers: [...gymMarkers, ...staticUserMarkers]),
                  ],
                ),
              ),

              // TOP HUD: Search and filter
              Positioned(
                left: 20,
                right: 20,
                top: 60,
                child: Column(
                  children: [
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
                                    hintText: 'Search gyms, categories',
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

              // Gym Pin Preview Card (shown when a gym pin is tapped)
              if (_selectedPin != null)
                Positioned(
                  left: 20,
                  right: 80,
                  bottom: 180,
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.gymDetail, extra: _selectedPin!.id),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFA141414),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedPin!.coverImage != null
                                ? Image.network(
                                    _selectedPin!.coverImage!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _pinThumbFallback(),
                                  )
                                : _pinThumbFallback(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedPin!.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(_selectedPin!.locationName, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                    const SizedBox(width: 3),
                                    Text(_selectedPin!.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedPin!.distanceLabel,
                                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2),

              // Location refresh button — raised above bottom nav bar
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
                            color: AppColors.primary.withOpacity(0.45),
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
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: Colors.black,
                                size: 28,
                              ),
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

  Marker _buildUserMarker(double lat, double lng) {
    return Marker(
      point: LatLng(lat, lng),
      width: 42,
      height: 51,
      child: GestureDetector(
        onTap: _showUnlockCommunityModal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.45),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
            CustomPaint(
              size: const Size(14, 9),
              painter: _PinTrianglePainter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinThumbFallback() {
    return Container(
      width: 70, height: 70, color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 28),
    );
  }
}

// Paints the pin triangle tail
class _PinTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCBF135)..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTrianglePainter oldDelegate) => false;
}
