import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedFilterIndex = 0;
  bool _isOpenNow = true;
  String _selectedDistance = '1 KM';
  String _selectedCategory = 'GYM';
  String _selectedRating = '4.0+';

  final List<String> _quickFilters = ['Open Now', 'Near me', 'CrossFit', 'MMA'];

  // Coordinates normalized as percentage offsets (X, Y) relative to map size
  // Pin types: 'gym' (dumbbell icon), 'user' (person avatar icon)
  final List<Map<String, dynamic>> _pins = [
    {'x': 0.15, 'y': 0.35, 'type': 'user'},
    {'x': 0.25, 'y': 0.82, 'type': 'user'},
    {'x': 0.58, 'y': 0.34, 'type': 'gym'},
    {'x': 0.48, 'y': 0.52, 'type': 'gym'},
    {'x': 0.12, 'y': 0.58, 'type': 'gym'},
    {'x': 0.52, 'y': 0.67, 'type': 'gym'},
    {'x': 0.72, 'y': 0.67, 'type': 'user'},
    {'x': 0.86, 'y': 0.27, 'type': 'user'},
  ];

  void _showFilterBottomSheet() {
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
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bottom sheet Header
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
                        onPressed: () {
                          setModalState(() {
                            _selectedDistance = '1 KM';
                            _selectedCategory = 'GYM';
                            _selectedRating = '4.0+';
                            _isOpenNow = true;
                          });
                        },
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

                  // Distance Filter Section
                  const Text(
                    'Distance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                            onSelected: (selected) {
                              setModalState(() => _selectedDistance = dist);
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.transparent,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.white12,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Filter Section
                  const Text(
                    'Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['GYM', 'CrossFit', 'Yoga', 'MMA', 'Cardio'].map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() => _selectedCategory = cat);
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.transparent,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.white12,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rating Filter Section
                  const Text(
                    'Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['5.0', '4.0+', '3.0+', '2.0+', '1.0+'].map((rate) {
                        final isSelected = rate == _selectedRating;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(rate),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() => _selectedRating = rate);
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.transparent,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.white12,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Open Now Toggle Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Open Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _isOpenNow ? 'ON' : 'OFF',
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isOpenNow,
                            onChanged: (val) {
                              setModalState(() => _isOpenNow = val);
                            },
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
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'APPLY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
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

  // Guest to User Conversion Flow Dialog
  void _showUnlockCommunityModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFA151515),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top yellow/green profile avatar icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFCBF135), // Primary neon yellow
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.black,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
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
                
                // Description
                const Text(
                  'Sign up for a free account to turn on your active status and see who is looking for a workout partner at Gold\'s Gym right now.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Create Free Account Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.register);
                    },
                    child: const Text(
                      'Create Free Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Already have account? Log In footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.login);
                      },
                      child: Text(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // MAP Background widget (using street grid painter)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F0F0F),
              child: CustomPaint(
                painter: _MapStreetPainter(),
              ),
            ),
          ),

          // Custom Stack Pins on map
          ..._pins.map((pin) {
            final isGym = pin['type'] == 'gym';
            return Positioned(
              left: MediaQuery.of(context).size.width * pin['x'] - 22,
              top: MediaQuery.of(context).size.height * pin['y'] - 54,
              child: GestureDetector(
                onTap: _showUnlockCommunityModal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular pin head with perfectly centered icon
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
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isGym
                              ? Icons.fitness_center_rounded
                              : Icons.person_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                    // Pin tail triangle
                    CustomPaint(
                      size: const Size(14, 9),
                      painter: _PinTrianglePainter(),
                    ),
                  ],
                ),
              ),
            );
          }),

          // TOP HUD: Search and filter elements
          Positioned(
            left: 20,
            right: 20,
            top: 60,
            child: Column(
              children: [
                // Round pill search bar with filter button inside
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
                      const Expanded(
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
                      // Filter Sheet Button
                      IconButton(
                        onPressed: _showFilterBottomSheet,
                        icon: Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),

                // Horizontal filters list
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
                          onTap: () {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white12,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _quickFilters[index],
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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

          // Bottom right compass/logo button overlay
          Positioned(
            right: 20,
            bottom: 30,
            child: GestureDetector(
              onTap: _showUnlockCommunityModal,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.PNG',
                    width: 32,
                    height: 32,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// Paints the small downward triangle tail beneath each map pin circle
class _PinTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBF135) // AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTrianglePainter oldDelegate) => false;
}

// Custom painter to draw premium grid map streets (black & grey contrast)
class _MapStreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = const Color(0xFF2E2E2E)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Draw some custom intersection grids
    const step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + 20, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 40), linePaint);
    }

    // Draw main roads
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.4, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(size.width * 0.6, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(_MapStreetPainter oldDelegate) => false;
}

