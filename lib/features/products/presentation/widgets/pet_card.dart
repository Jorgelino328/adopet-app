import 'package:flutter/material.dart';

import '../../data/pet_service.dart';

class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.pet,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onAdoptPressed,
  });

  final PetItem pet;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onAdoptPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                pet.imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: onFavoritePressed,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${pet.breed} • ${pet.age}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pet.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text(pet.tag)),
                      const Spacer(),
                      Text(
                        pet.price,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onAdoptPressed,
                    icon: const Icon(Icons.pets),
                    label: const Text('Quero adotar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
