class Notice {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? createdBy;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.attachmentUrl,
    this.createdBy,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      attachmentUrl: json['attachment_url'] ?? json['attachmentUrl'],
      createdBy:
          (json['createdBy'] != null && json['createdBy']['full_name'] != null)
          ? json['createdBy']['full_name']
          : json['created_by']?.toString(),
    );
  }
}

class Complaint {
  final String id;
  final String category;
  final String description;
  final String status; // OPEN, IN_PROGRESS, RESOLVED, REJECTED
  final String priority; // LOW, MEDIUM, HIGH
  final String? imagePath;
  final DateTime createdAt;
  final List<ComplaintComment> comments;

  Complaint({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.priority,
    this.imagePath,
    required this.createdAt,
    this.comments = const [],
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id']?.toString() ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'OPEN',
      priority: json['priority'] ?? 'MEDIUM',
      imagePath: json['image_path'] ?? json['imagePath'],
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      comments:
          (json['ComplaintComments'] as List? ??
                  json['comments'] as List? ??
                  [])
              .map((c) => ComplaintComment.fromJson(c))
              .toList(),
    );
  }
}

class ComplaintComment {
  final String id;
  final String message;
  final String userName;
  final DateTime createdAt;

  ComplaintComment({
    required this.id,
    required this.message,
    required this.userName,
    required this.createdAt,
  });

  factory ComplaintComment.fromJson(Map<String, dynamic> json) {
    return ComplaintComment(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      userName: (json['User'] != null && json['User']['full_name'] != null)
          ? json['User']['full_name']
          : (json['userName'] ?? 'Unknown'),
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}
