class Bill {
  final String id;
  final String title;
  final String? description;
  final double amountTotal;
  final DateTime dueDate;
  final String status; // DRAFT, PUBLISHED, CANCELLED
  final String billType; // MAINTENANCE, SPECIAL
  final String applyTo; // ALL, SELECTED
  final String? penaltyType; // FIXED, PERCENT
  final double penaltyValue;
  final DateTime? createdAt;

  Bill({
    required this.id,
    required this.title,
    this.description,
    required this.amountTotal,
    required this.dueDate,
    required this.status,
    required this.billType,
    this.applyTo = 'ALL',
    this.penaltyType,
    this.penaltyValue = 0,
    this.createdAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      amountTotal: double.parse(
        (json['amount_total'] ?? json['amountTotal'] ?? '0').toString(),
      ),
      dueDate: DateTime.parse(
        json['due_date'] ?? json['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'DRAFT',
      billType: json['bill_type'] ?? json['billType'] ?? 'MAINTENANCE',
      applyTo: json['apply_to'] ?? json['applyTo'] ?? 'ALL',
      penaltyType: json['penalty_type'] ?? json['penaltyType'],
      penaltyValue:
          double.tryParse(
            (json['penalty_value'] ?? json['penaltyValue'] ?? '0').toString(),
          ) ??
          0,
      createdAt: DateTime.tryParse(
        (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      ),
    );
  }
}

class MemberBill {
  final String id;
  final String billId;
  final String? billTitle;
  final double amount;
  final double penaltyAmount;
  final DateTime dueDate;
  final String status; // PENDING, PARTIAL, PAID, OVERDUE

  MemberBill({
    required this.id,
    required this.billId,
    this.billTitle,
    required this.amount,
    required this.penaltyAmount,
    required this.dueDate,
    required this.status,
  });

  factory MemberBill.fromJson(Map<String, dynamic> json) {
    return MemberBill(
      id: json['id']?.toString() ?? '',
      billId: json['bill_id']?.toString() ?? json['billId']?.toString() ?? '',
      billTitle: json['bill'] != null
          ? json['bill']['title']
          : (json['Bill'] != null ? json['Bill']['title'] : null),
      amount: double.parse((json['amount'] ?? '0').toString()),
      penaltyAmount: double.parse(
        (json['penalty_amount'] ?? json['penaltyAmount'] ?? '0').toString(),
      ),
      dueDate: DateTime.parse(
        json['due_date'] ?? json['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'PENDING',
    );
  }
}

class DashboardPayment {
  final String id;
  final double amount;
  final String paymentMode;
  final DateTime paymentDate;
  final String? memberName;
  final String? flatNo;

  DashboardPayment({
    required this.id,
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
    this.memberName,
    this.flatNo,
  });

  factory DashboardPayment.fromJson(Map<String, dynamic> json) {
    return DashboardPayment(
      id: json['id']?.toString() ?? '',
      amount: double.parse((json['amount'] ?? '0').toString()),
      paymentMode: json['payment_mode'] ?? json['paymentMode'] ?? 'CASH',
      paymentDate:
          DateTime.tryParse(
            json['payment_date'] ?? json['paymentDate'] ?? '',
          ) ??
          DateTime.now(),
      memberName: json['member_name'] ?? json['memberName'],
      flatNo: json['flat_no'] ?? json['flatNo'],
    );
  }
}

class BillDashboardStats {
  final double totalCollected;
  final double totalPending;
  final int pendingBillsCount;

  BillDashboardStats({
    required this.totalCollected,
    required this.totalPending,
    required this.pendingBillsCount,
  });

  factory BillDashboardStats.fromJson(Map<String, dynamic> json) {
    return BillDashboardStats(
      totalCollected: double.parse(
        (json['total_collected'] ?? json['totalCollected'] ?? '0').toString(),
      ),
      totalPending: double.parse(
        (json['total_pending'] ?? json['totalPending'] ?? '0').toString(),
      ),
      pendingBillsCount:
          int.tryParse(
            (json['pending_bills_count'] ?? json['pendingBillsCount'] ?? '0')
                .toString(),
          ) ??
          0,
    );
  }

  factory BillDashboardStats.empty() => BillDashboardStats(
    totalCollected: 0,
    totalPending: 0,
    pendingBillsCount: 0,
  );
}

/// One member still owing on a particular bill.
class PendingMember {
  final String? memberName;
  final String? flatNo;
  final double amount;
  final String status;

  PendingMember({
    this.memberName,
    this.flatNo,
    required this.amount,
    required this.status,
  });

  factory PendingMember.fromJson(Map<String, dynamic> json) {
    return PendingMember(
      memberName: json['member_name'] ?? json['memberName'],
      flatNo: json['flat_no'] ?? json['flatNo'],
      amount: double.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      status: json['status'] ?? 'PENDING',
    );
  }
}

/// Bill-wise pending report — one published bill with the members who have
/// not paid it yet. The amounts across all entries add up to the society's
/// total pending dues.
class PendingBillReport {
  final String billId;
  final String title;
  final String billType;
  final DateTime? dueDate;
  final int pendingCount;
  final double pendingAmount;
  final int paidCount;
  final double paidAmount;

  /// Everyone the bill was raised on — paid and unpaid alike.
  final List<PendingMember> members;

  PendingBillReport({
    required this.billId,
    required this.title,
    required this.billType,
    this.dueDate,
    required this.pendingCount,
    required this.pendingAmount,
    this.paidCount = 0,
    this.paidAmount = 0,
    this.members = const [],
  });

  int get totalCount => pendingCount + paidCount;

  factory PendingBillReport.fromJson(Map<String, dynamic> json) {
    return PendingBillReport(
      billId: (json['bill_id'] ?? json['billId'] ?? '').toString(),
      title: json['title'] ?? 'Bill',
      billType: json['bill_type'] ?? json['billType'] ?? '',
      dueDate: DateTime.tryParse(
        (json['due_date'] ?? json['dueDate'] ?? '').toString(),
      ),
      pendingCount:
          int.tryParse(
            (json['pending_count'] ?? json['pendingCount'] ?? '0').toString(),
          ) ??
          0,
      pendingAmount:
          double.tryParse(
            (json['pending_amount'] ?? json['pendingAmount'] ?? '0').toString(),
          ) ??
          0,
      paidCount:
          int.tryParse(
            (json['paid_count'] ?? json['paidCount'] ?? '0').toString(),
          ) ??
          0,
      paidAmount:
          double.tryParse(
            (json['paid_amount'] ?? json['paidAmount'] ?? '0').toString(),
          ) ??
          0,
      members: ((json['members']) as List? ?? [])
          .map((m) => PendingMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BillsDashboardData {
  final BillDashboardStats stats;
  final List<DashboardPayment> recentPayments;
  final List<PendingBillReport> pendingByBill;

  BillsDashboardData({
    required this.stats,
    required this.recentPayments,
    this.pendingByBill = const [],
  });

  factory BillsDashboardData.fromJson(Map<String, dynamic> json) {
    return BillsDashboardData(
      stats: BillDashboardStats.fromJson(
        (json['stats'] as Map<String, dynamic>?) ?? {},
      ),
      recentPayments:
          ((json['recent_payments'] ?? json['recentPayments']) as List? ?? [])
              .map((p) => DashboardPayment.fromJson(p as Map<String, dynamic>))
              .toList(),
      pendingByBill:
          ((json['pending_by_bill'] ?? json['pendingByBill']) as List? ?? [])
              .map((b) => PendingBillReport.fromJson(b as Map<String, dynamic>))
              .toList(),
    );
  }
}

class Payment {
  final String id;
  final String memberBillId;
  final double amount;
  final String paymentMode;
  final DateTime paymentDate;
  final String? referenceNo;
  final String? note;

  Payment({
    required this.id,
    required this.memberBillId,
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
    this.referenceNo,
    this.note,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      memberBillId:
          json['member_bill_id']?.toString() ??
          json['memberBillId']?.toString() ??
          '',
      amount: double.parse((json['amount'] ?? '0').toString()),
      paymentMode: json['payment_mode'] ?? json['paymentMode'] ?? 'CASH',
      paymentDate: DateTime.parse(
        json['payment_date'] ??
            json['paymentDate'] ??
            DateTime.now().toIso8601String(),
      ),
      referenceNo: json['reference_no'] ?? json['referenceNo'],
      note: json['note'],
    );
  }
}
