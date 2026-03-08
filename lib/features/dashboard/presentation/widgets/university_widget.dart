import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// A compact card to display a university in lists/grids.
class UniversityCard extends StatelessWidget {
  final Map<String, dynamic> university;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;
  final bool isOnline;

  const UniversityCard({
    super.key,
    required this.university,
    this.onTap,
    this.onSave,
    this.isSaved = false,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = university['name']?.toString().trim() ?? '';
    final country = university['country']?.toString().trim() ?? '';
    final logo = university['logo_url'];
    final website = _websiteOf(university);

    // 🚫 Do not render invalid universities
    if (name.isEmpty ||
        name.toLowerCase() == country.toLowerCase()) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildAvatar(logo),
              const SizedBox(width: 12),

              /// University name + country
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      country,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              /// Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (website != null && website.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.language,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () => _launchUrl(website),
                      tooltip: 'Visit website',
                    ),
                  IconButton(
                    icon: Icon(
                      isSaved
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                    ),
                    color: isSaved ? Colors.red : Colors.grey,
                    onPressed: onSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds university logo avatar
  Widget _buildAvatar(Object? logo) {
    if (!isOnline) {
      return _initialsAvatar();
    }

    if (logo != null && logo.toString().trim().isNotEmpty) {
      final url = logo.toString();
      final pngUrl = _asPng(url);

      // SVG logo
      if (url.toLowerCase().endsWith('.svg')) {
        return CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE2E8F0),
          child: pngUrl != null
              ? Image.network(
                  pngUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 20),
                )
              : SvgPicture.network(
                  url,
                  width: 28,
                  height: 28,
                  placeholderBuilder: (context) =>
                      const CircularProgressIndicator(strokeWidth: 2),
                ),
        );
      }

      // Normal image logo
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFE2E8F0),
        child: ClipOval(
          child: Image.network(
            url,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.school, size: 20),
            ),
          ),
        ),
      );
    }

    // Fallback icon
    return _initialsAvatar();
  }

  String? _asPng(String url) {
    // Convert common SVG endpoints to PNG fallback (helps offline/cache)
    if (url.toLowerCase().endsWith('.svg')) {
      final filename = url.split('/').last.split('.').first;
      // attempt flagcdn-style png as a generic fallback
      return 'https://flagcdn.com/w80/${filename.toLowerCase()}.png';
    }
    return null;
  }

  Widget _initialsAvatar() {
    final name = (university['name'] ?? '').toString().trim();
    final initials = name.isNotEmpty
        ? name
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join()
        : 'U';
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE2E8F0),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
  }

  /// Opens website externally
  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(_normalizeWebsite(url));

    if (uri == null) return;

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // silently ignore
    }
  }

  String? _websiteOf(Map<String, dynamic> uni) {
    final raw = uni['website_url'] ??
        uni['website'] ??
        uni['websiteUrl'] ??
        uni['web_pages'] ??
        uni['webPages'];

    if (raw is List && raw.isNotEmpty) return _normalizeWebsite(raw.first.toString());
    if (raw is String) return _normalizeWebsite(raw);
    return null;
  }

  String _normalizeWebsite(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
    return hasScheme ? trimmed : 'https://$trimmed';
  }
}
