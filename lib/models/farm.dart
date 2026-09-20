class Farm {
  final String id;
  final String name;
  final String? city;
  final String? state;
  final String role;

  const Farm({
    required this.id,
    required this.name,
    required this.role,
    this.city,
    this.state,
  });

  factory Farm.fromMembership(Map<String, dynamic> row) {
    final farm = Map<String, dynamic>.from(row['farms'] as Map);
    return Farm(
      id: farm['id'].toString(),
      name: (farm['name'] ?? '').toString(),
      city: farm['city']?.toString(),
      state: farm['state']?.toString(),
      role: (row['role'] ?? 'member').toString(),
    );
  }
}
