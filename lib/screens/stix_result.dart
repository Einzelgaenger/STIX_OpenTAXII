import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';
import 'dart:convert'; // ✅ ini yang lupa tadi
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class StixResult extends StatefulWidget {
  final List<Map<String, dynamic>> stixItems;
  final String collectionName;
  final String username;
  final String password;

  const StixResult({
    super.key,
    required this.stixItems,
    required this.collectionName,
    required this.username,
    required this.password,
  });

  @override
  State<StixResult> createState() => _StixResultState();
}

class _StixResultState extends State<StixResult> {
  final Map<int, bool> _expandedMap = {};
  final Map<int, bool> _hoverMap = {};
  bool _isDeleting = false;
  List<Map<String, dynamic>> _currentItems = [];

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.stixItems);
  }

  void _showSnackbar(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _deleteStix(int stixId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this STIX?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final url = Uri.parse('http://172.16.11.159:8000/delete_stix');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': stixId,
          'username': widget.username,
          'password': widget.password,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentItems.removeAt(index);
        });
        _showSnackbar('STIX deleted successfully.');
      } else {
        _showSnackbar('Failed to delete: ${response.body}', error: true);
      }
    } catch (e) {
      _showSnackbar('Error: $e', error: true);
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  List<TextSpan> _highlightSTIX(
    String xml,
    String highlightTitle,
    String highlightValue,
  ) {
    final spans = <TextSpan>[];
    final titleRegex = RegExp(r'(<indicator:Title>)(.*?)(</indicator:Title>)');
    final valueRegex = RegExp(
      r'(<(?:AddressObject:Address_Value|DomainNameObject:Value|URIObject:Value|cyboxCommon:Simple_Hash_Value)[^>]*>)(.*?)(</[^>]+>)',
    );
    int currentIndex = 0;
    final allMatches = [
      ...titleRegex.allMatches(xml),
      ...valueRegex.allMatches(xml),
    ]..sort((a, b) => a.start.compareTo(b.start));

    for (final match in allMatches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: xml.substring(currentIndex, match.start)));
      }
      final openingTag = match.group(1) ?? '';
      final content = match.group(2) ?? '';
      final closingTag = match.group(3) ?? '';
      final shouldHighlight =
          content.trim() == highlightTitle.trim() ||
          content.trim() == highlightValue.trim();

      spans.add(TextSpan(text: openingTag));
      spans.add(
        TextSpan(
          text: content,
          style:
              shouldHighlight
                  ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  )
                  : const TextStyle(fontWeight: FontWeight.normal),
        ),
      );
      spans.add(TextSpan(text: closingTag));
      currentIndex = match.end;
    }

    if (currentIndex < xml.length) {
      spans.add(TextSpan(text: xml.substring(currentIndex)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: Text('STIX in: ${widget.collectionName}'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
      body:
          _isDeleting
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _currentItems.isEmpty
              ? const Center(
                child: Text(
                  'No STIX data to show.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentItems.length,
                itemBuilder: (context, index) {
                  final item = _currentItems[index];
                  final isExpanded = _expandedMap[index] ?? false;
                  final isHovered = _hoverMap[index] ?? false;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoverMap[index] = true),
                    onExit: (_) => setState(() => _hoverMap[index] = false),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _expandedMap[index] = !isExpanded;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              isExpanded
                                  ? Colors.deepPurple.shade900.withOpacity(0.2)
                                  : const Color(0xFF1C1F26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isHovered
                                    ? Colors.deepPurpleAccent.withOpacity(0.6)
                                    : Colors.grey.shade800,
                            width: isHovered ? 1.4 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['hash'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            if (isExpanded) ...[
                              const Divider(height: 24, color: Colors.white24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Raw STIX',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: item['raw'] ?? '',
                                            ),
                                          );
                                          _showSnackbar('Copied to clipboard!');
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          final now =
                                              DateTime.now()
                                                  .millisecondsSinceEpoch;
                                          final blob = Blob([
                                            item['raw'] ?? '<empty />',
                                          ], 'application/xml');
                                          final url =
                                              Url.createObjectUrlFromBlob(blob);
                                          AnchorElement(href: url)
                                            ..setAttribute(
                                              'download',
                                              'stix_$now.xml',
                                            )
                                            ..click();
                                          Url.revokeObjectUrl(url);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        onPressed:
                                            () =>
                                                _deleteStix(item['id'], index),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade900.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                    children: _highlightSTIX(
                                      item['raw'] ?? '',
                                      item['title'] ?? '',
                                      item['hash'] ?? '',
                                    ),
                                  ),
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
