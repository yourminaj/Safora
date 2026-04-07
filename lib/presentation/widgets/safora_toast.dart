import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

enum ToastType { success, error, info }

/// Custom branded Toast component overriding the default Material SnackBar.
class SaforaToast {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, ToastType.error);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, ToastType.info);
  }

  static void _showToast(BuildContext context, String message, ToastType type) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Clear any existing toasts to prevent stacking delays
    messenger.hideCurrentSnackBar();

    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        backgroundColor = AppColors.success;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case ToastType.error:
        backgroundColor = AppColors.error;
        iconData = Icons.error_outline_rounded;
        break;
      case ToastType.info:
        backgroundColor = AppColors.info;
        iconData = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}
