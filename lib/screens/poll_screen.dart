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

    if (username.isEmpty) return _showErrorSnackbar("Username is required.");
    if (password.isEmpty) return _showErrorSnackbar("Password is required.");
    if (collection.isEmpty)
      return _showErrorSnackbar("Collection Name is required.");
    if (path.isEmpty) return _showErrorSnackbar("Path is required.");

    setState(() => _isLoading = true);

    final url = Uri.parse('http://172.16.11.159:8000/poll');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'collection': collection,
        'path': path,
      }),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        final raw = decoded['stdout'] ?? '';
        final parsedList = _splitIndicatorsAsPackages(raw).reversed.toList();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StixResult(stixItems: parsedList)),
        );
      } catch (e) {
        _showErrorSnackbar("Parsing failed: $e");
      }
    } else {
      _showErrorSnackbar("Polling Error: ${response.body}");
    }
  }

  List<Map<String, dynamic>> _splitIndicatorsAsPackages(String xml) {
    final packageRegex = RegExp(
      r'(<stix:STIX_Package\b.*?>.*?<\/stix:STIX_Package>)',
      dotAll: true,
    );
    final indicatorRegex = RegExp(
      r'(<stix:Indicator\b[^>]*>.*?<\/stix:Indicator>)',
      dotAll: true,
    );
    final titleRegex = RegExp(r'<indicator:Title>(.*?)<\/indicator:Title>');
    final valueRegex = RegExp(
      r'<(AddressObject:Address_Value|DomainNameObject:Value|URIObject:Value|cyboxCommon:Simple_Hash_Value)[^>]*>(.*?)<\/\1>',
    );

    final result = <Map<String, dynamic>>[];

    final packages = packageRegex.allMatches(xml);

    for (final match in packages) {
      final packageXml = match.group(0)!;

      // Temukan semua indikator dalam paket ini
      final indicators = indicatorRegex.allMatches(packageXml);
      for (final indicatorMatch in indicators) {
        final indicatorXml = indicatorMatch.group(0)!;
        final title =
            titleRegex.firstMatch(indicatorXml)?.group(1)?.trim() ?? 'Unknown';

        final value =
            valueRegex.firstMatch(indicatorXml)?.group(2)?.trim() ?? 'No data';

        result.add({
          'title': title,
          'hash': value,
          'raw': packageXml, // hanya STIX Package ini
        });
      }
    }

    return result;
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
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   foregroundColor: Colors.white,
      //   title: const Text('Poll STIX from Server'),
      // ),
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
                      onPressed: _pollSTIX,
                      child: const Text('Poll', style: TextStyle(fontSize: 16)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
