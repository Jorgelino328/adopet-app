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
    test('updates the current user profile preferences and new fields', () async {
      final auth = AuthService.instance;
      
      // Simulate an existing Auth0 session
      final mockUser = UserProfile(
        id: 'auth0|123456789',
        name: 'Ana',
        email: 'ana@example.com',
        passwordHash: 'managed_by_auth0',
        dob: '1994-01-01', // New field
        contactNumber: '(84) 99999-9999', // New field
        preferences: 'dog',
        favorites: '',
        createdAt: DateTime.now(),
      );
      
      SharedPreferences.setMockInitialValues({
        'auth_session': jsonEncode(mockUser.toJson()),
      });

      await auth.initialize();
      
      expect(auth.currentUser, isNotNull);

      // Test the updateProfile method with the new schema
      final updated = await auth.updateProfile(
        name: 'Ana Silva',
        preferences: 'dog,cat',
        dob: '1994-01-01',
        contactNumber: '(84) 98888-8888',
        cep: '59000-000',
        city: 'Parnamirim',
        state: 'RN',
      );

      // Verify the updates
      expect(updated, isTrue);
      expect(auth.currentUser?.name, 'Ana Silva');
      expect(auth.currentUser?.preferences, 'dog,cat');
      expect(auth.currentUser?.contactNumber, '(84) 98888-8888');
      expect(auth.currentUser?.city, 'Parnamirim');
    });
  });
}