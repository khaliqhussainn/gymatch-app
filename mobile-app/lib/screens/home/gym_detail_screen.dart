import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';

class GymDetailScreen extends StatefulWidget {
  const GymDetailScreen({super.key});

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  int _currentImageIndex = 0;
  bool _activePartnerFeed = true;

  final List<String> _gymImages = [
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
    'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800',
    'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800',
  ];

  final List<Map<String, String>> _partners = [
    {'name': 'Sarah J.', 'status': 'Active Now'},
    {'name': 'Mike T.', 'status': 'Training Now'},
    {'name': 'Alex K.', 'status': 'Training Now'},
  ];

  final List<String> _amenities = [
    'Yoga Studio',
    'Parking',
    'Cardio',
    'Suana',
    'Shower',
    'Free WiFi',
    'Pool',
    'Locker Room',
    'Weights',
    'Personal Training Area',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel with indicators
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    itemCount: _gymImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        _gymImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                // Indicator dots
                Positioned(
                  bottom: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_gymImages.length, (index) {
                      final isSelected = index == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Rating
                  Row(
                    children: [
                      const Text(
                        'GOLD\'S GYM',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'City Centered | 0.5 KM Away',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick action buttons
                  Row(
                    children: [
                      _buildActionButton('Direction', true),
                      const SizedBox(width: 8),
                      _buildActionButton('Call', false),
                      const SizedBox(width: 8),
                      _buildActionButton('Save', false),
                      const SizedBox(width: 8),
                      _buildActionButton('Share', false),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Active Partner Feed Container Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ACTIVE PARTNER FEED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Switch(
                              value: _activePartnerFeed,
                              onChanged: (val) {
                                setState(() {
                                  _activePartnerFeed = val;
                                });
                              },
                              activeColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Partners looking subtitle
                        Row(
                          children: [
                            const Text(
                              '🔥 ',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '3 people are currently looking for a\npartner here.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Horizontal profiles list
                        if (_activePartnerFeed)
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _partners.length,
                              itemBuilder: (context, index) {
                                final partner = _partners[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Container(
                                    width: 82,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1C1C),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primary,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  color: Colors.black,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4DFF91),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: const Color(0xFF1C1C1C), width: 1.5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          partner['name']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          partner['status']!,
                                          style: const TextStyle(
                                            color: Color(0xFF4DFF91),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // AMENITIES & INFO
                  const Text(
                    'AMENITIES & INFO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'OPEN NOW: 6:00 am - 11:00 pm',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Wrap chips of amenities
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          amenity,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // MEMBERSHIP PLANS
                  const Text(
                    'MEMBERSHIP PLANS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Plan list row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan 1: Basic
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BASIC ACCESS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: const [
                                  Text(
                                    '\$30',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '/mo',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._buildPlanBullets([
                                'Basic Access',
                                'Cardio & Weights',
                                'Standard Hours',
                                'Locker & Showers',
                                '1 Free Assessment',
                              ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Plan 2: Ultra Premium
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'ULTRA\nPREMIUMMATCH',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        const Text(
                                          '\$99',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const Text(
                                          '/mo',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ..._buildPlanBullets([
                                      'Premium Access',
                                      'All Basic Features',
                                      'Unlimited Classes',
                                      'Sauna & Spa',
                                      'Multi-Branch Access',
                                      '2 Guest Passes/mo',
                                      'Personal training',
                                    ]),
                                    const SizedBox(height: 16),
                                    // Select button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(19),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () {},
                                        child: const Text(
                                          'SELECT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Top indicator banner
                              Positioned(
                                top: -10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Call to Book a Tour button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'CALL TO BOOK A TOUR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, bool isPrimary) {
    return Expanded(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isPrimary ? AppColors.primary : Colors.white24,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlanBullets(List<String> bullets) {
    return bullets.map((bullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 6),
              child: Icon(Icons.circle, size: 4, color: Colors.white70),
            ),
            Expanded(
              child: Text(
                bullet,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
