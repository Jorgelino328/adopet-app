import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/persistence_service.dart';
import '../../../adoption/presentation/pages/adoption_form_page.dart';
import '../../data/pet_service.dart';
import '../widgets/pet_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final PersistenceService _persistence = PersistenceService();
  final Set<String> _selectedFilters = <String>{};
  
  List<PetItem> _allPets = [];
  List<String> _favoriteIds = [];

  @override
  void initState() {
    super.initState();
    
    _allPets = PetService.pets;
    _loadFavorites();

    final user = AuthService.instance.currentUser;
    if (user != null && user.preferences.isNotEmpty) {
      _selectedFilters.addAll(
        UserProfile.parsePreferenceSelections(user.preferences),
      );
    }
  }

  Future<void> _loadFavorites() async {
    final favorites = await _persistence.loadFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = favorites);
  }

  Future<void> _toggleFavorite(PetItem pet) async {
    setState(() {
      if (_favoriteIds.contains(pet.id)) {
        _favoriteIds.remove(pet.id);
      } else {
        _favoriteIds.add(pet.id);
      }
    });
    await _persistence.saveFavoriteIds(_favoriteIds);
  }

  void _openAdoptionForm(PetItem pet) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdoptionFormPage(selectedPet: pet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPets = _allPets.where((pet) {
      if (_selectedFilters.isEmpty) {
        return true;
      }
      return _selectedFilters.contains(pet.type);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets para Adoção'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por tipo:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: UserProfile.petPreferenceOptions.map((type) {
                      final isSelected = _selectedFilters.contains(type);
                      return FilterChip(
                        label: Text(UserProfile.labelForPreference(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add(type);
                            } else {
                              _selectedFilters.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredPets.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum pet encontrado com esses filtros.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredPets.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pet = filteredPets[index];
                      return PetCard(
                        pet: pet,
                        isFavorite: _favoriteIds.contains(pet.id),
                        onFavoritePressed: () => _toggleFavorite(pet),
                        onAdoptPressed: () => _openAdoptionForm(pet),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}