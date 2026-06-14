import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();

  // Production backend URL
  static const String _productionUrl = 'https://gymatch.syedmisbahali.com/api';
  // Web Application OAuth Client ID (used as serverClientId for Google Sign-In)
  // Android client ID: 466640926142-m7c6snjamq92et7ms36a6o4pmf1srmd5.apps.googleusercontent.com
  static const String googleClientId = '466640926142-s7s1ra0sn74ov37lrrdf96cubjloqh5g.apps.googleusercontent.com';

  static String get defaultBaseUrl => _productionUrl;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        String errorMsg = 'An unexpected error occurred. Please try again.';
        int? statusCode = error.response?.statusCode;

        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Connection timeout. Please check your internet connection.';
        } else if (error.type == DioExceptionType.connectionError) {
          // On iOS, TLS/SSL failures also surface as connectionError.
          // Inspect the underlying error message to give a better hint.
          final underlying = error.error?.toString().toLowerCase() ?? '';
          if (underlying.contains('certificate') ||
              underlying.contains('ssl') ||
              underlying.contains('tls') ||
              underlying.contains('trust') ||
              underlying.contains('handshake')) {
            errorMsg = 'Secure connection failed. The server certificate could not be verified.';
          } else {
            errorMsg = 'No internet connection. Please verify your network settings.';
          }
        } else if (error.response != null) {
          final data = error.response?.data;
          if (data is Map && data.containsKey('error')) {
            errorMsg = data['error'];
          } else if (data is Map && data.containsKey('msg')) {
            errorMsg = data['msg'];
          } else if (statusCode == 401) {
            errorMsg = 'Authentication required or session expired. Please sign in again.';
          } else if (statusCode == 403) {
            errorMsg = 'You do not have permission to access this resource.';
          } else if (statusCode == 404) {
            errorMsg = 'Requested resource not found.';
          } else if (statusCode == 500) {
            errorMsg = 'Server under maintenance. Please try again later.';
          }
        }

        return handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: NetworkException(errorMsg, statusCode: statusCode),
          response: error.response,
        ));
      },
    ));
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'jwt_token');
  }
}
