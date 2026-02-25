import 'dart:async';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../data/datasources/local/university_csv_loader.dart';
import 'package:Uniguide/common/navigation_bar.dart';
import '../widgets/country_widget.dart';
import '../widgets/course_widget.dart';
import '../widgets/university_widget.dart';
import '../widgets/dashboard_chatbot.dart';
import 'university_detail_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;
  String search = '';
  int _navIndex = 0;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime? _lastShake;
  static const int _shakeCooldownMs = 1500;
  static const double _shakeThreshold = 15; // m/s^2 magnitude

  List<Map<String, dynamic>> universities = [];
  List<String> courses = [];
  List<String> countries = [];
  Set<String> savedIds = {};
  Map<String, Set<String>> courseCountries = {};
  Map<String, Set<String>> countryCourses = {};

  @override
  void initState() {
    super.initState();
    _load();
    _accelSub = accelerometerEvents.listen(_checkShake);
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        ApiClient.I.get(ApiEndpoints.universities),
        ApiClient.I.get(ApiEndpoints.courses),
        ApiClient.I.get(ApiEndpoints.savedUniversities),
      ]);

      final uniRes = results[0];
      final courseRes = results[1];
      final savedRes = results[2];

      // Load and normalize universities from API, then deduplicate on frontend
      final rawUnis = _extractList(uniRes.data).whereType<Map>().map(
        (e) => _normalizeUniversity(e.map((k, v) => MapEntry(k.toString(), v))),
      );

      // Deduplicate using id when available, otherwise fall back to name|country
      final Map<String, Map<String, dynamic>> unique = {};
      for (final u in rawUnis) {
        final id = (u['id'] ?? u['sourceId'] ?? u['_id'])?.toString();
        final name = (u['name'] ?? '').toString().trim().toLowerCase();
        final country = (u['country'] ?? '').toString().trim().toLowerCase();
        final key = id != null && id.isNotEmpty ? 'id:$id' : 'nc:$name|$country';
        if (key.startsWith('nc:') && (name.isEmpty || country.isEmpty)) {
          // prefer to keep entries with both name and country; still accept if no id
          unique.putIfAbsent(key, () => u);
        } else {
          unique.putIfAbsent(key, () => u);
        }
      }

      universities = unique.values.toList();

      final apiCourses = _extractList(courseRes.data)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty);
      final inferredCourses = universities.expand(_coursesOf).map((e) => e.trim());

      courses = {...apiCourses, ...inferredCourses}.where((e) => e.isNotEmpty).toList()..sort();

      countries = universities
          .map((u) => (u['country'] ?? '').toString().trim())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      try {
        final ids = _extractList(savedRes.data);
        savedIds = ids.map((e) => e.toString()).toSet();
      } catch (_) {
        // Saved universities failed to load, continue without them
      }

      if (universities.isEmpty) {
        await _loadFromCsvFallback();
      } else {
        _recomputeMappings();
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
    universities = loader.universities
        .map((e) => _normalizeUniversity(Map<String, dynamic>.from(e)))
        .toList();
    courses = loader.courses;
    countries = loader.countries;
    _recomputeMappings();
  }

  Map<String, dynamic> _normalizeUniversity(Map<String, dynamic> uni) {
    final copy = Map<String, dynamic>.from(uni);
    copy['courses'] = _coursesOf(uni);
    copy['country'] ??= uni['countryName'];
    copy['id'] ??= uni['_id'] ?? uni['sourceId'] ?? uni['source_id'];
    return copy;
  }

  List<String> _coursesOf(Map<String, dynamic> uni) {
    final raw = uni['courses'];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String) {
      return UniversityCsvLoader.splitCourses(raw);
    }
    return const [];
  }

  void _recomputeMappings() {
    final courseToCountries = <String, Set<String>>{};
    final countryToCourses = <String, Set<String>>{};

    for (final uni in universities) {
      final country = (uni['country'] ?? '').toString().trim();
      if (country.isEmpty) continue;

      for (final course in _coursesOf(uni)) {
        // Course to countries mapping
        final countrySet = courseToCountries.putIfAbsent(course, () => <String>{});
        countrySet.add(country);

        // Country to courses mapping
        final courseSet = countryToCourses.putIfAbsent(country, () => <String>{});
        courseSet.add(course);
      }
    }

    courseCountries = courseToCountries;
    countryCourses = countryToCourses;
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
            : a.key.compareTo(b.key))
        .toList();
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
            : a.key.compareTo(b.key))
        .toList();
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

  Future<void> _toggleSave(Map<String, dynamic> university) async {
    final id = university['id']?.toString();
    if (id == null) return;

    final isCurrentlySaved = savedIds.contains(id);
    try {
      if (isCurrentlySaved) {
        // Remove from saved
        await ApiClient.I.delete('${ApiEndpoints.savedUniversities}/$id');
        setState(() => savedIds.remove(id));
      } else {
        // Add to saved
        await ApiClient.I.post(ApiEndpoints.savedUniversities, data: {'university_id': id});
        setState(() => savedIds.add(id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${isCurrentlySaved ? 'unsave' : 'save'} university: $e')),
        );
      }
    }
  }

  void _showUniversitiesForCountry(String country) {
    final countryUniversities = universities
        .where((u) => (u['country'] ?? '').toString().trim() == country)
        .toList();

    if (countryUniversities.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Universities in $country',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('${countryUniversities.length} universities found'),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: countryUniversities.length,
                    itemBuilder: (context, index) {
                      final uni = countryUniversities[index];
                      return ListTile(
                        leading: const Icon(Icons.school),
                        title: Text(uni['name'] ?? 'Unknown University'),
                        subtitle: Text(uni['city'] ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UniversityDetailPage(
                                university: uni,
                                isSaved: savedIds.contains(uni['id']?.toString()),
                                onSaveToggle: () => _toggleSave(uni),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatbot-fab',
        elevation: 8,
        backgroundColor: Colors.transparent,
        onPressed: _openChatbotSheet,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x334F46E5),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: MyNavigationBar(
        currentIndex: _navIndex,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;

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
                                      onTap: () => _showUniversitiesForCountry(c.key),
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
                                  .map((c) => CourseCard(
                                        name: c.key,
                                        universityCount: c.value,
                                        countries: courseCountries[c.key]?.toList() ?? [],
                                        onCountryTap: (country) {
                                          // Show universities for this course and country
                                          final filteredUnis = universities.where((u) {
                                            final uniCountry = (u['country'] ?? '').toString().trim();
                                            final uniCourses = _coursesOf(u);
                                            return uniCountry == country && uniCourses.contains(c.key);
                                          }).toList();

                                          if (filteredUnis.isNotEmpty) {
                                            showModalBottomSheet(
                                              context: context,
                                              shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                              ),
                                              isScrollControlled: true,
                                              builder: (_) => DraggableScrollableSheet(
                                                expand: false,
                                                initialChildSize: 0.7,
                                                minChildSize: 0.5,
                                                maxChildSize: 0.9,
                                                builder: (_, controller) => SafeArea(
                                                  child: Padding(
                                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '${c.key} in $country',
                                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text('${filteredUnis.length} universities found'),
                                                        const SizedBox(height: 16),
                                                        Expanded(
                                                          child: ListView.builder(
                                                            controller: controller,
                                                            itemCount: filteredUnis.length,
                                                            itemBuilder: (context, index) {
                                                              final uni = filteredUnis[index];
                                                              return ListTile(
                                                                leading: const Icon(Icons.school),
                                                                title: Text(uni['name'] ?? 'Unknown University'),
                                                                subtitle: Text(uni['city'] ?? ''),
                                                                trailing: const Icon(Icons.chevron_right),
                                                                onTap: () {
                                                                  Navigator.pop(context);
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (_) => UniversityDetailPage(
                                                                        university: uni,
                                                                        isSaved: savedIds.contains(uni['id']?.toString()),
                                                                        onSaveToggle: () => _toggleSave(uni),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            _UniversitiesGrid(
                              universities: filteredUniversities.take(6).toList(),
                              onUniversityTap: (university) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UniversityDetailPage(
                                    university: university,
                                    isSaved: savedIds.contains(university['id']?.toString()),
                                    onSaveToggle: () => _toggleSave(university),
                                  ),
                                ),
                              ),
                              savedIds: savedIds,
                              onSave: _toggleSave,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            return scroll;
          },
        ),
      ),
    );
  }

  void _openChatbotSheet() {
    showDashboardChatbot(context, universities);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _checkShake(AccelerometerEvent e) {
    final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    final now = DateTime.now();
    if (magnitude > _shakeThreshold &&
        (_lastShake == null ||
            now.difference(_lastShake!).inMilliseconds > _shakeCooldownMs)) {
      _lastShake = now;
      _triggerShakeRefresh();
    }
  }

  void _triggerShakeRefresh() {
    if (loading) return;
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shake detected — refreshing universities...')),
    );
  }
}

/// Robustly pull a list out of various API response shapes.
List _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['data'] is List) return data['data'];
  if (data is Map && data['universities'] is List) return data['universities'];
  if (data is Map && data['courses'] is List) return data['courses'];
  return const [];
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to UniGuide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover universities worldwide',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(children: stats),
        ],
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.subtitle,
    required this.itemHeight,
    required this.children,
  });

  final String title;
  final String subtitle;
  final double itemHeight;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: itemHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 200,
              child: children[i],
            ),
          ),
        ),
      ],
    );
  }
}

class _UniversitiesGrid extends StatelessWidget {
  const _UniversitiesGrid({
    required this.universities,
    required this.onUniversityTap,
    required this.savedIds,
    required this.onSave,
  });

  final List<Map<String, dynamic>> universities;
  final void Function(Map<String, dynamic>) onUniversityTap;
  final Set<String> savedIds;
  final void Function(Map<String, dynamic>) onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Universities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: universities.length,
          itemBuilder: (_, i) => UniversityCard(
            university: universities[i],
            onTap: () => onUniversityTap(universities[i]),
            onSave: () => onSave(universities[i]),
            isSaved: savedIds.contains(universities[i]['id']?.toString()),
          ),
        ),
      ],
    );
  }
}


String? _flagForCountry(List<Map<String, dynamic>> universities, String country) {
  for (final u in universities) {
    if ((u['country'] ?? '').toString().trim() == country) {
      final flag = u['flag_url'] ?? u['flagUrl'];
      if (flag != null && flag.toString().isNotEmpty) return flag.toString();
    }
  }
  return null;
}
