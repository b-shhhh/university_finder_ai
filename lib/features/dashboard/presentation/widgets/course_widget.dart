import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String name;
  final int universityCount;
  final List<String> countries;
  final VoidCallback? onTap;
  final void Function(String country)? onCountryTap;

  const CourseCard({
    super.key,
    required this.name,
    required this.universityCount,
    this.countries = const [],
    this.onTap,
    this.onCountryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => _showCountries(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book, color: Color(0xFF0F9AD8)),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                "$universityCount universities",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountries(BuildContext context) {
    if (countries.isEmpty) return;
    final sortedCountries = countries.toList()..sort();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...sortedCountries.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    onCountryTap?.call(c);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}