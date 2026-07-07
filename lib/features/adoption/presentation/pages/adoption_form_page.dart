import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/persistence_service.dart';
import '../../../pets/data/pet_service.dart';
import '../../models/adoption_submission.dart';
import '../../../pets/models/pet_item.dart';

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

    if (widget.selectedPet == null) return;

    final existingSubmissions = await _persistence.loadSubmissions();
    // Using object notation .petId instead of ['petId']
    final alreadyAdopted = existingSubmissions.any((s) => s.petId == widget.selectedPet!.id);

    if (alreadyAdopted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já solicitou a adoção deste pet!')),
      );
      return;
    }
    
    if (currentUser.dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete seu perfil e informe pelo menos sua data de nascimento para adotar.')),
      );
      return;
    }

    if (!currentUser.isOver18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve ter pelo menos 18 anos para adotar.')),
      );
      return;
    }

    // Using the strongly typed AdoptionSubmission object
    final submission = AdoptionSubmission(
      name: currentUser.name,
      email: currentUser.email,
      dob: currentUser.dob!,
      contactNumber: currentUser.contactNumber!,
      petId: widget.selectedPet!.id,
      note: _noteController.text.trim(),
      timestamp: DateTime.now(),
    );

    await _persistence.saveSubmission(submission);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interesse registrado com sucesso!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Restored your original UI
    final petName = widget.selectedPet?.name ?? 'Pet não selecionado';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Adoção')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quase lá!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Você está solicitando a adoção de: '),
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.pets, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(petName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Conte um pouco sobre você.',
                  hintText: 'Escreva por que você quer adotar...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().length < 10) 
                    ? 'Descreva pelo menos 10 caracteres' 
                    : null,
              ),
              const SizedBox(height: 24),
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