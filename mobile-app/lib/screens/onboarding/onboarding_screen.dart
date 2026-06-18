import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../widgets/app_logo.dart';
import '../../providers/gym_provider.dart';

class _OnboardingPage {
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  int _selectedDiscipline = 1; // Default to CrossFit (index 1) to match mockup
  bool _isRequestingLocation = false;

  static const _pages = [
    _OnboardingPage(
      title: 'FITNESS INTEL.\nINSTANTLY.',
      subtitle: 'No manual searching. GYMatch automatically scans your immediate area to reveal the top fitness hubs surrounding you right now.',
    ),
    _OnboardingPage(
      title: 'CHOOSE YOUR\nDISCIPLINE',
      subtitle: 'Select your primary training styles so we can personalize your live feed and match you with compatible partners training near you know.',
    ),
    _OnboardingPage(
      title: 'ACTIVATE\nGPS INTEL',
      subtitle: 'GYMatch automatically detects your coordinates to instantly map out gyms and connect you with live training partners nearby. No exact location sharing, just pure fitness connection.',
    ),
  ];

  Future<void> _markSeenAndGo(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) context.go(route);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _markSeenAndGo(AppRoutes.login);
    }
  }

  Future<void> _requestLocationAndProceed() async {
    if (_isRequestingLocation) return;
    setState(() => _isRequestingLocation = true);

    try {
      final gymProvider = context.read<GymProvider>();
      await gymProvider.refreshDeviceLocation();
    } catch (_) {
      // Permission denied or GPS failed — proceed to login anyway
    } finally {
      if (mounted) {
        setState(() => _isRequestingLocation = false);
        _markSeenAndGo(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _markSeenAndGo(AppRoutes.login),
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View containing the page contents
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Graphic container
                        Center(
                          child: _buildGraphic(index),
                        ),
                        const SizedBox(height: 48),
                        
                        // Text section
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphic(int index) {
    switch (index) {
      case 0:
        return const _RadarScanningWidget();
      case 1:
        return _DisciplineCardsWidget(
          selectedIndex: _selectedDiscipline,
          onSelected: (val) {
            setState(() {
              _selectedDiscipline = val;
            });
          },
        );
      case 2:
        return const _GPSWaveWidget();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomControls() {
    if (_currentPage == 2) {
      // Screen 3 shows the full-width ALLOW LOCATION ACCESS button
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
          ),
          onPressed: _isRequestingLocation ? null : _requestLocationAndProceed,
          child: _isRequestingLocation
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'ALLOW LOCATION ACCESS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.95, 0.95), duration: 400.ms, curve: Curves.easeOut);
    }

    // Screens 1 and 2 show active dots and a Next button
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dot indicator
        Row(
          children: List.generate(
            _pages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentPage ? 36 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppColors.primary
                    : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        // Next button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          onPressed: _nextPage,
          child: const Text(
            'Next',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Graphic Components

class _RadarScanningWidget extends StatelessWidget {
  const _RadarScanningWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid lines
          Container(
            width: 280,
            height: 1,
            color: Colors.white10,
          ),
          Container(
            width: 1,
            height: 280,
            color: Colors.white10,
          ),
          // Concentric circles
          _buildCircle(size: 80, opacity: 0.08),
          _buildCircle(size: 140, opacity: 0.12),
          _buildCircle(size: 200, opacity: 0.16),
          _buildCircle(
            size: 260,
            opacity: 0.35,
            color: AppColors.primary,
            hasGlow: true,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1.04, 1.04),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          
          // Target nodes with different fitness icons matching the design
          // Top Left — kettlebell (active, yellow)
          _buildTargetNode(x: -75, y: -55, isActive: true,  icon: Icons.sports_gymnastics),
          // Top Right — dumbbell (inactive, white)
          _buildTargetNode(x: 70,  y: -60, isActive: false, icon: Icons.fitness_center_rounded),
          // Bottom Left — cardio/runner (inactive, white)
          _buildTargetNode(x: -80, y: 60,  isActive: false, icon: Icons.directions_run_rounded),
          // Bottom Right — boxing/MMA (active, yellow)
          _buildTargetNode(x: 70,  y: 65,  isActive: true,  icon: Icons.sports_mma_rounded),
          
          // Center Moovit/GYMatch logo
          const AppLogo(size: 48)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  Widget _buildCircle({
    required double size,
    required double opacity,
    Color color = Colors.white,
    bool hasGlow = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(opacity),
          width: hasGlow ? 2.0 : 1.0,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }

  Widget _buildTargetNode({
    required double x,
    required double y,
    required bool isActive,
    IconData icon = Icons.fitness_center_rounded,
  }) {
    final color = isActive ? AppColors.primary : Colors.white54;
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 10, spreadRadius: 1)]
              : null,
        ),
        child: Center(
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _DisciplineCardsWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DisciplineCardsWidget({
    required this.selectedIndex,
    required this.onSelected,
  });

  // Map each card index to its yellow and gray icon assets
  static const _icons = [
    // index 0 — Bodybuilding
    (yellow: 'assets/images/onboarding-icon-1-yellow.png',
     gray:   'assets/images/onboarding-icon-1-gray.png'),
    // index 1 — CrossFit
    (yellow: 'assets/images/onboarding-icon-2-yellow.png',
     gray:   'assets/images/onboarding-icon-2-gray.png'),
    // index 2 — Cardio
    (yellow: 'assets/images/onboarding-icon-3-yellow.png',
     gray:   'assets/images/onboarding-icon-3-gray.png'),
  ];

  static const _labels = ['Bodybuilding', 'CROSSFIT', 'Cardio'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_labels.length, (index) {
          final isLast = index == _labels.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(child: _buildCard(index: index)),
                if (!isLast) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCard({required int index}) {
    final isSelected = index == selectedIndex;
    final bgColor    = isSelected ? const Color(0xFF111502) : const Color(0xFF141414);
    final borderColor= isSelected ? AppColors.primary       : const Color(0xFF2A2A2A);
    final textColor  = isSelected ? Colors.white            : AppColors.onSurfaceMuted;
    final iconAsset  = isSelected ? _icons[index].yellow    : _icons[index].gray;

    return GestureDetector(
      onTap: () => onSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 135,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.18), blurRadius: 16, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _labels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            Image.asset(
              iconAsset,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              // Gracefully fall back to a simple icon if asset is missing
              errorBuilder: (_, __, ___) => Icon(
                Icons.fitness_center_rounded,
                size: 38,
                color: isSelected ? AppColors.primary : Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GPSWaveWidget extends StatelessWidget {
  const _GPSWaveWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Row: GY + Pin Icon + atch
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GY',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 4),
              // Logo icon replacing M with glow
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.PNG',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'atch',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Large location pin with concentric waves
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Waves (expanding circles with decreasing opacity)
                ...List.generate(3, (index) {
                  final delayMs = index * 500;
                  return Container(
                    width: 70.0 + (index * 50.0),
                    height: 70.0 + (index * 50.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.35 - (index * 0.1)),
                        width: 1.5,
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1.3, 1.3),
                        duration: 1800.ms,
                        delay: delayMs.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeOut(duration: 1800.ms);
                }),
                // Pin icon in center
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.45),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 68,
                    color: AppColors.primary,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .moveY(begin: -6, end: 6, duration: 1600.ms, curve: Curves.easeInOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
