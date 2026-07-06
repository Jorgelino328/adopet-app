import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../../features/profile/presentation/pages/setup_profile_page.dart'; 

mixin SetupDialogMixin<T extends StatefulWidget> on State<T> {
  Future<void> checkAndShowSetupDialog() async {
    final user = AuthService.instance.currentUser;
    if (user == null || user.isSetupComplete) return;

    final prefs = await SharedPreferences.getInstance();
    final bool alreadyShown = prefs.getBool('setup_dialog_shown_${user.id}') ?? false;

    if (!alreadyShown && mounted) {
      _showSetupDialog();
      await prefs.setBool('setup_dialog_shown_${user.id}', true);
    }
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quase lá!'),
        content: const Text('Complete seu perfil para aproveitar todas as funcionalidades.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Depois')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupProfilePage()));
            },
            child: const Text('Completar agora'),
          ),
        ],
      ),
    );
  }
}