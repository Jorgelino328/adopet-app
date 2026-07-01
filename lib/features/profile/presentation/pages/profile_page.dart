import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../auth/presentation/pages/auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onSignedOut});

  final VoidCallback? onSignedOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService.instance;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final Set<String> _selectedWantedPets = <String>{};

  bool _isSaving = false;
  bool _isEditing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _syncFromUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _syncFromUser() {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    _nameController.text = user.name;
    _emailController.text = user.email;
    _ageController.text = user.age?.toString() ?? '';

    _selectedWantedPets
      ..clear()
      ..addAll(UserProfile.parsePreferenceSelections(user.preferences));
  }

  Future<void> _saveProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final success = await _authService.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      preferences: UserProfile.serializePreferenceSelections(
        _selectedWantedPets.toList(),
      ),
      age: int.tryParse(_ageController.text),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _message = success
          ? 'Perfil atualizado com sucesso.'
          : 'Não foi possível atualizar o perfil.';
    });

    if (success) {
      _syncFromUser();
      setState(() => _isEditing = false);
    }
  }

  Future<void> _openAuthPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AuthPage(
          onAuthenticated: () {
            Navigator.of(context).pop();
            widget.onSignedOut?.call();
            setState(() {});
          },
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    widget.onSignedOut?.call();
    if (!mounted) {
      return;
    }
    setState(() {
      _isEditing = false;
      _message = 'Você saiu da conta.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu perfil')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Você está navegando como visitante',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entre para salvar suas preferências e começar a adotar pets!',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openAuthPage,
                      icon: const Icon(Icons.login_outlined),
                      label: const Text('Entrar ou criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Sair'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações da conta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        if (user.age != null) Text('Idade: ${user.age} anos'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user.preferences.isNotEmpty) ...[
                    Text(
                      'Você quer:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          UserProfile.parsePreferenceSelections(user.preferences)
                              .map(
                                (option) => Chip(
                                  label: Text(
                                    UserProfile.labelForPreference(option),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar perfil'),
                  ),
                ],
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar perfil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Idade (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Que tipo de pet você quer?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: UserProfile.petPreferenceOptions.map((option) {
                        final isSelected = _selectedWantedPets.contains(option);
                        return FilterChip(
                          label: Text(UserProfile.labelForPreference(option)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedWantedPets.add(option);
                              } else {
                                _selectedWantedPets.remove(option);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (_message != null) ...[
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.contains('sucesso')
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _isEditing = false;
                              _message = null;
                              _syncFromUser();
                            }),
                            icon: const Icon(Icons.close_outlined),
                            label: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}