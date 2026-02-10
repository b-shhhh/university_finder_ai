import 'package:flutter/material.dart';
import '../../../../common/navigation_bar.dart';
import '../../../dashboard/presentation/pages/bottom screen/application_page.dart';
import '../../../dashboard/presentation/pages/bottom screen/profile_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // track the selected tab

  void _onNavTap(int index) {
    if (index == _currentIndex) return; // already on this tab

    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // Navigate to Application Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ApplicationPage()),
      );
    } else if (index == 2) {
      // Navigate to Profile Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Courses'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your existing dashboard UI here
            TextField(
              decoration: InputDecoration(
                hintText: 'Search universities, courses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Try our AI to find your course →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Popular Destinations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _flagIcon('USA'),
                _flagIcon('UK'),
                _flagIcon('Australia'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('In-Demand Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _courseChip('Computer Science'),
                _courseChip('Business'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Top Universities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              children: [
                _universityCard('Stanford University', 'USA', 4.9),
                _universityCard('Oxford University', 'UK', 4.8),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _flagIcon(String country) {
    return Column(
      children: [
        CircleAvatar(radius: 24, child: Text(country[0])), // Replace with flag image later
        const SizedBox(height: 4),
        Text(country),
      ],
    );
  }

  Widget _courseChip(String course) {
    return Chip(
      label: Text(course),
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _universityCard(String name, String country, double rating) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.school),
        title: Text(name),
        subtitle: Text(country),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber),
            Text(rating.toString()),
          ],
        ),
      ),
    );
  }
}
