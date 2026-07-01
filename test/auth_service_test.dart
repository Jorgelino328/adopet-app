import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService', () {
    test('stores a salted password hash and validates it', () async {
      final auth = AuthService.instance;
      await auth.initialize();
      await auth.clearForTests();

      final created = await auth.signUp(
        name: 'Ana',
        email: 'ana@example.com',
        password: 'supersecret',
        preferences: 'gatos,brinquedos',
        age: 28, // Passed as int
      );

      expect(created, isTrue);

      final user = await auth.signIn(
        email: 'ana@example.com',
        password: 'supersecret',
      );

      expect(user, isNotNull);
      expect(user!.name, 'Ana');
      expect(user.preferences, contains('gatos'));
      expect(user.age, 28); // Expect int
    });

    test('updates the current user profile preferences', () async {
      final auth = AuthService.instance;
      await auth.initialize();
      await auth.clearForTests();

      await auth.signUp(
        name: 'Ana',
        email: 'ana@example.com',
        password: 'supersecret',
        preferences: 'dog',
        age: 31, // Passed as int
      );

      final updated = await auth.updateProfile(
        name: 'Ana',
        email: 'ana@example.com',
        preferences: 'dog,cat',
        age: 32, // Passed as int
      );

      expect(updated, isTrue);
      expect(auth.currentUser?.preferences, 'dog,cat');
      expect(auth.currentUser?.age, 32); // Expect int
    });
  });
}