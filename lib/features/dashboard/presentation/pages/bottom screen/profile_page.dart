import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  Map<String, dynamic> user = {};
  File? _localImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.I.get(ApiEndpoints.userProfile);
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      setState(() => user = Map<String, dynamic>.from(data));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    // Request runtime permissions
    final status = await (source == ImageSource.camera
        ? Permission.camera.request()
        : (Platform.isAndroid ? Permission.storage.request() : Permission.photos.request()));

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
      return;
    }

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _localImage = File(picked.path));
    await _uploadAvatar(_localImage!);
  }

  Future<void> _uploadAvatar(File file) async {
    try {
      final form = FormData.fromMap({
        'profilePic': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
      });
      final res = await ApiClient.I.put(ApiEndpoints.updateProfile, data: form);
      final updated = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      setState(() => user = Map<String, dynamic>.from(updated));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user['profilePic']?.toString();
    final name = user['fullName'] ?? 'User';
    final email = user['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImagePickerSheet,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _localImage != null
                          ? FileImage(_localImage!)
                          : (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl) as ImageProvider
                              : null,
                      backgroundColor: Colors.grey.shade300,
                      child: (_localImage == null && (avatarUrl == null || avatarUrl.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Reload profile'),
                    trailing: const Icon(Icons.refresh),
                    onTap: _loadProfile,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text('Logout', style: TextStyle(color: Colors.orange)),
                    onTap: _logout,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete account', style: TextStyle(color: Colors.red)),
                    onTap: _confirmDelete,
                  ),
                ],
              ),
            ),
    );
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await ApiClient.I.clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await ApiClient.I.delete(ApiEndpoints.deleteAccount);
      await _logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}
