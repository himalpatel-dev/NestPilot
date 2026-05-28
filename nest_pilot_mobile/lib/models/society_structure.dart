class Society {
  final String id;
  final String name;
  final String address;
  final String? registrationNumber;
  final String societyType;

  Society({
    required this.id,
    required this.name,
    required this.address,
    this.registrationNumber,
    required this.societyType,
  });

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      registrationNumber: json['registrationNumber'] ?? json['registration_number'],
      societyType: json['society_type'] ?? json['societyType'] ?? 'APARTMENT',
    );
  }
}

class Building {
  final String id;
  final String name;
  final String societyId;
  final String? blocks;
  final String? wings;
  final int floorsCount;

  Building({
    required this.id,
    required this.name,
    required this.societyId,
    this.blocks,
    this.wings,
    required this.floorsCount,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      societyId: json['society_id']?.toString() ?? json['societyId']?.toString() ?? '',
      blocks: json['blocks']?.toString(),
      wings: json['wings']?.toString(),
      floorsCount: json['floors_count'] is int
          ? json['floors_count']
          : (int.tryParse(json['floors_count']?.toString() ?? '0') ?? 0),
    );
  }
}

class Flat {
  final String id;
  final String number;
  final String buildingId;
  final String? floor;
  final String? wing;
  final String unitType;
  final String? areaSqft;

  Flat({
    required this.id,
    required this.number,
    required this.buildingId,
    this.floor,
    this.wing,
    required this.unitType,
    this.areaSqft,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json['id']?.toString() ?? '',
      number: json['house_no']?.toString() ?? json['number']?.toString() ?? '',
      buildingId: json['building_id']?.toString() ?? json['buildingId']?.toString() ?? '',
      floor: json['floor_no']?.toString() ?? json['floor']?.toString(),
      wing: json['wing']?.toString(),
      unitType: json['unit_type'] ?? 'FLAT',
      areaSqft: json['area_sqft']?.toString(),
    );
  }
}

