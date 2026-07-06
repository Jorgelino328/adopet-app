import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/pets/presentation/providers/pets_provider.dart';
import 'core/services/auth_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AuthService.instance.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PetsProvider()..initializeData(),
        ),
      ],
      child: const AdopetApp(),
    ),
  );
}
