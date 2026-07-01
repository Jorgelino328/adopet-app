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
  final Set<String> _activePreferenceFilters = <String>{};

  @override
  void initState() {
    super.initState();
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

  List<String> get _savedPreferences {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return <String>[];
    }
    return UserProfile.parsePreferenceSelections(user.preferences);
  }

  List<PetItem> _applyFilters(List<PetItem> source) {
    final normalizedQuery = _searchText.trim().toLowerCase();
    final activeFilters = _activePreferenceFilters.isEmpty
        ? _savedPreferences.toSet()
        : _activePreferenceFilters;

    return source.where((pet) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          [
            pet.name,
            pet.breed,
            pet.description,
            pet.tag,
          ].join(' ').toLowerCase().contains(normalizedQuery);
      final matchesPreference =
          activeFilters.isEmpty ||
          activeFilters.any(
            (preference) => _petMatchesPreference(pet, preference),
          );
      return matchesSearch && matchesPreference;
    }).toList();
  }

  bool _petMatchesPreference(PetItem pet, String preference) {
    final normalized = preference.toLowerCase();
    final lowerTag = pet.tag.toLowerCase();
    switch (normalized) {
      case 'dog':
        return lowerTag.contains('cão') ||
            lowerTag.contains('cao') ||
            lowerTag.contains('cachorro');
      case 'cat':
        return lowerTag.contains('gato');
      case 'bird':
        return lowerTag.contains('pássaro') || lowerTag.contains('passaro');
      case 'other':
      default:
        return lowerTag.contains('pequeno') || lowerTag.contains('pet');
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
      _filteredPets = _applyFilters(_pets);
    });
  }

  void _togglePreferenceFilter(String preference) {
    setState(() {
      if (_activePreferenceFilters.contains(preference)) {
        _activePreferenceFilters.remove(preference);
      } else {
        _activePreferenceFilters.add(preference);
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
    final savedPreferences = _savedPreferences;
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
                  if (savedPreferences.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Filtrando por suas preferências salvas',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: savedPreferences.map((preference) {
                        final isSelected =
                            _activePreferenceFilters.contains(preference) ||
                            _activePreferenceFilters.isEmpty;
                        return FilterChip(
                          label: Text(
                            UserProfile.labelForPreference(preference),
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              _togglePreferenceFilter(preference),
                        );
                      }).toList(),
                    ),
                  ],
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
                        child: Text('Nenhum pet corresponde à sua busca.'),
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
