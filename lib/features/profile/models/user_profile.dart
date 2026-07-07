class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.dob,
    this.contactNumber,
    this.cep,
    this.city,
    this.state,
    this.preferences,
    this.favorites = '',
    required this.createdAt,
  });

  static const petPreferenceOptions = ['dog', 'cat', 'bird', 'other'];

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String? dob;
  final String? contactNumber;
  final String? cep;
  final String? city;
  final String? state;
  final String? preferences;
  final String? favorites;
  final DateTime createdAt;

  bool get isOver18 {
    if (dob == null) return false;
    
    final birthDate = DateTime.tryParse(dob!);
    if (birthDate == null) return false;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age >= 18;
  }

  bool get isSetupComplete {
    return dob != null && 
          contactNumber != null && contactNumber!.isNotEmpty &&
          cep != null && cep!.isNotEmpty &&
          city != null && city!.isNotEmpty &&
          state != null && state!.isNotEmpty;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      dob: json['dob'] as String?,
      contactNumber: json['contact_number'] as String?,
      cep: json['cep'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      preferences: (json['preferences'] == null || json['preferences'] == '') 
          ? null 
          : json['preferences'] as String,
      favorites: json['favorites'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'dob': dob,
      'contact_number': contactNumber,
      'cep': cep,
      'city': city,
      'state': state,
      'preferences': preferences ?? '',
      'favorites': favorites,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<String> parsePreferenceSelections(String? preferences) {
    if (preferences == null || preferences.isEmpty) return [];
    return preferences
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static String serializePreferenceSelections(List<String> selections) {
    return selections
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .join(',');
  }

  static String labelForPreference(String value) {
    switch (value.toLowerCase()) {
      case 'dog': return 'Cachorro';
      case 'cat': return 'Gato';
      case 'bird': return 'Pássaro';
      case 'other':
      default: return 'Outro';
    }
  }
}
