import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:adopet/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService', () {
    test('updates the current user profile preferences', () async {
      final auth = AuthService.instance;
      
      // Simulate an existing Auth0 session being loaded from SharedPreferences
      final mockUser = UserProfile(
        id: 'auth0|123456789',
        name: 'Ana',
        email: 'ana@example.com',
        passwordHash: 'managed_by_auth0',
        preferences: 'dog',
        age: 31,
        favorites: '',
        createdAt: DateTime.now(),
      );
      
      SharedPreferences.setMockInitialValues({
        'auth_session': jsonEncode(mockUser.toJson()),
      });

      await auth.initialize();
      
      // Verify the session was loaded correctly
      expect(auth.currentUser, isNotNull);

      // Test the updateProfile method
      final updated = await auth.updateProfile(
        name: 'Ana Silva',
        email: 'ana@example.com',
        preferences: 'dog,cat',
        age: 32,
      );

      // Verify the updates were applied
      expect(updated, isTrue);
      expect(auth.currentUser?.name, 'Ana Silva');
      expect(auth.currentUser?.preferences, 'dog,cat');
      expect(auth.currentUser?.age, 32);
    });
  });
}