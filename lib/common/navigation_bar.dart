import 'package:flutter/material.dart';
import '../features/dashboard/presentation/pages/bottom screen/saved_page.dart';
import '../features/dashboard/presentation/pages/bottom screen/profile_page.dart';

class MyNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const MyNavigationBar({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        if (onTap != null) {
          onTap!(i);
          return;
        }
        // Handle navigation based on index
        _handleNavigation(context, i);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Navigate to dashboard/home
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
        break;
      case 1:
        // Navigate to saved page
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SavedPage()),
        );
        break;
      case 2:
        // Navigate to profile page
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }
}
