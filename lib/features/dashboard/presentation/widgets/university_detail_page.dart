import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UniversityDetailPage extends StatefulWidget {
  final Map university;
  final bool isSaved;
  final Future<void> Function()? onToggleSave;
  const UniversityDetailPage({
    super.key,
    required this.university,
    this.isSaved = false,
    this.onToggleSave,
  });

  @override
  State<UniversityDetailPage> createState() => _UniversityDetailPageState();
}

class _UniversityDetailPageState extends State<UniversityDetailPage> {
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.university['name'] ?? '';
    final country = widget.university['country'] ?? '';
    final city = widget.university['city'] ?? '';
    final description = widget.university['description'] ?? '';
    final courses =
        (widget.university['courses'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final website = widget.university['web_pages'] ?? widget.university['website'] ?? '';
    final logo = widget.university['logo_url'];
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: Icon(_saved ? Icons.favorite : Icons.favorite_border),
            onPressed: widget.onToggleSave == null
                ? null
                : () async {
                    await widget.onToggleSave!();
                    setState(() => _saved = !_saved);
                  },
            color: _saved ? Colors.redAccent : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logoAvatar(logo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          [country, city]
                              .map((e) => e?.toString() ?? '')
                              .where((e) => e.isNotEmpty)
                              .join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (description.toString().isNotEmpty) ...[
                Text(description),
                const SizedBox(height: 16),
              ],
              if (courses.isNotEmpty) ...[
                const Text('Courses', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: courses.map((c) => Chip(label: Text(c))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (website is String && website.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(website)),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visit website'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoAvatar(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(radius: 28, child: Icon(Icons.school));
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue.shade50,
      child: ClipOval(
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Color(0xFF0B6FAB)),
        ),
      ),
    );
  }
}
