import 'package:flutter/material.dart';

/// Card used to display a country with its university count.
class CountryCard extends StatelessWidget {
  const CountryCard({
    super.key,
    required this.name,
    required this.universityCount,
    this.flagUrl,
    this.onTap,
  });

  final String name;
  final int universityCount;
  final String? flagUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = flagUrl != null && flagUrl!.isNotEmpty
        ? CircleAvatar(backgroundImage: NetworkImage(flagUrl!))
        : const CircleAvatar(child: Icon(Icons.flag));

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '$universityCount universities',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: card);
    }
    return card;
  }
}
