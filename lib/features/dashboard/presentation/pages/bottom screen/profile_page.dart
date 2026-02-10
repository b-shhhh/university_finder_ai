import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Avatar
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Username
            const Text(
              'Dummy User',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // Email
            const Text(
              'dummyuser@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Profile options
            _ProfileMenuItem(icon: Icons.person_outline, title: 'Edit Profile'),
            _ProfileMenuItem(icon: Icons.history, title: 'My Items'),
            _ProfileMenuItem(icon: Icons.notifications, title: 'Notifications'),
            _ProfileMenuItem(icon: Icons.security, title: 'Privacy & Security'),
            _ProfileMenuItem(icon: Icons.help_outline, title: 'Help & Support'),
            _ProfileMenuItem(icon: Icons.info_outline, title: 'About'),
            _ProfileMenuItem(icon: Icons.logout, title: 'Logout', isDestructive: true),

            const SizedBox(height: 30),
            const Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black),
          title: Text(
            title,
            style: TextStyle(color: isDestructive ? Colors.red : Colors.black),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        const Divider(),
      ],
    );
  }
}
