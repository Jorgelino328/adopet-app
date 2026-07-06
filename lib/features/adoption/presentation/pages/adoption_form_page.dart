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
    if (currentUser == null) return;
    if (widget.selectedPet == null) return;

    final existingSubmissions = await _persistence.loadSubmissions();
    final alreadyAdopted = existingSubmissions.any((s) => s.petId == widget.selectedPet!.id);

    if (alreadyAdopted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Já solicitado!')));
      return;
    }

    final submission = AdoptionSubmission(
      name: currentUser.name,
      email: currentUser.email,
      dob: currentUser.dob ?? '',
      contactNumber: currentUser.contactNumber ?? '',
      petId: widget.selectedPet!.id,
      note: _noteController.text.trim(),
      timestamp: DateTime.now(),
    );

    await _persistence.saveSubmission(submission);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Adoção')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Conte sobre você'),
              validator: (v) => (v?.length ?? 0) < 10 ? 'Mínimo 10 caracteres' : null,
            ),
            FilledButton(onPressed: _submit, child: const Text('Confirmar')),
          ],
        ),
      ),
    );
  }
}