import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _online = true;
  static const _profileCacheKey = 'profile_cache_v1';
  static const _profileQueueKey = 'profile_update_queue_v1';

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadProfileFromCache();
    _loadProfile();
  }

  Future<void> _initConnectivity() async {
    final initial = await _connectivity.checkConnectivity();
    _updateConnectivity(_asList(initial));
    _connSub = _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final nowOnline = results.any((r) => r != ConnectivityResult.none);
    if (nowOnline && !_online) {
      _flushQueuedProfile();
      _loadProfile();
    }
    if (!mounted) return;
    setState(() => _online = nowOnline);
  }

  List<ConnectivityResult> _asList(dynamic value) {
    if (value is ConnectivityResult) return [value];
    if (value is List<ConnectivityResult>) return value;
    return const [];
  }

  Future<void> _loadProfileFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileCacheKey);
      if (raw == null) return;
      final data = Map<String, dynamic>.from((jsonDecode(raw) as Map));
      setState(() {
        user = data;
        _nameCtrl.text = user['fullName'] ?? '';
        _emailCtrl.text = user['email'] ?? '';
        _phoneCtrl.text = user['phone'] ?? '';
        _countryCtrl.text = user['country'] ?? '';
        _bioCtrl.text = user['bio'] ?? '';
        _loading = false;
      });
    } catch (_) {}
  }

  Future<void> _cacheProfile(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    if (!_online) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: showing cached profile')),
        );
      }
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiClient.I.get(ApiEndpoints.userProfile);
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      setState(() {
        user = Map<String, dynamic>.from(data);
        _nameCtrl.text = user['fullName'] ?? '';
        _emailCtrl.text = user['email'] ?? '';
        _phoneCtrl.text = user['phone'] ?? '';
        _countryCtrl.text = user['country'] ?? '';
        _bioCtrl.text = user['bio'] ?? '';
      });
      await _cacheProfile(user);
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
    if (!_online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline: avatar upload will sync when online.')),
      );
      return;
    }
    try {
      final form = FormData.fromMap({
        'profilePic': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
      });
      final res = await ApiClient.I.put(ApiEndpoints.updateProfile, data: form);
      final updated = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      setState(() => user = Map<String, dynamic>.from(updated));
      await _cacheProfile(user);
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      };
      if (!_online) {
        user = {...user, ...payload};
        await _cacheProfile(user);
        await _queueProfileUpdate(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline: profile changes cached and will sync.')),
          );
        }
        if (mounted) setState(() => _loading = false);
        return;
      }

      final res = await ApiClient.I.put(ApiEndpoints.updateProfile, data: payload);
      final updated = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      setState(() => user = Map<String, dynamic>.from(updated));
      await _cacheProfile(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _resolveAvatarUrl(user['profilePic']?.toString());
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
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
                    ),
                    const SizedBox(height: 16),
                    Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 6),
                    Center(child: Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                    const SizedBox(height: 24),

                    const Text('Full name'),
                    TextFormField(
                      controller: _nameCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Email'),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 12),
                    const Text('Phone'),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    const Text('Country'),
                    TextFormField(
                      controller: _countryCtrl,
                    ),
                    const SizedBox(height: 12),
                    const Text('Bio'),
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save profile'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Reload profile'),
                      trailing: const Icon(Icons.refresh),
                      onTap: _loadProfile,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: const Text('Change password'),
                      onTap: _showChangePasswordDialog,
                    ),
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
            ),
    );
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
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

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Change password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current password'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password'),
                    validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                  ),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm new password'),
                    validator: (v) => v == newCtrl.text ? null : 'Passwords do not match',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => loading = true);
                        try {
                          await ApiClient.I.put(ApiEndpoints.changePassword, data: {
                            'oldPassword': oldCtrl.text.trim(),
                            'newPassword': newCtrl.text.trim(),
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Password updated')),
                            );
                          }
                        } catch (e) {
                          setState(() => loading = false);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _queueProfileUpdate(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileQueueKey, jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> _flushQueuedProfile() async {
    if (!_online) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileQueueKey);
      if (raw == null) return;
      final payload = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      await ApiClient.I.put(ApiEndpoints.updateProfile, data: payload);
      await prefs.remove(_profileQueueKey);
      await _loadProfile();
    } catch (_) {
      // keep queued on failure
    }
  }

  String? _resolveAvatarUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    if (lower.startsWith('http')) return raw;

    // Extract filename
    final afterUploads = raw.split(RegExp(r'uploads[\\/]+')).length > 1
        ? raw.split(RegExp(r'uploads[\\/]+')).last
        : raw.split(RegExp(r'[\\\\/]')).last;

    final origin = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$origin/uploads/$afterUploads';
  }
}
