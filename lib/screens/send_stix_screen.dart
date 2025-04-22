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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _sendStix() async {
    final stix = _stixController.text.trim();
    final url = _urlController.text.trim();
    final collection = _collectionController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (stix.isEmpty) return _showErrorSnackbar("STIX Message is required.");
    if (url.isEmpty) return _showErrorSnackbar("Target URL is required.");
    if (collection.isEmpty)
      return _showErrorSnackbar("Collection Name is required.");
    if (username.isEmpty) return _showErrorSnackbar("Username is required.");
    if (password.isEmpty) return _showErrorSnackbar("Password is required.");

    setState(() => _isLoading = true);

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

    if (response.statusCode == 200 || response.statusCode == 202) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Success"),
              content: const Text("STIX message sent successfully."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Error"),
              content: Text(
                "Failed to send STIX:\n${response.statusCode}\n${response.body}",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
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
