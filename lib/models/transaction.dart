class Transaction {
  String id;
  String description;
  double amount;
  String category;
  String type;
  DateTime date;
  DateTime createdAt;
  DateTime updatedAt;
  String? upiId;
  String? notes;
  String? accountId;
  String? paymentMethodId;
  String? toAccountId; // For transfers
  String? profileId; // User who created this transaction
  String? groupId; // Group this transaction belongs to

  static String normalizeType(String? type) {
    switch (type?.trim().toLowerCase()) {
      case 'credit':
      case 'income':
        return 'income';
      case 'transfer':
        return 'transfer';
      case 'debit':
      case 'expense':
      default:
        return 'expense';
    }
  }

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required String type,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.upiId,
    this.notes,
    this.accountId,
    this.paymentMethodId,
    this.toAccountId,
    this.profileId,
    this.groupId,
  }) : type = normalizeType(type),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Backward compatibility - use description as title
  String get title => description;
  set title(String value) => description = value;

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'category': category,
    'type': normalizeType(type),
    'date': date.toIso8601String().split('T')[0], // Store as date only
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'upiId': upiId,
    'notes': notes,
    'accountId': accountId,
    'paymentMethodId': paymentMethodId,
    'toAccountId': toAccountId,
    'profileId': profileId,
    'groupId': groupId,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Handle both old 'title' field and new 'description' field for backward compatibility
    final description = json['description'] ?? json['title'] ?? '';

    // Parse date - handle both full ISO8601 and date-only formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // If parsing fails, try date-only format
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

    return Transaction(
      id: json['id'] ?? '',
      description: description,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      type: normalizeType(json['type'] as String?),
      date: parseDate(json['date']),
      createdAt: json['createdAt'] != null
          ? parseDate(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? parseDate(json['updatedAt'])
          : DateTime.now(),
      upiId: json['upiId'],
      notes: json['notes'],
      accountId: json['accountId'],
      profileId: json['profileId'],
      groupId: json['groupId'],
      paymentMethodId: json['paymentMethodId'],
      toAccountId: json['toAccountId'],
    );
  }

  // Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    String? category,
    String? type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? upiId,
    String? profileId,
    String? groupId,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Always update timestamp
      upiId: upiId ?? this.upiId,
      notes: notes,
      accountId: accountId,
      paymentMethodId: paymentMethodId,
      toAccountId: toAccountId,
      profileId: profileId ?? this.profileId,
      groupId: groupId ?? this.groupId,
    );
  }
}
