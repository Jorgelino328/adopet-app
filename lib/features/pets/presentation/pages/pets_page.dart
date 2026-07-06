import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/persistence_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../adoption/presentation/pages/adoption_form_page.dart';
import '../../data/pet_service.dart';
import '../widgets/pet_card.dart';
import '../../../../core/mixins/setup_dialogue_mixin.dart';
import '../../../../core/mixins/address_mixin.dart';
import 'package:adopet/features/pets/presentation/pages/pet_details_page.dart';
import '../../models/pet_item.dart';
import '../providers/pets_provider.dart';
import 'package:adopet/features/profile/models/user_profile.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> with SetupDialogMixin, AddressMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowSetupDialog(); 
    });
    
    fetchStates();  

    final user = AuthService.instance.currentUser;
    if (user != null && user.state != null) {
      selectedState = user.state;
      fetchCities(selectedState!).then((_) {
        if (mounted && user.city != null) {
          setState(() {
            if (cities.any((c) => c['nome'] == user.city)) {
              selectedCity = user.city;
            }
          });

          context.read<PetsProvider>().updateLocation(
            state: selectedState, 
            city: selectedCity
          );
        }
      });
    }
  }
    
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openAdoptionForm(PetItem pet) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdoptionFormPage(selectedPet: pet),
      ),
    );
    if (mounted) {
      context.read<PetsProvider>().refreshAdoptedPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetsProvider>();
    final currentUser = AuthService.instance.currentUser;
    
    final List<String> favoriteIds = currentUser != null 
        ? UserProfile.parsePreferenceSelections(currentUser.favorites) 
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets para adoção'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PetsProvider>().initializeData(),
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
                            onChanged: (value) {
                              provider.updateSearchText(value);
                              _scrollToTop();
                            },
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
                            provider.toggleShowOnlyFavorites();
                            _scrollToTop();
                          },
                          
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                                  color: provider.showOnlyFavorites ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                                const Text(
                                  'Favoritos',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
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
                            hint: Text(selectedState ?? '--'),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('--')),
                              ...states.map((s) => s['sigla'] as String).toSet().map((sigla) => DropdownMenuItem(value: sigla, child: Text(sigla))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedState = val;
                                selectedCity = null;
                                if (val != null) {
                                  fetchCities(val);
                                } else {
                                  cities = [];
                                }
                              });
                              provider.updateLocation(state: val, city: null);
                              _scrollToTop();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: Key('city_${cities.length}_$selectedCity'),
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                            hint: Text(selectedCity ?? '---'),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('---')),
                              ...cities.map((c) => c['nome'] as String).toSet().map((nome) => DropdownMenuItem(value: nome, child: Text(nome))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedCity = val;
                              });
                              provider.updateLocation(state: selectedState, city: val);
                              _scrollToTop();
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
                        final isSelected = provider.selectedFilters.contains(type);
                        return FilterChip(
                          label: Text(UserProfile.labelForPreference(type)),
                          selected: isSelected,
                          onSelected: (_) {
                            provider.toggleFilter(type);
                            _scrollToTop();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.filteredPets.isEmpty)
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
                          provider.showOnlyFavorites 
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
                      final pet = provider.filteredPets[index];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => PetDetailsPage(pet: pet))
                        ),
                        child: PetCard(
                          pet: pet,
                          isFavorite: favoriteIds.contains(pet.id),
                          onFavoritePressed: () {
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Faça login para curtir pets!')),
                              );
                              return;
                            }
                            provider.toggleFavorite(pet);
                          },
                          onAdoptPressed: provider.adoptedPetIds.contains(pet.id)
                              ? null
                              : () => _openAdoptionForm(pet),
                        ),
                      );
                    },
                    childCount: provider.filteredPets.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}