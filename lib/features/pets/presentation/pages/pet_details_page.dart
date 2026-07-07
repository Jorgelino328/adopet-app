import 'package:flutter/material.dart';
import '../../models/pet_item.dart';

class PetDetailsPage extends StatelessWidget {
  const PetDetailsPage({
      super.key, 
      required this.pet, 
      this.isAdopted = false, 
      this.onAdoptPressed,
    });
    
  final PetItem pet;
  final bool isAdopted; 
  final VoidCallback? onAdoptPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              pet.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                );
              },
            ),
            
            Transform.translate(
              offset: const Offset(0, -30),
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white, 
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              // Using theme colors instead of hardcoded hex!
                              color: Theme.of(context).colorScheme.primary, 
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pet.sex} • ${pet.breed} • ${pet.age}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            pet.location,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(context, 'Sobre', pet.description),
                      _buildSection(context, 'Temperamento', pet.temperament),
                      _buildSection(context, 'Saúde', pet.health),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: isAdopted ? null : onAdoptPressed, 
                          icon: const Icon(Icons.pets),
                          label: const Text('Quero adotar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
      );
}