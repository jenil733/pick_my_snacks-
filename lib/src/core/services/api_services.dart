import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';

class ApiService {
  factory ApiService({required LocalStorageService storage, Dio? dio}) {
    return ApiService._(storage, dio);
  }

  ApiService._(this._storage, Dio? dio) : _dio = dio ?? Dio(_baseOptions()) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.getString(LocalStorageService.authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          log('API error: ${error.message}', name: 'ApiService', error: error);
          if (error.response?.data != null) {
            log(
              'API response ${error.response?.statusCode}: '
              '${error.response?.data}',
              name: 'ApiService',
            );
          }

          if (_isNetworkError(error)) {
            _showMessage(
              title: 'No internet connection',
              message: 'Check your connection and try again.',
            );
            handler.next(error);
            return;
          }

          if (error.response?.statusCode == 401) {
            await _handleUnauthorized();
          } else {
            _showMessage(title: 'Error', message: _responseMessage(error));
          }

          handler.next(error);
        },
      ),
    );
  }

  static const authTokenKey = LocalStorageService.authTokenKey;

  final Dio _dio;
  final LocalStorageService _storage;
  String? _lastUnauthorizedToken;

  static BaseOptions _baseOptions() {
    final headers = <String, dynamic>{'Accept': Headers.jsonContentType};
    if (ApiRoutes.apiKey.isNotEmpty) {
      headers['x-api-key'] = ApiRoutes.apiKey;
    }

    return BaseOptions(
      baseUrl: ApiRoutes.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> post(String endpoint, {dynamic data}) {
    return _handleResponse(
      () => _dio.post<dynamic>(
        endpoint,
        data: data,
        options: Options(
          contentType: data is FormData
              ? 'multipart/form-data'
              : Headers.jsonContentType,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? params,
  }) {
    return _handleResponse(
      () => _dio.get<dynamic>(endpoint, queryParameters: params),
    );
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
    bool useFormData = false,
  }) {
    final requestData = useFormData && data is Map
        ? FormData.fromMap(Map<String, dynamic>.from(data))
        : data;

    return _handleResponse(
      () => _dio.put<dynamic>(
        endpoint,
        data: requestData,
        options: Options(
          contentType: useFormData
              ? 'multipart/form-data'
              : Headers.jsonContentType,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? data,
  }) {
    return _handleResponse(() => _dio.delete<dynamic>(endpoint, data: data));
  }

  Future<Map<String, dynamic>> _handleResponse(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final responseData = response.data;

      if (responseData is Map) {
        return Map<String, dynamic>.from(responseData);
      }
      return <String, dynamic>{'data': responseData};
    } on DioException catch (error, stackTrace) {
      log(
        'Request failed: ${error.message}',
        name: 'ApiService',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      log(
        'Unexpected API error',
        name: 'ApiService',
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception('Unexpected error occurred.');
    }
  }

  bool _isNetworkError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.unknown => error.response == null,
      _ => false,
    };
  }

  String _responseMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        final messages = errors.values
            .expand(
              (value) => value is List
                  ? value.map((item) => item.toString())
                  : <String>[value.toString()],
            )
            .where((message) => message.trim().isNotEmpty)
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _handleUnauthorized() async {
    final token = _storage.getString(LocalStorageService.authTokenKey) ?? '';
    if (_lastUnauthorizedToken == token) return;
    _lastUnauthorizedToken = token;

    await Future.wait([
      _storage.remove(LocalStorageService.authTokenKey),
      _storage.remove(LocalStorageService.selectedStaffIdKey),
    ]);
    _showMessage(title: 'Session expired', message: 'Please log in again.');
    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _showMessage({required String title, required String message}) {
    final context = Get.context;
    if (context == null) return;
    AppToast.error(context, message);
  }
}
