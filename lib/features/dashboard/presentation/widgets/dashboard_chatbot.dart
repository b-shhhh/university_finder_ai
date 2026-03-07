import 'package:flutter/material.dart';
import 'package:Uniguide/app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../pages/university_detail_page.dart';

/// Chatbot UI that calls backend `/api/chatbot`.
void showDashboardChatbot(
  BuildContext context,
  List<Map<String, dynamic>> universities, // kept for potential future use
  {bool isOnline = true}
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
            scrollController: controller,
            universities: universities,
            isOnline: isOnline,
          ),
        ),
      ),
    ),
  );
}

class _ChatbotPanel extends StatefulWidget {
  const _ChatbotPanel({
    required this.scrollController,
    required this.universities,
    required this.isOnline,
  });

  final ScrollController scrollController;
  final List<Map<String, dynamic>> universities;
  final bool isOnline;

  @override
  State<_ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<_ChatbotPanel> {
  final _inputCtrl = TextEditingController();
  final List<_Message> _messages = <_Message>[];
  bool _loading = false;
  static const _apiTimeout = Duration(seconds: 4);
  bool get _online => widget.isOnline;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Seed with a friendly example message.
    _messages.add(const _Message(
      sender: Sender.bot,
      text:
          'Try: "Universities in Canada that accept IELTS 6.5" or "MBA in Germany with SAT optional".',
    ));
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
    await _scrollToBottom();
  }

  Future<void> _respond(String query) async {
    if (!_online) {
      _answerOffline(query);
      return;
    }
    try {
      final res = await ApiClient.I
          .post('/chatbot', data: {'message': query})
          .timeout(_apiTimeout);
      final data = res.data;
      final reply =
          data is Map ? (data['reply'] ?? data['message'] ?? data.toString()) : data.toString();
      final universities = data is Map && data['universities'] is List
          ? List<Map<String, dynamic>>.from(data['universities'].whereType<Map>())
          : <Map<String, dynamic>>[];

      _messages.add(_Message(
        sender: Sender.bot,
        text: reply,
        universities: universities,
      ));
    } catch (_) {
      // Graceful offline-style fallback on any failure
      _answerOffline(query);
    }
    setState(() {});
    await _scrollToBottom();
  }

  void _answerOffline(String query) {
    final term = query.toLowerCase();
    final matches = widget.universities.where((u) {
      final haystack =
          '${u['name'] ?? ''} ${u['country'] ?? ''} ${(u['courses'] ?? []).join(' ')}'.toString().toLowerCase();
      return haystack.contains(term);
    }).take(6).toList();

    final intro = matches.isEmpty
        ? 'Offline mode: I could not find a match in cached data.'
        : 'Offline mode: here are matches from cached data.';

    _messages.add(_Message(
      sender: Sender.bot,
      text: intro,
      universities: matches,
    ));
    setState(() {});
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!widget.scrollController.hasClients) return;
    await widget.scrollController.animateTo(
      widget.scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openUniversity(Map<String, dynamic> uni) async {
    Map<String, dynamic> detail = uni;
    final id = (uni['id'] ?? uni['_id'] ?? uni['sourceId'])?.toString();
    if (id != null && id.isNotEmpty) {
      try {
        final res = await ApiClient.I
            .get("${ApiEndpoints.universities}/$id")
            .timeout(_apiTimeout);
        final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
        if (data is Map) {
          detail = Map<String, dynamic>.from(data);
        }
      } catch (_) {
        // fall back to provided data if detail fetch fails
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UniversityDetailPage(
          university: detail,
          isSaved: false,
          onSaveToggle: null,
        ),
      ),
    );
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
              children: [
                const Icon(Icons.school, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UniGuide Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Ask about universities, courses, IELTS/SAT',
                              style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 12),
                            ),
                          ),
                          if (!_online)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Offline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
                  child: Column(
                    crossAxisAlignment:
                        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
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
                      if (m.universities.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: m.universities
                                .map(
                                  (u) => _UniCard(
                                    university: u,
                                    onTap: () => _openUniversity(u),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
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
                      hintText: 'Ask about country, course, IELTS/SAT...',
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
                  child: Text(_loading ? '...' : 'Send'),
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
  final List<Map<String, dynamic>> universities;

  const _Message({
    required this.sender,
    required this.text,
    this.universities = const [],
  });
}

class _UniCard extends StatelessWidget {
  const _UniCard({required this.university, required this.onTap});

  final Map<String, dynamic> university;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (university['name'] ?? 'University').toString();
    final country = (university['country'] ?? '').toString();
    final degreeLevels = (university['degreeLevels'] is List)
        ? (university['degreeLevels'] as List).whereType<String>().join(', ')
        : '';
    final ielts = university['ieltsMin']?.toString() ?? 'N/A';
    final sat = university['satRequired'] == true
        ? (university['satMin']?.toString() ?? 'N/A')
        : (university['satRequired'] == false ? 'Optional' : 'N/A');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (country.isNotEmpty)
                      Text(country, style: const TextStyle(color: Colors.black54)),
                    if (degreeLevels.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('- $degreeLevels',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'IELTS $ielts | SAT $sat',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
