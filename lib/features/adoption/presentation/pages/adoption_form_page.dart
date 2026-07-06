import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
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
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = AuthService.instance.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para adotar.')),
      );
      return;
    }

    if (currentUser.dob == null || currentUser.contactNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete seu perfil (data de nascimento e telefone) para adotar.')),
      );
      return;
    }

    if (!currentUser.isOver18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve ter pelo menos 18 anos para adotar.')),
      );
      return;
    }

    final submission = {
      'name': currentUser.name,
      'email': currentUser.email,
      'dob': currentUser.dob,
      'contactNumber': currentUser.contactNumber,
      'petPreference': _petPreference ?? 'Preferência não informada',
      'note': _noteController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _persistence.saveSubmission(submission);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interesse registrado com sucesso!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPetName = widget.selectedPet?.name ?? 'Seu futuro pet';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Adoção')),
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
                'Confirme seu interesse em $selectedPetName. Seus dados (nome, e-mail, data de nascimento e telefone) serão enviados automaticamente a partir do seu perfil.',
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _petPreference,
                decoration: const InputDecoration(labelText: 'Pet de interesse'),
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
                  labelText: 'Conte um pouco sobre você.',
                  hintText: 'Escreva por que você quer adotar...',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Descreva pelo menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Nossos especialistas entrarão em contato com você em breve.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Confirmar Adoção'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}