import 'package:flutter/material.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../widgets/university_detail_page.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  bool loading = true;
  List<String> savedIds = [];
  List universities = [];

  @override
  void initState() {
    super.initState();
    loadSaved();
  }

  Future<void> loadSaved() async {
    setState(() => loading = true);
    try {
      final savedRes = await ApiClient.I.get(ApiEndpoints.savedUniversities);
      final ids = (savedRes.data is Map ? savedRes.data['data'] : savedRes.data) as List;
      savedIds = ids.map((e) => e.toString()).toList();

      // fetch details for each saved id in parallel
      universities = [];
      for (final id in savedIds) {
        try {
          final detail = await ApiClient.I.get("${ApiEndpoints.universities}/$id");
          final data = detail.data is Map ? (detail.data['data'] ?? detail.data) : detail.data;
          universities.add(data);
        } catch (_) {}
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load saved: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.I.delete("${ApiEndpoints.savedUniversities}/$id");
      savedIds.remove(id);
      universities.removeWhere((u) => (u['id'] ?? u['_id']).toString() == id);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Universities'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : universities.isEmpty
              ? const Center(child: Text('No saved universities yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, i) {
                    final u = universities[i];
                    final id = u['id']?.toString() ?? u['_id']?.toString() ?? '';
                    return Dismissible(
                      key: ValueKey(id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => remove(id),
                      child: ListTile(
                        leading: u['logo_url'] != null
                            ? CircleAvatar(backgroundImage: NetworkImage(u['logo_url']))
                            : const Icon(Icons.school),
                        title: Text(u['name'] ?? ''),
                        subtitle: Text(u['country'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => remove(id),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UniversityDetailPage(university: u),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: universities.length,
                ),
    );
  }
}
