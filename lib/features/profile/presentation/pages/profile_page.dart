import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.onSignedOut});

  final VoidCallback onSignedOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService.instance;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final Set<String> _selectedWantedPets = <String>{};
  final Set<String> _selectedHavePets = <String>{};

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
    super.dispose();
  }

  void _syncFromUser() {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    _nameController.text = user.name;
    _emailController.text = user.email;
    _selectedWantedPets
      ..clear()
      ..addAll(UserProfile.parsePreferenceSelections(user.preferences));
    _selectedHavePets
      ..clear()
      ..addAll(UserProfile.parsePreferenceSelections(user.existingPets));
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
      existingPets: UserProfile.serializePreferenceSelections(
        _selectedHavePets.toList(),
      ),
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para ver seu perfil.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [
          TextButton.icon(
            onPressed: widget.onSignedOut,
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
                    subtitle: Text(user.email),
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
                          UserProfile.parsePreferenceSelections(
                                user.preferences,
                              )
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
                  if (user.existingPets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Você tem:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          UserProfile.parsePreferenceSelections(
                                user.existingPets,
                              )
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
                    const SizedBox(height: 12),
                    Text(
                      'Que tipo de pet você tem?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: UserProfile.petPreferenceOptions.map((option) {
                        final isSelected = _selectedHavePets.contains(option);
                        return FilterChip(
                          label: Text(UserProfile.labelForPreference(option)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedHavePets.add(option);
                              } else {
                                _selectedHavePets.remove(option);
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
