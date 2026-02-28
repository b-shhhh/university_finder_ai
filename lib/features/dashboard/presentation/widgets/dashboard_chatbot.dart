import 'package:flutter/material.dart';
import 'package:Uniguide/app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';

/// Chatbot UI that calls backend `/api/chatbot`.
void showDashboardChatbot(
  BuildContext context,
  List<Map<String, dynamic>> universities, // kept for potential future use
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
          child: _ChatbotPanel(scrollController: controller),
        ),
      ),
    ),
  );
}

class _ChatbotPanel extends StatefulWidget {
  const _ChatbotPanel({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<_ChatbotPanel> {
  final _inputCtrl = TextEditingController();
  final List<_Message> _messages = const [
    _Message(
      sender: Sender.bot,
      text:
          'Try: “Universities in Canada that accept IELTS 6.5” or “MBA in Germany with SAT optional”.',
    ),
  ];
  bool _loading = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(_Message(sender: Sender.user, text: text));
      _loading = true;
    });
    _inputCtrl.clear();
    await _respond(text);
    setState(() => _loading = false);
    await Future.delayed(const Duration(milliseconds: 50));
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _respond(String query) async {
    try {
      final res = await ApiClient.I.post('/chatbot', data: {'message': query});
      final data = res.data;
      final reply =
          data is Map ? (data['reply'] ?? data['message'] ?? data.toString()) : data.toString();
      _messages.add(_Message(sender: Sender.bot, text: reply));
    } catch (_) {
      _messages.add(const _Message(
        sender: Sender.bot,
        text: 'Oops! Something went wrong reaching the assistant.',
      ));
    }
    setState(() {});
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
              color: AppColors.primary,
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
                    color: isUser ? AppColors.primary : Colors.white,
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
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _loading ? null : _send,
                  child: Text(_loading ? '…' : 'Send'),
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
