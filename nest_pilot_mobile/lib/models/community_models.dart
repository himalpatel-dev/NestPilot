class Vehicle {
  final int id;
  final int userId;
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
    required this.userId,
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
      // The vehicle API flattens the owner's current flat ("A-2") in here.
      uFlat = json['owner']['flat_number'];
    } else if (json['User'] != null) {
      uName = json['User']['full_name'];
      uMobile = json['User']['mobile'];
      uFlat = json['User']['flat_number'];
    }

    return Vehicle(
      id: json['id'],
      userId: json['user_id'],
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

  /// Dash-separated for display only, e.g. GJ01AB1234 -> GJ-01-AB-1234 — a
  /// dash is inserted at every letter/digit transition. [vehicleNumber]
  /// itself (what's stored and sent to the backend) is never touched.
  String get displayNumber {
    final clean = vehicleNumber
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (clean.isEmpty) return clean;

    final buffer = StringBuffer(clean[0]);
    for (int i = 1; i < clean.length; i++) {
      final prevIsDigit = int.tryParse(clean[i - 1]) != null;
      final curIsDigit = int.tryParse(clean[i]) != null;
      if (prevIsDigit != curIsDigit) buffer.write('-');
      buffer.write(clean[i]);
    }
    return buffer.toString();
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

/// One purchasable period of a MEMBERSHIP amenity, e.g. "Monthly" = 1 MONTH.
class AmenityPlan {
  final int id;
  final String name;
  final int durationValue;

  /// DAY | MONTH | YEAR
  final String durationUnit;
  final double price;

  const AmenityPlan({
    required this.id,
    required this.name,
    required this.durationValue,
    required this.durationUnit,
    required this.price,
  });

  factory AmenityPlan.fromJson(Map<String, dynamic> json) {
    return AmenityPlan(
      id: json['id'],
      name: (json['name'] ?? '').toString(),
      durationValue: int.tryParse('${json['duration_value']}') ?? 1,
      durationUnit: (json['duration_unit'] ?? 'MONTH').toString(),
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
    );
  }

  /// "1 month", "3 months", "1 year", "7 days".
  String get durationLabel {
    final word = switch (durationUnit) {
      'DAY' => 'day',
      'YEAR' => 'year',
      _ => 'month',
    };
    return '$durationValue $word${durationValue == 1 ? '' : 's'}';
  }

  /// Whole months covered, or null for day-based plans.
  int? get months => switch (durationUnit) {
    'MONTH' => durationValue,
    'YEAR' => durationValue * 12,
    _ => null,
  };

  /// Last day (inclusive) of a membership starting on [start]. Mirrors the
  /// server's membershipEnd, so the dates shown are the dates saved: a month
  /// runs to the day before the same date next month (16 Nov → 15 Dec), or
  /// to the month's last day when that date doesn't exist (31 Jan → 28 Feb).
  DateTime endDateFor(DateTime start) {
    if (durationUnit == 'DAY') {
      return DateTime(start.year, start.month, start.day + durationValue - 1);
    }
    final monthIndex = (start.month - 1) + months!;
    final year = start.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (start.day > daysInMonth) return DateTime(year, month, daysInMonth);
    return DateTime(year, month, start.day - 1);
  }
}

/// SLOT = fixed hourly slots within a daily window (courts, party room).
/// FULL_DAY = booked for whole date(s) as needed (banquet hall, common plot).
/// MEMBERSHIP = shared facility used on a pass for a period (gym, pool) —
/// residents buy one of [plans]; nothing is reserved.
class Amenity {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isPaid;
  final String bookingType;
  final double pricePerHour;
  final double pricePerDay;

  /// SLOT: booking window. MEMBERSHIP: opening hours (shown only).
  final String? startTime;
  final String? endTime;

  /// MEMBERSHIP only.
  final List<AmenityPlan> plans;
  final int? maxMembers;
  final int activeMembers;

  bool get isFullDay => bookingType == 'FULL_DAY';
  bool get isMembership => bookingType == 'MEMBERSHIP';

  /// Cheapest plan price — the "From ₹…" figure.
  double? get lowestPlanPrice => plans.isEmpty
      ? null
      : plans.map((p) => p.price).reduce((a, b) => a < b ? a : b);

  Amenity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isPaid,
    this.bookingType = 'SLOT',
    required this.pricePerHour,
    this.pricePerDay = 0.0,
    this.startTime,
    this.endTime,
    this.plans = const [],
    this.maxMembers,
    this.activeMembers = 0,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      isPaid: json['is_paid'] ?? false,
      bookingType: json['booking_type'] ?? 'SLOT',
      pricePerHour: (json['price_per_hour'] != null)
          ? double.parse(json['price_per_hour'].toString())
          : 0.0,
      pricePerDay: (json['price_per_day'] != null)
          ? double.parse(json['price_per_day'].toString())
          : 0.0,
      startTime: json['start_time'],
      endTime: json['end_time'],
      plans: (json['plans'] as List? ?? [])
          .map((p) => AmenityPlan.fromJson(p as Map<String, dynamic>))
          .toList(),
      maxMembers: json['max_members'] as int?,
      activeMembers: json['active_members'] as int? ?? 0,
    );
  }
}

class Booking {
  final int id;
  final int amenityId;
  final Amenity? amenity;

  /// Start date; for a membership, the first day it's valid.
  final String date;

  /// Whole-day bookings and memberships: last day covered (inclusive).
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String status;
  final double amount;

  /// MEMBERSHIP bookings only — the plan bought (name kept as a snapshot).
  final int? planId;
  final String? planName;

  /// PENDING | PAID | NOT_APPLICABLE
  final String? paymentStatus;

  /// When the resident sent the request (ISO timestamp, UTC).
  final String? createdAt;

  // Extra fields for Admin display
  final String? userName;
  final String? userMobile;

  bool get isMembership => planId != null;
  bool get isFullDay => startTime == null;

  Booking({
    required this.id,
    required this.amenityId,
    this.amenity,
    required this.date,
    this.endDate,
    this.startTime,
    this.endTime,
    required this.status,
    required this.amount,
    this.planId,
    this.planName,
    this.paymentStatus,
    this.createdAt,
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
      endDate: json['end_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      amount: (json['amount'] != null)
          ? double.parse(json['amount'].toString())
          : 0.0,
      planId: json['plan_id'] as int?,
      planName: json['plan_name'] as String?,
      paymentStatus: json['payment_status'] as String?,
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString(),
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
