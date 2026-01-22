class Society {
  final String id;
  final String name;
  final String address;
  final String? registrationNumber;

  Society({
    required this.id,
    required this.name,
    required this.address,
    this.registrationNumber,
  });

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      registrationNumber: json['registrationNumber'],
    );
  }
}

class Building {
  final String id;
  final String name;
  final String societyId;

  Building({required this.id, required this.name, required this.societyId});

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      societyId: json['societyId']?.toString() ?? '',
    );
  }
}

class Flat {
  final String id;
  final String number;
  final String buildingId;
  final String? floor;

  Flat({
    required this.id,
    required this.number,
    required this.buildingId,
    this.floor,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? '',
      buildingId: json['buildingId']?.toString() ?? '',
      floor: json['floor']?.toString(),
    );
  }
}
