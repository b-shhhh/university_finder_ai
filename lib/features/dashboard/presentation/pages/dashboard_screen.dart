import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Universities"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      bottomNavigationBar:
      MyNavigationBar(currentIndex: _currentIndex, onTap: _onNavTap),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= SEARCH =================
            TextField(
              controller: searchController,
              onChanged: searchUniversities,
              decoration: InputDecoration(
                hintText: "Search universities...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= AI BUTTON =================
            ElevatedButton.icon(
              onPressed: () {
                // TODO: navigate to AI finder
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text("AI University Finder"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 24),

            // ================= COURSES =================
            if (courses.isNotEmpty) ...[
              const Text(
                "Courses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final course = courses[i];
                    final active = course == selectedCourse;
                    return ChoiceChip(
                      label: Text(course),
                      selected: active,
                      onSelected: (_) => loadByCourse(course),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ================= COUNTRIES =================
            const Text(
              "Countries",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: countries.length,
                itemBuilder: (_, i) {
                  final code = countries[i];
                  return GestureDetector(
                    onTap: () => loadUniversities(code),
                    child: Container(
                      margin: const EdgeInsets.only(right: 14),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            child: Text(code.length > 2 ? code.substring(0, 2).toUpperCase() : code.toUpperCase()),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 70,
                            child: Text(
                              code,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ================= UNIVERSITIES =================
            const Text(
              "Universities",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...universities.map((u) {
              final name = u['name'] ?? 'University';
              final country = u['country'] ?? '';
              final website = u['web_pages'] ?? u['website'] ?? '';
              final logo = u['logo_url'];
              final id = u['id']?.toString() ?? u['_id']?.toString() ?? name;
              final isSaved = savedIds.contains(id);
              return Card(
                child: ListTile(
                  leading: logo != null
                      ? CircleAvatar(backgroundImage: NetworkImage(logo))
                      : const Icon(Icons.school),
                  title: Text(name),
                  subtitle: Text(country),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: () => toggleSave(id),
                      ),
                      const Icon(Icons.open_in_new),
                    ],
                  ),
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UniversityDetailPage(university: u),
                      ),
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 32),

            // ================= RECOMMENDATIONS =================
            if (recommendations.isNotEmpty) ...[
              const Text(
                "Recommended for you",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final rec = recommendations[i];
                    return SizedBox(
                      width: 260,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rec['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(rec['program'] ?? ''),
                              const SizedBox(height: 8),
                              Text(rec['country'] ?? '', style: const TextStyle(color: Colors.grey)),
                              const Spacer(),
                              Text('Score: ${rec['score'] ?? ''}'),
                              Text('Tuition: ${rec['tuition'] ?? ''}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (deadlines.isNotEmpty) ...[
              const Text(
                "Upcoming deadlines",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...deadlines.map((d) => ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(d['title'] ?? ''),
                    subtitle: Text(d['date'] ?? ''),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
