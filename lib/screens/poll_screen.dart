import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'home_screen.dart';
import 'stix_result.dart';
import '../widgets/success_fail_pop_up.dart';
import '../config.dart';

class PollingScreen extends StatefulWidget {
  const PollingScreen({super.key});

  @override
  State<PollingScreen> createState() => _PollingScreenState();
}

class _PollingScreenState extends State<PollingScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _collectionController = TextEditingController();
  final _pathController = TextEditingController(
    text: 'http://172.16.11.159:9000/services/poll',
  );

  bool _isLoading = false;

  void _showCustomDialog(String title, String content, {bool isError = false}) {
    showDialog(
      context: context,
      builder:
          (_) => SuccessFailPopUp(
            title: title,
            message: content,
            isError: isError,
          ),
    );
  }

  void _pollSTIX() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final collection = _collectionController.text.trim();
    final path = _pathController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        collection.isEmpty ||
        path.isEmpty) {
      _showCustomDialog("Error", "All fields are required.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authUrl = Uri.parse(AppConfig.pollAuthenticateUrl);
      final authResponse = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'collection': collection,
          'path': path,
        }),
      );

      if (authResponse.statusCode != 200) {
        try {
          final errorBody = jsonDecode(authResponse.body);
          _showCustomDialog(
            "Error",
            errorBody['error'] ?? 'Authentication failed.',
            isError: true,
          );
        } catch (_) {
          _showCustomDialog(
            "Error",
            'Authentication failed with unknown error.',
            isError: true,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final listUrl = Uri.parse(AppConfig.listStixUrl);
      final listResponse = await http.post(
        listUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'collection': collection,
          'username': username,
          'password': password,
        }),
      );

      if (listResponse.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(listResponse.body);
        final List<Map<String, dynamic>> parsedList =
            decoded.cast<Map<String, dynamic>>();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StixResult(
                  stixItems: parsedList,
                  collectionName: collection,
                  username: username,
                  password: password,
                ),
          ),
        );
      } else {
        final errorBody = jsonDecode(listResponse.body);
        _showCustomDialog(
          "Error",
          errorBody['error'] ?? 'Failed to load STIX.',
          isError: true,
        );
      }
    } catch (e) {
      _showCustomDialog("Error", "Unexpected error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteCollection() async {
    final collection = _collectionController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (collection.isEmpty || username.isEmpty || password.isEmpty) {
      _showCustomDialog(
        "Error",
        "Collection Name, Username, and Password are required to delete.",
        isError: true,
      );
      return;
    }

    try {
      final url = Uri.parse(AppConfig.deleteCollectionUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'collection': collection,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        _showCustomDialog(
          "Success",
          "Collection deleted successfully.",
          isError: false,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        _showCustomDialog(
          "Error",
          errorBody['error'] ?? 'Failed to delete collection.',
          isError: true,
        );
      }
    } catch (e) {
      _showCustomDialog("Error", "Unexpected Error: $e", isError: true);
    }
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
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
        title: const SelectableText('Poll STIX from Server'),
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
                _buildInput('Username *', _usernameController),
                const SizedBox(height: 20),
                _buildInput('Password *', _passwordController, obscure: true),
                const SizedBox(height: 20),
                _buildInput('Collection Name *', _collectionController),
                const SizedBox(height: 20),
                _buildInput('Custom Path (optional) *', _pathController),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: _pollSTIX,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Poll STIX',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _deleteCollection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete Collection',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
