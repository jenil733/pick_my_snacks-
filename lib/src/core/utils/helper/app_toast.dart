import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';

class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      messageText: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
        size: 20,
      ),
      backgroundColor: isError ? AppColors.error : const Color(0xE61E293B),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 12,
      duration: duration,
      animationDuration: const Duration(milliseconds: 400),
      boxShadows: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      isError: true,
      duration: const Duration(milliseconds: 2000),
    );
  }

  static void dismiss() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }
}
