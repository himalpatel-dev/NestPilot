// Location master models — state and district reference data served by
// `/api/locations/*`. Used to populate the cascading dropdowns on the
// Society Create screen.

int _toInt(dynamic v) => v is int ? v : (int.tryParse(v?.toString() ?? '') ?? 0);

class StateModel {
  final int id;
  final String name;
  final String? code;

  const StateModel({required this.id, required this.name, this.code});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
    );
  }
}

class DistrictModel {
  final int id;
  final int stateId;
  final String name;

  const DistrictModel({
    required this.id,
    required this.stateId,
    required this.name,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: _toInt(json['id']),
      stateId: _toInt(json['state_id']),
      name: json['name']?.toString() ?? '',
    );
  }
}
