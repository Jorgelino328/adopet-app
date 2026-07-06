class PetItem {
  const PetItem({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.description,
    required this.imageUrl,
    required this.sex,        
    required this.temperament, 
    required this.health,
    required this.location,      
  });

  final String id;
  final String name;
  final String type;
  final String breed;
  final String age;
  final String description;
  final String imageUrl;
  final String sex;
  final String temperament;
  final String health;
  final String location;
}