class Contact {
  final String id;
  final String name;
  final String role;
  final String linkedinUrl;
  final String email;
  final String notes;

  const Contact({
    required this.id,
    required this.name,
    this.role = '',
    this.linkedinUrl = '',
    this.email = '',
    this.notes = '',
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        linkedinUrl: json['linkedinUrl'] as String? ?? '',
        email: json['email'] as String? ?? '',
        notes: (json['notes'] as String?) ?? '',
      );
}
