import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/core/services/persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists favorite pet ids across saves and loads', () async {
    SharedPreferences.setMockInitialValues({});
    final persistence = PersistenceService();

    await persistence.saveFavoriteIds(['p1', 'p2']);
    final savedFavorites = await persistence.loadFavoriteIds();

    expect(savedFavorites, ['p1', 'p2']);
  });
}
