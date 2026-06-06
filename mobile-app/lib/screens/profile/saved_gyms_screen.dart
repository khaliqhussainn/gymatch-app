import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';

class SavedGymsScreen extends StatelessWidget {
  const SavedGymsScreen({super.key});

  final List<Map<String, dynamic>> _savedList = const [
    {
      'name': 'GOLD\'S GYM',
      'rating': '4.0',
      'distance': '0.5 KM',
      'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
    },
    {
      'name': 'ONYX FITNESS',
      'rating': '4.5',
      'distance': '2 KM',
      'imageUrl': 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=400',
    },
    {
      'name': 'EQUINOX',
      'rating': '3.0',
      'distance': '5 KM',
      'imageUrl': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400',
    },
    {
      'name': 'TITAN STRONGHOLD',
      'rating': '4.0',
      'distance': '1 KM',
      'imageUrl': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400',
    },
    {
      'name': 'FITNESS CLUB',
      'rating': '5',
      'distance': '10 KM',
      'imageUrl': 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=400',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'SAVED GYMS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GridView.builder(
            itemCount: _savedList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final gym = _savedList[index];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gym Photo container with Bookmark overlay tag
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              gym['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFF222222),
                                child: const Icon(Icons.fitness_center, color: Colors.white24),
                              ),
                            ),
                          ),
                          // Yellow bookmark icon on top right
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Details text box
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gym['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${gym['rating']} ★ | ${gym['distance']} away',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms);
            },
          ),
        ),
      ),
    );
  }
}
