import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/gym_model.dart';
import '../../widgets/featured_badge.dart';
import '../../services/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  double _lastLat = 0;
  double _lastLng = 0;
  GymProvider? _gymProvider; // stored ref so dispose() doesn't need context

  // Toggle: 0 = Gyms, 1 = Partners
  int _tabIndex = 0;

  // Partners tab state
  List<Map<String, dynamic>> _partners = [];
  bool _partnersLoading = false;
  String? _partnersError;

  // Used only until the admin-managed category list loads (or if the
  // request fails), so the filter bar is never empty.
  static const List<String> _fallbackCategories = [
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
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gymProvider = Provider.of<GymProvider>(context, listen: false);
      _gymProvider!.addListener(_onProviderLocationChanged);
      _gymProvider!.initLocation();
      _gymProvider!.fetchCategories();
      _lastLat = _gymProvider!.userLat;
      _lastLng = _gymProvider!.userLng;
    });
  }

  /// Same scoring logic as PartnerProfileScreen._calcMatchScore.
  int _calcMatchScore(AuthProvider auth, Map<String, dynamic> fullProfile) {
    final myProfile = auth.userProfile;
    if (myProfile == null) return 72;

    final myWorkout  = (myProfile['workoutTypes']  ?? '').toString().toLowerCase().trim();
    final theirWorkout = (fullProfile['workoutTypes'] ?? fullProfile['workoutType'] ?? '').toString().toLowerCase().trim();
    final myGoal     = (myProfile['fitnessGoals']   ?? '').toString().toLowerCase().trim();
    final theirGoal  = (fullProfile['fitnessGoals'] ?? '').toString().toLowerCase().trim();

    int score = 50;

    if (myWorkout.isNotEmpty && theirWorkout.isNotEmpty) {
      if (myWorkout == theirWorkout) {
        score += 30;
      } else {
        final myWords    = myWorkout.split(RegExp(r'[\s,/]+'));
        final theirWords = theirWorkout.split(RegExp(r'[\s,/]+'));
        final overlap    = myWords.any((w) => w.length > 3 && theirWords.any((t) => t.contains(w) || w.contains(t)));
        if (overlap) score += 15;
      }
    }

    if (myGoal.isNotEmpty && theirGoal.isNotEmpty) {
      if (myGoal == theirGoal) {
        score += 20;
      } else {
        final myWords    = myGoal.split(RegExp(r'[\s,/]+'));
        final theirWords = theirGoal.split(RegExp(r'[\s,/]+'));
        final overlap    = myWords.any((w) => w.length > 3 && theirWords.any((t) => t.contains(w) || w.contains(t)));
        if (overlap) score += 10;
      }
    }

    return score.clamp(50, 99).toInt();
  }

  /// Fetch nearby partners based on location using new location-based API.
  Future<void> _fetchAllPartners() async {
    if (!mounted) return;
    setState(() {
      _partnersLoading = true;
      _partnersError = null;
    });

    try {
      final gymProvider  = Provider.of<GymProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final api = ApiClient();
      
      // Use new location-based API to get all nearby partners at once
      final resp = await api.dio.get('/users/nearby', queryParameters: {
        'lat': gymProvider.userLat,
        'lng': gymProvider.userLng,
        'radius': gymProvider.radius,
      });

      final List<dynamic> partnersList = resp.data['partners'] ?? [];
      
      if (partnersList.isEmpty) {
        if (mounted) setState(() { _partners = []; _partnersLoading = false; });
        return;
      }

      // Enrich each partner with existing thread check
      final enrichedPartners = await Future.wait(partnersList.map((p) async {
        final partner = Map<String, dynamic>.from(p);
        final uid = (partner['userId'] as num?)?.toInt() ?? 0;
        
        try {
          final threadId = await chatProvider.findThreadWithPartner(uid);
          partner['existingThreadId'] = threadId;
        } catch (_) {
          partner['existingThreadId'] = null;
        }

        // Compute match score
        final score = _calcMatchScore(authProvider, partner);
        partner['matchScore'] = score;
        
        return partner;
      }));

      // Sort by match score
      enrichedPartners.sort((a, b) =>
          ((b['matchScore'] as num?)?.toInt() ?? 0)
              .compareTo((a['matchScore'] as num?)?.toInt() ?? 0));

      if (mounted) {
        setState(() {
          _partners = enrichedPartners;
          _partnersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _partnersError = 'Could not load partners. Please try again.';
          _partnersLoading = false;
        });
      }
    }
  }

  /// Update a single partner's threadId in state after connect/disconnect.
  void _updatePartnerThread(int userId, int? threadId) {
    final idx = _partners.indexWhere((p) => (p['userId'] as num?)?.toInt() == userId);
    if (idx == -1) return;
    setState(() {
      _partners[idx] = {..._partners[idx], 'existingThreadId': threadId};
    });
  }

  @override
  void dispose() {
    _gymProvider?.removeListener(_onProviderLocationChanged);
    super.dispose();
  }

  void _onProviderLocationChanged() {
    // Use stored ref — never touch context here since this fires after dispose too
    final gymProvider = _gymProvider;
    if (gymProvider == null || !mounted) return;

    final newLat = gymProvider.userLat;
    final newLng = gymProvider.userLng;

    if ((newLat - _lastLat).abs() > 0.0001 || (newLng - _lastLng).abs() > 0.0001) {
      _lastLat = newLat;
      _lastLng = newLng;
      gymProvider.fetchNearbyGyms();
    }

    if (_tabIndex == 1 &&
        !_partnersLoading &&
        gymProvider.state == GymLoadState.loaded) {
      _fetchAllPartners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<GymProvider>(
          builder: (context, gymProvider, _) {
            final categories = gymProvider.categories.isNotEmpty
                ? <String>['All', ...gymProvider.categories]
                : _fallbackCategories;
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: () async {
                if (_tabIndex == 0) {
                  await gymProvider.fetchNearbyGyms();
                } else {
                  await _fetchAllPartners();
                }
              },
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
                            child: Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                final profileImage = authProvider.userProfile?['profileImage'] as String?;
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF2A2A2A),
                                  ),
                                  child: ClipOval(
                                    child: profileImage != null && profileImage.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(profileImage),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.person_rounded,
                                              color: Colors.white60,
                                              size: 24,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white60,
                                            size: 24,
                                          ),
                                  ),
                                );
                              },
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
                            hintText: 'Search gyms, partners, locations',
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

                    // ── Gyms / Partners Toggle ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            _buildToggleTab('Gyms', 0),
                            _buildToggleTab('Partners', 1),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 120.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    // Category chips — only shown on Gyms tab
                    if (_tabIndex == 0)
                      SizedBox(
                        height: 46,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _selectedCategoryIndex;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCategoryIndex = index);
                                  gymProvider.setCategory(
                                    index == 0 ? '' : categories[index],
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
                                    categories[index],
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

                    if (_tabIndex == 0) const SizedBox(height: 24),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _tabIndex == 0
                          ? _buildGymList(gymProvider)
                          : _buildPartnerList(),
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

  /// Single tab button for the Gyms / Partners toggle.
  Widget _buildToggleTab(String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabIndex == index) return;
          setState(() => _tabIndex = index);
          if (index == 1 && _partners.isEmpty) {
            _fetchAllPartners();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ── Partner list ────────────────────────────────────────────────────────
  Widget _buildPartnerList() {
    if (_partnersLoading) {
      return Column(children: List.generate(3, (_) => _buildPartnerShimmer()));
    }

    if (_partnersError != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(_partnersError!, style: const TextStyle(color: Colors.white60, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _fetchAllPartners,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    if (_partners.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          children: [
            Icon(Icons.people_alt_rounded, color: Colors.white24, size: 48),
            SizedBox(height: 16),
            Text(
              'No active partners nearby right now.\nCheck back later or visit a gym to see who\'s working out!',
              style: TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _partners.map((partner) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPartnerCard(partner),
        );
      }).toList(),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    final name        = (partner['name'] as String?)?.isNotEmpty == true
        ? partner['name'] as String
        : 'Athlete';
    final gymId       = (partner['gymId'] as num?)?.toInt() ?? 0;
    final gymName     = partner['gymName'] as String? ?? '';
    final matchScore  = (partner['matchScore'] as num?)?.toInt() ?? 72;
    final profileImgB64 = partner['profileImage'] as String?;
    final existingThreadId = partner['existingThreadId'] as int?;
    final isConnected = existingThreadId != null;
    final isFeatured  = partner['isFeatured'] == true;

    // Use full workoutTypes from profile, fall back to active-partner workoutType
    final rawWorkout  = (partner['workoutTypes'] as String?)?.isNotEmpty == true
        ? partner['workoutTypes'] as String
        : (partner['workoutType'] as String? ?? 'General');
    final tags = rawWorkout
        .split(RegExp(r'[,/]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConnected
              ? Colors.redAccent.withOpacity(0.4)
              : (isFeatured ? AppColors.primary.withOpacity(0.5) : const Color(0xFF1E1E1E)),
          width: isConnected ? 1.5 : (isFeatured ? 1.5 : 1),
        ),
        boxShadow: isFeatured
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 16, spreadRadius: 2)]
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar ─────────────────────────────────────────────────
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: profileImgB64 != null && profileImgB64.isNotEmpty
                  ? Image.memory(
                      base64Decode(profileImgB64),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _partnerAvatarFallback(),
                    )
                  : _partnerAvatarFallback(),
            ),
          ),
          const SizedBox(width: 14),

          // ── Info ────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Match badge + workout chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (isFeatured)
                      const FeaturedBadge(fontSize: 10, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4A1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$matchScore% Match',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 10),

                // Action buttons
                Row(
                  children: [
                    // View Profile
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push(
                          AppRoutes.partnerProfile,
                          extra: {
                            'partner': partner,
                            'gymId': gymId,
                            'gymName': gymName,
                          },
                        ),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Connect / Disconnect
                    Expanded(
                      child: GestureDetector(
                        onTap: () => isConnected
                            ? _handleDisconnect(partner, existingThreadId)
                            : _handleConnect(partner, gymId, gymName),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? const Color(0xFF2A2A2A)
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: isConnected
                                ? Border.all(color: Colors.redAccent, width: 1.5)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isConnected ? 'Disconnect' : 'Connect',
                            style: TextStyle(
                              color: isConnected ? Colors.redAccent : Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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

  Widget _partnerAvatarFallback() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.person_rounded, color: Colors.white38, size: 38),
    );
  }

  void _handleConnect(Map<String, dynamic> partner, int gymId, String gymName) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isGuest) { _showUnlockModal(); return; }

    final name = (partner['name'] as String?)?.isNotEmpty == true
        ? partner['name'] as String : 'this person';
    final workoutType = partner['workoutType'] as String? ?? 'General';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Text(
          'CONNECT WITH ${name.toUpperCase()}?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Text(
          'Would you like to connect with $name for $workoutType training at $gymName?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final userId = (partner['userId'] as num?)?.toInt() ?? 0;
              final threadId = await chatProvider.invitePartner(gymId, userId, workoutType);
              if (mounted) {
                if (threadId != null) _updatePartnerThread(userId, threadId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      threadId != null
                          ? 'Connected with $name!'
                          : 'Failed to connect. Please try again.',
                    ),
                    backgroundColor: threadId != null
                        ? const Color(0xFF1A2A12)
                        : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Connect Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDisconnect(Map<String, dynamic> partner, int threadId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text(
          'Disconnect',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will remove your active match and delete the chat. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.disconnectPartner(threadId);
    if (mounted) {
      if (success) {
        final userId = (partner['userId'] as num?)?.toInt() ?? 0;
        _updatePartnerThread(userId, null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Disconnected successfully.' : 'Failed to disconnect.'),
          backgroundColor: success ? Colors.black87 : Colors.redAccent,
        ),
      );
    }
  }

  void _showUnlockModal() {
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
              const Text('SIGN IN REQUIRED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Sign up to connect with partners and unlock the full GYMatch experience.', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
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

  Widget _buildPartnerShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(18),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white10);
  }

  // ── Gym list ─────────────────────────────────────────────────────────────
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
                    ? _buildGymImage(gym.coverImage!)
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

  Widget _buildGymImage(String imageUrl, {double height = 200}) {
    // Check if it's a base64 data URI
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _imageFallback(),
        );
      } catch (e) {
        debugPrint('[HomeScreen] base64 decode failed: $e');
        return _imageFallback();
      }
    }

    // Network URL
    return Image.network(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imageFallback(),
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
