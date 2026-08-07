import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/firebase_options.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/services/fcm_token_service.dart';
import 'package:pick_my_snacks/src/core/services/local_notification_sevices.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';
import 'package:pick_my_snacks/src/di/service_locator.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.showRemoteMessage(message, dataOnly: true);
  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (error) {
    debugPrint('Firebase is unavailable; notifications are disabled: $error');
  }

  try {
    await LocalNotificationService.initialize();
  } catch (error) {
    debugPrint('Unable to initialize local notifications: $error');
  }

  final initialRoute = await setupServiceLocator();
  try {
    final fcmTokenService = locate<FcmTokenService>();
    fcmTokenService.listenForTokenRefresh();
    if (initialRoute == AppRoutes.homescreen) {
      unawaited(fcmTokenService.syncToken());
    }
  } catch (error) {
    debugPrint('Unable to start FCM token sync: $error');
  }
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = AppRoutes.login});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'pick my snacks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      initialRoute: initialRoute,
      getPages: AppRoutes.pages,
    );
  }
}
