import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Add listener to update UI when text changes
    _emailController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      // Clear error when user types
      _emailError = null;
    });
  }

  bool get _isFormValid {
    return _emailController.text.trim().isNotEmpty && _emailError == null;
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError = null;
    });

    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.forgotPassword(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (result != null) {
        final message = result['message'] ?? 'Password reset email sent.';
        final resetToken = result['resetToken'];
        
        // Show the message from the API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // If we have a reset token (development mode), navigate to reset password screen
        if (resetToken != null) {
          context.go(AppRoutes.resetPassword, extra: resetToken);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('If an account exists with this email, a password reset link has been sent.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 20),

                // Logo
                Image.asset(
                  'assets/images/logo.PNG',
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.85, 0.85), duration: 500.ms, curve: Curves.easeOut),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'FORGOT PASSWORD',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 12),

                const Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 40),

                // Form card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (value) => setState(() => _emailError = null),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // Send Reset Link button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (_isLoading || !_isFormValid) ? null : _sendResetEmail,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 360.ms, duration: 400.ms),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(30),
            border: errorText != null
                ? Border.all(color: Colors.redAccent, width: 1)
                : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
              prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
