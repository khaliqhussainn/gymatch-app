import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/gym_model.dart';
import '../../widgets/featured_badge.dart';

class SavedGymsScreen extends StatefulWidget {
  const SavedGymsScreen({super.key});

  @override
  State<SavedGymsScreen> createState() => _SavedGymsScreenState();
}

class _SavedGymsScreenState extends State<SavedGymsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isGuest) {
        Provider.of<GymProvider>(context, listen: false).fetchSavedGyms();
      }
    });
  }

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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Consumer2<AuthProvider, GymProvider>(
        builder: (context, authProvider, gymProvider, _) {
          // Guests — prompt to sign in
          if (authProvider.isGuest) {
            return _buildSignInPrompt(context);
          }

          final savedGyms = gymProvider.savedGyms;

          if (gymProvider.isLoading && savedGyms.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFCBF135)));
          }

          if (savedGyms.isEmpty) {
            return _buildEmpty(context);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: () => gymProvider.fetchSavedGyms(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridView.builder(
                  itemCount: savedGyms.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final gym = savedGyms[index];
                    return GestureDetector(
                      onTap: () => context.push(AppRoutes.gymDetail, extra: gym.id),
                      child: _buildCard(gym, index),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(GymModel gym, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gym.isFeatured ? AppColors.primary.withOpacity(0.4) : Colors.white10,
          width: gym.isFeatured ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: gym.coverImage != null
                      ? Image.network(
                          gym.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF222222),
                            child: const Icon(Icons.fitness_center, color: Colors.white24),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF222222),
                          child: const Icon(Icons.fitness_center, color: Colors.white24),
                        ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 28),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        gym.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (gym.isFeatured) ...[
                      const SizedBox(width: 4),
                      const FeaturedBadge(fontSize: 9, padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${gym.rating.toStringAsFixed(1)} ★ | ${gym.distanceLabel} away',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms);
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, color: Colors.white24, size: 72),
          const SizedBox(height: 20),
          const Text('No saved gyms yet', style: TextStyle(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text('Tap the bookmark icon on any gym to save it here.', style: TextStyle(color: Colors.white38, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Browse Gyms', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.2)),
              child: Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Sign In to Save Gyms', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('Create a free account to bookmark your favorite gyms and access them anytime.', style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Create Free Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                  children: [TextSpan(text: 'Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
