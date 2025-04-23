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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isError
                    ? [Colors.red.shade400, Colors.red.shade700]
                    : [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                isError ? Icons.close : Icons.check,
                color: isError ? Colors.red : Colors.blue,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isError ? "Failed !" : "Success !",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _simplifyMessage(message, isError),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(isError ? Icons.refresh : Icons.arrow_forward),
              label: Text(isError ? "TRY AGAIN" : "CONTINUE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isError ? Colors.red : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _simplifyMessage(String rawContent, bool isError) {
    String contentToCheck = rawContent.trim();

    if (!isError) {
      debugPrint('>>> RAW RESPONSE: $rawContent');

      // 1. Coba parse JSON dulu
      try {
        final decoded = jsonDecode(rawContent);
        if (decoded is Map) {
          // Preferensi 1: message field
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

          // Preferensi 2: stderr field
          if (decoded.containsKey('stderr')) {
            final stderr = decoded['stderr'].toString().toLowerCase();
            if (stderr.contains("successfully pushed")) {
              return "Content block successfully pushed!";
            }
          }
        }
      } catch (_) {
        // Gagal decode JSON? fallback ke plain string
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

    // -------------------------
    // Error section
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
      return "Invalid Path!";
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
