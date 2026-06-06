import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isDetailView = false;
  String _activePartnerName = 'Tommy';
  bool _activePartnerIsOnline = true;
  String _activeMatchText = 'MATCHED FOR: CROSSFIT AT GOLD\'S GYM';

  // Chat conversation list data
  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'John',
      'message': 'Sounds Good! See you on the mat at 9',
      'isYellowMessage': true,
      'matchType': 'YOGA MATCH',
      'time': '2 min ago',
      'isOnline': true,
    },
    {
      'name': 'Tommy',
      'message': 'Perfect. I\'m down. See you at the lifting racks at 8.',
      'isYellowMessage': true,
      'matchType': 'CROSSFIT MATCH',
      'time': '30 min ago',
      'isOnline': true,
    },
    {
      'name': 'Ali',
      'message': 'Maybe Next time, Thanks!',
      'isYellowMessage': false,
      'matchType': 'MMA MATCH',
      'time': '1h ago',
      'isOnline': false,
    },
    {
      'name': 'Snow',
      'message': 'Can we switch to Tuesday?',
      'isYellowMessage': true,
      'matchType': 'CARDIO MATCH',
      'time': '3h ago',
      'isOnline': false,
    },
    {
      'name': 'Shawn',
      'message': 'Tonight 10?',
      'isYellowMessage': false,
      'matchType': 'CROSSFIT MATCH',
      'time': '3h ago',
      'isOnline': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isDetailView) {
      return _buildChatDetailScreen();
    }
    return _buildChatListScreen();
  }

  // CHATS TAB VIEW
  Widget _buildChatListScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                        padding: EdgeInsets.only(left: 48), // balance alignment
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
                  Container(
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
                  const SizedBox(width: 12),
                  
                  // Notification bell
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => context.push(AppRoutes.notifications),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                        ),
                      ),
                    ],
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
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final chat = _conversations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activePartnerName = chat['name'];
                          _activePartnerIsOnline = chat['isOnline'];
                          _activeMatchText = 'MATCHED FOR: ${chat['matchType']} AT GOLD\'S GYM';
                          _isDetailView = true;
                        });
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: chat['isOnline'] ? AppColors.primary : const Color(0xFF2A2A2A),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: chat['isOnline'] ? Colors.black : Colors.white60,
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
                                      color: chat['isOnline'] ? const Color(0xFF4DFF91) : Colors.white70,
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
                                        chat['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        chat['time'],
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat['message'],
                                    style: TextStyle(
                                      color: chat['isYellowMessage'] ? AppColors.primary : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: chat['isYellowMessage'] ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    chat['matchType'],
                                    style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 60 * index), duration: 350.ms);
                },
              ),
            ),
          ],
        ),
      ),
      
      // Floating add conversation button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () {},
        child: const Icon(
          Icons.add_rounded,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }

  // ACTIVE CHAT DETAIL VIEW
  Widget _buildChatDetailScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            setState(() {
              _isDetailView = false;
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _activePartnerIsOnline ? AppColors.primary : const Color(0xFF2A2A2A),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: _activePartnerIsOnline ? Colors.black : Colors.white60,
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
                      color: _activePartnerIsOnline ? const Color(0xFF4DFF91) : Colors.white70,
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
                  _activePartnerName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _activePartnerIsOnline ? 'Active now' : 'Offline',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
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
                    _activeMatchText,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // Chat Messages area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Left Partner Message
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Hey! I\'m hitting Gold\'s Gym around 8:00 PM for the CrossFit WOD. Down to partner up?',
                        style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Right User Message
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Perfect. I\'m down. See you at the lifting racks at 8.',
                        style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
                      ),
                    ),
                  ),
                ],
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
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white38, size: 26),
                      onPressed: () {},
                    ),
                    const Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
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
                        onPressed: () {},
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
}
