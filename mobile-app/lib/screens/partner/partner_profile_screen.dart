import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_client.dart';
import '../../routes/app_router.dart';

class PartnerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> partner; // basic data from active-partners list
  final int gymId;
  final String gymName;

  const PartnerProfileScreen({
    super.key,
    required this.partner,
    required this.gymId,
    required this.gymName,
  });

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  Map<String, dynamic>? _fullProfile;
  bool _isLoading = true;
  bool _isConnecting = false;
  String? _error;

  // Match state — null = still checking, int = threadId if matched, -1 = not matched
  int? _existingThreadId; // set once checked; null while loading
  bool _matchChecked = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final fallbackProfile = _profileFromPartner();

    try {
      final api = ApiClient();
      final partnerId = int.tryParse(widget.partner['userId'].toString());
      if (partnerId == null) {
        if (mounted) {
          setState(() {
            _fullProfile = fallbackProfile;
            _isLoading = false;
          });
        }
        return;
      }

      // Run profile fetch and match check in parallel
      final results = await Future.wait([
        api.dio.get('/users/$partnerId/profile'),
        Provider.of<ChatProvider>(context, listen: false)
            .findThreadWithPartner(partnerId),
      ]);

      if (mounted) {
        setState(() {
          _fullProfile = {
            ...fallbackProfile,
            ...Map<String, dynamic>.from((results[0] as dynamic).data),
          };
          _existingThreadId = results[1] as int?;
          _matchChecked = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullProfile = fallbackProfile;
          _matchChecked = true;
          _error = null;
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _profileFromPartner() {
    final partner = widget.partner;
    return {
      'userId': partner['userId'],
      'name': partner['name'] ?? '',
      'email': partner['email'] ?? '',
      'fitnessGoals': partner['fitnessGoals'] ?? '',
      'workoutTypes': partner['workoutTypes'] ?? partner['workoutType'] ?? '',
      'availability': partner['availability'] ?? '',
      'profileImage': partner['profileImage'],
      'aboutMe': partner['aboutMe'] ?? '',
    };
  }

  /// Calculate a match score based on shared workout types / goals.
  ///
  /// Scoring breakdown (total possible = 100):
  ///   - Base score:                    50
  ///   - Workout type match:      +30  (exact) / +15 (partial overlap)
  ///   - Fitness goal match:      +20  (exact) / +10 (partial overlap)
  ///
  /// Result is clamped to [50, 99].
  int _calcMatchScore(AuthProvider auth) {
    final myProfile = auth.userProfile;
    if (myProfile == null || _fullProfile == null) return 72;

    final myWorkout = (myProfile['workoutTypes'] ?? '').toString().toLowerCase().trim();
    final theirWorkout = (_fullProfile!['workoutTypes'] ?? '').toString().toLowerCase().trim();
    final myGoal = (myProfile['fitnessGoals'] ?? '').toString().toLowerCase().trim();
    final theirGoal = (_fullProfile!['fitnessGoals'] ?? '').toString().toLowerCase().trim();

    int score = 50;

    // Workout type scoring
    if (myWorkout.isNotEmpty && theirWorkout.isNotEmpty) {
      if (myWorkout == theirWorkout) {
        score += 30; // exact match
      } else {
        // Partial: check if any word in one appears in the other
        final myWords = myWorkout.split(RegExp(r'[\s,/]+'));
        final theirWords = theirWorkout.split(RegExp(r'[\s,/]+'));
        final hasOverlap = myWords.any((w) => w.length > 3 && theirWords.any((t) => t.contains(w) || w.contains(t)));
        if (hasOverlap) score += 15;
      }
    }

    // Fitness goal scoring
    if (myGoal.isNotEmpty && theirGoal.isNotEmpty) {
      if (myGoal == theirGoal) {
        score += 20; // exact match
      } else {
        final myWords = myGoal.split(RegExp(r'[\s,/]+'));
        final theirWords = theirGoal.split(RegExp(r'[\s,/]+'));
        final hasOverlap = myWords.any((w) => w.length > 3 && theirWords.any((t) => t.contains(w) || w.contains(t)));
        if (hasOverlap) score += 10;
      }
    }

    return score.clamp(50, 99);
  }

  Future<void> _connect() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isGuest) {
      context.go(AppRoutes.login);
      return;
    }

    setState(() => _isConnecting = true);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final threadId = await chatProvider.invitePartner(
      widget.gymId,
      widget.partner['userId'] as int,
      widget.partner['workoutType'] ?? 'General',
    );
    if (mounted) {
      setState(() {
        _isConnecting = false;
        if (threadId != null) _existingThreadId = threadId;
      });
      if (threadId != null) {
        context.go('/main/map');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    final threadId = _existingThreadId;
    if (threadId == null) return;

    // Confirm before disconnecting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text(
          'Disconnect',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will remove your active match and delete the chat. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConnecting = true);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.disconnectPartner(threadId);
    if (mounted) {
      setState(() {
        _isConnecting = false;
        if (success) _existingThreadId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Disconnected successfully.' : 'Failed to disconnect.'),
          backgroundColor: success ? Colors.black87 : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: !_isLoading && _error == null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'PARTNER PROFILE',
                style: GoogleFonts.bebasNeue(
                  fontSize: 28,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFCBF135)))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white24, size: 60),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadProfile(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final profile = _fullProfile!;
    final name = (profile['name'] as String?)?.isNotEmpty == true
        ? profile['name'] as String
        : widget.partner['name'] as String? ?? 'Athlete';
    final email = profile['email'] as String? ?? '';
    final profileImageB64 = profile['profileImage'] as String?;
    final workoutTypes = (profile['workoutTypes'] as String?) ?? '';
    final availability = (profile['availability'] as String?) ?? '';
    final fitnessGoals = (profile['fitnessGoals'] as String?) ?? '';
    final aboutMe = (profile['aboutMe'] as String?) ?? '';
    final gymName = widget.gymName;
    final workoutType = widget.partner['workoutType'] as String? ?? '';

    // Parse availability into time slots for display
    final timeSlots = _parseTimeSlots(availability);
    // Parse workout types into list
    final activities = _parseActivities(workoutTypes.isNotEmpty ? workoutTypes : workoutType);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final matchScore = _calcMatchScore(authProvider);

        return Stack(
          children: [
            // Scrollable body
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Avatar ───────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: profileImageB64 != null && profileImageB64.isNotEmpty
                            ? Image.memory(
                                base64Decode(profileImageB64),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarFallback(),
                              )
                            : _avatarFallback(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Name + email ─────────────────────────────────────
                  Center(
                    child: Text(
                      name.toUpperCase(),
                      style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      email,
                      style: const TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Stats row: Match Score | Activities | Workout Time ─
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Match Score
                          Expanded(
                            child: _statCard(
                              child: Column(
                                children: [
                                  const Text(
                                    'Matched Score',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: CircularProgressIndicator(
                                            value: matchScore / 100,
                                            strokeWidth: 6,
                                            backgroundColor: Colors.white12,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$matchScore%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            Text(
                                              'Match',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Activities
                          Expanded(
                            child: _statCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Activities',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ... (activities.isNotEmpty ? activities : ['Cardio', 'Yoga', 'Crossfit']).take(3).map((a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        a,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Workout Time
                          Expanded(
                            child: _statCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Workout Time',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ... (timeSlots.isNotEmpty ? timeSlots : ['03:00 - 04:00', '15:00 - 16:00', '20:00 - 21:00']).take(3).map((t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Gallery placeholder ───────────────────────────────
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Text(
                  //         'Gallery',
                  //         style: TextStyle(
                  //           color: AppColors.primary,
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.w900,
                  //         ),
                  //       ),
                  //       const Text(
                  //         'View All',
                  //         style: TextStyle(color: Colors.white54, fontSize: 13),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 12),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: Row(
                  //     children: List.generate(4, (i) => Expanded(
                  //       child: Container(
                  //         margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  //         height: 85,
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFF161616),
                  //           borderRadius: BorderRadius.circular(14),
                  //         ),
                  //       ),
                  //     )),
                  //   ),
                  // ),

                  // const SizedBox(height: 28),

                  // ── Info rows ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (gymName.isNotEmpty) ...[
                          _infoRow('GYM', gymName),
                          const SizedBox(height: 14),
                        ],
                        if (fitnessGoals.isNotEmpty) ...[
                          _infoRow('Preferred Training Style', fitnessGoals),
                          const SizedBox(height: 14),
                        ],
                        if (aboutMe.isNotEmpty) ...[
                          _infoRow('About Me', aboutMe),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Connect / Disconnect button (pinned bottom) ──────────────────
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _existingThreadId != null
                        ? const Color(0xFF2A2A2A)
                        : AppColors.primary,
                    foregroundColor: _existingThreadId != null
                        ? Colors.redAccent
                        : Colors.black,
                    side: _existingThreadId != null
                        ? const BorderSide(color: Colors.redAccent, width: 1.5)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isConnecting
                      ? null
                      : (_existingThreadId != null ? _disconnect : _connect),
                  child: _isConnecting
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _existingThreadId != null
                                ? Colors.redAccent
                                : Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _existingThreadId != null
                                  ? Icons.link_off_rounded
                                  : Icons.link_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _existingThreadId != null ? 'Disconnect' : 'Connect',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.0),
      ),
      child: child,
    );
  }

  Widget _infoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Icon(Icons.person_rounded, color: Colors.white38, size: 56),
    );
  }

  List<String> _parseActivities(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(RegExp(r'[,/]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  List<String> _parseTimeSlots(String availability) {
    if (availability.isEmpty) return [];
    // Extract time ranges like "5–8 AM", "6-8 PM" or return 2-word chunks
    final timeRegex = RegExp(r'\d{1,2}[:\.]?\d{0,2}\s*[AP]M?\s*[-–]\s*\d{1,2}[:\.]?\d{0,2}\s*[AP]M?', caseSensitive: false);
    final matches = timeRegex.allMatches(availability).map((m) => m.group(0)!.trim()).toList();
    if (matches.isNotEmpty) return matches;
    // Fallback: shorten the availability string to max 3 lines
    final parts = availability.split(RegExp(r'[,–-]'));
    return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).take(3).toList();
  }
}
