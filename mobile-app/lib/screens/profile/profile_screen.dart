import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isGuest = false; // Toggle to switch between User and Guest profile views

  // Saved Gyms data
  final List<Map<String, String>> _savedGyms = [
    {
      'name': 'AB Gym',
      'logo': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=200',
    },
    {
      'name': 'Smart Fitness',
      'logo': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200',
    },
    {
      'name': 'Gold\'s Gym',
      'logo': 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=200',
    },
    {
      'name': 'Buff up',
      'logo': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=200',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // PROFILE Header (Interactive toggle)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isGuest = !_isGuest;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${_isGuest ? "Guest" : "User"} profile preview'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    'PROFILE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Avatar & Details
              Center(
                child: _isGuest ? _buildGuestAvatar() : _buildUserAvatar(),
              ),

              const SizedBox(height: 32),

              // Saved Gyms section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Gyms',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.savedGyms),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Saved Gyms content area (Locked for guest, active for user)
              _isGuest ? _buildLockedSavedGyms() : _buildActiveSavedGyms(),

              const SizedBox(height: 24),

              // Activity Status section (User only)
              if (!_isGuest) ...[
                const Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'ACTIVITY STATUS QUICK VIEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(value: '12', label: 'Matches'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusCard(value: '3', label: 'Active Threads'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Settings Options List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: _isGuest
                        ? [
                            _buildMenuTile(
                              icon: Icons.help_outline_rounded,
                              label: 'Help & Support',
                              onTap: () {},
                            ),
                          ]
                        : [
                            _buildMenuTile(
                              icon: Icons.settings_outlined,
                              label: 'Account Settings',
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white10, height: 1, indent: 56),
                            _buildMenuTile(
                              icon: Icons.location_on_outlined,
                              label: 'Location Preferences',
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white10, height: 1, indent: 56),
                            _buildMenuTile(
                              icon: Icons.help_outline_rounded,
                              label: 'Help & Support',
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white10, height: 1, indent: 56),
                            _buildMenuTile(
                              icon: Icons.logout_rounded,
                              label: 'Log Out',
                              isLogout: true,
                              onTap: () => context.go(AppRoutes.login),
                            ),
                          ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // USER PROFILE SPECIFIC VIEWS
  Widget _buildUserAvatar() {
    return Column(
      children: [
        // Bodybuilder profile image circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=200',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'JOHN WILSON',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'username@gmail.com',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSavedGyms() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _savedGyms.length,
        itemBuilder: (context, index) {
          final gym = _savedGyms[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    gym['logo']!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gym['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // GUEST PROFILE SPECIFIC VIEWS
  Widget _buildGuestAvatar() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Center(
            child: Icon(
              Icons.person_rounded,
              color: Colors.black,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'GUEST',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedSavedGyms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
            ),
            fit: BoxFit.cover,
            opacity: 0.15, // Blurry/locked background feel
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.75),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon in neon yellow
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'UNLOCK THE COMMUNITY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              
              const Text(
                'Sign up for a free account to turn on your active status and see who is looking for a workout partner at Gold\'s Gym right now.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Create Free Account Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => context.go(AppRoutes.register),
                  child: const Text(
                    'Create Free Account',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Already have account? Log In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UTILITY VIEW BUILDERS
  Widget _buildStatusCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        leading: Icon(
          icon,
          color: isLogout ? Colors.redAccent : Colors.white60,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: isLogout
            ? null
            : const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white24,
              ),
      ),
    );
  }
}
