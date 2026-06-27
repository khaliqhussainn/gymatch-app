import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../config/app_colors.dart';
import '../../routes/app_router.dart';

class GymDashboardScreen extends StatefulWidget {
  const GymDashboardScreen({super.key});

  @override
  State<GymDashboardScreen> createState() => _GymDashboardScreenState();
}

class _GymDashboardScreenState extends State<GymDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _gymDetails;
  List<Map<String, dynamic>> _partners = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final gymProvider = context.read<GymProvider>();

      // For now, we'll need to get the gym ID from the auth provider or user profile
      // This is a placeholder - in a real implementation, you'd fetch the gym owner's gym ID
      // For this demo, we'll assume the gym ID is stored or fetched from user profile
      
      // TODO: Fetch gym ID from user profile or gym owner relationship
      // For now, we'll use a placeholder or fetch from profile
      final userProfile = authProvider.userProfile;
      final gymId = userProfile?['gym_id'] as int?;

      if (gymId == null) {
        setState(() {
          _errorMessage = 'No gym associated with your account';
          _isLoading = false;
        });
        return;
      }

      // Fetch gym details
      final gym = await gymProvider.fetchGymDetail(gymId);
      if (gym != null) {
        _gymDetails = {
          'id': gym.id,
          'name': gym.name,
          'subName': gym.subName,
          'locationName': gym.locationName,
          'category': gym.category,
          'contactPhone': gym.contactPhone,
          'openHours': gym.openHours,
          'isFeatured': gym.isFeatured,
          'activePartnersCount': gym.activePartnersCount,
        };
      }

      // Fetch gym partners
      _partners = await gymProvider.fetchGymPartners(gymId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Gym Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _gymDetails == null
                  ? const Center(
                      child: Text(
                        'No gym found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gym Info Card
                            _buildGymInfoCard(),
                            const SizedBox(height: 24),

                            // Stats Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Active Partners',
                                    _partners.length.toString(),
                                    Icons.people,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    'Featured',
                                    _gymDetails!['isFeatured'] == 1 ? 'Yes' : 'No',
                                    Icons.star,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            _buildActionButtons(),
                            const SizedBox(height: 24),

                            // Recent Partners Section
                            _buildPartnersSection(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildGymInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _gymDetails!['name'] ?? 'Gym Name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_gymDetails!['subName'] != null && _gymDetails!['subName'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _gymDetails!['subName'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, _gymDetails!['locationName'] ?? 'Location'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.category, _gymDetails!['category'] ?? 'Category'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone, _gymDetails!['contactPhone'] ?? 'No phone'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time, _gymDetails!['openHours'] ?? 'Hours not set'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Partners Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to partners screen
              // context.push(AppRoutes.gymPartners);
            },
            icon: const Icon(Icons.people),
            label: const Text('View Active Partners'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Request Featured Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to feature request screen
              // context.push(AppRoutes.gymFeatureRequest);
            },
            icon: const Icon(Icons.star),
            label: const Text('Request Featured Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Edit Gym Details Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to edit gym screen
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Gym Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Active Partners',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_partners.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No active partners yet',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _partners.take(5).length,
            itemBuilder: (context, index) {
              final partner = _partners[index];
              return _buildPartnerCard(partner);
            },
          ),
        if (_partners.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: () {
                // Navigate to full partners list
              },
              child: const Text(
                'View All Partners',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              (partner['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${partner['workoutType'] ?? 'General'} • ${partner['experienceLevel'] ?? 'Intermediate'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}
