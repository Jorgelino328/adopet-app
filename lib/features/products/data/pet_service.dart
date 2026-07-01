class PetItem {
  const PetItem({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String type;
  final String breed;
  final String age;
  final String description;
  final String imageUrl;
}

class PetApiService {
  Future<List<PetItem>> fetchPets({required int page, int pageSize = 10}) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final allPets = <PetItem>[
      const PetItem(
        id: 'p1',
        name: 'Luna',
        type: 'dog',
        breed: 'Lhasa Apso',
        age: '2 anos',
        description: 'Muito dócil e pronta para interagir com crianças.',
        imageUrl:
            'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p2',
        name: 'Milo',
        type: 'cat',
        breed: 'Siamês',
        age: '1 ano',
        description: 'Aventureiro e cheio de energia para brincar.',
        imageUrl:
            'https://images.unsplash.com/photo-1511044568932-338cba0ad803?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p3',
        name: 'Pipoca',
        type: 'bird',
        breed: 'Calopsita',
        age: '6 meses',
        description: 'Cantora e muito curiosa.',
        imageUrl:
            'https://images.unsplash.com/photo-1444464666168-49d633b86797?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p4',
        name: 'Bela',
        type: 'dog',
        breed: 'Golden Retriever',
        age: '3 anos',
        description: 'Ideal para famílias com espaço para correr.',
        imageUrl:
            'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p5',
        name: 'Nina',
        type: 'cat',
        breed: 'British Shorthair',
        age: '4 anos',
        description: 'Calma, carinhosa e bem independente.',
        imageUrl:
            'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p6',
        name: 'Tico',
        type: 'other',
        breed: 'Hamster Sírio',
        age: '8 meses',
        description: 'Pequeno e muito ativo à noite.',
        imageUrl:
            'https://images.unsplash.com/photo-1425082661705-1834bfd09dca?q=80&w=1476&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
      const PetItem(
        id: 'p7',
        name: 'Cacau',
        type: 'dog',
        breed: 'Pug',
        age: '2 anos',
        description: 'Muito companheiro e ótimo para apartamentos.',
        imageUrl:
            'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p8',
        name: 'Kiara',
        type: 'cat',
        breed: 'Gato Persa',
        age: '5 anos',
        description: 'Elegante e tranquila, ótima para ambientes serenos.',
        imageUrl:
            'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p9',
        name: 'Ligeiro',
        type: 'other',
        breed: 'Tartaruga',
        age: '10 anos',
        description: 'Tranquilo e adora passear no gramado.',
        imageUrl:
            'https://plus.unsplash.com/premium_photo-1724311824020-d5aa35632c81?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
      const PetItem(
        id: 'p10',
        name: 'Loro',
        type: 'bird',
        breed: 'Papagaio',
        age: '2 anos',
        description: 'Muito falador e inteligente.',
        imageUrl:
            'https://images.unsplash.com/photo-1552728089-57bdde30beb3?q=80&w=725&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
    ];

    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    if (start >= allPets.length) {
      return <PetItem>[];
    }

    return allPets.sublist(start, end > allPets.length ? allPets.length : end);
  }
}