import 'package:flutter/material.dart';
import '../../models/pet_item.dart';
import '../../data/pet_service.dart';
import '../../../../core/services/persistence_service.dart';
import '../../../../core/services/auth_service.dart';

class PetsProvider extends ChangeNotifier {
  final PetApiService _apiService = PetApiService();
  final PersistenceService _persistence = PersistenceService();

  List<PetItem> pets = [];
  List<PetItem> filteredPets = [];
  List<String> adoptedPetIds = [];
  bool isLoading = false;
  
  String searchText = '';
  Set<String> selectedFilters = <String>{};
  bool showOnlyFavorites = false;
  String? selectedState;
  String? selectedCity;

  Future<void> initializeData() async {
    isLoading = true;
    notifyListeners();

    try {
      final submissions = await _persistence.loadSubmissions();
      adoptedPetIds = submissions
          .map((s) => s['petId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      pets = await _apiService.fetchPets(page: 1, pageSize: 100);
      
      final user = AuthService.instance.currentUser;
      if (user != null && (user.preferences?.isNotEmpty ?? false)) {
        selectedFilters.addAll(
          UserProfile.parsePreferenceSelections(user.preferences),
        );
      }

      applyFilters();
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters() {
    final normalizedQuery = searchText.trim().toLowerCase();
    final user = AuthService.instance.currentUser;
    final favoriteIds = user != null 
        ? UserProfile.parsePreferenceSelections(user.favorites) 
        : <String>[];

    filteredPets = pets.where((pet) {
      if (adoptedPetIds.contains(pet.id)) return false;

      final matchesSearch = normalizedQuery.isEmpty ||
          [
            pet.name,
            pet.breed,
            pet.description,
            pet.location,
            UserProfile.labelForPreference(pet.type),
          ].join(' ').toLowerCase().contains(normalizedQuery);
      
      final matchesFilter = selectedFilters.isEmpty || selectedFilters.contains(pet.type);

      bool matchesLocation = true;
      if (selectedState != null && selectedCity != null) {
        final expectedLocation = "$selectedCity, $selectedState".toLowerCase();
        matchesLocation = pet.location.toLowerCase() == expectedLocation;
      } else if (selectedState != null) {
        matchesLocation = pet.location.toLowerCase().endsWith(selectedState!.toLowerCase());
      }
      
      final matchesFavorite = !showOnlyFavorites || favoriteIds.contains(pet.id);

      return matchesSearch && matchesFilter && matchesLocation && matchesFavorite;
    }).toList();
    
    notifyListeners();
  }

  void updateSearchText(String text) {
    searchText = text;
    applyFilters();
  }

  void toggleFilter(String type) {
    if (selectedFilters.contains(type)) {
      selectedFilters.remove(type);
    } else {
      selectedFilters.add(type);
    }
    applyFilters();
  }

  void toggleShowOnlyFavorites() {
    showOnlyFavorites = !showOnlyFavorites;
    applyFilters();
  }

  void updateLocation({String? state, String? city}) {
    selectedState = state;
    selectedCity = city;
    applyFilters();
  }

  Future<void> toggleFavorite(PetItem pet) async {
    final user = AuthService.instance.currentUser;
    
    if (user == null) return; 

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
    
    if (showOnlyFavorites) {
      applyFilters();
    } else {
      notifyListeners();
    }
  }

  Future<void> refreshAdoptedPets() async {
    try {
      final submissions = await _persistence.loadSubmissions();
      adoptedPetIds = submissions
          .map((s) => s['petId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      applyFilters();
    } catch (e) {
      debugPrint("Error loading adopted pets: $e");
    }
  }
}