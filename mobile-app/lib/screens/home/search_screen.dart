import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _hasQuery = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query, GymProvider gymProvider) {
    setState(() => _hasQuery = query.trim().isNotEmpty);
    if (query.trim().isNotEmpty) {
      gymProvider.searchGyms(query.trim());
    } else {
      gymProvider.searchGyms(''); // clears results
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

                // Search bar row
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
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(Icons.search_rounded, color: Colors.white38, size: 22),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (q) => _onQueryChanged(q, gymProvider),
                                  decoration: const InputDecoration(
                                    hintText: 'Search gyms, categories',
                                    hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              if (_hasQuery)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                                  onPressed: () {
                                    _controller.clear();
                                    _onQueryChanged('', gymProvider);
                                  },
                                ),
                              IconButton(
                                icon: Icon(Icons.tune_rounded, color: AppColors.primary),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Body: results or history + suggestions
                Expanded(
                  child: _hasQuery
                      ? _buildSearchResults(gymProvider)
                      : _buildDefaultView(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(GymProvider gymProvider) {
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
        return _buildResultTile(gym);
      },
    );
  }

  Widget _buildResultTile(GymModel gym) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.gymDetail, extra: gym.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Gym thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: gym.coverImage != null
                  ? Image.network(
                      gym.coverImage!,
                      width: 80, height: 80,
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
              child: Text(
                gym.distanceLabel,
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDefaultView() {
    final suggestions = ['Gold\'s Gym', 'CrossFit', 'Yoga Studio', 'MMA Gym', 'Fitness Club'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // History section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('SEARCH HISTORY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: suggestions.take(4).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    _controller.text = item;
                    final gymProvider = Provider.of<GymProvider>(context, listen: false);
                    _onQueryChanged(item, gymProvider);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                        const Icon(Icons.access_time_rounded, color: Colors.white38, size: 20),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('SUGGESTED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 10, runSpacing: 10,
              children: suggestions.map((item) => GestureDetector(
                onTap: () {
                  _controller.text = item;
                  final gymProvider = Provider.of<GymProvider>(context, listen: false);
                  _onQueryChanged(item, gymProvider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              )).toList(),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      width: 80, height: 80,
      color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 28),
    );
  }
}
