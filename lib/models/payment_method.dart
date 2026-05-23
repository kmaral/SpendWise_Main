import 'package:flutter/material.dart';

class PaymentMethod {
  String id;
  String name;
  String type; // 'cash', 'upi', 'debit_card', 'credit_card'
  String? upiId;
  String? last4Digits;
  String? linkedAccountId;
  String? linkedCreditCardId;
  String? bankName;
  String? profileId;
  String? groupId;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.upiId,
    this.last4Digits,
    this.linkedAccountId,
    this.linkedCreditCardId,
    this.bankName,
    this.profileId,
    this.groupId,
  });

  IconData get icon {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.qr_code;
      case 'debit_card':
        return Icons.credit_card;
      case 'credit_card':
        return Icons.credit_score;
      default:
        return Icons.payment;
    }
  }

  Color get color {
    switch (type) {
      case 'cash':
        return const Color(0xFF4CAF50);
      case 'upi':
        return const Color(0xFF4CAF50);
      case 'debit_card':
        return const Color(0xFFFF9800);
      case 'credit_card':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String get displayInfo {
    switch (type) {
      case 'upi':
        return upiId ?? 'UPI';
      case 'debit_card':
      case 'credit_card':
        return last4Digits != null ? '****$last4Digits' : 'Card';
      default:
        return name;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'upiId': upiId,
    'last4Digits': last4Digits,
    'linkedAccountId': linkedAccountId,
    'linkedCreditCardId': linkedCreditCardId,
    'bankName': bankName,
    'profileId': profileId,
    'groupId': groupId,
  };

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    upiId: json['upiId'],
    last4Digits: json['last4Digits'],
    linkedAccountId: json['linkedAccountId'],
    linkedCreditCardId: json['linkedCreditCardId'],
    profileId: json['profileId'],
    groupId: json['groupId'],
    bankName: json['bankName'],
  );
}
