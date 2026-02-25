import 'package:flutter/material.dart';

/// Shows the chatbot bottom sheet with the given universities list.
void showDashboardChatbot(BuildContext context, List<Map<String, dynamic>> universities) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _ChatbotPanel(universities: universities),
        ),
      ),
    ),
  );
}

class _ChatbotPanel extends StatefulWidget {
  const _ChatbotPanel({required this.universities});

  final List<Map<String, dynamic>> universities;

  @override
  State<_ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<_ChatbotPanel> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<String> _results = [];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final q = _inputCtrl.text.trim();
    if (q.isEmpty) return;
    final list = _searchUniversities(q);
    setState(() => _results = list);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _searchUniversities(String query) {
    final q = query.toLowerCase();
    final list = widget.universities.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final country = (u['country'] ?? '').toString().toLowerCase();
      final courses = (u['courses'] ?? []).toString().toLowerCase();
      return name.contains(q) || country.contains(q) || courses.contains(q);
    }).take(10);

    int i = 1;
    return list.map((u) {
      final name = u['name'] ?? 'Unknown';
      final country = u['country'] ?? '';
      final degrees =
          (u['degree_level'] ?? u['degreeLevel'] ?? "Bachelor's, Master's, PhD").toString();
      final ielts = u['ielts_min'] ?? u['ielts'] ?? '–';
      final sat = u['sat_min'] ?? u['sat'] ?? '–';
      return '${i++}. $name — $country ($degrees) · IELTS $ielts · SAT $sat';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: const [
                Icon(Icons.school, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UniGuide Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ask about universities, courses, IELTS/SAT',
                        style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _inputCtrl,
                  decoration: InputDecoration(
                    hintText: 'law',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                if (_results.isEmpty)
                  const Text(
                    'Try: "Universities in Canada that accept IELTS 6.5" or "MBA in Germany with SAT optional".',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollCtrl,
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        shrinkWrap: true,
                        itemCount: _results.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _results[i],
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Footer input + send
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask about country, course, IELTS/SAT...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _search,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
