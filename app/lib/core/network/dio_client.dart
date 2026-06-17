import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class DioClient {
  final Dio dio;

  DioClient({
    required String baseUrl,
    required AuthInterceptor authInterceptor,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            contentType: Headers.jsonContentType,
          ),
        ) {
    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
    ));
  }
}
