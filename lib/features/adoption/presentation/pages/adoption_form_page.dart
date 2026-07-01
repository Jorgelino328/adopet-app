import 'package:flutter/material.dart';

import '../../../../core/services/persistence_service.dart';
import '../../../products/data/pet_service.dart';

class AdoptionFormPage extends StatefulWidget {
  const AdoptionFormPage({super.key, this.selectedPet});

  final PetItem? selectedPet;

  @override
  State<AdoptionFormPage> createState() => _AdoptionFormPageState();
}

class _AdoptionFormPageState extends State<AdoptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _noteController = TextEditingController();
  final PersistenceService _persistence = PersistenceService();

  String? _petPreference;

  @override
  void initState() {
    super.initState();
    if (widget.selectedPet != null) {
      _petPreference = widget.selectedPet!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final submission = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'age': _ageController.text.trim(),
      'petPreference': _petPreference ?? 'Preferência não informada',
      'note': _noteController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _persistence.saveSubmission(submission);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulário salvo com sucesso!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPetName = widget.selectedPet?.name ?? 'Seu futuro pet';
    return Scaffold(
      appBar: AppBar(title: const Text('Formulário de adoção')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quase lá!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete as informações de $selectedPetName para registrar seu interesse.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Seu nome'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe seu nome'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe seu e-mail';
                  }
                  if (!value.contains('@')) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Idade'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe sua idade';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18) {
                    return 'A adoção precisa ser autorizada por um maior de 18 anos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _petPreference,
                decoration: const InputDecoration(
                  labelText: 'Pet de interesse',
                ),
                items: const [
                  DropdownMenuItem(value: 'Luna', child: Text('Luna')),
                  DropdownMenuItem(value: 'Milo', child: Text('Milo')),
                  DropdownMenuItem(value: 'Pipoca', child: Text('Pipoca')),
                  DropdownMenuItem(value: 'Bela', child: Text('Bela')),
                  DropdownMenuItem(value: 'Nina', child: Text('Nina')),
                ],
                onChanged: (value) => setState(() => _petPreference = value),
                validator: (value) => value == null ? 'Escolha um pet' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Conte um pouco sobre seu dia a dia',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Descreva pelo menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Salvar interesse'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
