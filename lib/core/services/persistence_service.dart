import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const _submissionsKey = 'adoption_submissions';

  Future<List<Map<String, dynamic>>> loadSubmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_submissionsKey) ?? <String>[];
    return raw
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList(growable: false);
  }

  Future<void> saveSubmission(Map<String, dynamic> submission) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_submissionsKey) ?? <String>[];
    existing.add(jsonEncode(submission));
    await prefs.setStringList(_submissionsKey, existing);
  }
}