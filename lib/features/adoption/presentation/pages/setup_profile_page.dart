import 'package:flutter/material.dart';
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
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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

  Future<void> _completeSetup() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.updateProfile(
        name: user.name,
        dob: _selectedDate?.toIso8601String().split('T')[0], // Saves YYYY-MM-DD
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
      appBar: AppBar(title: const Text('Complete seu cadastro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _dobController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Data de Nascimento', suffixIcon: Icon(Icons.calendar_today)),
            onTap: _pickDate,
          ),
          TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: 'Telefone (ex: (84) 99999-9999)')),
          TextFormField(controller: _cepController, decoration: const InputDecoration(labelText: 'CEP')),
          TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Cidade')),
          TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'Estado')),
          const SizedBox(height: 20),
          // ... (Your FilterChip code for preferences)
          FilledButton(onPressed: _completeSetup, child: const Text('Finalizar')),
        ],
      ),
    );
  }
}