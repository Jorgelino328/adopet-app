import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/adoption/models/adoption_submission.dart';

class PersistenceService {
  static const _submissionsKey = 'adoption_submissions';

  Future<List<AdoptionSubmission>> loadSubmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_submissionsKey) ?? <String>[];
    
    return raw.map((item) {
      return AdoptionSubmission.fromJson(jsonDecode(item) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> saveSubmission(AdoptionSubmission submission) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_submissionsKey) ?? <String>[];
    
    existing.add(jsonEncode(submission.toJson()));
    
    await prefs.setStringList(_submissionsKey, existing);
  }
}