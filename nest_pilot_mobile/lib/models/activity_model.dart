class ActivityModel {
  final int id;
  final String action;
  final String? entityType;
  final String? entityId;
  final String message;
  final String? actor;
  final DateTime? createdAt;

  ActivityModel({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.actor,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] ?? json['createdAt'];
    DateTime? created;
    if (createdRaw is DateTime) {
      created = createdRaw;
    } else if (createdRaw != null) {
      created = DateTime.tryParse(createdRaw.toString());
    }
    return ActivityModel(
      id: (json['id'] as num).toInt(),
      action: (json['action'] ?? '').toString(),
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id']?.toString(),
      message: (json['message'] ?? '').toString(),
      actor: json['actor']?.toString(),
      createdAt: created,
    );
  }
}
