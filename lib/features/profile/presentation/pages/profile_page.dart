import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onSignedOut});
  final VoidCallback? onSignedOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService.instance;
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _contactController = TextEditingController();
  final _cepController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  DateTime? _selectedDate;
  final Set<String> _selectedWantedPets = <String>{};

  bool _isSaving = false;
  bool _isEditing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _syncFromUser();
  }

  void _syncFromUser() {
    final user = _authService.currentUser;
    if (user == null) return;

    _nameController.text = user.name;
    _contactController.text = user.contactNumber ?? '';
    _cepController.text = user.cep ?? '';
    _cityController.text = user.city ?? '';
    _stateController.text = user.state ?? '';
    
    if (user.dob != null) {
      _selectedDate = DateTime.tryParse(user.dob!);
      _dobController.text = _selectedDate != null 
          ? DateFormat('dd/MM/yyyy').format(_selectedDate!) 
          : '';
    }

    _selectedWantedPets
      ..clear()
      ..addAll(UserProfile.parsePreferenceSelections(user.preferences ?? ''));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final success = await _authService.updateProfile(
      name: _nameController.text,
      dob: _selectedDate?.toIso8601String().split('T')[0],
      contactNumber: _contactController.text,
      cep: _cepController.text,
      city: _cityController.text,
      state: _stateController.text,
      preferences: UserProfile.serializePreferenceSelections(_selectedWantedPets.toList()),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
      _message = success ? 'Perfil atualizado com sucesso.' : 'Erro ao atualizar.';
    });
  }

  Future<void> _handleLogin() async {
    final success = await _authService.loginWithAuth0();
    
    if (!mounted) return;

    if (success) {
      _syncFromUser();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login cancelado ou falhou.')),
      );
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
                      onPressed: _handleLogin,
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
                        if (user.dob != null) Text('Nascimento: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(user.dob!))}'),
                        if (user.contactNumber != null && user.contactNumber!.isNotEmpty) Text('Telefone: ${user.contactNumber}'),
                        if (user.city != null && user.state != null) Text('Localização: ${user.city}/${user.state}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user.preferences?.isNotEmpty ?? false) ...[
                    Text(
                      'Preferências:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          UserProfile.parsePreferenceSelections(user.preferences!)
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
                    Text('Editar perfil', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Data de Nascimento', suffixIcon: Icon(Icons.calendar_today)),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Telefone')),
                    const SizedBox(height: 12),
                    TextField(controller: _cepController, decoration: const InputDecoration(labelText: 'CEP')),
                    const SizedBox(height: 12),
                    TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Cidade')),
                    const SizedBox(height: 12),
                    TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'Estado')),
                    const SizedBox(height: 12),
                    Text('Que tipo de pet você quer?', style: Theme.of(context).textTheme.titleSmall),
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