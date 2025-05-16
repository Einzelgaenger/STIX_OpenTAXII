import 'package:flutter/material.dart';

class SnackBarWidget {
  static void show(
    BuildContext context, {
    required String message,
    String mode = "default", // "add", "remove"
  }) {
    Color backgroundColor;
    IconData icon;

    switch (mode.toLowerCase()) {
      case "add":
        backgroundColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case "remove":
        backgroundColor = Colors.redAccent;
        icon = Icons.delete_outline;
        break;
      default:
        backgroundColor = Colors.blueAccent;
        icon = Icons.info_outline;
    }

    final snackBar = SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }
}
