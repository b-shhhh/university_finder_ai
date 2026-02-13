import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/navigation_bar.dart';
import 'bottom screen/application_page.dart';
import 'bottom screen/profile_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final String baseUrl = "http://10.0.2.2:3000/api/dashboard";

  List countries = [];
  List universities = [];
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
      final c = await http.get(Uri.parse("$baseUrl/countries"));
      final u =
      await http.get(Uri.parse("$baseUrl/country/US/universities"));

      setState(() {
        countries = jsonDecode(c.body);
        universities = jsonDecode(u.body);
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadUniversities(String code) async {
    final res =
    await http.get(Uri.parse("$baseUrl/country/$code/universities"));

    setState(() {
      universities = jsonDecode(res.body);
    });
  }

  void searchUniversities(String query) {
    setState(() {
      universities = universities
          .where((u) =>
          u['name'].toLowerCase().contains(query.toLowerCase()))
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
        MaterialPageRoute(builder: (_) => const ApplicationPage()),
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
                  final c = countries[i];

                  return GestureDetector(
                    onTap: () => loadUniversities(c['code']),
                    child: Container(
                      margin: const EdgeInsets.only(right: 14),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage:
                            NetworkImage(c['flag']),
                          ),
                          const SizedBox(height: 6),
                          Text(c['code']),
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
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.school),
                  title: Text(u['name']),
                  subtitle: Text(u['country']),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    await launchUrl(Uri.parse(u['website']));
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
