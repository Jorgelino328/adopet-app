import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/mixins/address_mixin.dart'; 
import '../../models/user_profile.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> with AddressMixin {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _contactController = TextEditingController();
  
  DateTime? _selectedDate;
  final Set<String> _selectedPets = <String>{};

  @override
  void initState() {
    super.initState();
    fetchStates();
    
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _completeSetup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O campo Nome é obrigatório.')),
      );
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        dob: _selectedDate?.toIso8601String().split('T')[0],
        contactNumber: _contactController.text,
        cep: cepController.text,
        city: selectedCity,
        state: selectedState,
        preferences: UserProfile.serializePreferenceSelections(_selectedPets.toList()),
      );
      
      if (!mounted) return;
      
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Cadastro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Personalize seu perfil.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome (obrigatório)', 
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dobController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Data de Nascimento (opcional)', // Restored
              suffixIcon: Icon(Icons.calendar_today)
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            inputFormatters: [phoneFormatter],
            decoration: const InputDecoration(
              labelText: 'Telefone (opcional)', 
              hintText: '(84) 99999-9999', 
              counterText: ''
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: cepController, 
            keyboardType: TextInputType.number,
            maxLength: 9, 
            inputFormatters: [cepFormatter], 
            onChanged: (value) {
              if (value.length == 9) {
                fetchAddressByCep(value); 
              }
            },
            decoration: const InputDecoration(
              labelText: 'CEP (opcional)',
              hintText: '00000-000', 
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          const Text('Tipos de pet de interesse:'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserProfile.petPreferenceOptions.map((option) {
              return FilterChip(
                label: Text(UserProfile.labelForPreference(option)),
                selected: _selectedPets.contains(option),
                onSelected: (selected) => setState(() => selected ? _selectedPets.add(option) : _selectedPets.remove(option)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _completeSetup, child: const Text('Finalizar')),
          ),
        ],
      ),
    );
  }
}