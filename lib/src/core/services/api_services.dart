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
          log('${options.method} ${options.uri}', name: 'ApiRequest');
          handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            '${response.requestOptions.method} '
            '${response.requestOptions.uri} -> ${response.statusCode}',
            name: 'ApiResponse',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          log(
            '${error.requestOptions.method} ${error.requestOptions.uri} -> '
            '${error.response?.statusCode ?? 'NETWORK_ERROR'}',
            name: 'ApiResponse',
          );
          if (!_isExpectedKotRecoveryResponse(error)) {
            log(
              'API error: ${error.message}',
              name: 'ApiService',
              error: error,
            );
            if (error.response?.data != null) {
              log(
                'API response ${error.response?.statusCode}: '
                '${error.response?.data}',
                name: 'ApiService',
              );
            }
          }

          if (_isNetworkError(error)) {
            handler.next(error);
            return;
          }

          if (error.response?.statusCode == 401) {
            await _handleUnauthorized();
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
    Set<int> acceptedStatusCodes = const <int>{},
  }) {
    return _handleResponse(
      () => _dio.get<dynamic>(
        endpoint,
        queryParameters: params,
        options: acceptedStatusCodes.isEmpty
            ? null
            : Options(
                validateStatus: (status) =>
                    status != null &&
                    ((status >= 200 && status < 300) ||
                        acceptedStatusCodes.contains(status)),
              ),
      ),
    );
  }

  Future<Map<String, dynamic>> getWithData(String endpoint, {dynamic data}) {
    return _handleResponse(
      () => _dio.request<dynamic>(
        endpoint,
        data: data,
        options: Options(
          method: 'GET',
          contentType: data is FormData
              ? 'multipart/form-data'
              : Headers.jsonContentType,
        ),
      ),
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
      if (!_isExpectedKotRecoveryResponse(error)) {
        log(
          'Request failed: ${error.message}',
          name: 'ApiService',
          error: error,
          stackTrace: stackTrace,
        );
      }
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

  static bool _isExpectedKotRecoveryResponse(DioException error) {
    final requestPath = error.requestOptions.path.toLowerCase();
    if (error.response?.statusCode == 404 &&
        requestPath.contains('kot_table_status')) {
      return true;
    }
    final data = error.response?.data;
    if (data is! Map) return false;
    final message = data['message']?.toString().trim().toLowerCase() ?? '';
    if (error.response?.statusCode == 404 &&
        requestPath.contains('delete_hold_bill/') &&
        message.contains('hold bill') &&
        message.contains('not found')) {
      return true;
    }
    if (error.response?.statusCode != 422) return false;
    final details = data['data'];
    final hasHoldId = details is Map && details['hold_order_id'] != null;
    return hasHoldId &&
        message.contains('processing order') &&
        message.contains('no products');
  }

  Future<void> _handleUnauthorized() async {
    final token = _storage.getString(LocalStorageService.authTokenKey) ?? '';
    if (_lastUnauthorizedToken == token) return;
    _lastUnauthorizedToken = token;

    await Future.wait([
      _storage.remove(LocalStorageService.authTokenKey),
      _storage.remove(LocalStorageService.selectedStaffIdKey),
    ]);
    _showMessage('Please log in again.');
    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _showMessage(String message) {
    final context = Get.context;
    if (context == null) return;
    AppToast.error(context, message);
  }
}
