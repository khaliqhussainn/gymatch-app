import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    }
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
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
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              if (notificationProvider.notifications.isEmpty) {
                return const SizedBox(width: 16);
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                color: const Color(0xFF1A1A1A),
                onSelected: (value) {
                  if (value == 'read') notificationProvider.markAllAsRead();
                  if (value == 'clear') notificationProvider.clearAll();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'read',
                    enabled: notificationProvider.hasUnread,
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Text(
                      'Clear all',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, NotificationProvider>(
        builder: (context, authProvider, notificationProvider, _) {
          // Not logged in – show guest message
          if (!authProvider.isAuthenticated) {
            return _buildGuestLock(context);
          }

          // Loading state
          if (notificationProvider.isLoading &&
              notificationProvider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFCBF135)),
            );
          }

          if (notificationProvider.notifications.isEmpty) {
            return const _EmptyNotifications();
          }

          final today = notificationProvider.todayNotifications;
          final earlier = notificationProvider.earlierNotifications;

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF151515),
            onRefresh: () => notificationProvider.fetchNotifications(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (today.isNotEmpty) ...[
                  _buildSectionLabel('TODAY'),
                  const SizedBox(height: 10),
                  ...today.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotifCard(
                        notif: entry.value,
                        index: entry.key,
                        onTap: () => _openNotification(
                          context,
                          notificationProvider,
                          entry.value,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (earlier.isNotEmpty) ...[
                  _buildSectionLabel('EARLIER'),
                  const SizedBox(height: 10),
                  ...earlier.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotifCard(
                        notif: entry.value,
                        index: entry.key + today.length,
                        onTap: () => _openNotification(
                          context,
                          notificationProvider,
                          entry.value,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildSectionLabel(String label) {
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

  Widget _buildGuestLock(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Icon(Icons.lock_outline_rounded,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'SIGN IN REQUIRED',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please sign in to view your notifications.',
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
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
                      borderRadius: BorderRadius.circular(26)),
                ),
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Log In',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotification(
    BuildContext context,
    NotificationProvider notificationProvider,
    AppNotification notification,
  ) {
    notificationProvider.markAsRead(notification.id);

    switch (notification.action) {
      case NotificationAction.gymDetail:
        context.push(AppRoutes.gymDetail, extra: notification.gymId);
        break;
      case NotificationAction.chats:
        context.go(AppRoutes.map);
        break;
      case NotificationAction.profile:
        context.go(AppRoutes.profile);
        break;
    }
  }
}


class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_off_outlined, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              'NO NOTIFICATIONS',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Matches, gym updates, and partner requests will show up here.',
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final int index;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notif,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = !notif.isRead;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isNew
              ? AppColors.primary.withOpacity(0.07)
              : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNew
                ? AppColors.primary.withOpacity(0.3)
                : Colors.white10,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isNew
                    ? AppColors.primary.withOpacity(0.2)
                    : const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif.icon,
                color: isNew ? AppColors.primary : Colors.white38,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: isNew ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isNew)
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
                  Row(
                    children: [
                      Text(
                        notif.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isNew ? AppColors.primary : Colors.white24,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 60 * index),
          duration: 350.ms,
        );
  }
}
