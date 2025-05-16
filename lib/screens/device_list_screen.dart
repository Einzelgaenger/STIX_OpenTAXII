import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../widgets/alert_dialog_widget.dart';
import '../widgets/snack_bar_widget.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  Map<int, bool> _hoverMap = {};
  Map<int, bool> _expandedMap = {};
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
        _showSnack("Failed to fetch device list.", isError: true);
      }
    } catch (e) {
      _showSnack("Network error: $e", isError: true);
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
      _showSnack("Device $ip has been removed.", mode: "remove");
      fetchDevices();
    } else {
      _showSnack("Failed to delete device.", isError: true);
    }
  }

  void confirmDelete(String ip) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialogWidget(
            title: "Confirm Delete",
            message: "Are you sure you want to delete $ip from the database?",
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              Navigator.pop(context);
              deleteDevice(ip);
            },
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
    _showSnack(
      body['message'] ?? body['error'] ?? 'Sync completed.',
      isError: response.statusCode != 200,
    );
    fetchDevices();
  }

  Future<void> addDevice() async {
    if (ipController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      return;
    }

    Navigator.pop(context);
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

    _showSnack(
      body['message'] ?? body['error'] ?? 'Unknown response',
      mode: "add",
      isError: response.statusCode != 200,
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
            backgroundColor: const Color(0xFF1C1F26),
            title: const Text(
              "Add New Device",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Device IP",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(onPressed: addDevice, child: const Text("Add")),
            ],
          ),
    );
  }

  void _showSnack(
    String message, {
    String mode = "default",
    bool isError = false,
  }) {
    SnackBarWidget.show(
      context,
      message: message,
      mode: isError ? "error" : mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F26),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SelectableText(
          "Device Management",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add New Device',
            onPressed: showAddDeviceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
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
                  final isHovered = _hoverMap[index] ?? false;
                  final isExpanded = _expandedMap[index] ?? false;

                  final baseColor = const Color(0xFF1C1F26);
                  final hoverColor = Colors.deepPurple.shade900.withOpacity(
                    0.2,
                  );
                  final borderColor =
                      isHovered
                          ? Colors.deepPurpleAccent.withOpacity(0.6)
                          : Colors.grey.shade800;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoverMap[index] = true),
                    onExit: (_) => setState(() => _hoverMap[index] = false),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _expandedMap[index] = !isExpanded;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isExpanded ? hoverColor : baseColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: isHovered ? 1.4 : 1.0,
                          ),
                          boxShadow: [
                            if (isHovered)
                              BoxShadow(
                                color: Colors.deepPurpleAccent.withOpacity(
                                  0.08,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.memory,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    device['device_ip'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.sync,
                                    color: Colors.blueAccent,
                                  ),
                                  tooltip: 'Sync',
                                  onPressed:
                                      () => syncDevice(device['device_ip']),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed:
                                      () => confirmDelete(device['device_ip']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Username: ${device['username']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 16),
                              for (final src in sources)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25282F),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Source: ${src['source_name']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Last Processed: ${src['last_processed'] == 0 ? 'Never' : "${DateFormat('dd-MM-yyyy • HH:mm', 'id_ID').format(DateTime.fromMillisecondsSinceEpoch(src['last_processed'] * 1000, isUtc: true).add(const Duration(hours: 7)))} WIB"}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
