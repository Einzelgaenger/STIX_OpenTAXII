import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../widgets/previous_next_buttons.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isDeleting = false;
  bool _isDescending = true;
  List<Map<String, dynamic>> _currentItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  int currentPage = 1;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.stixItems.reversed); // default terbaru
    _filteredItems = List.from(_currentItems);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          _currentItems.where((item) {
            final title = item['title']?.toString().toLowerCase() ?? '';
            final hash = item['hash']?.toString().toLowerCase() ?? '';
            return title.contains(query) || hash.contains(query);
          }).toList();
      currentPage = 1;
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _isDescending = !_isDescending;
      _currentItems = _currentItems.reversed.toList();
      _applyFilter();
    });
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

    // setState(() => _isDeleting = true);
    setState(() {
      _currentItems.removeWhere((item) => item['id'] == stixId);
      _applyFilter();
    });

    final url = Uri.parse(AppConfig.deleteStixUrl);

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
          _currentItems.removeWhere((item) => item['id'] == stixId);
          _applyFilter();
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

  List<Map<String, dynamic>> _paginatedItems() {
    if (_filteredItems.isEmpty) return [];
    final maxPage =
        (_filteredItems.length / itemsPerPage)
            .ceil()
            .clamp(1, double.infinity)
            .toInt();
    currentPage = currentPage.clamp(1, maxPage);

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      _filteredItems.length,
    );
    return _filteredItems.sublist(startIndex, endIndex);
  }

  int get totalPages => (_filteredItems.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final paginated = _paginatedItems();

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
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
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          widget.collectionName,
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search by Title or Value...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey.shade900,
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SelectableText(
                              _filteredItems.isEmpty
                                  ? 'No results found'
                                  : 'Showing ${(currentPage - 1) * itemsPerPage + 1} - ${((currentPage) * itemsPerPage).clamp(1, _filteredItems.length)} of ${_filteredItems.length} result',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            DropdownButton<String>(
                              value: _isDescending ? 'Newest' : 'Oldest',
                              dropdownColor: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              style: const TextStyle(color: Colors.white),
                              underline: Container(height: 0),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Newest',
                                  child: Text('Newest First'),
                                ),
                                DropdownMenuItem(
                                  value: 'Oldest',
                                  child: Text('Oldest First'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) _toggleSortOrder();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        _filteredItems.isEmpty
                            ? const Center(
                              child: Text(
                                'No STIX matched your search.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: paginated.length,
                              itemBuilder: (context, index) {
                                final item = paginated[index];
                                final isExpanded = _expandedMap[index] ?? false;
                                final isHovered = _hoverMap[index] ?? false;
                                return _buildStixCard(
                                  item,
                                  index,
                                  isExpanded,
                                  isHovered,
                                );
                              },
                            ),
                  ),
                  if (_filteredItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: PreviousNextButton(
                        onPrevious: () => setState(() => currentPage--),
                        onNext: () => setState(() => currentPage++),
                        isFirstPage: currentPage == 1,
                        isLastPage: currentPage == totalPages,
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildStixCard(
    Map<String, dynamic> item,
    int index,
    bool isExpanded,
    bool isHovered,
  ) {
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              if (isExpanded) ...[
                const Divider(height: 24, color: Colors.white24),
                _buildExpandedContent(item, index),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Map<String, dynamic> item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item['raw'] ?? ''));
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
                    final now = DateTime.now().millisecondsSinceEpoch;
                    final blob = Blob([
                      item['raw'] ?? '<empty />',
                    ], 'application/xml');
                    final url = Url.createObjectUrlFromBlob(blob);
                    AnchorElement(href: url)
                      ..setAttribute('download', 'stix_$now.xml')
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
                  onPressed: () {
                    final index = _filteredItems.indexWhere(
                      (i) => i['id'] == item['id'],
                    );
                    if (index != -1) {
                      _deleteStix(item['id'], index);
                    } else {
                      _showSnackbar(
                        'Item not found in current filtered list.',
                        error: true,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade900.withOpacity(0.2),
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
    );
  }
}
