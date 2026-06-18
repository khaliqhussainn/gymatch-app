import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';

enum _SearchMode { gym, location }

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query, GymProvider gymProvider) {
    setState(() {
      _hasQuery = query.trim().isNotEmpty;
      _locationError = null;
    });
    if (_mode == _SearchMode.gym && query.trim().isNotEmpty) {
      gymProvider.searchGyms(query.trim());
    }
  }

  Future<void> _submitSearch(GymProvider gymProvider) async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (_mode == _SearchMode.gym) {
      // Add to history and search
      await gymProvider.addToHistory(query);
      gymProvider.searchGyms(query);
    } else {
      // Location search
      setState(() { _isSearchingLocation = true; _locationError = null; });
      final success = await gymProvider.searchByLocation(query);
      if (mounted) {
        setState(() => _isSearchingLocation = false);
        if (success) {
          await gymProvider.addToHistory('📍 $query');
          // Navigate back — home/explore will refresh with new location
          context.pop();
        } else {
          setState(() => _locationError = 'Location "$query" not found. Try a city or address.');
        }
      }
    }
  }

  void _applyHistoryItem(String item, GymProvider gymProvider) {
    // Strip location prefix if any
    final clean = item.startsWith('📍 ') ? item.substring(3) : item;
    final isLocation = item.startsWith('📍 ');

    setState(() {
      _mode = isLocation ? _SearchMode.location : _SearchMode.gym;
      _controller.text = clean;
      _hasQuery = true;
      _locationError = null;
    });

    if (isLocation) {
      _submitSearch(gymProvider);
    } else {
      gymProvider.searchGyms(clean);
    }
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  _mode == _SearchMode.location
                                      ? Icons.location_on_rounded
                                      : Icons.search_rounded,
                                  color: _mode == _SearchMode.location
                                      ? AppColors.primary
                                      : Colors.white38,
                                  size: 22,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  style: const TextStyle(color: Colors.white),
                                  textInputAction: TextInputAction.search,
                                  onChanged: (q) => _onQueryChanged(q, gymProvider),
                                  onSubmitted: (_) => _submitSearch(gymProvider),
                                  decoration: InputDecoration(
                                    hintText: _mode == _SearchMode.location
                                        ? 'Enter city, area or address...'
                                        : 'Search gyms, categories',
                                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 15),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              if (_hasQuery)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() { _hasQuery = false; _locationError = null; });
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
                ),

                const SizedBox(height: 12),

                // ── Mode toggle: Gyms | Location ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildModeChip('Gyms', Icons.fitness_center_rounded, _SearchMode.gym),
                      const SizedBox(width: 10),
                      _buildModeChip('By Location', Icons.location_on_rounded, _SearchMode.location),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Location error ─────────────────────────────────────
                if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      _locationError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 4),

                // ── Body ───────────────────────────────────────────────
                Expanded(
                  child: _isSearchingLocation
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFFCBF135), strokeWidth: 2),
                              SizedBox(height: 16),
                              Text('Finding location...', style: TextStyle(color: Colors.white60)),
                            ],
                          ),
                        )
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
        setState(() {
          _mode = mode;
          _locationError = null;
          _hasQuery = _controller.text.trim().isNotEmpty;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.black : Colors.white54),
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

  Widget _buildGymResults(GymProvider gymProvider) {
    if (gymProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFCBF135), strokeWidth: 2));
    }

    if (gymProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.white24, size: 60),
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
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: gym.coverImage != null
                  ? Image.network(
                      gym.coverImage!, width: 80, height: 80, fit: BoxFit.cover,
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
                    Text(gym.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(gym.locationName, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(gym.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: gym.isOpen ? AppColors.primary.withOpacity(0.15) : Colors.white10,
                          ),
                          child: Text(
                            gym.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: gym.isOpen ? AppColors.primary : Colors.white38,
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
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDefaultView(GymProvider gymProvider) {
    final history = gymProvider.searchHistory;
    final suggestions = ['CrossFit', 'MMA', 'Yoga', 'Bodybuilding', 'HIIT', 'Boxing', 'Pilates', 'Zumba', 'Powerlifting', 'Calisthenics'];

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
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                TextButton(
                  onPressed: () => gymProvider.clearHistory(),
                  child: Text('Clear all', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...history.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _applyHistoryItem(item, gymProvider),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        item.startsWith('📍') ? Icons.location_on_rounded : Icons.access_time_rounded,
                        color: item.startsWith('📍') ? AppColors.primary : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      // Delete individual history item
                      GestureDetector(
                        onTap: () => gymProvider.removeFromHistory(item),
                        child: const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
            const SizedBox(height: 24),
          ],

          // ── Suggestions ────────────────────────────────────────────
          const Text('SUGGESTED',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: suggestions.map((item) => GestureDetector(
              onTap: () {
                _controller.text = item;
                setState(() { _mode = _SearchMode.gym; _hasQuery = true; });
                gymProvider.searchGyms(item);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _thumbFallback() => Container(
    width: 80, height: 80, color: const Color(0xFF1A1A1A),
    child: const Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 28),
  );
}
