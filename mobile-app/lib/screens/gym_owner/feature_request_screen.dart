import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';

class FeatureRequestScreen extends StatefulWidget {
  final int gymId;
  final String gymName;
  final String? requestType; // 'gym' or 'user'

  const FeatureRequestScreen({
    super.key,
    required this.gymId,
    required this.gymName,
    this.requestType = 'gym',
  });

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;
  List<Map<String, dynamic>> _previousRequests = [];
  static const int _minWords = 10;
  static const int _maxWords = 200;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(_onTextChanged);
    _loadPreviousRequests();
  }

  @override
  void dispose() {
    _reasonController.removeListener(_onTextChanged);
    _reasonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  bool _isValidDescription() {
    final wordCount = _getWordCount(_reasonController.text);
    return wordCount >= _minWords && wordCount <= _maxWords;
  }

  Future<void> _loadPreviousRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gymProvider = context.read<GymProvider>();
      _previousRequests = await gymProvider.fetchUserFeatureRequests();
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

  Future<void> _submitRequest() async {
    final wordCount = _getWordCount(_reasonController.text);
    
    if (_reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a reason for your request';
      });
      return;
    }
    
    if (wordCount < _minWords) {
      setState(() {
        _errorMessage = 'Description must be at least $_minWords words';
      });
      return;
    }
    
    if (wordCount > _maxWords) {
      setState(() {
        _errorMessage = 'Description must not exceed $_maxWords words';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final gymProvider = context.read<GymProvider>();
      final success = await gymProvider.createFeatureRequest(
        requestType: widget.requestType ?? 'gym',
        entityId: widget.gymId,
        reason: _reasonController.text.trim(),
      );

      if (success) {
        setState(() {
          _successMessage = 'Feature request submitted successfully!';
          _reasonController.clear();
        });
        await _loadPreviousRequests();
      } else {
        setState(() {
          _errorMessage = gymProvider.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGymRequest = widget.requestType == 'gym';
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.role;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          isGymRequest ? 'Request Featured Status' : 'Request Featured Profile',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entity Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    isGymRequest ? Icons.business : Icons.person,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isGymRequest ? widget.gymName : 'User / Trainer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Request Form
            Text(
              isGymRequest 
                  ? 'Why should your gym be featured?'
                  : 'Why should you be featured?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isGymRequest
                  ? 'Tell us what makes your gym special and why it deserves to be featured on GYMatch.'
                  : 'Tell us about your fitness journey, achievements, and why you deserve to be featured on GYMatch.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _reasonController,
              maxLines: 5,
              maxLength: 2000,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isGymRequest
                    ? 'e.g., We have state-of-the-art equipment, expert trainers, and a supportive community...'
                    : 'e.g., I have transformed my health through consistent training, completed multiple fitness challenges, and love motivating others...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Word count indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Word count: ${_getWordCount(_reasonController.text)}',
                  style: TextStyle(
                    color: _isValidDescription() 
                        ? Colors.green 
                        : Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Min: $_minWords • Max: $_maxWords',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Success Message
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null) const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_isSubmitting || !_isValidDescription()) ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                  disabledForegroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Previous Requests
            const Text(
              'Previous Requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_previousRequests.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No previous requests',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _previousRequests.length,
                itemBuilder: (context, index) {
                  final request = _previousRequests[index];
                  return _buildRequestCard(request);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final isGymRequest = widget.requestType == 'gym';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['entity_name'] ?? (isGymRequest ? 'Gym' : 'Profile'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request['reason'] != null && request['reason'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request['reason'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            request['created_at'] ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
