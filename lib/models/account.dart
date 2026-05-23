import 'package:flutter/material.dart';

class Account {
  String id;
  String name;
  String type;
  double balance;
  String? accountHolderName;
  String? accountNumber;
  String? bankName;
  String? branchName;
  String? iconName;
  String? colorHex;
  bool isDefault;
  DateTime createdAt;
  DateTime updatedAt;
  String? profileId; // User who owns this account
  String? groupId; // Group this account belongs to

  // Legacy fields for backward compatibility
  String? ifscCode;
  String? debitCardNumber;
  String? debitCardExpiry;
  String? linkedCardId;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.accountHolderName,
    this.accountNumber,
    this.bankName,
    this.branchName,
    this.iconName,
    this.colorHex,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.ifscCode,
    this.debitCardNumber,
    this.debitCardExpiry,
    this.linkedCardId,
    this.profileId,
    this.groupId,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  IconData get icon {
    // Parse icon from string name or fall back to type-based icon
    if (iconName != null) {
      switch (iconName!.toLowerCase()) {
        case 'building2':
        case 'building':
          return Icons.business;
        case 'bank':
        case 'account_balance':
          return Icons.account_balance;
        case 'wallet':
          return Icons.account_balance_wallet;
        case 'money':
        case 'cash':
          return Icons.money;
        case 'credit_card':
          return Icons.credit_card;
        case 'credit_score':
          return Icons.credit_score;
        case 'savings':
          return Icons.savings;
        case 'piggy_bank':
          return Icons.account_balance;
        default:
          return Icons.account_balance_wallet;
      }
    }

    // Fallback to type-based icons
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_score;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    // Parse color from hex string or fall back to type-based color
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        final hex = colorHex!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        // Fall through to type-based color
      }
    }

    // Fallback to type-based colors
    switch (type) {
      case 'cash':
        return const Color(0xFF4CAF50);
      case 'bank':
        return const Color(0xFF2196F3);
      case 'credit_card':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'balance': balance,
    'accountHolderName': accountHolderName,
    'accountNumber': accountNumber,
    'bankName': bankName,
    'branchName': branchName,
    'icon': iconName,
    'color': colorHex,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    // Include legacy fields if present
    if (ifscCode != null) 'ifscCode': ifscCode,
    if (debitCardNumber != null) 'debitCardNumber': debitCardNumber,
    if (debitCardExpiry != null) 'debitCardExpiry': debitCardExpiry,
    if (linkedCardId != null) 'linkedCardId': linkedCardId,
  };

  factory Account.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Account(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'bank',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      accountHolderName: json['accountHolderName'],
      accountNumber: json['accountNumber'],
      bankName: json['bankName'],
      branchName: json['branchName'],
      iconName: json['icon'],
      colorHex: json['color'],
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] != null
          ? parseDate(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? parseDate(json['updatedAt'])
          : DateTime.now(),
      // Legacy fields
      ifscCode: json['ifscCode'],
      debitCardNumber: json['debitCardNumber'],
      debitCardExpiry: json['debitCardExpiry'],
      linkedCardId: json['linkedCardId'],
    );
  }

  // Create a copy with updated fields
  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? accountHolderName,
    String? accountNumber,
    String? bankName,
    String? branchName,
    String? iconName,
    String? colorHex,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ifscCode,
    String? debitCardNumber,
    String? debitCardExpiry,
    String? linkedCardId,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Always update timestamp
      ifscCode: ifscCode ?? this.ifscCode,
      debitCardNumber: debitCardNumber ?? this.debitCardNumber,
      debitCardExpiry: debitCardExpiry ?? this.debitCardExpiry,
      linkedCardId: linkedCardId ?? this.linkedCardId,
    );
  }
}
