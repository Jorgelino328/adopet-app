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
  final PetApiService _apiService = PetApiService();
  final PersistenceService _persistence = PersistenceService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PetItem> _pets = [];
  List<PetItem> _filteredPets = [];
  List<String> _favoriteIds = [];
  bool _isLoading = false;
  String _searchText = '';
  
  final Set<String> _selectedFilters = <String>{};

  @override
  void initState() {
    super.initState();
    
    // Pre-select user preferences
    final user = AuthService.instance.currentUser;
    if (user != null && user.preferences.isNotEmpty) {
      _selectedFilters.addAll(
        UserProfile.parsePreferenceSelections(user.preferences),
      );
    }

    _loadFavorites();
    _loadPets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _persistence.loadFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = favorites);
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    final loadedPets = await _apiService.fetchPets(page: 1, pageSize: 100);
    if (!mounted) return;

    setState(() {
      _pets = loadedPets;
      _filteredPets = _applyFilters(loadedPets);
      _isLoading = false;
    });
  }

  List<PetItem> _applyFilters(List<PetItem> source) {
    final normalizedQuery = _searchText.trim().toLowerCase();

    return source.where((pet) {
      // 1. Check if matches search text
      final matchesSearch = normalizedQuery.isEmpty ||
          [
            pet.name,
            pet.breed,
            pet.description,
            UserProfile.labelForPreference(pet.type),
          ].join(' ').toLowerCase().contains(normalizedQuery);
      
      // 2. Check if matches selected filters (If empty, show all)
      final matchesFilter = _selectedFilters.isEmpty || _selectedFilters.contains(pet.type);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
      _filteredPets = _applyFilters(_pets);
    });
  }

  void _toggleFilter(String type) {
    setState(() {
      if (_selectedFilters.contains(type)) {
        _selectedFilters.remove(type);
      } else {
        _selectedFilters.add(type);
      }
      _filteredPets = _applyFilters(_pets);
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pets para adoção')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFavorites();
          await _loadPets();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome, raça ou descrição',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Filtrar por tipo:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: UserProfile.petPreferenceOptions.map((type) {
                      final isSelected = _selectedFilters.contains(type);
                      return FilterChip(
                        label: Text(UserProfile.labelForPreference(type)),
                        selected: isSelected,
                        onSelected: (_) => _toggleFilter(type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPets.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhum pet corresponde à sua busca/filtro.'),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _filteredPets.length,
                      itemBuilder: (context, index) {
                        final pet = _filteredPets[index];
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
      ),
    );
  }
}