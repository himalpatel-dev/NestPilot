class Vehicle {
  final int id;
  final String vehicleNumber;
  final String type; // CAR, BIKE, OTHER
  final String? brand;
  final String? model;
  final String? stickerNumber;
  final bool isActive;

  // Extra fields for Admin
  final String? userName;
  final String? userMobile;
  final String? flatNumber;

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.type,
    this.brand,
    this.model,
    this.stickerNumber,
    required this.isActive,
    this.userName,
    this.userMobile,
    this.flatNumber,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    String? uName;
    String? uMobile;
    String? uFlat;

    if (json['owner'] != null) {
      uName = json['owner']['full_name'];
      uMobile = json['owner']['mobile'];
      // flat_number is not on user directly in backend, so we might skip it or check if we added it to attributes.
      // In last edit I removed flat_number from attributes to be safe.
    } else if (json['User'] != null) {
      uName = json['User']['full_name'];
      uMobile = json['User']['mobile'];
      uFlat = json['User']['flat_number'];
    }

    return Vehicle(
      id: json['id'],
      vehicleNumber: json['vehicle_number'],
      type: json['type'],
      brand: json['brand'],
      model: json['model'],
      stickerNumber: json['sticker_number'],
      isActive: json['is_active'] ?? true,
      userName: uName,
      userMobile: uMobile,
      flatNumber: uFlat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_number': vehicleNumber,
      'type': type,
      'brand': brand,
      'model': model,
      'sticker_number': stickerNumber,
    };
  }
}

class Visitor {
  final int id;
  final String name;
  final String mobile;
  final String? profileImage;
  final String type; // GUEST, DELIVERY, CAB, SERVICE
  final bool frequentVisitor;

  Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    this.profileImage,
    required this.type,
    required this.frequentVisitor,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      profileImage: json['profile_image'],
      type: json['type'],
      frequentVisitor: json['frequent_visitor'] ?? false,
    );
  }
}

class VisitorLog {
  final int id;
  final int visitorId;
  final Visitor? visitor;
  final String? entryTime;
  final String? exitTime;
  final String
  status; // PRE_APPROVED, WAITING_APPROVAL, APPROVED, DENIED, INSIDE, EXITED
  final String? passCode;
  final String? vehicleNumber;
  final String? purpose;

  VisitorLog({
    required this.id,
    required this.visitorId,
    this.visitor,
    this.entryTime,
    this.exitTime,
    required this.status,
    this.passCode,
    this.vehicleNumber,
    this.purpose,
  });

  factory VisitorLog.fromJson(Map<String, dynamic> json) {
    return VisitorLog(
      id: json['id'],
      visitorId: json['visitor_id'],
      visitor: json['Visitor'] != null
          ? Visitor.fromJson(json['Visitor'])
          : null,
      entryTime: json['entry_time'],
      exitTime: json['exit_time'],
      status: json['status'],
      passCode: json['pass_code'],
      vehicleNumber: json['vehicle_number'],
      purpose: json['purpose'],
    );
  }
}

class Amenity {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isPaid;
  final double pricePerHour;
  final String startTime;
  final String endTime;

  Amenity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isPaid,
    required this.pricePerHour,
    required this.startTime,
    required this.endTime,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      isPaid: json['is_paid'] ?? false,
      pricePerHour: (json['price_per_hour'] != null)
          ? double.parse(json['price_per_hour'].toString())
          : 0.0,
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}

class Booking {
  final int id;
  final int amenityId;
  final Amenity? amenity;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final double amount;

  // Extra fields for Admin display
  final String? userName;
  final String? userMobile;

  Booking({
    required this.id,
    required this.amenityId,
    this.amenity,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.amount,
    this.userName,
    this.userMobile,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    String? uName;
    String? uMobile;

    if (json['User'] != null) {
      uName = json['User']['full_name'];
      uMobile = json['User']['mobile'];
    }

    return Booking(
      id: json['id'],
      amenityId: json['amenity_id'],
      amenity: json['Amenity'] != null
          ? Amenity.fromJson(json['Amenity'])
          : null,
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      amount: (json['amount'] != null)
          ? double.parse(json['amount'].toString())
          : 0.0,
      userName: uName,
      userMobile: uMobile,
    );
  }
}

class ServiceStaff {
  final int id;
  final String name;
  final String role;
  final String mobile;
  final String? profileImage;
  final bool isActive;

  ServiceStaff({
    required this.id,
    required this.name,
    required this.role,
    required this.mobile,
    this.profileImage,
    required this.isActive,
  });

  factory ServiceStaff.fromJson(Map<String, dynamic> json) {
    return ServiceStaff(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      mobile: json['mobile'],
      profileImage: json['profile_image'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class StaffAttendance {
  final int id;
  final int staffId;
  final String date;
  final String? inTime;
  final String? outTime;

  StaffAttendance({
    required this.id,
    required this.staffId,
    required this.date,
    this.inTime,
    this.outTime,
  });

  factory StaffAttendance.fromJson(Map<String, dynamic> json) {
    return StaffAttendance(
      id: json['id'],
      staffId: json['staff_id'],
      date: json['date'],
      inTime: json['in_time'],
      outTime: json['out_time'],
    );
  }
}

class Poll {
  final int id;
  final String question;
  final String? description;
  final String endDate;
  final List<PollOption>? options;
  final List<PollVote>? votes;

  Poll({
    required this.id,
    required this.question,
    this.description,
    required this.endDate,
    this.options,
    this.votes,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'],
      question: json['question'],
      description: json['description'],
      endDate: json['end_date'],
      options: json['options'] != null
          ? (json['options'] as List)
                .map((i) => PollOption.fromJson(i))
                .toList()
          : null,
      votes: json['votes'] != null
          ? (json['votes'] as List).map((i) => PollVote.fromJson(i)).toList()
          : null,
    );
  }
}

class PollOption {
  final int id;
  final String optionText;

  PollOption({required this.id, required this.optionText});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(id: json['id'], optionText: json['option_text']);
  }
}

class PollVote {
  final int id;
  final int optionId;
  final int userId;

  PollVote({required this.id, required this.optionId, required this.userId});

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['id'],
      optionId: json['option_id'],
      userId: json['user_id'],
    );
  }
}

class Document {
  final int id;
  final String title;
  final String category;
  final String fileUrl;
  final bool isPrivate;
  final String createdAt;

  Document({
    required this.id,
    required this.title,
    required this.category,
    required this.fileUrl,
    required this.isPrivate,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      fileUrl: json['file_url'],
      isPrivate: json['is_private'] ?? false,
      createdAt: json['created_at'],
    );
  }
}
