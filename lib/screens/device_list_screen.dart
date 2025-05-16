import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:intl/intl.dart'; // pastikan sudah import
// import 'package:intl/date_symbol_data_local.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<Map<String, dynamic>> devices = [];
  bool isLoading = false;

  final TextEditingController ipController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    try {
      final uri = Uri.parse(AppConfig.getDevicesUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body.containsKey('devices')) {
          List<Map<String, dynamic>> deviceList = [];

          for (var device in body['devices']) {
            final detail = await fetchDeviceDetail(device['device_ip']);
            if (detail != null) {
              deviceList.add(detail);
            }
          }

          setState(() => devices = deviceList);
        } else {
          setState(() => devices = []);
        }
      } else {
        _showDialog("Error", "Failed to fetch device list.");
      }
    } catch (e) {
      _showDialog("Error", "Network error: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchDeviceDetail(String ip) async {
    try {
      final uri = Uri.parse(AppConfig.deviceDetailUrl);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_ip': ip}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteDevice(String ip) async {
    final uri = Uri.parse(AppConfig.deleteDeviceUrl);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_ip': ip}),
    );

    if (response.statusCode == 200) {
      _showDialog("Deleted", "Device $ip has been removed.");
      fetchDevices();
    } else {
      _showDialog("Error", "Failed to delete device.");
    }
  }

  void confirmDelete(String ip) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: Text(
              "Are you sure you want to delete $ip from the database?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteDevice(ip);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  Future<void> syncDevice(String ip) async {
    setState(() => isLoading = true);
    final uri = Uri.parse(AppConfig.syncSourcesUrl);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    setState(() => isLoading = false);

    final body = jsonDecode(response.body);
    _showDialog(
      response.statusCode == 200 ? "Success" : "Error",
      body['message'] ?? body['error'] ?? 'Sync completed.',
    );
    fetchDevices();
  }

  Future<void> addDevice() async {
    if (ipController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      return;
    }

    Navigator.pop(context); // Close dialog
    setState(() => isLoading = true);

    final uri = Uri.parse(AppConfig.addDeviceUrl);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_ip': ipController.text.trim(),
        'username': usernameController.text.trim(),
        'password': passwordController.text,
      }),
    );

    setState(() => isLoading = false);
    final body = jsonDecode(response.body);

    _showDialog(
      response.statusCode == 200 ? "Device Added" : "Error",
      body['message'] ?? body['error'] ?? 'Unknown response',
    );
    fetchDevices();
  }

  void showAddDeviceDialog() {
    ipController.clear();
    usernameController.clear();
    passwordController.clear();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Add New Device"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(labelText: "Device IP"),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(onPressed: addDevice, child: const Text("Add")),
            ],
          ),
    );
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
      appBar: AppBar(
        title: const Text("Device Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddDeviceDialog,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : devices.isEmpty
              ? const Center(
                child: Text(
                  "No devices yet.\nClick '+' to add one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: devices.length,
                itemBuilder: (_, index) {
                  final device = devices[index];
                  final sources = device['sources'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ExpansionTile(
                      title: Text(device['device_ip']),
                      subtitle: Text("Username: ${device['username']}"),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.sync,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () => syncDevice(device['device_ip']),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => confirmDelete(device['device_ip']),
                          ),
                        ],
                      ),
                      children:
                          sources.map<Widget>((src) {
                            final ts = src['last_processed'];
                            final tsStr =
                                ts == 0
                                    ? 'Never'
                                    : "${DateFormat('dd-MM-yyyy • HH:mm', 'id_ID').format(DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true).add(const Duration(hours: 7)))} WIB";

                            return StatefulBuilder(
                              builder: (context, setLocalState) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  child: Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Source: ${src['source_name']}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text("Last Processed: $tsStr"),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
    );
  }
}
