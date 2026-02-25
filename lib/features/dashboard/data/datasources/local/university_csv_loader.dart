import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class UniversityCsvLoader {
  UniversityCsvLoader._();
  static final UniversityCsvLoader instance = UniversityCsvLoader._();

  List<Map<String, String>> _rows = [];

  /// Split a course string that may use commas or semicolons as separators.
  static List<String> splitCourses(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[;,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> load() async {
    if (_rows.isNotEmpty) return;
    final csvString = await rootBundle.loadString('assets/universities.csv');
    final csvRows = const CsvToListConverter().convert(csvString, eol: '\n');
    if (csvRows.isEmpty) return;
    final headers = csvRows.first.map((e) => e.toString()).toList();
    _rows = [
      for (int i = 1; i < csvRows.length; i++)
        Map<String, String>.fromIterables(
          headers,
          csvRows[i].map((e) => e?.toString() ?? '').toList(),
        )
    ];
  }

  List<Map<String, String>> get universities => _rows;

  List<String> get countries => {
        for (final row in _rows) row['country'] ?? ''
      }.where((e) => e.isNotEmpty).toList()
        ..sort();

  List<String> get courses => {
        for (final row in _rows)
          ...splitCourses(row['courses'])
      }.where((e) => e.isNotEmpty).toList()
        ..sort();

  List<Map<String, String>> universitiesByCountry(String country) =>
      _rows.where((r) => (r['country'] ?? '').toLowerCase() == country.toLowerCase()).toList();

  List<Map<String, String>> universitiesByCourse(String course) =>
      _rows
          .where((r) => splitCourses(r['courses'])
              .any((c) => c.toLowerCase() == course.toLowerCase()))
          .toList();

  Map<String, String>? universityById(String id) =>
      _rows.firstWhere((r) => (r['id'] ?? r['sourceId'] ?? '') == id, orElse: () => {});
}
