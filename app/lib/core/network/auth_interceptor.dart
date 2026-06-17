import 'package:dio/dio.dart';
import '../security/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final String _baseUrl;
  final void Function()? _onLogoutRequired;

  AuthInterceptor({
    required SecureStorageService secureStorage,
    required String baseUrl,
    void Function()? onLogoutRequired,
  })  : _secureStorage = secureStorage,
        _baseUrl = baseUrl,
        _onLogoutRequired = onLogoutRequired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.contains('/auth/google') &&
        !options.path.contains('/auth/refresh')) {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/google') &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final responseData = response.data;
            if (responseData['success'] == true) {
              final newAccessToken = responseData['data']['access_token'] as String;
              
              await _secureStorage.saveAccessToken(newAccessToken);

              final requestOptions = err.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryDio = Dio(BaseOptions(baseUrl: _baseUrl));
              final retryResponse = await retryDio.request(
                requestOptions.path,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
                options: Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                ),
              );

              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          await _secureStorage.clearAll();
          _onLogoutRequired?.call();
        }
      } else {
        await _secureStorage.clearAll();
        _onLogoutRequired?.call();
      }
    }
    super.onError(err, handler);
  }
}
