import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../adoption/presentation/pages/adoption_form_page.dart';
import '../../data/pet_service.dart';
import '../widgets/pet_card.dart';
import '../../../../core/mixins/setup_dialogue_mixin.dart';
import '../../../../core/mixins/address_mixin.dart';
import 'package:adopet/features/products/presentation/pages/pet_details_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with SetupDialogMixin, AddressMixin {
  final PetApiService _apiService = PetApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PetItem> _pets = [];
  List<PetItem> _filteredPets = [];
  bool _isLoading = false;
  String _searchText = '';
  
  final Set<String> _selectedFilters = <String>{};
  
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowSetupDialog(); 
    });
    
    fetchStates();

    final user = AuthService.instance.currentUser;
    if (user != null) {
      if (user.state != null) {
        selectedState = user.state;
        fetchCities(selectedState!).then((_) {
          if (mounted && user.city != null) {
            setState(() {
              if (cities.any((c) => c['nome'] == user.city)) {
                selectedCity = user.city;
              }
              _filteredPets = _applyFilters(_pets);
            });
          }
        });
      }

      if (user.preferences?.isNotEmpty ?? false) {
        _selectedFilters.addAll(
          UserProfile.parsePreferenceSelections(user.preferences),
        );
      }
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
    
    final user = AuthService.instance.currentUser;
    final favoriteIds = user != null 
        ? UserProfile.parsePreferenceSelections(user.favorites) 
        : <String>[];

    return source.where((pet) {
      final matchesSearch = normalizedQuery.isEmpty ||
          [
            pet.name,
            pet.breed,
            pet.description,
            pet.location,
            UserProfile.labelForPreference(pet.type),
          ].join(' ').toLowerCase().contains(normalizedQuery);
      
      final matchesFilter = _selectedFilters.isEmpty || _selectedFilters.contains(pet.type);

      bool matchesLocation = true;
      if (selectedState != null && selectedCity != null) {
        final expectedLocation = "$selectedCity, $selectedState".toLowerCase();
        matchesLocation = pet.location.toLowerCase() == expectedLocation;
      } else if (selectedState != null) {
        matchesLocation = pet.location.toLowerCase().endsWith(selectedState!.toLowerCase());
      }
      
      final matchesFavorite = !_showOnlyFavorites || favoriteIds.contains(pet.id);

      return matchesSearch && matchesFilter && matchesLocation && matchesFavorite;
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
    
    setState(() {
      if (_showOnlyFavorites) {
        _filteredPets = _applyFilters(_pets);
      }
    });
  }

  void _openAdoptionForm(PetItem pet) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdoptionFormPage(selectedPet: pet),
      ),
    );
  }

  Widget _buildPetTypeChip(String type) {
    final isSelected = _selectedFilters.contains(type);
    return FilterChip(
      labelStyle: const TextStyle(fontSize: 12),
      padding: EdgeInsets.zero,
      label: Center(child: Text(UserProfile.labelForPreference(type))),
      selected: isSelected,
      onSelected: (_) => _toggleFilter(type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final List<String> favoriteIds = currentUser != null 
        ? UserProfile.parsePreferenceSelections(currentUser.favorites) 
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets para adoção'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPets,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nome ou raça',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Faça login!')),
                              );
                              return;
                            }
                            setState(() {
                              _showOnlyFavorites = !_showOnlyFavorites;
                              _filteredPets = _applyFilters(_pets);
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                                color: _showOnlyFavorites ? Colors.red : Colors.grey,
                                size: 24,
                              ),
                              const Text(
                                'Favoritos',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            key: Key('state_${states.length}_$selectedState'),
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'UF', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                            hint: Text(selectedState ?? 'UF'),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('UF')),
                              ...states.map((s) => s['sigla'] as String).toSet().map((sigla) => DropdownMenuItem(value: sigla, child: Text(sigla))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedState = val;
                                selectedCity = null;
                                _filteredPets = _applyFilters(_pets);
                                if (val != null) fetchCities(val); else cities = [];
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: Key('city_${cities.length}_$selectedCity'),
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                            hint: Text(selectedCity ?? 'Cidade'),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('Cidade')),
                              ...cities.map((c) => c['nome'] as String).toSet().map((nome) => DropdownMenuItem(value: nome, child: Text(nome))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedCity = val;
                                _filteredPets = _applyFilters(_pets);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Filtrar por tipo:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
            ),
            
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredPets.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sentiment_very_dissatisfied, size: 64, color: Color(0xFF8E4C32)),
                        const SizedBox(height: 16),
                        Text(
                          _showOnlyFavorites 
                            ? 'Você ainda não possui pets favoritados com esses filtros!'
                            : 'Nenhum pet encontrado! Por favor, ajuste seus filtros e tente novamente.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final pet = _filteredPets[index];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => PetDetailsPage(pet: pet))
                        ),
                        child: PetCard(
                          pet: pet,
                          isFavorite: favoriteIds.contains(pet.id),
                          onFavoritePressed: () => _toggleFavorite(pet),
                          onAdoptPressed: () => _openAdoptionForm(pet),
                        ),
                      );
                    },
                    childCount: _filteredPets.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}