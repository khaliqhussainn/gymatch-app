import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _todayNotifs = [
    _Notif(
      title: 'New Match Found! 🎉',
      body: 'Tommy is looking for a CrossFit partner at Gold\'s Gym right now.',
      time: '2m ago',
      icon: Icons.people_alt_rounded,
      isNew: true,
    ),
    _Notif(
      title: 'Gym Now Open',
      body: 'Gold\'s Gym (Karachi Central) is now open. 32 people are active.',
      time: '45m ago',
      icon: Icons.fitness_center_rounded,
      isNew: true,
    ),
    _Notif(
      title: 'Partner Request',
      body: 'Sarah J. wants to train with you at Titan Fitness today at 6 PM.',
      time: '1h ago',
      icon: Icons.person_add_rounded,
      isNew: true,
    ),
  ];

  static const _earlierNotifs = [
    _Notif(
      title: 'Workout Streak 🔥',
      body: 'You\'ve matched with partners 5 days in a row! Keep it up.',
      time: 'Yesterday',
      icon: Icons.local_fire_department_rounded,
      isNew: false,
    ),
    _Notif(
      title: 'New Gym Near You',
      body: '\"Titan Stronghold\" just opened 1 KM away. Check it out!',
      time: '2 days ago',
      icon: Icons.place_rounded,
      isNew: false,
    ),
    _Notif(
      title: 'Thread Expired',
      body: 'Your match thread with Ali has expired after 48 hours.',
      time: '3 days ago',
      icon: Icons.chat_bubble_outline_rounded,
      isNew: false,
    ),
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
          'NOTIFICATIONS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Clear All',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // TODAY section
          _buildSectionLabel('TODAY'),
          const SizedBox(height: 10),
          ..._todayNotifs.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotifCard(notif: e.value, index: e.key),
            ),
          ),

          const SizedBox(height: 16),

          // EARLIER section
          _buildSectionLabel('EARLIER'),
          const SizedBox(height: 10),
          ..._earlierNotifs.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotifCard(notif: e.value, index: e.key + 3),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white38,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _Notif {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final bool isNew;

  const _Notif({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.isNew,
  });
}

class _NotifCard extends StatelessWidget {
  final _Notif notif;
  final int index;

  const _NotifCard({required this.notif, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notif.isNew
            ? AppColors.primary.withOpacity(0.07)
            : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notif.isNew
              ? AppColors.primary.withOpacity(0.3)
              : Colors.white10,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: notif.isNew
                  ? AppColors.primary.withOpacity(0.2)
                  : const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notif.icon,
              color: notif.isNew ? AppColors.primary : Colors.white38,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (notif.isNew)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notif.body,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notif.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 60 * index),
          duration: 350.ms,
        );
  }
}
