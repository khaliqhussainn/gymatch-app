import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import '../../routes/app_router.dart';

class GymRegistrationScreen extends StatefulWidget {
  const GymRegistrationScreen({super.key});

  @override
  State<GymRegistrationScreen> createState() => _GymRegistrationScreenState();
}

class _GymRegistrationScreenState extends State<GymRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _locationUrlController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  
  String _selectedCategory = 'GYM';
  final List<String> _categories = [
    'GYM', 'CrossFit', 'MMA', 'Yoga', 'Strength Training',
    'Bodybuilding', 'Powerlifting', 'Cardio Training', 'HIIT',
    'Functional Fitness', 'Boxing', 'Kickboxing', 'Pilates'
  ];
  
  bool _isLoading = false;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _gymNameError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // Add listeners to update UI when text changes
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _gymNameController.addListener(_validateForm);
    _locationUrlController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      // Clear errors when user types
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _gymNameError = null;
      _locationError = null;
    });
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
           _emailController.text.trim().isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty &&
           _gymNameController.text.trim().isNotEmpty &&
           _locationUrlController.text.trim().isNotEmpty &&
           _nameError == null &&
           _emailError == null &&
           _passwordError == null &&
           _confirmPasswordError == null &&
           _gymNameError == null &&
           _locationError == null &&
           _termsAccepted;
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _confirmPasswordController.removeListener(_validateForm);
    _gymNameController.removeListener(_validateForm);
    _locationUrlController.removeListener(_validateForm);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _gymNameController.dispose();
    _locationUrlController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }


  Future<void> _register() async {
    if (!_termsAccepted) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final gymName = _gymNameController.text.trim();
    final location = _locationUrlController.text.trim();

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _gymNameError = null;
      _locationError = null;
    });

    bool hasError = false;
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      hasError = true;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email');
      hasError = true;
    }

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

    if (gymName.isEmpty) {
      setState(() => _gymNameError = 'Gym name is required');
      hasError = true;
    }

    if (location.isEmpty) {
      setState(() => _locationError = 'Location URL is required');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    await authProvider.registerGymOwner(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      gymName: _gymNameController.text.trim(),
      locationName: 'Gym Location',
      location: _locationUrlController.text.trim(),
      category: _selectedCategory,
      contactPhone: _contactPhoneController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Back button — top left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Logo
                  Image.asset(
                    'assets/images/logo.PNG',
                    width: 62,
                    height: 62,
                    fit: BoxFit.contain,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.85, 0.85), duration: 500.ms, curve: Curves.easeOut),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'REGISTER YOUR GYM',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      height: 1.05,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                  
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
                        // Owner Information Section
                        const Text(
                          'Owner Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _nameController,
                          hint: 'Owner Name',
                          prefixIcon: Icons.person_outline_rounded,
                          errorText: _nameError,
                          onChanged: (value) => setState(() => _nameError = null),
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                        
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: (value) => setState(() => _emailError = null),
                        ).animate().fadeIn(delay: 310.ms, duration: 400.ms),
                        
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password',
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
                        ).animate().fadeIn(delay: 370.ms, duration: 400.ms),
                        
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: 'Confirm Password',
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
                        ).animate().fadeIn(delay: 430.ms, duration: 400.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Gym Information Section
                        const Text(
                          'Gym Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 480.ms, duration: 400.ms),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _gymNameController,
                          hint: 'Gym Name',
                          prefixIcon: Icons.business,
                          errorText: _gymNameError,
                          onChanged: (value) => setState(() => _gymNameError = null),
                        ).animate().fadeIn(delay: 530.ms, duration: 400.ms),
                        
                        const SizedBox(height: 12),
                        
                        
                        _buildDropdown(
                          hint: 'Category',
                          prefixIcon: Icons.category,
                          value: _selectedCategory,
                          items: _categories,
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ).animate().fadeIn(delay: 630.ms, duration: 400.ms),
                        
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _locationUrlController,
                          hint: 'Google Maps URL',
                          prefixIcon: Icons.location_on,
                          keyboardType: TextInputType.url,
                          errorText: _locationError,
                          onChanged: (value) => setState(() => _locationError = null),
                        ).animate().fadeIn(delay: 680.ms, duration: 400.ms),
                        
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _contactPhoneController,
                          hint: 'Contact Phone',
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ).animate().fadeIn(delay: 730.ms, duration: 400.ms),
                        
                        const SizedBox(height: 24),
                  
                        // Terms and Conditions checkbox
                        GestureDetector(
                          onTap: () =>
                              setState(() => _termsAccepted = !_termsAccepted),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _termsAccepted
                                        ? AppColors.primary
                                        : Colors.white38,
                                    width: 1.5,
                                  ),
                                  color: _termsAccepted
                                      ? AppColors.primary.withOpacity(0.15)
                                      : Colors.transparent,
                                ),
                                child: _termsAccepted
                                    ? Icon(
                                        Icons.check,
                                        size: 13,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Text(
                                      'I Agree to ',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Terms and Conditions',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 880.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              elevation: 0,
                            ),
                            onPressed:
                                (_isLoading || !_isFormValid) ? null : _register,
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
                                    'Register Gym',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ).animate().fadeIn(delay: 920.ms, duration: 400.ms),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 28),

                  // Already have an account? Sign In
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 960.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
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
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
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


  Widget _buildDropdown({
    required String hint,
    required IconData prefixIcon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
          prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white38),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

}

