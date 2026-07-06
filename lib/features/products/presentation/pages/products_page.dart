import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../adoption/presentation/pages/adoption_form_page.dart';
import '../../data/pet_service.dart';
import '../widgets/pet_card.dart';
import '../../../../core/mixins/setup_dialogue_mixin.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with SetupDialogMixin {
  final PetApiService _apiService = PetApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PetItem> _pets = [];
  List<PetItem> _filteredPets = [];
  bool _isLoading = false;
  String _searchText = '';
  
  final Set<String> _selectedFilters = <String>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowSetupDialog(); 
    });
    
    final user = AuthService.instance.currentUser;
    if (user != null && (user.preferences?.isNotEmpty ?? false)) {
      _selectedFilters.addAll(
        UserProfile.parsePreferenceSelections(user.preferences),
      );
    }

    _loadPets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
      final matchesSearch = normalizedQuery.isEmpty ||
          [
            pet.name,
            pet.breed,
            pet.description,
            UserProfile.labelForPreference(pet.type),
          ].join(' ').toLowerCase().contains(normalizedQuery);
      
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
    final user = AuthService.instance.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para curtir pets!')),
      );
      return;
    }

    List<String> favs = UserProfile.parsePreferenceSelections(user.favorites);
    
    if (favs.contains(pet.id)) {
      favs.remove(pet.id);
    } else {
      favs.add(pet.id);
    }

    await AuthService.instance.updateProfile(
      name: user.name,
      preferences: user.preferences,
      favorites: UserProfile.serializePreferenceSelections(favs),
    );
    
    setState(() {});
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
    final currentUser = AuthService.instance.currentUser;
    final List<String> favoriteIds = currentUser != null 
        ? UserProfile.parsePreferenceSelections(currentUser.favorites) 
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text('Pets para adoção')),
      body: RefreshIndicator(
        onRefresh: _loadPets,
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
                          isFavorite: favoriteIds.contains(pet.id),
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