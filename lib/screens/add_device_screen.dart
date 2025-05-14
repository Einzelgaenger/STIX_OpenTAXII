import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ipController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController sourceNameController = TextEditingController();

  bool isLoading = false;

  Future<void> submitDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final uri = Uri.parse('AppConfig.addDeviceUrl');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_ip': ipController.text.trim(),
        'username': usernameController.text.trim(),
        'password': passwordController.text,
        'source_name': sourceNameController.text.trim(),
      }),
    );

    setState(() => isLoading = false);

    final body = jsonDecode(response.body);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(response.statusCode == 200 ? "Success" : "Error"),
            content: Text(
              body['message'] ?? body['error'] ?? 'Unknown response',
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

  Future<void> previewSources() async {
    final deviceIp = ipController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (deviceIp.isEmpty || username.isEmpty || password.isEmpty) {
      _showDialog(
        "Error",
        "Please fill Device IP, Username, and Password first.",
      );
      return;
    }

    setState(() => isLoading = true);

    final uri = Uri.parse(AppConfig.listSourcesUrl);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_ip': deviceIp,
        'username': username,
        'password': password,
      }),
    );

    setState(() => isLoading = false);

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['sources'] != null) {
      final sources = (body['sources'] as List).cast<String>();
      _showDialog("Available Sources", sources.join("\n"));
    } else {
      _showDialog("Error", body['error'] ?? 'Unknown error');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F26),
        title: const Text("Add New Device"),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField("Device IP", ipController, validator: _notEmpty),
                _buildField(
                  "Username",
                  usernameController,
                  validator: _notEmpty,
                ),
                _buildField(
                  "Password",
                  passwordController,
                  obscure: true,
                  validator: _notEmpty,
                ),
                _buildField(
                  "Source Name",
                  sourceNameController,
                  // validator: _notEmpty,
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Leave blank to auto-detect from indicators",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: isLoading ? null : previewSources,
                  icon: const Icon(Icons.visibility, color: Colors.white70),
                  label: const Text("Preview Available Sources"),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: isLoading ? null : submitDevice,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Add Device",
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF1C1F26),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String? _notEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
