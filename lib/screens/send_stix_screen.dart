import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'advanced_option.dart';
import 'home_screen.dart';

class SendStixScreen extends StatefulWidget {
  const SendStixScreen({super.key});

  @override
  State<SendStixScreen> createState() => _SendStixScreenState();
}

class _SendStixScreenState extends State<SendStixScreen> {
  final _stixController = TextEditingController();
  final _urlController = TextEditingController(
    text: 'http://172.16.11.159:9000/services/inbox',
  );
  final _collectionController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  void _showCustomDialog(
    String title,
    String rawContent, {
    bool isError = false,
  }) {
    String message = _simplifyMessage(rawContent, isError);

    showDialog(
      context: context,
      builder: (context) {
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
              boxShadow: [
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
                  message,
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
      },
    );
  }

  String _simplifyMessage(String rawContent, bool isError) {
    if (!isError) return "STIX message sent successfully!";

    if (rawContent.contains("Unauthorized access")) {
      return "Unauthorized access!";
    } else if (rawContent.contains("NOT_FOUND") ||
        rawContent.contains("Collection collectio") ||
        rawContent.contains("collection not found")) {
      return "Collection not found!";
    } else if (rawContent.contains("ERROR")) {
      return "Server error occurred!";
    }

    return "An unexpected error occurred!";
  }

  void _sendStix() async {
    final stix = _stixController.text.trim();
    final url = _urlController.text.trim();
    final collection = _collectionController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (stix.isEmpty)
      return _showCustomDialog(
        "Error",
        "STIX Message is required.",
        isError: true,
      );
    if (url.isEmpty)
      return _showCustomDialog(
        "Error",
        "Target URL is required.",
        isError: true,
      );
    if (collection.isEmpty)
      return _showCustomDialog(
        "Error",
        "Collection Name is required.",
        isError: true,
      );
    if (username.isEmpty)
      return _showCustomDialog("Error", "Username is required.", isError: true);
    if (password.isEmpty)
      return _showCustomDialog("Error", "Password is required.", isError: true);

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://172.16.11.159:8000/push'),
        headers: {
          'Content-Type': 'application/xml',
          'X-Username': username,
          'X-Password': password,
          'X-Collection': collection,
          'X-Path': url,
        },
        body: stix,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      final bodyLower = response.body.toLowerCase();
      final isError = response.statusCode != 200 || bodyLower.contains('error');

      _showCustomDialog(
        isError ? "Error" : "Success",
        response.body,
        isError: isError,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showCustomDialog("Error", "Error: $e", isError: true);
    }
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Send STIX Message'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Back to Home',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInput(
                  'STIX Message (raw XML) *',
                  _stixController,
                  maxLines: 8,
                ),
                const SizedBox(height: 12),
                _buildInput('Target URL *', _urlController),
                const SizedBox(height: 12),
                _buildInput('Collection Name *', _collectionController),
                const SizedBox(height: 12),
                _buildInput('Username *', _usernameController),
                const SizedBox(height: 12),
                _buildInput('Password *', _passwordController, obscure: true),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdvancedOption(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Advanced Option'),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _sendStix,
                      child: const Text('Send', style: TextStyle(fontSize: 16)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
