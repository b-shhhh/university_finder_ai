import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

import '../../../../common/navigation_bar.dart';
import 'bottom screen/saved_page.dart';
import 'bottom screen/profile_page.dart';
import 'university_detail_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  List<String> countries = [];
  List allUniversities = [];
  List universities = [];
  List<String> courses = [];
  String? selectedCourse;
  List stats = [];
  List recommendations = [];
  List deadlines = [];
  Set<String> savedIds = {};
  bool loading = true;
  bool showAllCountries = false;
  bool showAllCourses = false;
  bool showMoreUniversities = false;

  final TextEditingController searchController = TextEditingController();

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= API =================

  Future<void> loadData() async {
    try {
      final c = await ApiClient.I.get(ApiEndpoints.universities + "/countries");
      final u = await ApiClient.I.get(ApiEndpoints.universities);
      final coursesRes = await ApiClient.I.get(ApiEndpoints.universityCourses);
      final recRes = await ApiClient.I.get(ApiEndpoints.recommendations);

      // saved universities (if authenticated)
      try {
        final savedRes = await ApiClient.I.get(ApiEndpoints.savedUniversities);
        final data = savedRes.data is Map ? (savedRes.data['data'] ?? []) : (savedRes.data ?? []);
        savedIds = Set<String>.from(data.map((e) => e.toString()));
      } catch (_) {}

      setState(() {
        final countriesPayload = c.data is Map ? c.data['data'] : c.data;
        countries = List<String>.from(countriesPayload as List);
        allUniversities = u.data is Map ? (u.data['data'] ?? []) : (u.data ?? []);
        universities = List.from(allUniversities);
        courses = List<String>.from(
            (coursesRes.data is Map ? coursesRes.data['data'] : coursesRes.data) as List);
        final recPayload = recRes.data is Map ? (recRes.data['data'] ?? recRes.data) : {};
        stats = (recPayload['stats'] ?? []) as List;
        recommendations = (recPayload['recommendations'] ?? []) as List;
        deadlines = (recPayload['deadlines'] ?? []) as List;
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => loading = false);
    }
  }

  Future<void> loadUniversities(String code) async {
    final res = await ApiClient.I.get("${ApiEndpoints.universities}/country/$code");
    setState(() {
      universities = res.data is Map ? (res.data['data'] ?? []) : (res.data ?? []);
    });
  }

  Future<void> loadByCourse(String course) async {
    setState(() => selectedCourse = course);
    setState(() {
      universities = allUniversities
          .where((u) =>
              (u['courses'] as List?)
                  ?.map((e) => e.toString().toLowerCase())
                  .contains(course.toLowerCase()) ??
              false)
          .toList();
    });
  }

  Future<void> toggleSave(String id) async {
    final isSaved = savedIds.contains(id);
    try {
      if (isSaved) {
        await ApiClient.I.delete("${ApiEndpoints.savedUniversities}/$id");
        savedIds.remove(id);
      } else {
        await ApiClient.I.post(ApiEndpoints.savedUniversities, data: {'universityId': id});
        savedIds.add(id);
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  void searchUniversities(String query) {
    final base = selectedCourse == null
        ? allUniversities
        : allUniversities
            .where((u) =>
                (u['courses'] as List?)
                    ?.map((e) => e.toString().toLowerCase())
                    .contains(selectedCourse!.toLowerCase()) ??
                false)
            .toList();
    setState(() {
      universities = base
          .where(
            (u) => (u['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // ================= NAV =================

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final totalUniversities = allUniversities.length;
    final totalCountries = countries.length;
    final totalCourses = courses.length;

    List topUniversities = recommendations.isNotEmpty
        ? recommendations
        : universities.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      bottomNavigationBar:
          MyNavigationBar(currentIndex: _currentIndex, onTap: _onNavTap),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(
                      totalUniversities,
                      totalCountries,
                      totalCourses,
                    ),
                    const SizedBox(height: 16),
                    _buildCountries(),
                    const SizedBox(height: 16),
                    _buildCourses(),
                    const SizedBox(height: 16),
                    _buildTopUniversities(topUniversities),
                    const SizedBox(height: 24),
                    _buildDeadlines(),
                  ],
                ),
              ),
            ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildHeroCard(int unis, int countriesCount, int coursesCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6FAB), Color(0xFF00537A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(color: Colors.white70, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "Search universities with clarity.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Find universities by country, course, and ranking. Save options instantly while you build your shortlist.",
            style: TextStyle(color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: searchUniversities,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Search by university, course, or country...",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip("$unis", "Universities"),
              _statChip("$countriesCount", "Countries"),
              _statChip("$coursesCount", "Courses"),
            ],
          )
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountries() {
    final display = showAllCountries ? countries : countries.take(3).toList();
    return _sectionCard(
      title: "Countries",
      trailingText:
          "${countries.length} total",
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: display.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final code = display[i];
                return GestureDetector(
                  onTap: () => loadUniversities(code),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            code.length > 2 ? code.substring(0, 2).toUpperCase() : code.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF0B6FAB)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            code,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (countries.length > 3)
            TextButton(
              onPressed: () => setState(() => showAllCountries = !showAllCountries),
              child: Text(showAllCountries ? "Show less" : "Show more"),
            ),
        ],
      ),
    );
  }

  Widget _buildCourses() {
    final display = showAllCourses ? courses : courses.take(3).toList();
    return _sectionCard(
      title: "Courses",
      trailingText: "${courses.length} total",
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: display.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final course = display[i];
                final selected = selectedCourse == course;
                return ChoiceChip(
                  label: SizedBox(
                    width: 160,
                    child: Text(
                      course,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => loadByCourse(course),
                );
              },
            ),
          ),
          if (courses.length > 3)
            TextButton(
              onPressed: () => setState(() => showAllCourses = !showAllCourses),
              child: Text(showAllCourses ? "Show less" : "Show more"),
            ),
        ],
      ),
    );
  }

  Widget _buildTopUniversities(List uniList) {
    final display = showMoreUniversities ? uniList : uniList.take(3).toList();
    return _sectionCard(
      title: "Top Ranked Universities",
      trailingText: "Showing ${display.length} of ${uniList.length}",
      child: Column(
        children: [
          ...display.map((u) => _universityCard(u)).toList(),
          if (uniList.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => showMoreUniversities = !showMoreUniversities),
                child: Text(showMoreUniversities ? "Show less" : "Show more"),
              ),
            )
        ],
      ),
    );
  }

  Widget _universityCard(dynamic u) {
    final name = u['name'] ?? 'University';
    final country = u['country'] ?? '';
    final city = u['city'] ?? '';
    final rawWebsite = u['website'] ?? u['web_pages'] ?? '';
    final website = rawWebsite is List ? (rawWebsite.isNotEmpty ? rawWebsite.first : '') : rawWebsite;
    final logo = u['logo_url'] ?? u['logoUrl'];
    final id = u['id']?.toString() ?? u['_id']?.toString() ?? name;
    final isSaved = savedIds.contains(id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: logo != null ? NetworkImage(logo) : null,
                  child: logo == null
                      ? const Icon(Icons.school, color: Color(0xFF0B6FAB))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        [country, city].where((e) => (e ?? '').toString().isNotEmpty).join(" • "),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.blue),
                  onPressed: () => toggleSave(id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UniversityDetailPage(university: u),
                      ),
                    );
                  },
                  child: const Text("View Detail"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6FAB),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => toggleSave(id),
                  child: Text(isSaved ? "Saved" : "Save"),
                ),
                const Spacer(),
                if (website.toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => launchUrl(Uri.parse(website.toString())),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlines() {
    if (deadlines.isEmpty) return const SizedBox.shrink();
    return _sectionCard(
      title: "Upcoming deadlines",
      trailingText: "${deadlines.length} total",
      child: Column(
        children: deadlines.take(3).map((d) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: Color(0xFF0B6FAB)),
            title: Text(d['title'] ?? ''),
            subtitle: Text(d['date'] ?? ''),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionCard({required String title, String? trailingText, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(color: Colors.grey),
                )
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
