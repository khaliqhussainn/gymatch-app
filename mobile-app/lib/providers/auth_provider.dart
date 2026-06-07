import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuest = false;
  
  String? _token;
  int? _userId;
  String? _email;
  String? _role;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _token != null && !_isGuest;
  
  String? get token => _token;
  int? get userId => _userId;
  String? get email => _email;
  String? get role => _role;

  AuthProvider() {
    tryAutoLogin();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });

      final data = response.data;
      _token = data['token'];
      _userId = data['userId'];
      _role = data['role'] ?? 'user';
      _email = email.trim();
      _isGuest = false;

      if (_token != null) {
        await _apiClient.saveToken(_token!);
      }
    } on DioException catch (e) {
      if (e.error is NetworkException) {
        _errorMessage = e.error.toString();
      } else if (e.response?.statusCode == 401) {
        _errorMessage = 'Invalid email or password';
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
          _errorMessage = data['error'];
        } else {
          _errorMessage = 'Invalid request. Please check your input.';
        }
      } else {
        _errorMessage = 'An error occurred during login. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, {String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'email': email.trim(),
        'password': password,
        if (name != null) 'name': name,
      });

      final data = response.data;
      _token = data['token'];
      _userId = data['userId'];
      _role = data['role'] ?? 'user';
      _email = email.trim();
      _isGuest = false;

      if (_token != null) {
        await _apiClient.saveToken(_token!);
      }
    } on DioException catch (e) {
      if (e.error is NetworkException) {
        _errorMessage = e.error.toString();
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
          _errorMessage = data['error'];
        } else {
          _errorMessage = 'Invalid request. Please check your input.';
        }
      } else {
        _errorMessage = 'An error occurred during registration. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAsGuest() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/auth/guest-token');
      final data = response.data;
      _token = data['token'];
      _role = data['role'] ?? 'guest';
      _isGuest = true;
      _userId = null;
      _email = 'Guest User';

      if (_token != null) {
        await _apiClient.saveToken(_token!);
      }
    } on DioException catch (e) {
      if (e.error is NetworkException) {
        _errorMessage = e.error.toString();
      } else {
        _errorMessage = 'An error occurred during guest access. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> googleLogin(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/google-login', data: {
        'token': idToken,
      });

      final data = response.data;
      _token = data['token'];
      _userId = data['userId'];
      _role = data['role'] ?? 'user';
      _isGuest = false;

      if (_token != null) {
        await _apiClient.saveToken(_token!);
      }
    } on DioException catch (e) {
      if (e.error is NetworkException) {
        _errorMessage = e.error.toString();
      } else if (e.response?.statusCode == 401) {
        _errorMessage = 'Google authentication failed';
      } else {
        _errorMessage = 'An error occurred during Google login. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/forgot-password', data: {
        'email': email.trim(),
      });
      final data = response.data;
      return {
        'message': data['message'] ?? 'Password reset email sent.',
        'resetToken': data['resetToken'],
      };
    } on DioException catch (e) {
      if (e.error is NetworkException) {
        _errorMessage = e.error.toString();
      } else {
        _errorMessage = 'Failed to send password reset email. Please try again.';
      }
      return null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
      return true;
    } on DioException catch (e) {
      if (e.error is NetworkException) {
        _errorMessage = e.error.toString();
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
          _errorMessage = data['error'];
        } else {
          _errorMessage = 'Invalid or expired reset token';
        }
      } else {
        _errorMessage = 'Failed to reset password. Please try again.';
      }
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _email = null;
    _role = null;
    _isGuest = false;
    await _apiClient.deleteToken();
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    try {
      final token = await _apiClient.getToken();
      if (token == null) return false;

      // Decode JWT locally
      final parts = token.split('.');
      if (parts.length != 3) {
        await logout();
        return false;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payloadData = json.decode(payload);

      // Check expiry
      if (payloadData.containsKey('exp')) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(payloadData['exp'] * 1000);
        if (expiryTime.isBefore(DateTime.now())) {
          await logout();
          return false;
        }
      }

      _token = token;
      _role = payloadData['role'] ?? 'user';
      if (_role == 'guest') {
        _isGuest = true;
        _userId = null;
        _email = 'Guest User';
      } else {
        _isGuest = false;
        _userId = payloadData['userId'];
        // Load profile details right away on login sync
        await fetchProfile();
      }
      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Profile management state
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  /// Fetch user profile details and activity statistics.
  Future<void> fetchProfile() async {
    if (_isGuest || _token == null) return;
    
    try {
      final response = await _apiClient.dio.get('/users/profile');
      _userProfile = Map<String, dynamic>.from(response.data);
      if (_userProfile != null) {
        _email = _userProfile!['email'];
      }
      notifyListeners();
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException 
          ? e.error.toString() 
          : 'Failed to load profile details.';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
    }
  }

  /// Update user profile details.
  Future<bool> updateProfile({
    String? name,
    int? age,
    String? gender,
    String? fitnessGoals,
    String? workoutTypes,
    String? availability,
  }) async {
    if (_isGuest || _token == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.put('/users/profile', data: {
        'name': name,
        'age': age,
        'gender': gender,
        'fitnessGoals': fitnessGoals,
        'workoutTypes': workoutTypes,
        'availability': availability,
      });
      await fetchProfile();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.error is NetworkException 
          ? e.error.toString() 
          : 'Failed to update profile.';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
