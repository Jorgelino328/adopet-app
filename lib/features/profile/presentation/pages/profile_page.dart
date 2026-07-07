import 'package:adopet/core/mixins/address_mixin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';
import '../../../profile/models/user_profile.dart';

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
    fetchStates();
    _syncFromUser();
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

    if (user.dob != null && user.dob!.isNotEmpty) {
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

  // Helper widget to build consistent info rows
  Widget _buildInfoTile(BuildContext context, {required IconData icon, required String title, required String value}) {
    final isPlaceholder = value.contains('Não informad');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(
        title, 
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[800],
          fontWeight: FontWeight.bold,
          ),
        ),
      subtitle: Text(
        value, 
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.grey[600],
          fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
        )
      ),
    );
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Você está navegando como visitante',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entre para salvar suas preferências e começar a adotar pets!',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _handleLogin,
                        icon: const Icon(Icons.login_outlined),
                        label: const Text('Entrar ou criar conta'),
                      ),
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
            label: const Text(
              'Sair',
              style: TextStyle( 
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
                color: Color(0xFFC64600)
                ),
              ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header Section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 36,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Read-only Details Section
          if (!_isEditing) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Informações de Contato',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    context,
                    icon: Icons.cake_outlined,
                    title: 'Data de Nascimento',
                    value: user.dob != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(user.dob!)) : 'Não informada',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Telefone',
                    value: (user.contactNumber != null && user.contactNumber!.isNotEmpty) ? user.contactNumber! : 'Não informado',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Localização',
                    value: (user.city != null && user.state != null) ? '${user.city} - ${user.state}' : 'Não informada',
                  ),
                ],
              ),
            ),
            
            if (user.preferences?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferências de Adoção',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: UserProfile.parsePreferenceSelections(user.preferences!)
                            .map((option) => Chip(
                                  label: Text(UserProfile.labelForPreference(option)),
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                  side: BorderSide.none,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ),
          ],

          // Editing Section
          if (_isEditing) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar perfil', 
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Não informado'),
                        ),
                        ...states.map((s) => DropdownMenuItem(
                          value: s['sigla'] as String, 
                          child: Text(s['sigla'])
                        )),
                      ],
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
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Não informada'),
                        ),
                        ...cities.map((c) => DropdownMenuItem(
                          value: c['nome'] as String, 
                          child: Text(c['nome'])
                        )),
                      ],
                      onChanged: (val) => setState(() => selectedCity = val),
                      decoration: const InputDecoration(labelText: 'Cidade (opcional)'),
                    ),
                    const SizedBox(height: 24),
                    Text('Que tipo de pet você quer?', style: Theme.of(context).textTheme.titleMedium),
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
                              selected ? _selectedWantedPets.add(option) : _selectedWantedPets.remove(option);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
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