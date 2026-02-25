import 'package:flutter/material.dart';

/// Frontend-only chatbot: filters in-memory universities list and shows results.
void showDashboardChatbot(
  BuildContext context,
  List<Map<String, dynamic>> universities,
) {
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
          child: _ChatbotPanel(
            universities: universities,
            scrollController: controller,
          ),
        ),
      ),
    ),
  );
}

class _ChatbotPanel extends StatefulWidget {
  const _ChatbotPanel({
    required this.universities,
    required this.scrollController,
  });

  final List<Map<String, dynamic>> universities;
  final ScrollController scrollController;

  @override
  State<_ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<_ChatbotPanel> {
  final _inputCtrl = TextEditingController();
  final List<_Message> _messages = [
    const _Message(
      sender: Sender.bot,
      text:
          'Try: “Universities in Canada that accept IELTS 6.5” or “MBA in Germany with SAT optional”.',
    ),
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(_Message(sender: Sender.user, text: text)));
    _inputCtrl.clear();
    _respond(text);
  }

  void _respond(String query) {
    final results = _searchUniversities(query);
    final reply = results.isEmpty
        ? 'No matches for “$query”. Try another country or course.'
        : 'Here are some universities I found:\n${results.join('\n')}';
    setState(() => _messages.add(_Message(sender: Sender.bot, text: reply)));
    Future.delayed(const Duration(milliseconds: 50), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
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
        children: [
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
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isUser = m.sender == Sender.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: isUser
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ask about country, course, IELTS/SAT…',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _send,
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

enum Sender { user, bot }

class _Message {
  final Sender sender;
  final String text;
  const _Message({required this.sender, required this.text});
}
