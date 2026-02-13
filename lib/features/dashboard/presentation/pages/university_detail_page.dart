import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UniversityDetailPage extends StatelessWidget {
  final Map university;
  const UniversityDetailPage({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    final name = university['name'] ?? '';
    final country = university['country'] ?? '';
    final description = university['description'] ?? '';
    final courses = (university['courses'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final website = university['web_pages'] ?? university['website'] ?? '';
    final logo = university['logo_url'];
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                logo != null
                    ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(logo))
                    : const CircleAvatar(radius: 28, child: Icon(Icons.school)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(country),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (description.isNotEmpty) ...[
              Text(description),
              const SizedBox(height: 16),
            ],
            if (courses.isNotEmpty) ...[
              const Text('Courses', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
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
    );
  }
}
