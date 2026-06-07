import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/gym_model.dart';
import '../../providers/chat_provider.dart';

class GymDetailScreen extends StatefulWidget {
  final int? gymId;
  const GymDetailScreen({super.key, this.gymId});

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  int _currentImageIndex = 0;
  bool _myActiveStatus = false;
  bool _isTogglingPartner = false;
  bool _isLoading = true;
  bool _isSaving = false;
  GymModel? _gym;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGym();
  }

  Future<void> _loadGym() async {
    setState(() { _isLoading = true; _error = null; });

    if (widget.gymId != null) {
      final gymProvider = Provider.of<GymProvider>(context, listen: false);
      final gym = await gymProvider.fetchGymDetail(widget.gymId!);
      await gymProvider.fetchActivePartners(widget.gymId!);
      if (mounted) {
        setState(() {
          _gym = gym;
          _myActiveStatus = gym?.isActivePartner ?? false;
          _isLoading = gym == null;
          _error = gym == null ? 'Could not load gym details.' : null;
        });
      }
    } else {
      setState(() { _isLoading = false; _error = 'No gym selected.'; });
    }
  }

  Future<void> _toggleSave() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isGuest) {
      _showUnlockModal();
      return;
    }
    if (_gym == null) return;
    setState(() => _isSaving = true);
    final gymProvider = Provider.of<GymProvider>(context, listen: false);
    final result = await gymProvider.toggleSaved(_gym!.id);
    if (mounted && result != null) {
      setState(() {
        _gym = _gym!.copyWith(isSaved: result);
        _isSaving = false;
      });
    } else {
      setState(() => _isSaving = false);
    }
  }

  void _showUnlockModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFA151515),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                child: const Center(child: Icon(Icons.person_rounded, color: Colors.black, size: 38)),
              ),
              const SizedBox(height: 20),
              const Text('SIGN IN REQUIRED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Sign up to save gyms, contact them and unlock the full GYMatch experience.', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                  onPressed: () { Navigator.pop(context); context.go(AppRoutes.register); },
                  child: const Text('Create Free Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  GestureDetector(
                    onTap: () { Navigator.pop(context); context.go(AppRoutes.login); },
                    child: Text('Log In', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmMatch(Map<String, dynamic> partner) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isGuest) {
      _showUnlockModal();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
        title: Text('MATCH WITH ${partner['name'].toUpperCase()}?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Would you like to match with ${partner['name']} for ${partner['workoutType']} training at ${_gym?.name ?? 'this gym'}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final threadId = await chatProvider.invitePartner(
                _gym!.id,
                partner['userId'],
                partner['workoutType'],
              );
              if (mounted && threadId != null) {
                context.go('/main/map');
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to initiate match. Please try again.')),
                  );
                }
              }
            },
            child: const Text('Match Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_gym != null)
            IconButton(
              onPressed: _isSaving ? null : _toggleSave,
              icon: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(
                      _gym!.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _gym!.isSaved ? AppColors.primary : Colors.white,
                      size: 26,
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
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
          Text(_error!, style: const TextStyle(color: Colors.white60, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: _loadGym,
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final gym = _gym!;
    final images = gym.images.isNotEmpty ? gym.images : [gym.coverImage ?? ''];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                height: 320,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (context, index) {
                    final url = images[index];
                    return url.isNotEmpty
                        ? Image.network(url, fit: BoxFit.cover, width: double.infinity,
                            errorBuilder: (_, __, ___) => _imageFallback())
                        : _imageFallback();
                  },
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      final isSelected = index == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gym.name,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      gym.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${gym.locationName} | ${gym.distanceLabel} Away',
                  style: const TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    _buildActionButton('Direction', true, Icons.near_me_rounded, () {}),
                    const SizedBox(width: 8),
                    _buildActionButton('Call', false, Icons.call_rounded, () {}),
                    const SizedBox(width: 8),
                    _buildActionButton('Save', false, gym.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, _toggleSave),
                    const SizedBox(width: 8),
                    _buildActionButton('Share', false, Icons.share_rounded, () {}),
                  ],
                ),

                const SizedBox(height: 28),

                // Active Partner Feed
                Consumer<GymProvider>(
                  builder: (context, gymProvider, child) {
                    final partners = gymProvider.activePartners;
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E1E1E)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ACTIVE PARTNER FEED', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              _isTogglingPartner
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCBF135)))
                                  : Switch(
                                      value: _myActiveStatus,
                                      onChanged: (val) async {
                                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                        if (authProvider.isGuest) {
                                          _showUnlockModal();
                                          return;
                                        }
                                        setState(() => _isTogglingPartner = true);
                                        final res = await gymProvider.togglePartnerStatus(widget.gymId!);
                                        if (mounted && res != null) {
                                          setState(() {
                                            _myActiveStatus = res;
                                            _isTogglingPartner = false;
                                            if (_gym != null) {
                                              _gym = _gym!.copyWith(
                                                isActivePartner: res,
                                                activePartnersCount: res
                                                    ? _gym!.activePartnersCount + 1
                                                    : (_gym!.activePartnersCount > 0 ? _gym!.activePartnersCount - 1 : 0),
                                              );
                                            }
                                          });
                                        } else {
                                          setState(() => _isTogglingPartner = false);
                                        }
                                      },
                                      activeColor: AppColors.primary,
                                      activeTrackColor: AppColors.primary.withOpacity(0.3),
                                      inactiveThumbColor: Colors.grey,
                                      inactiveTrackColor: Colors.white12,
                                    ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('🔥 ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  '${gym.activePartnersCount} people are currently looking for a partner here.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          partners.isNotEmpty
                              ? SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: partners.length,
                                    itemBuilder: (context, index) {
                                      final partner = partners[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: GestureDetector(
                                          onTap: () => _confirmMatch(partner),
                                          child: Container(
                                            width: 82,
                                            decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  children: [
                                                    Container(
                                                      width: 44, height: 44,
                                                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                                                      child: const Center(child: Icon(Icons.person_rounded, color: Colors.black, size: 28)),
                                                    ),
                                                    Positioned(
                                                      right: 0, bottom: 0,
                                                      child: Container(width: 10, height: 10,
                                                        decoration: BoxDecoration(color: const Color(0xFF4DFF91), shape: BoxShape.circle,
                                                          border: Border.all(color: const Color(0xFF1C1C1C), width: 1.5)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  partner['name'] ?? '',
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  partner['status'] ?? 'Active Now',
                                                  style: const TextStyle(color: Color(0xFF4DFF91), fontSize: 8, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'No other partners active at the moment. Toggle your status above to let others match with you!',
                                    style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                                  ),
                                ),
                        ],
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // AMENITIES & INFO
                const Text('AMENITIES & INFO', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  '${gym.isOpen ? "OPEN NOW" : "CLOSED"}: ${gym.openHours}',
                  style: TextStyle(color: gym.isOpen ? AppColors.primary : Colors.white38, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                gym.amenities.isNotEmpty
                    ? Wrap(
                        spacing: 8, runSpacing: 8,
                        children: gym.amenities.map((amenity) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
                          child: Text(amenity, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        )).toList(),
                      )
                    : const Text('No amenity info available.', style: TextStyle(color: Colors.white38)),

                const SizedBox(height: 28),

                // MEMBERSHIP PLANS
                if (gym.plans.isNotEmpty) ...[
                  const Text('MEMBERSHIP PLANS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: gym.plans.asMap().entries.map((entry) {
                      final plan = entry.value;
                      final isPremium = plan.isPremium;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: entry.key > 0 ? 12 : 0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141414),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPremium ? AppColors.primary : Colors.white10,
                                    width: isPremium ? 2 : 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isPremium) const SizedBox(height: 8),
                                    Text(
                                      plan.name,
                                      style: TextStyle(
                                        color: isPremium ? AppColors.primary : Colors.white,
                                        fontSize: isPremium ? 14 : 15,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '\$${plan.price.toStringAsFixed(0)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                                        ),
                                        Text(
                                          '/${plan.billingPeriod}',
                                          style: const TextStyle(color: Colors.white60, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ..._buildPlanBullets(plan.features),
                                    if (isPremium) ...[
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity, height: 38,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () {},
                                          child: const Text('SELECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isPremium)
                                Positioned(
                                  top: -10, right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                // Book a Tour Button
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () {},
                    child: const Text('CALL TO BOOK A TOUR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 320, color: const Color(0xFF1A1A1A),
      child: const Center(child: Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 60)),
    );
  }

  Widget _buildActionButton(String label, bool isPrimary, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isPrimary ? AppColors.primary : Colors.white24),
            boxShadow: isPrimary ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6)] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 14),
              Text(label, style: TextStyle(color: isPrimary ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlanBullets(List<String> bullets) {
    return bullets.map((bullet) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 4, right: 6), child: Icon(Icons.circle, size: 4, color: Colors.white70)),
          Expanded(child: Text(bullet, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3))),
        ],
      ),
    )).toList();
  }
}
