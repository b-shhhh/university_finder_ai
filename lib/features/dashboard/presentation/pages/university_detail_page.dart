import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class UniversityDetailPage extends StatelessWidget {
  final Map<String, dynamic> university;
  final bool isSaved;
  final VoidCallback? onSaveToggle;

  const UniversityDetailPage({
    super.key,
    required this.university,
    this.isSaved = false,
    this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final logo = university['logo_url'];
    final name = university['name'] ?? 'Unknown University';
    final country = university['country'] ?? '';
    final city = university['city'] ?? '';
    final website = university['website_url'];
    final description = university['description'] ?? '';
    final courses = _coursesOf(university);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? Colors.red : Colors.grey,
            ),
            onPressed: onSaveToggle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // University Header
            Row(
              children: [
                logo != null && logo.toString().endsWith(".svg")
                    ? CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFE2E8F0),
                        child: SvgPicture.network(
                          logo,
                          width: 50,
                          height: 50,
                        ),
                      )
                    : CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: logo != null ? NetworkImage(logo) : null,
                        child: logo == null
                            ? const Icon(Icons.school, size: 40)
                            : null,
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$city${city.isNotEmpty && country.isNotEmpty ? ', ' : ''}$country',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Website Button
            if (website != null && website.toString().isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(website.toString()),
                  icon: const Icon(Icons.language),
                  label: const Text('Visit Website'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            if (website != null && website.toString().isNotEmpty)
              const SizedBox(height: 24),

            // Description
            if (description.isNotEmpty) ...[
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Courses
            if (courses.isNotEmpty) ...[
              const Text(
                'Courses Offered',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: courses.map((course) => Chip(
                  label: Text(course),
                  backgroundColor: const Color(0xFFF1F5F9),
                )).toList(),
              ),
            ],

            // Additional Info
            const SizedBox(height: 24),
            _buildInfoSection('Additional Information', university),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, Map<String, dynamic> data) {
    final infoFields = [
      'type',
      'founded_year',
      'student_count',
      'faculty_count',
      'address',
      'phone',
      'email',
    ];

    final infoWidgets = <Widget>[];

    for (final field in infoFields) {
      final value = data[field];
      if (value != null && value.toString().isNotEmpty) {
        final displayName = _getDisplayName(field);
        infoWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '$displayName:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (infoWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...infoWidgets,
      ],
    );
  }

  String _getDisplayName(String field) {
    switch (field) {
      case 'type':
        return 'Type';
      case 'founded_year':
        return 'Founded';
      case 'student_count':
        return 'Students';
      case 'faculty_count':
        return 'Faculty';
      case 'address':
        return 'Address';
      case 'phone':
        return 'Phone';
      case 'email':
        return 'Email';
      default:
        return field.replaceAll('_', ' ').toUpperCase();
    }
  }

  List<String> _coursesOf(Map<String, dynamic> university) {
    final courses = university['courses'];
    if (courses is List) {
      return courses.map((c) => c.toString()).toList();
    } else if (courses is String) {
      return courses.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    }
    return [];
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}