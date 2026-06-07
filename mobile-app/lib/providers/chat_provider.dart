import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class ChatThreadModel {
  final int id;
  final int gymId;
  final String gymName;
  final String matchType;
  final int partnerId;
  final String partnerName;
  final String latestMessage;
  final DateTime latestMessageTime;
  final String timeLabel;
  final DateTime expiresAt;

  ChatThreadModel({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.matchType,
    required this.partnerId,
    required this.partnerName,
    required this.latestMessage,
    required this.latestMessageTime,
    required this.timeLabel,
    required this.expiresAt,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: json['id'] as int,
      gymId: json['gymId'] as int,
      gymName: json['gymName'] as String? ?? '',
      matchType: json['matchType'] as String? ?? '',
      partnerId: json['partnerId'] as int,
      partnerName: json['partnerName'] as String? ?? '',
      latestMessage: json['latestMessage'] as String? ?? '',
      latestMessageTime: DateTime.parse(json['latestMessageTime']),
      timeLabel: json['timeLabel'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }
}

class ChatMessageModel {
  final int id;
  final int threadId;
  final int senderId;
  final String message;
  final DateTime createdAt;
  final bool isMe;

  ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isMe,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as int,
      threadId: json['threadId'] as int,
      senderId: json['senderId'] as int,
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isMe: json['isMe'] as bool? ?? false,
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<ChatThreadModel> _threads = [];
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _pollingTimer;
  int? _activeThreadId;

  List<ChatThreadModel> get threads => _threads;
  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Fetch all active chat threads.
  Future<void> fetchThreads() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _api.dio.get('/chats/threads');
      final List<dynamic> data = response.data['threads'] ?? [];
      _threads = data.map((j) => ChatThreadModel.fromJson(j)).toList();
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to load chat conversations.';
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch message history for a single thread.
  Future<void> fetchMessages(int threadId) async {
    _errorMessage = '';
    try {
      final response = await _api.dio.get('/chats/threads/$threadId/messages');
      final List<dynamic> data = response.data['messages'] ?? [];
      _messages = data.map((j) => ChatMessageModel.fromJson(j)).toList();
      notifyListeners();
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException
          ? e.error.toString()
          : 'Failed to load messages.';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
    }
  }

  /// Send a text message to a thread.
  Future<bool> sendMessage(int threadId, String text) async {
    if (text.trim().isEmpty) return false;

    try {
      final response = await _api.dio.post(
        '/chats/threads/$threadId/messages',
        data: {'messageText': text.trim()},
      );

      final newMessage = ChatMessageModel.fromJson(response.data);
      _messages.add(newMessage);
      
      // Update the latest message in threads list locally
      _threads = _threads.map((t) {
        if (t.id == threadId) {
          return ChatThreadModel(
            id: t.id,
            gymId: t.gymId,
            gymName: t.gymName,
            matchType: t.matchType,
            partnerId: t.partnerId,
            partnerName: t.partnerName,
            latestMessage: text.trim(),
            latestMessageTime: DateTime.now(),
            timeLabel: t.timeLabel,
            expiresAt: t.expiresAt,
          );
        }
        return t;
      }).toList();

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Create or load a chat thread with a gym partner.
  Future<int?> invitePartner(int gymId, int partnerId, String matchType) async {
    try {
      final response = await _api.dio.post(
        '/chats/invite',
        data: {
          'gymId': gymId,
          'partnerId': partnerId,
          'matchType': matchType,
        },
      );
      final threadId = response.data['threadId'] as int?;
      await fetchThreads();
      return threadId;
    } catch (_) {
      return null;
    }
  }

  /// Start periodic polling for the current active chat details view.
  void startPolling(int threadId) {
    stopPolling();
    _activeThreadId = threadId;
    fetchMessages(threadId); // initial load
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_activeThreadId == threadId) {
        fetchMessages(threadId);
      }
    });
  }

  /// Stop polling.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _activeThreadId = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
