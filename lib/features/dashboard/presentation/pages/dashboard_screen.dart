import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../data/datasources/local/university_csv_loader.dart';
import '../widgets/university_detail_page.dart';
import '../widgets/country_widget.dart';
import '../widgets/course_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;
  String search = '';

  List<Map<String, dynamic>> universities = [];
  List<String> courses = [];
  List<String> countries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        ApiClient.I.get(ApiEndpoints.universities),
        ApiClient.I.get(ApiEndpoints.courses),
      ]);

      final uniRes = results[0];
      final courseRes = results[1];

      universities = _extractList(uniRes.data)
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();

      courses = _extractList(courseRes.data)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      countries = universities
          .map((u) => (u['country'] ?? '').toString().trim())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();

      if (universities.isEmpty) {
        await _loadFromCsvFallback();
      }
    } catch (e) {
      await _loadFromCsvFallback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Using offline data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadFromCsvFallback() async {
    final loader = UniversityCsvLoader.instance;
    await loader.load();
    universities = loader.universities.map((e) => Map<String, dynamic>.from(e)).toList();
    courses = loader.courses;
    countries = loader.countries;
  }

  List<MapEntry<String, int>> get countryCounts {
    final map = <String, int>{};
    for (final uni in universities) {
      final country = (uni['country'] ?? '').toString().trim();
      if (country.isEmpty) continue;
      map[country] = (map[country] ?? 0) + 1;
    }
    return map.entries
        .where((e) => e.key.toLowerCase().contains(search.toLowerCase()))
        .sorted((a, b) => b.value.compareTo(a.value) != 0
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key));
  }

  List<MapEntry<String, int>> get courseCounts {
    final map = <String, int>{};
    for (final uni in universities) {
      for (final c in (uni['courses'] as List?) ?? []) {
        final name = c.toString().trim();
        if (name.isEmpty) continue;
        map[name] = (map[name] ?? 0) + 1;
      }
    }
    return map.entries
        .where((e) => e.key.toLowerCase().contains(search.toLowerCase()))
        .sorted((a, b) => b.value.compareTo(a.value) != 0
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key));
  }

  List<Map<String, dynamic>> get filteredUniversities {
    final term = search.toLowerCase();
    return universities.where((u) {
      final haystack =
          '${u['name'] ?? ''} ${u['country'] ?? ''} ${u['state'] ?? ''} ${u['city'] ?? ''} ${(u['courses'] ?? []).join(' ')}'
              .toLowerCase();
      return haystack.contains(term);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat(label: 'Universities', value: universities.length),
      _Stat(label: 'Countries', value: countries.toSet().length),
      _Stat(label: 'Courses', value: courses.toSet().length),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            final chatbot = _ChatbotPanel(universities: universities);

            final scroll = RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search universities, countries, courses...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onChanged: (v) => setState(() => search = v),
                          ),
                          const SizedBox(height: 12),
                          _HeroSection(stats: stats),
                          const SizedBox(height: 16),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else ...[
                            _HorizontalSection(
                              title: 'Countries',
                              subtitle: '${countryCounts.length} total',
                              itemHeight: 156,
                              children: countryCounts
                                  .map(
                                    (c) => CountryCard(
                                      name: c.key,
                                      universityCount: c.value,
                                      flagUrl: _flagForCountry(universities, c.key),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                            _HorizontalSection(
                              title: 'Courses',
                              subtitle: '${courseCounts.length} total',
                              itemHeight: 140,
                              children: courseCounts
                                  .map((c) => CourseCard(name: c.key, universityCount: c.value))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            _UniversitiesGrid(universities: filteredUniversities.take(6).toList()),
                            const SizedBox(height: 16),
                            if (!isWide) chatbot,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (!isWide) return scroll;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: scroll),
                SizedBox(
                  width: 360,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                    child: SingleChildScrollView(child: chatbot),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Robustly pull a list out of various API response shapes.
List _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    for (final key in ['data', 'results', 'items', 'universities', 'courses', 'countries']) {
      final value = data[key];
      if (value is List) return value;
    }
    for (final value in data.values) {
      if (value is List) return value;
      if (value is Map) {
        for (final inner in value.values) {
          if (inner is List) return inner;
        }
      }
    }
  }
  return const [];
}

String? _flagForCountry(List<Map<String, dynamic>> universities, String country) {
  final match = universities.firstWhereOrNull(
    (u) => (u['country'] ?? '').toString().trim().toLowerCase() == country.toLowerCase(),
  );
  if (match == null) return null;

  final explicitFlag = match['flag_url'] ?? match['flagUrl'] ?? match['flag'];
  if (explicitFlag != null && explicitFlag.toString().isNotEmpty) {
    return explicitFlag.toString();
  }

  final alpha2 = match['alpha2'] ?? match['alpha_2'] ?? match['iso2'];
  if (alpha2 == null || alpha2.toString().isEmpty) return null;
  return 'https://flagcdn.com/${alpha2.toString().toLowerCase()}.svg';
}

String? _logoFor(Map<String, dynamic> uni) {
  for (final key in ['logo_url', 'logoUrl', 'logo', 'image', 'logoURL']) {
    final value = uni[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return null;
}

class _Stat {
  final String label;
  final int value;
  _Stat({required this.label, required this.value});
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9AD8), Color(0xFF0C7FB9), Color(0xFF0A5C8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search universities with clarity.',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Top Countries. Top 50 Universities. One Smart Choice',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: stats
                .map(
                  (s) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          Text(
                            s.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${s.value}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.itemHeight,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: itemHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(width: 220, child: children[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversitiesGrid extends StatelessWidget {
  const _UniversitiesGrid({required this.universities});

  final List<Map<String, dynamic>> universities;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Ranked Universities',
            style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Text(
            'Showing ${universities.length} of ${universities.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: universities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (_, i) {
              final u = universities[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UniversityDetailPage(university: u)),
                ),
                child: _SimpleCard(
                  leading: _logoFor(u) != null
                      ? CircleAvatar(backgroundImage: NetworkImage(_logoFor(u)!))
                      : const CircleAvatar(child: Icon(Icons.school)),
                  title: u['name']?.toString() ?? '',
                  subtitle: u['country']?.toString() ?? '',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatbotPanel extends StatefulWidget {
  const _ChatbotPanel({required this.universities});
  final List<Map<String, dynamic>> universities;

  @override
  State<_ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<_ChatbotPanel> {
  final _messages = <_ChatMessage>[
    _ChatMessage(text: 'Hi! Ask about universities, countries, or courses.', fromUser: false)
  ];
  final _ctrl = TextEditingController();
  bool _typing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _ctrl.clear();
      _typing = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      final reply = _buildReply(text);
      setState(() {
        _messages.add(_ChatMessage(text: reply, fromUser: false));
        _typing = false;
      });
    });
  }

  String _buildReply(String prompt) {
    final term = prompt.toLowerCase();
    final hits = widget.universities.where((u) {
      final hay = '${u['name']} ${u['country']} ${(u['courses'] ?? []).join(' ')}'.toLowerCase();
      return hay.contains(term);
    }).take(3).toList();
    if (hits.isEmpty) return "I couldn't find matches yet. Try a country, course, or university name.";
    final lines = hits
        .map((u) =>
            '- ${u['name']} - ${u['country']}${(u['courses'] as List?)?.isNotEmpty == true ? ' | top course ${(
                u['courses'] as List).first}' : ''}')
        .join('\n');
    return 'Here are a few options:\n$lines';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chatbot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: ListView.builder(
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (_typing && i == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('... ', style: TextStyle(color: Colors.grey)),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m.fromUser ? const Color(0xFF0F9AD8) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: m.fromUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Ask about a course, country, or university...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _send),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool fromUser;
  _ChatMessage({required this.text, required this.fromUser});
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.title, required this.subtitle, this.leading});

  final String title;
  final String subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          if (leading != null) leading!,
          if (leading != null) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
