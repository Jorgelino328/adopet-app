import 'package:adopet/core/mixins/address_mixin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onSignedOut});
  final VoidCallback? onSignedOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AddressMixin{
  final _authService = AuthService.instance;
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _contactController = TextEditingController();
  
  DateTime? _selectedDate;
  final Set<String> _selectedWantedPets = <String>{};

  bool _isSaving = false;
  bool _isEditing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    fetchStates(); // From mixin
  }
  
  void _syncFromUser() {
    final user = _authService.currentUser;
    if (user == null) return;

    _nameController.text = user.name;
    _contactController.text = user.contactNumber ?? '';
    
    cepController.text = user.cep ?? '';
    selectedState = user.state;
    selectedCity = user.city;
    
    if (selectedState != null) fetchCities(selectedState!);

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
      cep: cepController.text, 
      city: selectedCity,
      state: selectedState,
      preferences: UserProfile.serializePreferenceSelections(_selectedWantedPets.toList()),
    );

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
                    title: Text(user.name), // No '?' needed
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email), // No '?' needed
                        if (user.dob != null)
                          Text('Nascimento: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(user.dob!))}'),
                        if (user.contactNumber != null && user.contactNumber!.isNotEmpty)
                          Text('Telefone: ${user.contactNumber}'),
                        if (user.city != null && user.state != null)
                          Text('Localização: ${user.city}/${user.state}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user.preferences?.isNotEmpty ?? false) ...[
                    Text('Preferências:', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: UserProfile.parsePreferenceSelections(user.preferences!)
                          .map((option) => Chip(label: Text(UserProfile.labelForPreference(option))))
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
                      decoration: const InputDecoration(labelText: 'Data de Nascimento (opcional)', suffixIcon: Icon(Icons.calendar_today)),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contactController, 
                      inputFormatters: [phoneFormatter],
                      maxLength: 15,
                      decoration: const InputDecoration(
                        labelText: 'Telefone (opcional)',
                        hintText: '(84) 99999-9999', 
                        counterText: ''
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cepController,
                      inputFormatters: [cepFormatter],
                      decoration: const InputDecoration(labelText: 'CEP (opcional)'),
                      onChanged: (val) {
                        if (val.length == 9) fetchAddressByCep(val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: Key('state_${states.length}_$selectedState'),
                      initialValue: selectedState,
                      items: states.map((s) => DropdownMenuItem(value: s['sigla'] as String, child: Text(s['sigla']))).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedState = val;
                          selectedCity = null;
                          fetchCities(val!);
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Estado (opcional)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: Key('city_${cities.length}_$selectedCity'),
                      initialValue: selectedCity,
                      items: cities.map((c) => DropdownMenuItem(value: c['nome'] as String, child: Text(c['nome']))).toList(),
                      onChanged: (val) => setState(() => selectedCity = val),
                      decoration: const InputDecoration(labelText: 'Cidade (opcional)'),
                    ),
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
                              selected ? _selectedWantedPets.add(option) : _selectedWantedPets.remove(option);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (_message != null) ...[
                      Text(_message!, style: TextStyle(color: _message!.contains('sucesso') ? Colors.green : Colors.redAccent)),
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
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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