import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> loginWithGoogle(String googleToken) async {
    final response = await _dio.post('/auth/google', data: {
      'google_token': googleToken,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }
}
