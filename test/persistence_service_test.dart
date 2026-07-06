import 'package:flutter_test/flutter_test.dart';
import 'package:adopet/core/services/persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists adoption submissions across saves and loads', () async {
    SharedPreferences.setMockInitialValues({});
    final persistence = PersistenceService();

    final submission = {'name': 'Ana', 'petPreference': 'Luna'};
    await persistence.saveSubmission(submission);
    
    final savedSubmissions = await persistence.loadSubmissions();

    expect(savedSubmissions.length, 1);
    expect(savedSubmissions.first['name'], 'Ana');
  });
}