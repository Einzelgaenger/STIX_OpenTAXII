import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'stix_result.dart';

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

  void _pollSTIX() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final collection = _collectionController.text.trim();
    final path = _pathController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        collection.isEmpty ||
        path.isEmpty) {
      _showErrorSnackbar("All fields are required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Authentication Check
      final authUrl = Uri.parse(
        'http://172.16.11.159:8000/poll_stix_authenticate',
      );
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
        // Autentikasi gagal
        try {
          final errorBody = jsonDecode(authResponse.body);
          _showErrorSnackbar(errorBody['error'] ?? 'Authentication failed.');
        } catch (_) {
          _showErrorSnackbar('Authentication failed with unknown error.');
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Step 2: Fetch STIX list
      final listUrl = Uri.parse('http://172.16.11.159:8000/list_stix');
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
        try {
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
        } catch (e) {
          _showErrorSnackbar('Failed to parse server response.');
        }
      } else {
        try {
          final errorBody = jsonDecode(listResponse.body);
          _showErrorSnackbar(errorBody['error'] ?? 'Failed to load STIX.');
        } catch (_) {
          _showErrorSnackbar('Failed to load STIX: Unknown server error.');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Unexpected Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteCollection() async {
    final collection = _collectionController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (collection.isEmpty || username.isEmpty || password.isEmpty) {
      _showErrorSnackbar(
        "Collection Name, Username, and Password are required to delete.",
      );
      return;
    }

    try {
      final url = Uri.parse('http://172.16.11.159:8000/delete_collection');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          _showErrorSnackbar(
            errorBody['error'] ?? 'Failed to delete collection.',
          );
        } catch (_) {
          _showErrorSnackbar(
            'Failed to delete collection: Unknown server error.',
          );
        }
      }
    } catch (e) {
      _showErrorSnackbar("Unexpected Error: $e");
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
        title: const Text('Poll STIX from Server'),
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
                const SizedBox(height: 12),
                _buildInput('Password *', _passwordController, obscure: true),
                const SizedBox(height: 12),
                _buildInput('Collection Name *', _collectionController),
                const SizedBox(height: 12),
                _buildInput('Custom Path (optional) *', _pathController),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: _pollSTIX,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
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
