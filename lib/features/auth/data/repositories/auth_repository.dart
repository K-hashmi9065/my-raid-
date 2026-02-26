import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String username, String password);
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final LocalStorage _localStorage;

  AuthRepositoryImpl(this._dio, this._localStorage);

  @override
  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'expiresInMins': 60,
        },
      );

      final user = UserModel.fromJson(response.data);
      await _localStorage.saveToken(user.token);
      await _localStorage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  @override
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // DummyJSON doesn't have a real register endpoint, so we simulate it
      // by logging in with a valid test user and creating a mock registration
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': 'emilys', // demo user from dummyjson
          'password': 'emilyspass',
          'expiresInMins': 60,
        },
      );

      // Override with registration data for demo purposes
      final rawUser = Map<String, dynamic>.from(response.data);
      rawUser['id'] = 999; // Mock a new user ID so they start with 0 tasks
      rawUser['firstName'] = firstName;
      rawUser['lastName'] = lastName;
      rawUser['username'] = username;
      rawUser['email'] = email;

      final user = UserModel.fromJson(rawUser);
      await _localStorage.saveToken(user.token);
      await _localStorage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    await _localStorage.clearAll();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userData = await _localStorage.getUserData();
    if (userData == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userData));
    } catch (_) {
      return null;
    }
  }

  Never _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      // In web development, a connection error often indicates a CORS issue
      // rather than an actual loss of internet.
      throw const NetworkFailure(
        message: 'Connection failed. Please check internet or CORS settings.',
      );
    }
    final message = e.response?.data?['message'] ?? e.message ?? 'Server error';
    throw ServerFailure(message: message, statusCode: e.response?.statusCode);
  }
}
