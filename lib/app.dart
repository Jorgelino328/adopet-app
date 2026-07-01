import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/adoption/presentation/pages/adoption_form_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/products/presentation/pages/products_page.dart';

class PetShopApp extends StatefulWidget {
  const PetShopApp({super.key});

  @override
  State<PetShopApp> createState() => _PetShopAppState();
}

class _PetShopAppState extends State<PetShopApp> {
  final _authService = AuthService.instance;
  bool _isReady = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _authService.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _isReady = true;
      _isAuthenticated = _authService.currentUser != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Shop',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _isReady
          ? (_isAuthenticated ? const PetShopShell() : AuthPage(onAuthenticated: () => setState(() => _isAuthenticated = true)))
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class PetShopShell extends StatefulWidget {
  const PetShopShell({super.key});

  @override
  State<PetShopShell> createState() => _PetShopShellState();
}

class _PetShopShellState extends State<PetShopShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ProductsPage(),
    AdoptionFormPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _pages[_currentIndex],
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Pets',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Adoção',
          ),
        ],
      ),
    );
  }
}
