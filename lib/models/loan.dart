class LoanPayment {
  String id;
  double amount;
  DateTime date;
  String? notes;

  LoanPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
    id: json['id'],
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    notes: json['notes'],
  );
}

class Loan {
  String id;
  String name;
  String? lender;
  String? type;
  double principalAmount;
  double totalPaid;
  double remainingAmount;
  double emiAmount;
  double? interestRate;
  int tenureMonths;
  String status;
  DateTime startDate;
  DateTime endDate;
  DateTime nextDueDate;
  DateTime createdAt;
  DateTime? updatedAt;
  List<LoanPayment> paymentHistory;
  String? profileId;
  String? groupId;

  // Backward compatibility - map old field names
  double get principal => principalAmount;
  set principal(double value) => principalAmount = value;

  double get paidAmount => totalPaid;
  set paidAmount(double value) => totalPaid = value;

  DateTime get nextPaymentDate => nextDueDate;
  set nextPaymentDate(DateTime value) => nextDueDate = value;

  Loan({
    required this.id,
    required this.name,
    this.lender,
    this.type,
    required this.principalAmount,
    required this.totalPaid,
    required this.remainingAmount,
    required this.emiAmount,
    this.interestRate,
    required this.tenureMonths,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.nextDueDate,
    DateTime? createdAt,
    this.updatedAt,
    List<LoanPayment>? paymentHistory,
    this.profileId,
    this.groupId,
  }) : createdAt = createdAt ?? DateTime.now(),
       paymentHistory = paymentHistory ?? [];

  double get totalAmount => principalAmount + interestAmount;
  double get interestAmount => (emiAmount * tenureMonths) - principalAmount;
  int get paymentsCompleted => paymentHistory.length;
  int get paymentsRemaining => tenureMonths - paymentsCompleted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lender': lender,
    'type': type,
    'principalAmount': principalAmount,
    'totalPaid': totalPaid,
    'remainingAmount': remainingAmount,
    'emiAmount': emiAmount,
    'interestRate': interestRate,
    'tenureMonths': tenureMonths,
    'status': status,
    'startDate': startDate.toIso8601String().split('T')[0],
    'endDate': endDate.toIso8601String().split('T')[0],
    'nextDueDate': nextDueDate.toIso8601String().split('T')[0],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(),
    'profileId': profileId,
    'groupId': groupId,
  };

  factory Loan.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          try {
            final parts = dateValue.split('-');
            if (parts.length == 3) {
              return DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            }
          } catch (_) {}
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Handle both old and new field names
    final principalAmount =
        (json['principalAmount'] ?? json['principal']) as num?;
    final totalPaid = (json['totalPaid'] ?? json['paidAmount']) as num?;
    final nextDueDate = json['nextDueDate'] ?? json['nextPaymentDate'];
    final startDate = parseDate(json['startDate']);
    final tenureMonths = (json['tenureMonths'] as num?)?.toInt() ?? 0;

    return Loan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lender: json['lender'],
      type: json['type'],
      principalAmount: principalAmount?.toDouble() ?? 0.0,
      totalPaid: totalPaid?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      emiAmount: (json['emiAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      tenureMonths: tenureMonths,
      status: json['status'] ?? 'active',
      startDate: startDate,
      endDate: json['endDate'] != null
          ? parseDate(json['endDate'])
          : DateTime(
              startDate.year,
              startDate.month + tenureMonths,
              startDate.day,
            ),
      nextDueDate: nextDueDate != null
          ? parseDate(nextDueDate)
          : DateTime(startDate.year, startDate.month + 1, startDate.day),
      createdAt: json['createdAt'] != null
          ? parseDate(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? parseDate(json['updatedAt'])
          : null,
      paymentHistory: json['paymentHistory'] != null
          ? (json['paymentHistory'] as List)
                .map((p) => LoanPayment.fromJson(p))
                .toList()
          : [],
      profileId: json['profileId'],
      groupId: json['groupId'],
    );
  }

  // Create a copy with updated fields
  Loan copyWith({
    String? id,
    String? name,
    String? lender,
    String? type,
    double? principalAmount,
    double? totalPaid,
    double? remainingAmount,
    double? emiAmount,
    double? interestRate,
    int? tenureMonths,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LoanPayment>? paymentHistory,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      lender: lender ?? this.lender,
      type: type ?? this.type,
      principalAmount: principalAmount ?? this.principalAmount,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      emiAmount: emiAmount ?? this.emiAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}
