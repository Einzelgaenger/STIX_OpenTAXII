import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';

class AdvancedOption extends StatefulWidget {
  const AdvancedOption({super.key});

  @override
  State<AdvancedOption> createState() => _AdvancedOptionState();
}

class _AdvancedOptionState extends State<AdvancedOption> {
  final _titleController = TextEditingController();
  final _indicatorController = TextEditingController();
  final _typeController = TextEditingController(text: 'ipv4-addr');
  final _descriptionController = TextEditingController();
  final _collectionController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController(
    text: 'http://172.16.11.159:9000/services/inbox',
  );

  String? _previewXml;
  bool _isLoading = false;

  final List<String> _observableTypes = [
    'ipv4-addr',
    'ipv6-addr',
    'domain-name',
    'url',
    'sha256',
  ];

  void _showDialog(String title, String rawContent, {bool isError = false}) {
    String message = _simplifyMessage(rawContent, isError);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320, // ✅ Fixed size supaya gak terlalu besar
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
    if (!isError) {
      // Kalau sukses, singkatin saja
      return "Content block successfully pushed!";
    }

    // Untuk error, cari tahu berdasarkan isi rawContent
    if (rawContent.contains("Unauthorized access")) {
      return "Unauthorized access!";
    } else if (rawContent.contains("NOT_FOUND") ||
        rawContent.contains("Collection collectio") ||
        rawContent.contains("collection not found")) {
      return "Collection not found!";
    } else if (rawContent.contains("ERROR")) {
      return "Server error occurred!";
    }

    // Kalau tidak bisa dikenali errornya, fallback generic
    return "An unexpected error occurred!";
  }

  String _generateStixXml() {
    final title = _titleController.text.trim();
    final value = _indicatorController.text.trim();
    final type = _typeController.text.trim();
    final description = _descriptionController.text.trim();

    String observableXml;

    if (type == 'ipv4-addr' || type == 'ipv6-addr') {
      observableXml = '''
<cybox:Object>
  <cybox:Properties xsi:type="AddressObject:AddressObjectType" category="$type">
    <AddressObject:Address_Value>$value</AddressObject:Address_Value>
  </cybox:Properties>
</cybox:Object>''';
    } else if (type == 'domain-name') {
      observableXml = '''
<cybox:Object>
  <cybox:Properties xsi:type="DomainNameObject:DomainNameObjectType" type="FQDN">
    <DomainNameObject:Value condition="Equals">$value</DomainNameObject:Value>
  </cybox:Properties>
</cybox:Object>''';
    } else if (type == 'url') {
      observableXml = '''
<cybox:Object>
  <cybox:Properties xsi:type="URIObject:URIObjectType" type="URL">
    <URIObject:Value>$value</URIObject:Value>
  </cybox:Properties>
</cybox:Object>''';
    } else if (type == 'sha256') {
      observableXml = '''
<cybox:Object>
  <cybox:Properties xsi:type="FileObj:FileObjectType">
    <FileObj:Hashes>
      <cyboxCommon:Hash>
        <cyboxCommon:Type>SHA256</cyboxCommon:Type>
        <cyboxCommon:Simple_Hash_Value>$value</cyboxCommon:Simple_Hash_Value>
      </cyboxCommon:Hash>
    </FileObj:Hashes>
  </cybox:Properties>
</cybox:Object>''';
    } else {
      observableXml = '<!-- Unsupported type -->';
    }

    return '''
<stix:STIX_Package xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xmlns:stix="http://stix.mitre.org/stix-1"
                   xmlns:indicator="http://stix.mitre.org/Indicator-2"
                   xmlns:cybox="http://cybox.mitre.org/cybox-2"
                   xmlns:AddressObject="http://cybox.mitre.org/objects#AddressObject-2"
                   xmlns:URIObject="http://cybox.mitre.org/objects#URIObject-2"
                   xmlns:DomainNameObject="http://cybox.mitre.org/objects#DomainNameObject-1"
                   xmlns:stixVocabs="http://stix.mitre.org/default_vocabularies-1"
                   xmlns:compnet="http://compnet.id"
                   xmlns:cyboxCommon="http://cybox.mitre.org/common-2"
                   xmlns:FileObj="http://cybox.mitre.org/objects#FileObject-2"
                   id="compnet:package-${DateTime.now().millisecondsSinceEpoch}"
                   version="1.2">
  <stix:Indicators>
    <stix:Indicator id="compnet:indicator-${DateTime.now().millisecondsSinceEpoch}" timestamp="${DateTime.now().toIso8601String()}Z" xsi:type="indicator:IndicatorType">
      <indicator:Title>$title</indicator:Title>
      ${description.isNotEmpty ? '<indicator:Description>$description</indicator:Description>' : ''}
      <indicator:Type>$type</indicator:Type>
      <indicator:Observable>
        $observableXml
      </indicator:Observable>
    </stix:Indicator>
  </stix:Indicators>
</stix:STIX_Package>
''';
  }

  Future<void> _sendStix() async {
    final stix = _generateStixXml();
    final collection = _collectionController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final url = _urlController.text.trim();

    if (collection.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        url.isEmpty) {
      _showDialog(
        'Error',
        'All required fields must be filled.',
        isError: true,
      );
      return;
    }

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

    final stderr = response.body;
    final isError = stderr.contains("ERROR") || response.statusCode != 200;

    _showDialog(isError ? "Error" : "Success", stderr, isError: isError);
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
        title: const Text("Advanced STIX Push"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildInput('Title *', _titleController),
            const SizedBox(height: 12),
            _buildInput('Indicator Value *', _indicatorController),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _typeController.text,
              dropdownColor: Colors.grey.shade900,
              decoration: InputDecoration(
                labelText: 'Observable Type',
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              items:
                  _observableTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) _typeController.text = val;
              },
            ),
            const SizedBox(height: 12),
            _buildInput(
              'Description (optional)',
              _descriptionController,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildInput('Collection Name *', _collectionController),
            const SizedBox(height: 12),
            _buildInput('Username *', _usernameController),
            const SizedBox(height: 12),
            _buildInput('Password *', _passwordController, obscure: true),
            const SizedBox(height: 12),
            _buildInput('Target URL *', _urlController),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final preview = _generateStixXml();
                      setState(() => _previewXml = preview);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Preview STIX'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendStix,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Send STIX'),
                  ),
                ),
              ],
            ),
            if (_previewXml != null) ...[
              const SizedBox(height: 24),
              const Text(
                'STIX Preview (XML)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _previewXml!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
