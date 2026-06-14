import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';

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
    final name = profile?['name'] as String?;
    final email = authProvider.email;

    return Column(
      children: [
        // Profile image placeholder
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
        Text(
          name?.isNotEmpty == true ? name!.toUpperCase() : 'FITNESS ENTHUSIAST',
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
          email ?? 'username@gmail.com',
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

  void _showEditProfileBottomSheet(AuthProvider authProvider) {
    final profile = authProvider.userProfile;
    final nameCtrl = TextEditingController(text: profile?['name'] ?? '');
    final ageCtrl = TextEditingController(text: profile?['age']?.toString() ?? '');
    final goalsCtrl = TextEditingController(text: profile?['fitnessGoals'] ?? '');
    final workoutTypesCtrl = TextEditingController(text: profile?['workoutTypes'] ?? '');
    final availabilityCtrl = TextEditingController(text: profile?['availability'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        bottom: false,
        child: Padding(
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
              const Text(
                'EDIT PROFILE DETAILS',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 20),
              
              _buildEditField(controller: nameCtrl, label: 'Full Name', hint: 'Enter your name'),
              _buildEditField(controller: ageCtrl, label: 'Age', hint: 'Enter your age', isNumber: true),
              _buildEditField(controller: goalsCtrl, label: 'Fitness Goals', hint: 'e.g. Build muscle, lose weight'),
              _buildEditField(controller: workoutTypesCtrl, label: 'Workout Types', hint: 'e.g. CrossFit, Yoga, MMA'),
              _buildEditField(controller: availabilityCtrl, label: 'Availability', hint: 'e.g. Weekdays 6-8 PM'),

              const SizedBox(height: 24),
              
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name cannot be empty')),
                      );
                      return;
                    }
                    final ageVal = int.tryParse(ageCtrl.text);
                    if (ageCtrl.text.isNotEmpty && ageVal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid age number')),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    final success = await authProvider.updateProfile(
                      name: nameCtrl.text.trim(),
                      age: ageVal,
                      fitnessGoals: goalsCtrl.text.trim(),
                      workoutTypes: workoutTypesCtrl.text.trim(),
                      availability: availabilityCtrl.text.trim(),
                    );
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Profile updated successfully!' : 'Failed to update profile.')),
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
      ),
    ),
    );
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

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
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
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
