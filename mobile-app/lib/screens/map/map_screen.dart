import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isDetailView = false;
  ChatThreadModel? _activeThread;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

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
      Provider.of<ChatProvider>(context, listen: false).fetchThreads();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _confirmUnmatch(ChatThreadModel thread) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text(
          'UNMATCH?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: Text(
          'This will permanently delete your match with ${thread.partnerName} and all chat messages. This cannot be undone.',
          style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final success = await chatProvider.deleteThread(thread.id);
              if (mounted) {
                if (success) {
                  chatProvider.stopPolling();
                  setState(() {
                    _isDetailView = false;
                    _activeThread = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unmatched from ${thread.partnerName}.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to unmatch. Please try again.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Unmatch', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isGuest) {
      return _buildGuestLockScreen();
    }

    if (_isDetailView && _activeThread != null) {
      return _buildChatDetailScreen();
    }

    return _buildChatListScreen();
  }

  // GUEST GATED SCREEN
  Widget _buildGuestLockScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MATCH CHATS LOCKED',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign up to view active matches, chat with workout partners, and coordinate training schedules in real-time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
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
                      onPressed: () => context.go(AppRoutes.register),
                      child: const Text(
                        'Create Free Account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
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
        ),
      ),
    );
  }

  // CHATS TAB VIEW
  Widget _buildChatListScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final filteredThreads = chatProvider.threads.where((t) {
              return t.partnerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  t.gymName.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: const Color(0xFF151515),
              onRefresh: () => chatProvider.fetchThreads(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(left: 48),
                              child: Text(
                                'CHATS',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Profile Icon
                        GestureDetector(
                          onTap: () => context.go('/main/profile'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2A2A2A),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white60,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Notification bell
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, _) {
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => context.push(AppRoutes.notifications),
                                ),
                                if (notificationProvider.hasUnread)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 10,
                                        minHeight: 10,
                                      ),
                                      padding: notificationProvider.unreadCount > 9
                                          ? const EdgeInsets.symmetric(horizontal: 4)
                                          : EdgeInsets.zero,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: notificationProvider.unreadCount > 9
                                            ? BoxShape.rectangle
                                            : BoxShape.circle,
                                        borderRadius: notificationProvider.unreadCount > 9
                                            ? BorderRadius.circular(8)
                                            : null,
                                        border: Border.all(color: Colors.black, width: 1.5),
                                      ),
                                      child: notificationProvider.unreadCount > 9
                                          ? const Text(
                                              '9+',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.white38, size: 22),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 50.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // Chats List
                  Expanded(
                    child: chatProvider.isLoading && chatProvider.threads.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFCBF135)))
                        : filteredThreads.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: filteredThreads.length,
                                itemBuilder: (context, index) {
                                  final thread = filteredThreads[index];
                                  final isUnread = false; // logic placeholder
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _activeThread = thread;
                                          _isDetailView = true;
                                        });
                                        chatProvider.startPolling(thread.id);
                                        _scrollToBottom();
                                      },
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF121212),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Profile Avatar stack with status dot
                                            Stack(
                                              children: [
                                                Container(
                                                  width: 54,
                                                  height: 54,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xFF2A2A2A),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.person_rounded,
                                                      color: Colors.white60,
                                                      size: 34,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 2,
                                                  bottom: 2,
                                                  child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF4DFF91),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: const Color(0xFF121212), width: 2),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(width: 16),
                                            
                                            // Message details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        thread.partnerName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 17,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        thread.timeLabel,
                                                        style: const TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    thread.latestMessage,
                                                    style: TextStyle(
                                                      color: isUnread ? AppColors.primary : Colors.white70,
                                                      fontSize: 14,
                                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${thread.matchType.toUpperCase()} MATCH AT ${thread.gymName.toUpperCase()}',
                                                    style: const TextStyle(
                                                      color: Colors.white24,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms);
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text(
            'NO MATCH CHATS YET',
            style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Discover nearby gyms in Home or Explore tabs, look at their Active Partner Feed, and match with someone to coordinate a workout!',
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ACTIVE CHAT DETAIL VIEW
  Widget _buildChatDetailScreen() {
    final thread = _activeThread!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            chatProvider.stopPolling();
            setState(() {
              _isDetailView = false;
              _activeThread = null;
            });
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Partner profile avatar
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2A2A2A),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white60,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DFF91),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.partnerName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Active now',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Unmatch button
          IconButton(
            icon: const Icon(Icons.person_remove_rounded, color: Colors.white54, size: 22),
            tooltip: 'Unmatch',
            onPressed: () => _confirmUnmatch(thread),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Matched badge indicator banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Center(
                  child: Text(
                    'MATCHED FOR: ${thread.matchType.toUpperCase()} AT ${thread.gymName.toUpperCase()}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            // Chat Messages area
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatProvider.messages[index];
                      final isMe = msg.isMe;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              msg.message,
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                                fontSize: 15,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Message Input box
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    // Send button
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                        onPressed: _handleSend,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() async {
    final text = _messageController.text;
    if (text.trim().isEmpty || _activeThread == null) return;
    
    _messageController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.sendMessage(_activeThread!.id, text);
    if (success) {
      _scrollToBottom();
    }
  }
}
