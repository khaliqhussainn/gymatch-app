import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _resetToken;

  String? _passwordError;
  String? _confirmPasswordError;

  bool get _isFormValid {
    return _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty &&
           _passwordError == null &&
           _confirmPasswordError == null;
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to update UI when text changes
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      // Clear errors when user types
      _passwordError = null;
      _confirmPasswordError = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the reset token from route extra or query parameter
    final state = GoRouterState.of(context);
    _resetToken = state.extra as String? ?? state.uri.queryParameters['token'];
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      hasError = true;
    } else if (confirmPassword != password) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    if (_resetToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid reset token. Please request a new password reset.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_resetToken!, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful. Please login with your new password.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  'RESET PASSWORD',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 12),

                const Text(
                  'Enter your new password below.',
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
                      // Password field
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'New Password',
                        prefixIcon: Icons.vpn_key_outlined,
                        obscureText: _obscurePassword,
                        errorText: _passwordError,
                        onChanged: (value) => setState(() => _passwordError = null),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                      const SizedBox(height: 12),

                      // Confirm Password field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm New Password',
                        prefixIcon: Icons.vpn_key_outlined,
                        obscureText: _obscureConfirmPassword,
                        errorText: _confirmPasswordError,
                        onChanged: (value) => setState(() => _confirmPasswordError = null),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword,
                          ),
                        ),
                      ).animate().fadeIn(delay: 360.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // Reset Password button
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
                          onPressed: (_isLoading || !_isFormValid) ? null : _resetPassword,
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
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 420.ms, duration: 400.ms),
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
    bool obscureText = false,
    Widget? suffixIcon,
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
            obscureText: obscureText,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
              prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
              suffixIcon: suffixIcon,
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
