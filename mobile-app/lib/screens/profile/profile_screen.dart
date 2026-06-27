import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/location_permission_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      authProvider.fetchProfile();
      Provider.of<GymProvider>(context, listen: false).fetchSavedGyms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isGuest = authProvider.isGuest;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // PROFILE Header
              const Center(
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

              const SizedBox(height: 24),

              // Avatar & Details
              Center(
                child: isGuest ? _buildGuestAvatar() : _buildUserAvatar(authProvider),
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
                      onTap: () {
                        if (isGuest) {
                          _showGuestAlert();
                        } else {
                          context.push(AppRoutes.savedGyms);
                        }
                      },
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
              isGuest ? _buildLockedSavedGyms() : _buildActiveSavedGyms(),

              const SizedBox(height: 24),

              // Activity Status section (User only)
              if (!isGuest) ...[
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
                        child: _buildStatusCard(
                          value: authProvider.userProfile?['stats']?['matches']?.toString() ?? '0',
                          label: 'Matches',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusCard(
                          value: authProvider.userProfile?['stats']?['activeThreads']?.toString() ?? '0',
                          label: 'Active Threads',
                        ),
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
                    children: isGuest
                        ? [
                            _buildMenuTile(
                              icon: Icons.login_rounded,
                              label: 'Log In / Register',
                              onTap: () => context.go(AppRoutes.login),
                            ),
                          ]
                        : [
                            _buildMenuTile(
                              icon: Icons.edit_note_rounded,
                              label: 'Edit Profile Info',
                              onTap: () => _showEditProfileBottomSheet(authProvider),
                            ),
                            if (authProvider.role == 'gym_owner') ...[
                              const Divider(color: Colors.white10, height: 1, indent: 56),
                              _buildMenuTile(
                                icon: Icons.business_rounded,
                                label: 'Edit Gym Info',
                                onTap: () => _showEditGymInfoBottomSheet(authProvider),
                              ),
                            ],
                            const Divider(color: Colors.white10, height: 1, indent: 56),
                            _buildMenuTile(
                              icon: Icons.location_on_outlined,
                              label: 'Location Preferences',
                              onTap: () => _showLocationPreferencesBottomSheet(
                                Provider.of<GymProvider>(context, listen: false),
                              ),
                            ),
                            const Divider(color: Colors.white10, height: 1, indent: 56),
                            _buildMenuTile(
                              icon: Icons.star_rounded,
                              label: 'Request to Feature',
                              onTap: () => _showFeatureRequestScreen(authProvider),
                            ),
                            const Divider(color: Colors.white10, height: 1, indent: 56),
                            _buildMenuTile(
                              icon: Icons.delete_forever_rounded,
                              label: 'Delete Account',
                              isLogout: true,
                              onTap: () => _showDeleteAccountDialog(authProvider),
                            ),
                            const Divider(color: Colors.white10, height: 1, indent: 56),
                            _buildMenuTile(
                              icon: Icons.logout_rounded,
                              label: 'Log Out',
                              isLogout: true,
                              onTap: () async {
                                await authProvider.logout();
                                if (mounted) {
                                  context.go(AppRoutes.login);
                                }
                              },
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
  Widget _buildUserAvatar(AuthProvider authProvider) {
    final profile = authProvider.userProfile;
    final name = (profile?['name'] as String?)?.trim();
    final email = _displayEmail(authProvider.email);
    final profileImage = profile?['profileImage'] as String?;
    final isProfileLoading = profile == null;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showEditProfileBottomSheet(authProvider),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: ClipOval(
                  child: profileImage != null && profileImage.isNotEmpty
                      ? Image.memory(
                          base64Decode(profileImage),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultAvatarIcon(),
                        )
                      : _defaultAvatarIcon(),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name?.isNotEmpty == true
              ? name!.toUpperCase()
              : isProfileLoading
                  ? 'LOADING PROFILE'
                  : 'GYMATCH MEMBER',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          email ?? (isProfileLoading ? 'Loading account details...' : 'Email hidden by Apple'),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white38,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String? _displayEmail(String? email) {
    final value = email?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.endsWith('@privaterelay.gymatch.local')) return null;
    return value;
  }

  Widget _defaultAvatarIcon() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Icon(Icons.person_rounded, color: Colors.white38, size: 52),
    );
  }

  Widget _buildActiveSavedGyms() {
    return Consumer<GymProvider>(
      builder: (context, gymProvider, child) {
        final saved = gymProvider.savedGyms;
        if (saved.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text(
              'No saved gyms yet. Tap the bookmark icon on any gym details page to save it.',
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
            ),
          );
        }

        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: saved.length,
            itemBuilder: (context, index) {
              final gym = saved[index];
              final imgUrl = gym.coverImage?.isNotEmpty == true ? gym.coverImage! : 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=200';
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.gymDetail, extra: gym.id),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imgUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72, height: 72, color: const Color(0xFF1E1E1E),
                            child: const Icon(Icons.fitness_center_rounded, color: Colors.white24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 72,
                        child: Text(
                          gym.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
          'GUEST USER',
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
            ),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.75),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 14),
              
              const Text(
                'UNLOCK THE COMMUNITY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Sign up for a free account to turn on your active status and see who is looking for a workout partner right now.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
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
                  ),
                  onPressed: () => context.go(AppRoutes.register),
                  child: const Text(
                    'Create Free Account',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
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

  void _showGuestAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Account Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Please register or log in to view saved gyms.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.register);
            },
            child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'This action is permanent. Your profile, saved gyms, matches, and messages will be deleted and cannot be recovered.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await authProvider.deleteAccount();
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your account has been deleted.'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go(AppRoutes.login);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      authProvider.errorMessage ?? 'Failed to delete account.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet(AuthProvider authProvider) {
    final profile = authProvider.userProfile;
    final nameCtrl = TextEditingController(text: profile?['name'] ?? '');
    final ageCtrl = TextEditingController(text: profile?['age']?.toString() ?? '');
    final aboutMeCtrl = TextEditingController(text: profile?['aboutMe'] ?? '');

    // Dropdown selections — initialise from saved profile
    String? selectedGoal = profile?['fitnessGoals']?.toString().isNotEmpty == true
        ? profile!['fitnessGoals']
        : null;
    String? selectedWorkout = profile?['workoutTypes']?.toString().isNotEmpty == true
        ? profile!['workoutTypes']
        : null;
    String? selectedAvailability = profile?['availability']?.toString().isNotEmpty == true
        ? profile!['availability']
        : null;

    // Profile image — start with the saved one (base64) or null
    String? localImageBase64 = profile?['profileImage'] as String?;
    const fitnessGoals = [
      'Build Muscle', 'Lose Weight', 'Improve Endurance', 'Increase Flexibility',
      'Stress Relief', 'Athletic Performance', 'Body Recomposition', 'Core Strength',
      'Improve Posture', 'Rehabilitation', 'Increase Stamina', 'Power & Explosiveness',
      'Functional Fitness', 'Weight Maintenance', 'Improve Balance', 'Tone Up',
      'Sports Specific Training', 'Mental Wellness', 'Boost Metabolism', 'General Health',
      'Train for Competition', 'Master a Discipline',
    ];

    const workoutTypes = [
      'CrossFit', 'MMA', 'Yoga', 'Strength Training', 'Bodybuilding',
      'Powerlifting', 'Cardio Training', 'HIIT', 'Functional Fitness', 'Boxing',
      'Kickboxing', 'Pilates', 'Zumba', 'Cycling / Spinning', 'Calisthenics',
      'Personal Training', 'Circuit Training', 'Aerobics', 'Dance Fitness',
      'Mobility & Stretching', 'Swimming', 'Rowing', 'Rock Climbing',
    ];

    const availabilityOptions = [
      'Weekdays – Early Morning (5–8 AM)', 'Weekdays – Morning (8–11 AM)',
      'Weekdays – Midday (11 AM–2 PM)', 'Weekdays – Afternoon (2–5 PM)',
      'Weekdays – Evening (5–8 PM)', 'Weekdays – Night (8–11 PM)',
      'Weekends – Early Morning (5–8 AM)', 'Weekends – Morning (8–11 AM)',
      'Weekends – Midday (11 AM–2 PM)', 'Weekends – Afternoon (2–5 PM)',
      'Weekends – Evening (5–8 PM)', 'Weekends – Night (8–11 PM)',
      'Monday / Wednesday / Friday', 'Tuesday / Thursday / Saturday',
      'Every Day', 'Flexible – Any Time', 'Flexible – Mornings Only',
      'Flexible – Evenings Only', 'Flexible – Weekends Only',
      'Remote / Online Workouts', 'Irregular Schedule',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        bottom: false,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            // Capture scaffold messenger from the sheet's context — valid while sheet is open
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            Future<void> pickImage() async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 400,
                  maxHeight: 400,
                  imageQuality: 80,
                );
                if (picked == null) return;
                final bytes = await picked.readAsBytes();
                final b64 = base64Encode(bytes);
                setModalState(() => localImageBase64 = b64);
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.redAccent),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 10,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Drag handle ───────────────────────────────────
                    Center(
                      child: Container(
                        width: 48, height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),

                    // ── Header row with close button ─────────────────
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'EDIT PROFILE',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Profile Image Picker ─────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                              child: ClipOval(
                                child: localImageBase64 != null && localImageBase64!.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(localImageBase64!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _defaultAvatarIcon(),
                                      )
                                    : _defaultAvatarIcon(),
                              ),
                            ),
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Tap to change photo', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ),
                    const SizedBox(height: 20),

                    // ── Name & Age ───────────────────────────────────
                    _buildEditField(controller: nameCtrl, label: 'Full Name', hint: 'Enter your name'),
                    _buildEditField(controller: ageCtrl, label: 'Age', hint: 'Enter your age', isNumber: true),

                    // ── Fitness Goals Dropdown ───────────────────────
                    _buildDropdownField(
                      label: 'Fitness Goal',
                      value: selectedGoal,
                      items: fitnessGoals,
                      onChanged: (val) => setModalState(() => selectedGoal = val),
                    ),

                    // ── Workout Types Dropdown ───────────────────────
                    _buildDropdownField(
                      label: 'Workout Type',
                      value: selectedWorkout,
                      items: workoutTypes,
                      onChanged: (val) => setModalState(() => selectedWorkout = val),
                    ),

                    // ── Availability Dropdown ────────────────────────
                    _buildDropdownField(
                      label: 'Availability',
                      value: selectedAvailability,
                      items: availabilityOptions,
                      onChanged: (val) => setModalState(() => selectedAvailability = val),
                    ),

                    // ── About Me ─────────────────────────────────────
                    _buildEditField(
                      controller: aboutMeCtrl,
                      label: 'About Me',
                      hint: 'Tell potential partners about yourself...',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),

                    // ── Save Button ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Name cannot be empty')),
                            );
                            return;
                          }
                          final ageVal = int.tryParse(ageCtrl.text);
                          if (ageCtrl.text.isNotEmpty && ageVal == null) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Please enter a valid age number')),
                            );
                            return;
                          }
                          // Close the sheet first, then save + show toast on parent scaffold
                          Navigator.pop(context);
                          final success = await authProvider.updateProfile(
                            name: nameCtrl.text.trim(),
                            age: ageVal,
                            fitnessGoals: selectedGoal,
                            workoutTypes: selectedWorkout,
                            availability: selectedAvailability,
                            profileImage: localImageBase64,
                            aboutMe: aboutMeCtrl.text.trim().isNotEmpty ? aboutMeCtrl.text.trim() : null,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      success ? Icons.check_circle_rounded : Icons.error_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      success ? 'Profile updated successfully!' : 'Failed to update profile.',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                backgroundColor: success ? AppColors.primary : Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditGymInfoBottomSheet(AuthProvider authProvider) {
    final gymId = authProvider.userProfile?['gymId'] as int?;
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No gym associated with your account'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    context.push(AppRoutes.editGymInfo, extra: gymId);
  }

  void _showFeatureRequestScreen(AuthProvider authProvider) {
    final gymId = authProvider.userProfile?['gymId'] as int?;
    final gymName = authProvider.userProfile?['gymName'] as String?;
    context.push(AppRoutes.gymFeatureRequest, extra: {
      'gymId': gymId,
      'gymName': gymName ?? 'Gym',
    });
  }

  void _showLocationPreferencesBottomSheet(GymProvider gymProvider) {
    final locationOptions = [
      _LocationOption(
        label: 'Venice Beach, CA',
        subtitle: 'California fitness hubs',
        latitude: 33.9922,
        longitude: -118.4718,
      ),
      _LocationOption(
        label: 'Copacabana, Brazil',
        subtitle: 'Brazilian fitness scene',
        latitude: -22.9711,
        longitude: -43.1886,
      ),
      _LocationOption(
        label: 'Washington DC',
        subtitle: 'Washington DC fitness scene',
        latitude: 38.8893,
        longitude: -77.0091,
      ),
      _LocationOption(
        label: 'Toronto, Canada',
        subtitle: 'Canadian fitness scene',
        latitude: 43.6695,
        longitude: -79.3870,
      ),
    ];

    var selectedLabel = gymProvider.locationLabel;
    var selectedLat = gymProvider.userLat;
    var selectedLng = gymProvider.userLng;
    var selectedRadius = gymProvider.radius;
    var useDeviceLocation = gymProvider.useDeviceLocation;
    var isRefreshingLocation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        bottom: false,
        child: StatefulBuilder(
          builder: (context, setModalState) {
          Future<void> useCurrentLocation() async {
            final shouldContinue = await showLocationPermissionRationale(context);
            if (!shouldContinue) return;

            setModalState(() => isRefreshingLocation = true);
            try {
              await gymProvider.refreshDeviceLocation();
              selectedLabel = gymProvider.locationLabel;
              selectedLat = gymProvider.userLat;
              selectedLng = gymProvider.userLng;
              selectedRadius = gymProvider.radius;
              useDeviceLocation = true;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Current location updated.')),
                );
              }
            } finally {
              if (mounted) {
                setModalState(() => isRefreshingLocation = false);
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOCATION PREFERENCES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedLabel,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: isRefreshingLocation ? null : useCurrentLocation,
                      icon: isRefreshingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.my_location_rounded, color: AppColors.primary),
                      label: Text(
                        isRefreshingLocation ? 'Updating location...' : 'Use Current Location',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  const Text(
                    'PREFERRED AREA',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...locationOptions.map(
                    (option) {
                      final isSelected = !useDeviceLocation && selectedLabel == option.label;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setModalState(() {
                              selectedLabel = option.label;
                              selectedLat = option.latitude;
                              selectedLng = option.longitude;
                              useDeviceLocation = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.12)
                                  : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected ? AppColors.primary : Colors.white30,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        option.subtitle,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'SEARCH RADIUS',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [3.0, 5.0, 10.0, 15.0, 25.0].map((radius) {
                      final isSelected = selectedRadius == radius;
                      return ChoiceChip(
                        label: Text('${radius.toInt()} KM'),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFF1E1E1E),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.white10,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setModalState(() => selectedRadius = radius);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${selectedLat.toStringAsFixed(4)}, ${selectedLng.toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
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
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await gymProvider.updateLocationPreferences(
                          label: useDeviceLocation ? 'Current Location' : selectedLabel,
                          latitude: selectedLat,
                          longitude: selectedLng,
                          radius: selectedRadius,
                          useDeviceLocation: useDeviceLocation,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location preferences saved.'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Save Preferences',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // If saved value isn't in the list, treat as null so hint shows
    final effectiveValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveValue,
                isExpanded: true,
                hint: Text('Select $label', style: const TextStyle(color: Colors.white24, fontSize: 14)),
                dropdownColor: const Color(0xFF1E1E1E),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 14)),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: isNumber
                  ? TextInputType.number
                  : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
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

class _LocationOption {
  final String label;
  final String subtitle;
  final double latitude;
  final double longitude;

  const _LocationOption({
    required this.label,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}
