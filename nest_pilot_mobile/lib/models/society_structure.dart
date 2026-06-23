class HouseStats {
  final int totalHouses;
  final int occupiedHouses;
  final int vacantHouses;
  final int ownerCount;
  final int tenantCount;

  const HouseStats({
    required this.totalHouses,
    required this.occupiedHouses,
    required this.vacantHouses,
    required this.ownerCount,
    required this.tenantCount,
  });

  factory HouseStats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : (int.tryParse(v?.toString() ?? '0') ?? 0);
    return HouseStats(
      totalHouses: toInt(json['total_houses']),
      occupiedHouses: toInt(json['occupied_houses']),
      vacantHouses: toInt(json['vacant_houses']),
      ownerCount: toInt(json['owner_count']),
      tenantCount: toInt(json['tenant_count']),
    );
  }
}

class Society {
  final String id;
  final String name;
  final String address;
  final String? registrationNumber;
  final String societyType;
  final String? city;
  final String? state;
  final String? pincode;
  final String? status;

  Society({
    required this.id,
    required this.name,
    required this.address,
    this.registrationNumber,
    required this.societyType,
    this.city,
    this.state,
    this.pincode,
    this.status,
  });

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      registrationNumber: json['registrationNumber'] ?? json['registration_number'],
      societyType: json['society_type'] ?? json['societyType'] ?? 'APARTMENT',
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      status: json['status']?.toString(),
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

class SuperAdminStats {
  final int totalSocieties;
  final int totalBuildings;
  final int totalFlats;
  final int totalMembers;

  const SuperAdminStats({
    required this.totalSocieties,
    required this.totalBuildings,
    required this.totalFlats,
    required this.totalMembers,
  });

  factory SuperAdminStats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : (int.tryParse(v?.toString() ?? '0') ?? 0);
    return SuperAdminStats(
      totalSocieties: toInt(json['total_societies']),
      totalBuildings: toInt(json['total_buildings']),
      totalFlats: toInt(json['total_flats']),
      totalMembers: toInt(json['total_members']),
    );
  }
}

class DashboardStats {
  final int pendingMembers;
  final int totalResidents;
  final int totalNotices;
  final int totalComplaints;

  const DashboardStats({
    required this.pendingMembers,
    required this.totalResidents,
    required this.totalNotices,
    required this.totalComplaints,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : (int.tryParse(v?.toString() ?? '0') ?? 0);
    return DashboardStats(
      pendingMembers: toInt(json['pending_members']),
      totalResidents: toInt(json['total_residents']),
      totalNotices: toInt(json['total_notices']),
      totalComplaints: toInt(json['total_complaints']),
    );
  }
}

