import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _dobController = TextEditingController();
  final _contactController = TextEditingController();
  final _cepController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  DateTime? _selectedDate;
  final Set<String> _selectedPets = <String>{};

  // Phone mask: (XX) XXXXX-XXXX
  final _phoneFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 0) newText += '(';
      if (i == 2) newText += ') ';
      if (i == 7) newText += '-';
      newText += text[i];
    }
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  });

  // CEP mask: XXXXX-XXX
  final _cepFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    String newText = '';
    
    for (int i = 0; i < text.length; i++) {
      if (i == 5) newText += '-';
      newText += text[i];
    }
    
    if (newText.length > 9) return oldValue;
    
    return TextEditingValue(
      text: newText, 
      selection: TextSelection.collapsed(offset: newText.length),
    );
  });

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
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.updateProfile(
        name: user.name,
        dob: _selectedDate?.toIso8601String().split('T')[0],
        contactNumber: _contactController.text,
        cep: _cepController.text,
        city: _cityController.text,
        state: _stateController.text,
        preferences: UserProfile.serializePreferenceSelections(_selectedPets.toList()),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Cadastro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Personalize seu perfil (opcional).',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _dobController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Data de Nascimento (opcional)', suffixIcon: Icon(Icons.calendar_today)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            inputFormatters: [_phoneFormatter],
            decoration: const InputDecoration(labelText: 'Telefone (opcional)', hintText: '(84) 99999-9999', counterText: ''),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cepController,
            keyboardType: TextInputType.number,
            maxLength: 9, 
            inputFormatters: [_cepFormatter],
            decoration: const InputDecoration(labelText: 'CEP (opcional)',hintText: '00000-000', counterText: ''),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Estado (opcional)'),
            items: ['RN', 'SP', 'RJ', 'MG', 'RS'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _stateController.text = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Cidade (opcional)'),
            items: ['Parnamirim', 'Natal', 'São Paulo'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _cityController.text = val!),
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