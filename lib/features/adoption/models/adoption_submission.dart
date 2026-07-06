class AdoptionSubmission {
  final String name;
  final String email;
  final String dob;
  final String contactNumber;
  final String petId;
  final String note;
  final DateTime timestamp;

  AdoptionSubmission({
    required this.name,
    required this.email,
    required this.dob,
    required this.contactNumber,
    required this.petId,
    required this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'dob': dob,
    'contactNumber': contactNumber,
    'petId': petId,
    'note': note,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AdoptionSubmission.fromJson(Map<String, dynamic> json) => AdoptionSubmission(
    name: json['name'],
    email: json['email'],
    dob: json['dob'],
    contactNumber: json['contactNumber'],
    petId: json['petId'],
    note: json['note'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}