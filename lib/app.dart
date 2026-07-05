import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/products/presentation/pages/products_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

class AdopetApp extends StatefulWidget {
  const AdopetApp({super.key});

  @override
  State<AdopetApp> createState() => _AdopetAppState();
}

class _AdopetAppState extends State<AdopetApp> {
  final _authService = AuthService.instance;
  bool _isReady = false;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Shop',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _isReady
          ? const AdopetShell()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class AdopetShell extends StatefulWidget {
  const AdopetShell({super.key});

  @override
  State<AdopetShell> createState() => _AdopetShellState();
}

class _AdopetShellState extends State<AdopetShell> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    HomePage(),
    ProductsPage(),
    ProfilePage(),
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
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
