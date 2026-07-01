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
        existingPets: 'Nenhum',
      );

      expect(created, isTrue);

      final user = await auth.signIn(
        email: 'ana@example.com',
        password: 'supersecret',
      );

      expect(user, isNotNull);
      expect(user!.name, 'Ana');
      expect(user.preferences, contains('gatos'));
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
        existingPets: 'Nenhum',
      );

      final updated = await auth.updateProfile(
        name: 'Ana',
        email: 'ana@example.com',
        preferences: 'dog,cat',
        existingPets: 'Um gato',
      );

      expect(updated, isTrue);
      expect(auth.currentUser?.preferences, 'dog,cat');
      expect(auth.currentUser?.existingPets, 'Um gato');
    });
  });
}
