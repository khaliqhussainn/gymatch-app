import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

enum NotificationAction {
  gymDetail,
  chats,
  profile,
}

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final NotificationAction action;
  final int? gymId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.action,
    required this.createdAt,
    this.gymId,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      icon: icon,
      action: action,
      createdAt: createdAt,
      gymId: gymId,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  int get unreadCount => _notifications.where((notif) => !notif.isRead).length;
  bool get hasUnread => unreadCount > 0;

  List<AppNotification> get todayNotifications {
    return _notifications.where((notif) {
      final age = DateTime.now().difference(notif.createdAt);
      return age.inHours < 24;
    }).toList();
  }

  List<AppNotification> get earlierNotifications {
    return _notifications.where((notif) {
      final age = DateTime.now().difference(notif.createdAt);
      return age.inHours >= 24;
    }).toList();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  IconData _mapTypeToIcon(String type) {
    switch (type) {
      case 'chats':
        return Icons.people_alt_rounded;
      case 'gymDetail':
        return Icons.fitness_center_rounded;
      case 'profile':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  NotificationAction _mapTypeToAction(String type) {
    switch (type) {
      case 'gymDetail':
        return NotificationAction.gymDetail;
      case 'profile':
        return NotificationAction.profile;
      case 'chats':
      default:
        return NotificationAction.chats;
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/notifications');
      final List<dynamic> data = response.data['notifications'] ?? [];
      
      _notifications = data.map((json) {
        final createdAtStr = json['createdAt'];
        final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
        final type = json['type'] as String? ?? 'chats';
        
        return AppNotification(
          id: json['id'] as int,
          title: json['title'] as String? ?? '',
          body: json['body'] as String? ?? '',
          time: _formatTimeAgo(createdAt),
          icon: _mapTypeToIcon(type),
          action: _mapTypeToAction(type),
          gymId: json['gymId'] as int?,
          isRead: json['isRead'] as bool? ?? false,
          createdAt: createdAt,
        );
      }).toList();
      
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to load notifications.';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((notif) => notif.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    // Optimistically update locally
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    try {
      await _apiClient.dio.post('/notifications/$id/read');
    } catch (e) {
      // Revert if error occurs
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (!hasUnread) return;

    // Optimistically update locally
    final original = List<AppNotification>.from(_notifications);
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _apiClient.dio.post('/notifications/read-all');
    } catch (e) {
      // Revert on error
      _notifications = original;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    if (_notifications.isEmpty) return;

    // Optimistically clear locally
    final original = List<AppNotification>.from(_notifications);
    _notifications.clear();
    notifyListeners();

    try {
      await _apiClient.dio.post('/notifications/clear');
    } catch (e) {
      // Revert on error
      _notifications = original;
      notifyListeners();
    }
  }
}
