import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_client.dart';
import '../../models/gym_model.dart';

enum _SearchMode { gym, partner, location }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  _SearchMode _mode = _SearchMode.gym;
  bool _hasQuery = false;
  bool _isSearchingLocation = false;
  String? _locationError;

  // Partner search state
  List<Map<String, dynamic>> _partnerResults = [];
  bool _isSearchingPartners = false;
  String? _partnerError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query, GymProvider gymProvider) {
    setState(() {
      _hasQuery = query.trim().isNotEmpty;
      _locationError = null;
      _partnerError = null;
    });
    if (query.trim().isEmpty) {
      if (_mode == _SearchMode.partner) {
        setState(() => _partnerResults = []);
      }
      return;
    }
    if (_mode == _SearchMode.gym) {
      gymProvider.searchGyms(query.trim());
    } else if (_mode == _SearchMode.partner) {
      _searchPartners(query.trim());
    }
  }

  Future<void> _searchPartners(String query) async {
    if (query.length < 2) return;
    setState(() {
      _isSearchingPartners = true;
      _partnerError = null;
    });
    try {
      final api = ApiClient();
      final resp =
          await api.dio.get('/users/search', queryParameters: {'q': query});
      final List<dynamic> list = resp.data['partners'] ?? [];
      if (mounted) {
        setState(() {
          _partnerResults =
              list.map((p) => Map<String, dynamic>.from(p)).toList();
          _isSearchingPartners = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _partnerError = 'Could not search partners. Please try again.';
          _isSearchingPartners = false;
        });
      }
    }
  }

  Future<void> _submitSearch(GymProvider gymProvider) async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (_mode == _SearchMode.gym) {
      await gymProvider.addToHistory(query);
      gymProvider.searchGyms(query);
    } else if (_mode == _SearchMode.partner) {
      await gymProvider.addToHistory('👤 $query');
      _searchPartners(query);
    } else {
      // Location search
      setState(() {
        _isSearchingLocation = true;
        _locationError = null;
      });
      final success = await gymProvider.searchByLocation(query);
      if (mounted) {
        setState(() => _isSearchingLocation = false);
        if (success) {
          await gymProvider.addToHistory('📍 $query');
          context.pop();
        } else {
          setState(() => _locationError =
              'Location "$query" not found. Try a city or address.');
        }
      }
    }
  }

  void _applyHistoryItem(String item, GymProvider gymProvider) {
    final isLocation = item.startsWith('📍 ');
    final isPartner = item.startsWith('👤 ');
    final clean = isLocation
        ? item.substring(3)
        : isPartner
            ? item.substring(3)
            : item;

    setState(() {
      _mode = isLocation
          ? _SearchMode.location
          : isPartner
              ? _SearchMode.partner
              : _SearchMode.gym;
      _controller.text = clean;
      _hasQuery = true;
      _locationError = null;
      _partnerError = null;
      _partnerResults = [];
    });

    if (isLocation) {
      _submitSearch(gymProvider);
    } else if (isPartner) {
      _searchPartners(clean);
    } else {
      gymProvider.searchGyms(clean);
    }
  }

  // ── Match score identical to PartnerProfileScreen ─────────────────────
  int _calcMatchScore(AuthProvider auth, Map<String, dynamic> profile) {
    final myProfile = auth.userProfile;
    if (myProfile == null) return 72;

    final myWorkout =
        (myProfile['workoutTypes'] ?? '').toString().toLowerCase().trim();
    final theirWorkout =
        (profile['workoutTypes'] ?? '').toString().toLowerCase().trim();
    final myGoal =
        (myProfile['fitnessGoals'] ?? '').toString().toLowerCase().trim();
    final theirGoal =
        (profile['fitnessGoals'] ?? '').toString().toLowerCase().trim();

    int score = 50;
    if (myWorkout.isNotEmpty && theirWorkout.isNotEmpty) {
      if (myWorkout == theirWorkout) {
        score += 30;
      } else {
        final myW = myWorkout.split(RegExp(r'[\s,/]+'));
        final theirW = theirWorkout.split(RegExp(r'[\s,/]+'));
        if (myW.any((w) =>
            w.length > 3 && theirW.any((t) => t.contains(w) || w.contains(t))))
          score += 15;
      }
    }
    if (myGoal.isNotEmpty && theirGoal.isNotEmpty) {
      if (myGoal == theirGoal) {
        score += 20;
      } else {
        final myG = myGoal.split(RegExp(r'[\s,/]+'));
        final theirG = theirGoal.split(RegExp(r'[\s,/]+'));
        if (myG.any((w) =>
            w.length > 3 && theirG.any((t) => t.contains(w) || w.contains(t))))
          score += 10;
      }
    }
    return score.clamp(50, 99).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<GymProvider>(
          builder: (context, gymProvider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Search bar row ──────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 380;
                    final horizontalPadding = isCompact ? 16.0 : 20.0;
                    final searchHint = _mode == _SearchMode.location
                        ? (isCompact
                            ? 'City, area or address'
                            : 'Enter city, area or address...')
                        : _mode == _SearchMode.partner
                            ? (isCompact
                                ? 'Name or workout type'
                                : 'Search by name or workout type...')
                            : 'Search gyms, categories';

                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Row(
                        children: [
                          IconButton(
                            constraints: const BoxConstraints.tightFor(
                                width: 44, height: 44),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                          SizedBox(width: isCompact ? 6 : 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF161616),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isCompact ? 14 : 16,
                                      right: isCompact ? 10 : 14,
                                    ),
                                    child: Icon(
                                      _mode == _SearchMode.location
                                          ? Icons.location_on_rounded
                                          : _mode == _SearchMode.partner
                                              ? Icons.people_alt_rounded
                                              : Icons.search_rounded,
                                      color: _mode == _SearchMode.location ||
                                              _mode == _SearchMode.partner
                                          ? AppColors.primary
                                          : Colors.white38,
                                      size: 22,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      autofocus: true,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      textInputAction: TextInputAction.search,
                                      onChanged: (q) =>
                                          _onQueryChanged(q, gymProvider),
                                      onSubmitted: (_) =>
                                          _submitSearch(gymProvider),
                                      decoration: InputDecoration(
                                        hintText: searchHint,
                                        hintStyle: const TextStyle(
                                            color: Colors.white24,
                                            fontSize: 15),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16),
                                      ),
                                    ),
                                  ),
                                  if (_hasQuery)
                                    IconButton(
                                      constraints:
                                          const BoxConstraints.tightFor(
                                              width: 40, height: 40),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close_rounded,
                                          color: Colors.white38, size: 20),
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {
                                          _hasQuery = false;
                                          _locationError = null;
                                          _partnerError = null;
                                          _partnerResults = [];
                                        });
                                        gymProvider.searchGyms('');
                                      },
                                    ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ── Mode chips ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildModeChip('Gyms', Icons.fitness_center_rounded,
                            _SearchMode.gym),
                        _buildModeChip('Partners', Icons.people_alt_rounded,
                            _SearchMode.partner),
                        _buildModeChip('By Location', Icons.location_on_rounded,
                            _SearchMode.location),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Errors ─────────────────────────────────────────────
                if (_locationError != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(_locationError!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ),
                if (_partnerError != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(_partnerError!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ),

                const SizedBox(height: 4),

                // ── Body ───────────────────────────────────────────────
                Expanded(
                  child: _isSearchingLocation
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: Color(0xFFCBF135), strokeWidth: 2),
                              SizedBox(height: 16),
                              Text('Finding location...',
                                  style: TextStyle(color: Colors.white60)),
                            ],
                          ),
                        )
                      : _mode == _SearchMode.partner
                          ? _buildPartnerResults()
                          : _hasQuery && _mode == _SearchMode.gym
                              ? _buildGymResults(gymProvider)
                              : _buildDefaultView(gymProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, IconData icon, _SearchMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        final query = _controller.text.trim();
        setState(() {
          _mode = mode;
          _locationError = null;
          _partnerError = null;
          _hasQuery = query.isNotEmpty;
        });
        // Re-run search in new mode if there's a query
        if (query.isNotEmpty) {
          if (mode == _SearchMode.partner) {
            _partnerResults = [];
            _searchPartners(query);
          } else if (mode == _SearchMode.gym) {
            Provider.of<GymProvider>(context, listen: false).searchGyms(query);
          } else if (mode == _SearchMode.location) {
            _submitSearch(Provider.of<GymProvider>(context, listen: false));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15, color: isSelected ? Colors.black : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Partner results ────────────────────────────────────────────────────
  Widget _buildPartnerResults() {
    if (!_hasQuery)
      return _buildDefaultView(
          Provider.of<GymProvider>(context, listen: false));

    if (_isSearchingPartners) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFCBF135), strokeWidth: 2),
            SizedBox(height: 16),
            Text('Searching partners...',
                style: TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }

    if (_partnerResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_alt_rounded,
                color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text(
              'No partners found for "${_controller.text}"',
              style: const TextStyle(color: Colors.white60, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching by name or workout type\ne.g. "John", "CrossFit", "Yoga"',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _partnerResults.length,
          itemBuilder: (context, index) {
            final partner = _partnerResults[index];
            final matchScore = _calcMatchScore(authProvider, partner);
            return _buildPartnerTile(partner, matchScore);
          },
        );
      },
    );
  }

  Widget _buildPartnerTile(Map<String, dynamic> partner, int matchScore) {
    final name = (partner['name'] as String?)?.isNotEmpty == true
        ? partner['name'] as String
        : 'Athlete';
    final workoutTypes = partner['workoutTypes'] as String? ?? '';
    final profileImgB64 = partner['profileImage'] as String?;
    final gymId = (partner['gymId'] as num?)?.toInt() ?? 0;
    final gymName = partner['gymName'] as String? ?? '';

    final tags = workoutTypes
        .split(RegExp(r'[,/]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();

    return GestureDetector(
      onTap: () => context.push(AppRoutes.partnerProfile, extra: {
        'partner': partner,
        'gymId': gymId,
        'gymName': gymName,
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
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
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Match badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A4A1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$matchScore% Match',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      ...tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          )),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _partnerAvatarFallback() => Container(
        color: const Color(0xFF1A1A1A),
        child:
            const Icon(Icons.person_rounded, color: Colors.white38, size: 30),
      );

  // ── Gym results ────────────────────────────────────────────────────────
  Widget _buildGymResults(GymProvider gymProvider) {
    if (gymProvider.isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFCBF135), strokeWidth: 2));
    }

    if (gymProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text(
              'No gyms found for "${_controller.text}"',
              style: const TextStyle(color: Colors.white60, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: gymProvider.searchResults.length,
      itemBuilder: (context, index) {
        final gym = gymProvider.searchResults[index];
        return _buildResultTile(gym, gymProvider);
      },
    );
  }

  Widget _buildResultTile(GymModel gym, GymProvider gymProvider) {
    return GestureDetector(
      onTap: () async {
        await gymProvider.addToHistory(gym.name);
        if (mounted) context.push(AppRoutes.gymDetail, extra: gym.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(15)),
              child: gym.coverImage != null
                  ? Image.network(
                      gym.coverImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbFallback(),
                    )
                  : _thumbFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gym.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(gym.locationName,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(gym.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: gym.isOpen
                                ? AppColors.primary.withOpacity(0.15)
                                : Colors.white10,
                          ),
                          child: Text(
                            gym.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: gym.isOpen
                                  ? AppColors.primary
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(gym.distanceLabel,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Default view (history + suggestions) ──────────────────────────────
  Widget _buildDefaultView(GymProvider gymProvider) {
    final history = gymProvider.searchHistory;
    final gymSuggestions = [
      'CrossFit',
      'MMA',
      'Yoga',
      'Bodybuilding',
      'HIIT',
      'Boxing',
      'Pilates',
      'Zumba',
      'Powerlifting',
      'Calisthenics'
    ];
    final partnerSuggestions = [
      'CrossFit',
      'Yoga',
      'HIIT',
      'Boxing',
      'Pilates',
      'Strength',
      'Running',
      'Cardio'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Search History ─────────────────────────────────────────
          if (history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RECENT SEARCHES',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
                TextButton(
                  onPressed: () => gymProvider.clearHistory(),
                  child: Text('Clear all',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...history
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _applyHistoryItem(item, gymProvider),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                item.startsWith('📍')
                                    ? Icons.location_on_rounded
                                    : item.startsWith('👤')
                                        ? Icons.people_alt_rounded
                                        : Icons.access_time_rounded,
                                color: item.startsWith('📍') ||
                                        item.startsWith('👤')
                                    ? AppColors.primary
                                    : Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(item,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    gymProvider.removeFromHistory(item),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white24, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
            const SizedBox(height: 24),
          ],

          // ── Suggestions ────────────────────────────────────────────
          Text(
            _mode == _SearchMode.partner ? 'PARTNER SUGGESTIONS' : 'SUGGESTED',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: (_mode == _SearchMode.partner
                    ? partnerSuggestions
                    : gymSuggestions)
                .map((item) => GestureDetector(
                      onTap: () {
                        _controller.text = item;
                        setState(() {
                          _hasQuery = true;
                        });
                        if (_mode == _SearchMode.partner) {
                          _searchPartners(item);
                        } else {
                          setState(() => _mode = _SearchMode.gym);
                          gymProvider.searchGyms(item);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_mode == _SearchMode.partner) ...[
                              Icon(Icons.people_alt_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                            ],
                            Text(item,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _thumbFallback() => Container(
        width: 80,
        height: 80,
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.fitness_center_rounded,
            color: Colors.white24, size: 28),
      );
}
