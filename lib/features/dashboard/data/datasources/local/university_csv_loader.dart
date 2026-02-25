import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class UniversityCsvLoader {
  UniversityCsvLoader._();
  static final UniversityCsvLoader instance = UniversityCsvLoader._();

  List<Map<String, String>> _rows = [];

  /// Split a course string that may use commas or semicolons as separators.
  static List<String> splitCourses(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[;,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Normalize string safely
  String _clean(String? value) {
    return (value ?? '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .trim();
  }

  Future<void> load() async {
    if (_rows.isNotEmpty) return;

    final csvString =
        await rootBundle.loadString('assets/universities.csv');

    final csvRows =
        const CsvToListConverter(eol: '\n').convert(csvString);

    if (csvRows.isEmpty) return;

    final headers =
        csvRows.first.map((e) => e.toString().trim()).toList();

    final temp = <Map<String, String>>[];

    for (int i = 1; i < csvRows.length; i++) {
      final rowValues =
          csvRows[i].map((e) => _clean(e?.toString())).toList();

      final row =
          Map<String, String>.fromIterables(headers, rowValues);

      final name = _clean(row['name']);
      final country = _clean(row['country']);

      // 🚫 Skip invalid rows
      if (name.isEmpty) continue;
      if (name.toLowerCase() == country.toLowerCase()) continue;

      temp.add(row);
    }

    // 🔥 Strong deduplication by normalized name + country
    final uniqueMap = <String, Map<String, String>>{};

    for (final row in temp) {
      final name = _clean(row['name']).toLowerCase();
      final country = _clean(row['country']).toLowerCase();

      final key = '$name|$country';

      uniqueMap.putIfAbsent(key, () => row);
    }

    _rows = uniqueMap.values.toList();
  }

  List<Map<String, String>> get universities => _rows;

  List<String> get countries => {
        for (final row in _rows) _clean(row['country'])
      }.where((e) => e.isNotEmpty).toList()
        ..sort();

  List<String> get courses => {
        for (final row in _rows)
          ...splitCourses(row['courses'])
      }.where((e) => e.isNotEmpty).toList()
        ..sort();

  List<Map<String, String>> universitiesByCountry(String country) =>
      _rows
          .where((r) =>
              _clean(r['country']).toLowerCase() ==
              country.toLowerCase())
          .toList();

  List<Map<String, String>> universitiesByCourse(String course) =>
      _rows
          .where((r) => splitCourses(r['courses']).any(
              (c) => c.toLowerCase() == course.toLowerCase()))
          .toList();

  Map<String, String>? universityById(String id) {
    try {
      return _rows.firstWhere(
          (r) => _clean(r['id'] ?? r['sourceId']) == id);
    } catch (_) {
      return null;
    }
  }
}