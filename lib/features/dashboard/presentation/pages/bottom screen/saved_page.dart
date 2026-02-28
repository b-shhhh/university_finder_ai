import 'package:flutter/material.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../university_detail_page.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({
    super.key,
    this.savedIds,
    this.allUniversities,
    this.onSavedChanged,
    this.onOpenUniversity,
    this.embed = false,
  });

  /// Optional preloaded saved IDs (e.g., from dashboard state).
  final List<String>? savedIds;

  /// Optional full university list to avoid refetching when offline.
  final List<Map<String, dynamic>>? allUniversities;

  /// Callback when saved IDs change.
  final void Function(List<String> ids)? onSavedChanged;

  /// Optional handler to open a university (used by dashboard context).
  final void Function(Map<String, dynamic> uni)? onOpenUniversity;

  /// Hide scaffold chrome when embedded.
  final bool embed;

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  bool loading = true;
  List<String> savedIds = [];
  List<Map<String, dynamic>> universities = [];

  @override
  void initState() {
    super.initState();
    loadSaved();
  }

  Future<void> loadSaved() async {
    setState(() => loading = true);
    try {
      // Prefer provided IDs if present; otherwise fetch from API.
      if (widget.savedIds != null) {
        savedIds = widget.savedIds!;
      } else {
        final savedRes = await ApiClient.I.get(ApiEndpoints.savedUniversities);
        final ids = (savedRes.data is Map ? savedRes.data['data'] : savedRes.data) as List;
        savedIds = ids.map((e) => e.toString()).toList();
      }

      universities = [];
      // If we have the master list in memory, hydrate from it first.
      if (widget.allUniversities != null) {
        for (final id in savedIds) {
          final match = widget.allUniversities!.firstWhere(
            (u) => _resolveId(u) == id,
            orElse: () => {},
          );
          if (match.isNotEmpty) universities.add(match);
        }
        // If we already populated all saved universities locally, skip network.
        if (universities.length == savedIds.length) {
          widget.onSavedChanged?.call(savedIds);
          setState(() => loading = false);
          return;
        }
      }

      // Fetch missing ones from API.
      final missing = savedIds.where(
        (id) => universities.every((u) => _resolveId(u) != id),
      );

      final fetched = await Future.wait(
        missing.map((id) async {
          try {
            final detail = await ApiClient.I.get("${ApiEndpoints.universities}/$id");
            final data = detail.data is Map ? (detail.data['data'] ?? detail.data) : detail.data;
            return Map<String, dynamic>.from(data);
          } catch (_) {
            return null;
          }
        }),
      );
      universities.addAll(fetched.whereType<Map<String, dynamic>>());

      widget.onSavedChanged?.call(savedIds);
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
      widget.onSavedChanged?.call(savedIds);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? const Center(child: CircularProgressIndicator())
        : universities.isEmpty
            ? const Center(child: Text('No saved universities yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: universities.length,
                itemBuilder: (_, i) {
                  final u = universities[i];
                  final id = _resolveId(u);
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: u['logo_url'] != null && (u['logo_url'] as String).isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(u['logo_url']))
                          : const CircleAvatar(child: Icon(Icons.school)),
                      title: Text(u['name'] ?? ''),
                      subtitle: Text(u['country'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.redAccent),
                        onPressed: id == null ? null : () => remove(id),
                      ),
                      onTap: () => widget.onOpenUniversity != null
                          ? widget.onOpenUniversity!(u)
                          : Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UniversityDetailPage(
                                  university: u,
                                  isSaved: true, // Since it's in saved page, it's saved
                                  onSaveToggle: id == null ? null : () => remove(id),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              );

    if (widget.embed) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Universities')),
      body: content,
    );
  }

  String? _resolveId(Map<String, dynamic> uni) =>
      uni['id']?.toString() ?? uni['_id']?.toString() ?? uni['sourceId']?.toString();
}
