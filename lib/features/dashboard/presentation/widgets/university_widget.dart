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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTabletCard = constraints.maxWidth >= 220;
            final padding = isTabletCard ? 16.0 : 12.0;
            final avatarRadius = isTabletCard ? 28.0 : 24.0;
            final iconSize = isTabletCard ? 18.0 : 16.0;
            final actionBox = isTabletCard ? 32.0 : 28.0;
            final titleSize = isTabletCard ? 15.0 : 14.0;
            final subtitleSize = isTabletCard ? 13.0 : 12.0;

            return Container(
              padding: EdgeInsets.all(padding),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(logo, radius: avatarRadius),
                      const Spacer(),
                      if (website != null && website.isNotEmpty)
                        IconButton(
                          constraints: BoxConstraints.tightFor(width: actionBox, height: actionBox),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.language,
                            color: Colors.blue,
                            size: iconSize,
                          ),
                          onPressed: () => _launchUrl(website),
                          tooltip: 'Visit website',
                        ),
                      IconButton(
                        constraints: BoxConstraints.tightFor(width: actionBox, height: actionBox),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          size: iconSize,
                        ),
                        color: isSaved ? Colors.red : Colors.grey,
                        onPressed: onSave,
                      ),
                    ],
                  ),
                  SizedBox(height: isTabletCard ? 12 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          maxLines: isTabletCard ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: titleSize,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds university logo avatar
  Widget _buildAvatar(Object? logo, {double radius = 24}) {
    final imageSize = radius * 1.65;
    final iconSize = radius * 0.85;
    if (!isOnline) {
      return _initialsAvatar(radius: radius);
    }

    if (logo != null && logo.toString().trim().isNotEmpty) {
      final url = logo.toString();
      final pngUrl = _asPng(url);

      // SVG logo
      if (url.toLowerCase().endsWith('.svg')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE2E8F0),
          child: pngUrl != null
              ? Image.network(
                  pngUrl,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.school, size: iconSize),
                )
              : SvgPicture.network(
                  url,
                  width: imageSize * 0.7,
                  height: imageSize * 0.7,
                  placeholderBuilder: (context) =>
                      const CircularProgressIndicator(strokeWidth: 2),
                ),
        );
      }

      // Normal image logo
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE2E8F0),
        child: ClipOval(
          child: Image.network(
            url,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => SizedBox(
              width: imageSize,
              height: imageSize,
              child: Icon(Icons.school, size: iconSize),
            ),
          ),
        ),
      );
    }

    // Fallback icon
    return _initialsAvatar(radius: radius);
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

  Widget _initialsAvatar({double radius = 24}) {
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
      radius: radius,
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
