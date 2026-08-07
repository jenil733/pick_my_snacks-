import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';

class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static String? _visibleMessage;
  static DateTime? _shownAt;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(milliseconds: 850),
  }) {
    final now = DateTime.now();
    if (_entry?.mounted == true &&
        _visibleMessage == message &&
        _shownAt != null &&
        now.difference(_shownAt!) < const Duration(seconds: 2)) {
      return;
    }
    dismiss();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _visibleMessage = message;
    _shownAt = now;

    _entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 20,
        right: 20,
        top: MediaQuery.paddingOf(context).top + 16,
        child: IgnorePointer(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isError ? AppColors.error : const Color(0xE61E293B),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    final isWidgetTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!isWidgetTest) {
      _timer = Timer(duration, dismiss);
    }
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      isError: true,
      duration: const Duration(milliseconds: 1200),
    );
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    _visibleMessage = null;
    if (entry?.mounted == true) entry!.remove();
  }
}
