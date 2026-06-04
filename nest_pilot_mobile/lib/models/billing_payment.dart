class Bill {
  final String id;
  final String title;
  final String? description;
  final double amountTotal;
  final DateTime dueDate;
  final String status; // DRAFT, PUBLISHED, CANCELLED
  final String billType; // MAINTENANCE, SPECIAL

  Bill({
    required this.id,
    required this.title,
    this.description,
    required this.amountTotal,
    required this.dueDate,
    required this.status,
    required this.billType,
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
      paymentDate: DateTime.tryParse(
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
      pendingBillsCount: int.tryParse(
            (json['pending_bills_count'] ?? json['pendingBillsCount'] ?? '0')
                .toString(),
          ) ??
          0,
    );
  }

  factory BillDashboardStats.empty() =>
      BillDashboardStats(totalCollected: 0, totalPending: 0, pendingBillsCount: 0);
}

class BillsDashboardData {
  final BillDashboardStats stats;
  final List<DashboardPayment> recentPayments;

  BillsDashboardData({required this.stats, required this.recentPayments});

  factory BillsDashboardData.fromJson(Map<String, dynamic> json) {
    return BillsDashboardData(
      stats: BillDashboardStats.fromJson(
        (json['stats'] as Map<String, dynamic>?) ?? {},
      ),
      recentPayments: ((json['recent_payments'] ?? json['recentPayments']) as List? ?? [])
          .map((p) => DashboardPayment.fromJson(p as Map<String, dynamic>))
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
