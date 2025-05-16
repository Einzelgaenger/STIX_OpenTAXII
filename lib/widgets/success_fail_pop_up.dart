import 'dart:convert';
import 'package:flutter/material.dart';

class SuccessFailPopUp extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;

  const SuccessFailPopUp({
    super.key,
    required this.title,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor =
        isError ? const Color(0xFFE53935) : Colors.blueAccent;
    final Color textColor = baseColor;

    final Size screenSize = MediaQuery.of(context).size;
    final double iconSize =
        screenSize.width * 0.18 > 90 ? 90 : screenSize.width * 0.18;

    final IconData iconData =
        isError ? Icons.close_rounded : Icons.check_rounded;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2431),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circle Icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [baseColor.withOpacity(0.2), Colors.transparent],
                    radius: 0.9,
                    stops: const [0.3, 1.0],
                  ),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: baseColor,
                    size: iconSize * 0.55,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isError ? "Error!" : "Success!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),

              // Message
              Text(
                _simplifyMessage(message, isError),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, color: Colors.white70),
              ),
              const SizedBox(height: 16),

              // Underline
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 1.5,
                width: 120,
                color: textColor.withOpacity(0.4),
              ),
              const SizedBox(height: 20),

              // Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isError ? "Try again" : "Continue",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _simplifyMessage(String rawContent, bool isError) {
    String contentToCheck = rawContent.trim();

    if (!isError) {
      try {
        final decoded = jsonDecode(rawContent);
        if (decoded is Map) {
          if (decoded.containsKey('message')) {
            final msg = decoded['message'].toString().toLowerCase();
            if (msg.contains("deleted") && msg.contains("collection")) {
              return "Collection deleted successfully!";
            }
            if (msg.contains("successfully pushed")) {
              return "Content block successfully pushed!";
            }
            return decoded['message'];
          }
          if (decoded.containsKey('stderr')) {
            final stderr = decoded['stderr'].toString().toLowerCase();
            if (stderr.contains("successfully pushed")) {
              return "Content block successfully pushed!";
            }
          }
        }
      } catch (_) {
        final msg = contentToCheck.toLowerCase();
        if (msg.contains("deleted") && msg.contains("collection")) {
          return "Collection deleted successfully!";
        }
        if (msg.contains("successfully pushed")) {
          return "Content block successfully pushed!";
        }
      }
      return "Success!";
    }

    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is Map && decoded.containsKey('error')) {
        contentToCheck = decoded['error'];
      } else if (decoded is Map && decoded.containsKey('message')) {
        contentToCheck = decoded['message'];
      }
    } catch (_) {}

    contentToCheck = contentToCheck.toLowerCase();

    if (contentToCheck.contains("unauthorized")) {
      return "Unauthorized access!";
    }
    if (contentToCheck.contains("invalid path")) {
      return "Invalid path!";
    }
    if (contentToCheck.contains("not_found") ||
        contentToCheck.contains("collection collectio") ||
        contentToCheck.contains("collection not found")) {
      return "Collection not found!";
    }
    if (contentToCheck.contains("error")) {
      return "Server error occurred!";
    }

    return "An unexpected error occurred!";
  }
}
