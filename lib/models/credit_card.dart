class CreditCard {
  String id;
  String name;
  double creditLimit;
  double availableLimit;
  double outstandingAmount;
  double minimumDue;
  int billingCycle;
  DateTime dueDate;
  String? bank;
  String? cardNumber;
  int rewardPoints;
  String status;
  DateTime createdAt;
  String? profileId;
  String? groupId;

  CreditCard({
    required this.id,
    required this.name,
    required this.creditLimit,
    double? availableLimit,
    double? outstandingAmount,
    double? minimumDue,
    int? billingCycle,
    required this.dueDate,
    this.bank,
    this.cardNumber,
    int? rewardPoints,
    String? status,
    DateTime? createdAt,
    this.profileId,
    this.groupId,
  }) : availableLimit = availableLimit ?? creditLimit,
       outstandingAmount = outstandingAmount ?? 0.0,
       minimumDue = minimumDue ?? 0.0,
       billingCycle = billingCycle ?? 1,
       rewardPoints = rewardPoints ?? 0,
       status = status ?? 'active',
       createdAt = createdAt ?? DateTime.now();

  // Legacy compatibility
  double get outstanding => outstandingAmount;
  double get available => availableLimit;
  double get minimumPayment => minimumDue;
  DateTime get statementDate => dueDate.subtract(Duration(days: billingCycle));
  double get lastPayment => 0.0;

  double get utilizationPercent => creditLimit > 0
      ? (outstandingAmount / creditLimit * 100).clamp(0, 100)
      : 0.0;
  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && outstandingAmount > 0;
  bool get isActive => status.toLowerCase() == 'active';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'creditLimit': creditLimit,
    'availableLimit': availableLimit,
    'outstandingAmount': outstandingAmount,
    'minimumDue': minimumDue,
    'billingCycle': billingCycle,
    'dueDate': dueDate.toIso8601String(),
    'profileId': profileId,
    'groupId': groupId,
    if (bank != null) 'bank': bank,
    if (cardNumber != null) 'cardNumber': cardNumber,
    'rewardPoints': rewardPoints,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    final creditLimit = (json['creditLimit'] as num?)?.toDouble() ?? 0.0;
    final outstandingAmount =
        (json['outstandingAmount'] as num?)?.toDouble() ??
        (json['outstanding'] as num?)?.toDouble() ??
        0.0;

    return CreditCard(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Card',
      creditLimit: creditLimit,
      availableLimit:
          (json['availableLimit'] as num?)?.toDouble() ??
          (creditLimit - outstandingAmount),
      outstandingAmount: outstandingAmount,
      minimumDue:
          (json['minimumDue'] as num?)?.toDouble() ??
          (json['minimumPayment'] as num?)?.toDouble() ??
          (outstandingAmount * 0.05),
      billingCycle: (json['billingCycle'] as num?)?.toInt() ?? 45,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now().add(const Duration(days: 30)),
      bank: json['bank'],
      cardNumber: json['cardNumber'],
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      profileId: json['profileId'],
      groupId: json['groupId'],
    );
  }

  CreditCard copyWith({
    String? id,
    String? name,
    double? creditLimit,
    double? availableLimit,
    double? outstandingAmount,
    double? minimumDue,
    int? billingCycle,
    DateTime? dueDate,
    String? bank,
    String? cardNumber,
    int? rewardPoints,
    String? status,
    DateTime? createdAt,
    required double outstanding,
  }) {
    return CreditCard(
      id: id ?? this.id,
      name: name ?? this.name,
      creditLimit: creditLimit ?? this.creditLimit,
      availableLimit: availableLimit ?? this.availableLimit,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      minimumDue: minimumDue ?? this.minimumDue,
      billingCycle: billingCycle ?? this.billingCycle,
      dueDate: dueDate ?? this.dueDate,
      bank: bank ?? this.bank,
      cardNumber: cardNumber ?? this.cardNumber,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
