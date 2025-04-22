import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';
import 'home_screen.dart';

class StixResult extends StatefulWidget {
  final List<Map<String, dynamic>> stixItems;

  const StixResult({super.key, required this.stixItems});

  @override
  State<StixResult> createState() => _StixResultState();
}

class _StixResultState extends State<StixResult> {
  final Map<int, bool> _expandedMap = {};
  final Map<int, bool> _hoverMap = {};

  // List<TextSpan> _highlightSTIX(String xml, String targetTitle) {
  //   final spans = <TextSpan>[];
  //   final titleRegex = RegExp(r'(<indicator:Title>)(.*?)(</indicator:Title>)');
  //   final valueRegex = RegExp(
  //     r'(<(?:AddressObject:Address_Value|DomainNameObject:Value|URIObject:Value|cyboxCommon:Simple_Hash_Value)[^>]*>)(.*?)(</[^>]+>)',
  //   );

  //   int currentIndex = 0;

  //   final allMatches = [
  //     ...titleRegex.allMatches(xml),
  //     ...valueRegex.allMatches(xml),
  //   ]..sort((a, b) => a.start.compareTo(b.start));

  //   for (final match in allMatches) {
  //     if (match.start > currentIndex) {
  //       spans.add(TextSpan(text: xml.substring(currentIndex, match.start)));
  //     }

  //     final isTarget = match.group(2)?.trim() == targetTitle;

  //     spans.add(TextSpan(text: match.group(1))); // opening tag
  //     spans.add(
  //       TextSpan(
  //         text: match.group(2),
  //         style:
  //             isTarget
  //                 ? const TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.amberAccent,
  //                 )
  //                 : const TextStyle(),
  //       ),
  //     );
  //     spans.add(TextSpan(text: match.group(3))); // closing tag

  //     currentIndex = match.end;
  //   }

  //   if (currentIndex < xml.length) {
  //     spans.add(TextSpan(text: xml.substring(currentIndex)));
  //   }

  //   return spans;
  // }
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('STIX Result'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            widget.stixItems.isEmpty
                ? const Center(
                  child: Text(
                    'No STIX data to show.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                : ListView.builder(
                  itemCount: widget.stixItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.stixItems[index];
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
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                isExpanded
                                    ? Colors.deepPurple.shade900.withOpacity(
                                      0.2,
                                    )
                                    : const Color(0xFF1C1F26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isHovered
                                      ? Colors.deepPurpleAccent.withOpacity(0.6)
                                      : Colors.grey.shade800,
                              width: isHovered ? 1.4 : 1.0,
                            ),
                            boxShadow:
                                isHovered
                                    ? [
                                      BoxShadow(
                                        color: Colors.deepPurple.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                    : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
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
                                const Divider(
                                  height: 24,
                                  color: Colors.white24,
                                ),
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
                                        TextButton.icon(
                                          onPressed: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: item['raw'] ?? '',
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Copied to clipboard!',
                                                ),
                                                backgroundColor: Colors.green,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.copy,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            "Copy",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(40, 30),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        TextButton.icon(
                                          onPressed: () async {
                                            final now =
                                                DateTime.now()
                                                    .millisecondsSinceEpoch;
                                            final fileName = 'stix_$now.xml';
                                            final content =
                                                item['raw'] ?? '<empty />';
                                            final blob = Blob([
                                              content,
                                            ], 'application/xml');
                                            final url =
                                                Url.createObjectUrlFromBlob(
                                                  blob,
                                                );
                                            AnchorElement(href: url)
                                              ..setAttribute(
                                                "download",
                                                fileName,
                                              )
                                              ..click();
                                            Url.revokeObjectUrl(url);
                                          },
                                          icon: const Icon(
                                            Icons.download,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            "Download",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(40, 30),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade900
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SelectableText.rich(
                                    TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        fontFamily: 'monospace',
                                      ),
                                      children: _highlightSTIX(
                                        item['raw'] ?? '<empty />',
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
      ),
    );
  }
}
