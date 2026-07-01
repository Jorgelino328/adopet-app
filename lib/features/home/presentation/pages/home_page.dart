import 'package:flutter/material.dart';

import '../../../../core/services/persistence_service.dart';
import '../../../products/presentation/pages/products_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PersistenceService _persistence = PersistenceService();
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final data = await _persistence.loadSubmissions();
    if (!mounted) return;
    setState(() => _submissions = data);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AdoPet')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encontre seu novo melhor amigo',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Animais com perfil, carinho e dados de adoção salvos no seu dispositivo.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const ProductsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.pets),
                      label: const Text('Ver pets disponíveis'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Últimas adoções salvas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_submissions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Ainda não há adoções registradas. Envie o formulário para salvar o histórico.',
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _submissions.length > 3 ? 3 : _submissions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final submission =
                        _submissions[_submissions.length - 1 - index];
                    final name = submission['name'] as String? ?? 'Cliente';
                    final pet = submission['petPreference'] as String? ?? 'Pet';
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.favorite),
                        ),
                        title: Text(name),
                        subtitle: Text('Preferência: $pet'),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
