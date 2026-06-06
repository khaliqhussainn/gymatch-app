import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

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
          'SETTINGS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ACCOUNT section
          _sectionLabel('ACCOUNT'),
          const SizedBox(height: 10),
          _buildGroup([
            _buildTile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () {},
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () {},
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              onTap: () {},
            ),
          ]).animate().fadeIn(delay: 50.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // PREFERENCES section
          _sectionLabel('PREFERENCES'),
          const SizedBox(height: 10),
          _buildGroup([
            _buildToggleTile(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.location_on_outlined,
              label: 'Location Services',
              value: _locationEnabled,
              onChanged: (val) => setState(() => _locationEnabled = val),
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.language_outlined,
              label: 'Language',
              trailing: const Text(
                'English',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              onTap: () {},
            ),
          ]).animate().fadeIn(delay: 100.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // PRIVACY section
          _sectionLabel('PRIVACY'),
          const SizedBox(height: 10),
          _buildGroup([
            _buildTile(
              icon: Icons.visibility_outlined,
              label: 'Profile Visibility',
              onTap: () {},
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.block_rounded,
              label: 'Blocked Users',
              onTap: () {},
            ),
          ]).animate().fadeIn(delay: 150.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // SUPPORT section
          _sectionLabel('SUPPORT'),
          const SizedBox(height: 10),
          _buildGroup([
            _buildTile(
              icon: Icons.help_outline_rounded,
              label: 'Help Center',
              onTap: () {},
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () {},
            ),
          ]).animate().fadeIn(delay: 200.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // LOGOUT button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A0A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => context.go(AppRoutes.login),
              ),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // Version
          Center(
            child: Text(
              'GYMATCH v1.0.0',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white38,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.white10,
      height: 1,
      indent: 56,
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white24,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withOpacity(0.3),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.white12,
        ),
      ),
    );
  }
}
