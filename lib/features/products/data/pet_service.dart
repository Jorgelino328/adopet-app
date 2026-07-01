class PetItem {
  final String id;
  final String name;
  final String type;
  final String breed;
  final String description;
  final String imageUrl;

  const PetItem({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.description,
    required this.imageUrl,
  });
}

class PetService {
  static final List<PetItem> pets = [
    const PetItem(
      id: '1',
      name: 'Luna',
      type: 'dog',
      breed: 'Labrador Retriever',
      description: 'Luna é uma cachorrinha muito amigável e cheia de energia.',
      imageUrl: 'assets/images/luna.png',
    ),
    const PetItem(
      id: '2',
      name: 'Milo',
      type: 'cat',
      breed: 'Siamês',
      description: 'Milo é muito carinhoso e adora dormir em lugares quentinhos.',
      imageUrl: 'assets/images/milo.png',
    ),
    const PetItem(
      id: '3',
      name: 'Pipoca',
      type: 'bird',
      breed: 'Calopsita',
      description: 'Pipoca canta o dia todo e adora interagir com as pessoas.',
      imageUrl: 'assets/images/pipoca.png',
    ),
    const PetItem(
      id: '4',
      name: 'Bela',
      type: 'dog',
      breed: 'Vira-lata',
      description: 'Bela é muito inteligente, dócil e adora brincar no parque.',
      imageUrl: 'assets/images/bela.png',
    ),
    const PetItem(
      id: '5',
      name: 'Nina',
      type: 'cat',
      breed: 'Persa',
      description: 'Nina é tranquila, peluda e ama um cafuné.',
      imageUrl: 'assets/images/nina.png',
    ),
    const PetItem(
      id: '6',
      name: 'Ligeiro',
      type: 'other',
      breed: 'Tartaruga',
      description: 'Ligeiro é um parceiro para a vida toda e adora passear pelo gramado.',
      imageUrl: 'assets/images/ligeiro.png',
    ),
    const PetItem(
      id: '7',
      name: 'Pernalonga',
      type: 'other',
      breed: 'Coelho',
      description: 'Pernalonga é muito saltitante e adora comer vegetais frescos.',
      imageUrl: 'assets/images/pernalonga.png',
    ),
  ];
}