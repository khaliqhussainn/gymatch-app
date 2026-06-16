import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/gym_model.dart';
import '../../widgets/featured_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  double _lastLat = 0;
  double _lastLng = 0;

  final List<String> _categories = [
    'GYM',
    'CrossFit',
    'MMA',
    'Yoga',
    'Women',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gymProvider = Provider.of<GymProvider>(context, listen: false);
      gymProvider.addListener(_onProviderLocationChanged);
      gymProvider.initLocation();
      _lastLat = gymProvider.userLat;
      _lastLng = gymProvider.userLng;
    });
  }

  @override
  void dispose() {
    final gymProvider = Provider.of<GymProvider>(context, listen: false);
    gymProvider.removeListener(_onProviderLocationChanged);
    super.dispose();
  }

  void _onProviderLocationChanged() {
    final gymProvider = Provider.of<GymProvider>(context, listen: false);
    final newLat = gymProvider.userLat;
    final newLng = gymProvider.userLng;

    if ((newLat - _lastLat).abs() > 0.0001 || (newLng - _lastLng).abs() > 0.0001) {
      _lastLat = newLat;
      _lastLng = newLng;
      // Location changed externally (e.g. from search screen) — refresh gyms
      if (mounted) gymProvider.fetchNearbyGyms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<GymProvider>(
          builder: (context, gymProvider, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: () => gymProvider.fetchNearbyGyms(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Top Header Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  'GY',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Image.asset(
                                    'assets/images/logo.PNG',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const Text(
                                  'atch',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.profile),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2A2A2A),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white60,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, _) {
                              return Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: () => context.push(AppRoutes.notifications),
                                  ),
                                  if (notificationProvider.hasUnread)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 10,
                                          minHeight: 10,
                                        ),
                                        padding: notificationProvider.unreadCount > 9
                                            ? const EdgeInsets.symmetric(horizontal: 4)
                                            : EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: notificationProvider.unreadCount > 9
                                              ? BoxShape.rectangle
                                              : BoxShape.circle,
                                          borderRadius: notificationProvider.unreadCount > 9
                                              ? BorderRadius.circular(8)
                                              : null,
                                          border: Border.all(color: Colors.black, width: 1.5),
                                        ),
                                        child: notificationProvider.unreadCount > 9
                                            ? const Text(
                                                '9+',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          readOnly: true,
                          onTap: () => context.push(AppRoutes.search),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search gyms, categories',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.white38, size: 22),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    // Category Chips
                    SizedBox(
                      height: 46,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedCategoryIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedCategoryIndex = index);
                                gymProvider.setCategory(
                                  index == 0 ? 'GYM' : _categories[index],
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(23),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.white12,
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  _categories[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Gym List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildGymList(gymProvider),
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          onPressed: () => context.go(AppRoutes.explore),
          child: const Icon(
            Icons.map_outlined,
            color: Colors.black,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildGymList(GymProvider gymProvider) {
    if (gymProvider.isLoading) {
      return Column(
        children: List.generate(2, (_) => _buildShimmerCard()),
      );
    }

    if (gymProvider.state == GymLoadState.error) {
      return _buildErrorState(gymProvider);
    }

    if (gymProvider.nearbyGyms.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: gymProvider.nearbyGyms.map((gym) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.gymDetail, extra: gym.id),
            child: _buildGymCard(gym),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(GymProvider gymProvider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Text(
            gymProvider.errorMessage,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => gymProvider.fetchNearbyGyms(),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 48),
          SizedBox(height: 16),
          Text(
            'No gyms found nearby.\nTry increasing your search radius.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: Colors.white10,
        );
  }

  Widget _buildGymCard(GymModel gym) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gym.isFeatured ? AppColors.primary.withOpacity(0.5) : const Color(0xFF1E1E1E),
          width: gym.isFeatured ? 1.5 : 1,
        ),
        boxShadow: gym.isFeatured
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 16, spreadRadius: 2)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gym Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                child: gym.coverImage != null
                    ? Image.network(
                        gym.coverImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _imageFallback(),
                      )
                    : _imageFallback(),
              ),
              // Rating Badge — top left
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        gym.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Featured Badge — top center, on the image
              if (gym.isFeatured)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FeaturedBadge(
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    ),
                  ),
                ),
              // Open/Closed Badge — top right
              Positioned(
                right: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gym.isOpen ? AppColors.primary : Colors.white38,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    gym.isOpen ? 'OPEN NOW' : 'CLOSED',
                    style: TextStyle(
                      color: gym.isOpen ? AppColors.primary : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Gym details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        gym.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gym.distanceLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  gym.subName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  gym.locationName,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  gym.nearLocation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${gym.activePartnersCount} people are looking for partner here',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 200,
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 50),
      ),
    );
  }
}
