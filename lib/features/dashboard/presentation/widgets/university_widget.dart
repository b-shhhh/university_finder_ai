import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UniversityCard extends StatelessWidget {
  final Map<String, dynamic> university;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;

  const UniversityCard({
    super.key,
    required this.university,
    this.onTap,
    this.onSave,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = university['logo_url'];

    return GestureDetector(
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
            logo != null && logo.toString().endsWith(".svg")
                ? CircleAvatar(
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: SvgPicture.network(
                      logo,
                      width: 30,
                      height: 30,
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage:
                        logo != null ? NetworkImage(logo) : null,
                    child: logo == null
                        ? const Icon(Icons.school)
                        : null,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    university['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    university['country'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : Colors.grey,
              ),
              onPressed: onSave,
            )
          ],
        ),
      ),
    );
  }
}