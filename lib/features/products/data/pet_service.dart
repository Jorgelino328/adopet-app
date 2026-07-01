class PetItem {
  const PetItem({
    required this.id,
    required this.name,
    required this.type, // Replaced tag with type
    required this.breed,
    required this.age,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String type;
  final String breed;
  final String age;
  final String description;
  final String price;
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
        price: 'R\$ 900',
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
        price: 'R\$ 1.100',
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
        price: 'R\$ 450',
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
        price: 'R\$ 1.400',
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
        price: 'R\$ 1.300',
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
        price: 'R\$ 180',
        imageUrl:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p7',
        name: 'Cacau',
        type: 'dog',
        breed: 'Pug',
        age: '2 anos',
        description: 'Muito companheiro e ótimo para apartamentos.',
        price: 'R\$ 950',
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
        price: 'R\$ 1.500',
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
        price: 'R\$ 300',
        imageUrl:
            'https://images.unsplash.com/photo-1437622368342-a8c61e4795e1?auto=format&fit=crop&w=600&q=80',
      ),
      const PetItem(
        id: 'p10',
        name: 'Loro',
        type: 'bird',
        breed: 'Papagaio',
        age: '2 anos',
        description: 'Muito falador e inteligente.',
        price: 'R\$ 2.000',
        imageUrl:
            'https://images.unsplash.com/photo-1518049688176-78e202517804?auto=format&fit=crop&w=600&q=80',
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