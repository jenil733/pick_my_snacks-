import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';

class FcmTokenService {
  FcmTokenService(this._apiService, {FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final ApiService _apiService;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> syncToken() async {
    try {
      debugPrint('[FCM] Requesting Firebase messaging token...');
      final token = await _messaging.getToken();
      debugPrint('[FCM] Current token: ${token ?? 'empty'}');

      if (token == null || token.trim().isEmpty) {
        debugPrint('[FCM] Token is empty, skipping server sync.');
        return;
      }

      await _sendToken(token);
    } catch (error, stackTrace) {
      debugPrint('[FCM] Unable to sync token: $error');
      debugPrint('[FCM] Stack trace: $stackTrace');
    }
  }

  void listenForTokenRefresh() {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      (token) {
        debugPrint('[FCM] Token refreshed: $token');
        unawaited(_sendToken(token));
      },
      onError: (Object error) {
        debugPrint('[FCM] Token refresh listener error: $error');
      },
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _sendToken(String token) async {
    debugPrint('[FCM] Sending token to ${ApiRoutes.fcmToken}: $token');
    final response = await _apiService.post(
      ApiRoutes.fcmToken,
      data: FormData.fromMap({'fcm_token': token}),
    );
    debugPrint('[FCM] Token API response: $response');
  }
}
