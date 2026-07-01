import 'package:flutter/material.dart';

import '../../../../core/services/persistence_service.dart';
import '../../data/pet_service.dart';
import '../widgets/pet_card.dart';
import '../../../adoption/presentation/pages/adoption_form_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final PetApiService _apiService = PetApiService();
  final PersistenceService _persistence = PersistenceService();
  final ScrollController _scrollController = ScrollController();

  List<PetItem> _pets = [];
  List<String> _favoriteIds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFavorites();
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _persistence.loadFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = favorites);
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);
    final nextPets = await _apiService.fetchPets(page: _page);
    if (!mounted) return;

    setState(() {
      _pets.addAll(nextPets);
      _page += 1;
      _hasMore = nextPets.isNotEmpty;
      _isLoading = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 220) {
      _loadNextPage();
    }
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
          setState(() {
            _pets = [];
            _page = 1;
            _hasMore = true;
            _isLoading = false;
          });
          await _loadNextPage();
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: _pets.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _pets.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final pet = _pets[index];
            return PetCard(
              pet: pet,
              isFavorite: _favoriteIds.contains(pet.id),
              onFavoritePressed: () => _toggleFavorite(pet),
              onAdoptPressed: () => _openAdoptionForm(pet),
            );
          },
        ),
      ),
    );
  }
}
