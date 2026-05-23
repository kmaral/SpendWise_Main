import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsParserService {
  static final SmsQuery _query = SmsQuery();

  /// Parse SMS message to extract transaction details
  static Map<String, dynamic>? parseTransactionFromSms(SmsMessage message) {
    final String body = message.body ?? '';
    final String address = message.address ?? '';

    // Check if it's a transaction SMS
    if (!_isTransactionSms(body, address)) {
      return null;
    }

    // Extract transaction details
    final amount = _extractAmount(body);
    final type = _extractTransactionType(body);
    final merchant = _extractMerchant(body);
    final accountInfo = _extractAccountInfo(body);
    final upiId = _extractUpiId(body);

    if (amount == null) {
      return null; // Invalid transaction SMS
    }

    return {
      'amount': amount,
      'type': type,
      'merchant': merchant,
      'accountInfo': accountInfo,
      'upiId': upiId,
      'date': message.date ?? DateTime.now(),
      'smsBody': body,
      'sender': address,
    };
  }

  /// Check if SMS is a transaction message
  static bool _isTransactionSms(String body, String address) {
    final lowerBody = body.toLowerCase();
    final lowerAddress = address.toLowerCase();

    // Skip OTP and verification code messages
    final otpKeywords = [
      'otp',
      'verification code',
      'verify',
      'confirmation code',
      'security code',
      'pin',
      'verification pin',
      'passcode',
      'one time password',
      'one-time password',
      'authentication code',
      'login code',
    ];

    // Check if it's an OTP message
    bool isOtp = otpKeywords.any((keyword) => lowerBody.contains(keyword));
    if (isOtp) {
      return false; // Skip OTP messages
    }

    // Skip auto-pay and scheduled payment messages
    final autoPayKeywords = [
      'auto-pay',
      'autopay',
      'auto pay',
      'automatic payment',
      'scheduled payment',
      'standing instruction',
      'si executed',
      'si processed',
      'emi',
      'auto debit',
      'recurring payment',
    ];

    // Check if it's an auto-pay message
    bool isAutoPay = autoPayKeywords.any(
      (keyword) => lowerBody.contains(keyword),
    );
    if (isAutoPay) {
      return false; // Skip auto-pay messages
    }

    // Common transaction keywords
    final transactionKeywords = [
      'debited',
      'credited',
      'withdrawn',
      'received',
      'paid',
      'sent',
      'purchased',
      'transaction',
      'payment',
      'transfer',
      'upi',
      'spent',
      'refund',
    ];

    // Common bank sender IDs
    final bankSenders = [
      'hdfc',
      'icici',
      'sbi',
      'axis',
      'kotak',
      'paytm',
      'phonepe',
      'gpay',
      'googlepay',
      'bank',
      'imobile',
    ];

    // Check for transaction keywords
    bool hasKeyword = transactionKeywords.any(
      (keyword) => lowerBody.contains(keyword),
    );

    // Check for bank sender
    bool isBankSender = bankSenders.any(
      (sender) => lowerAddress.contains(sender),
    );

    // Check for amount pattern (Rs. or INR followed by numbers)
    bool hasAmount = body.contains(
      RegExp(r'(rs\.?|inr|₹)\s*\d+', caseSensitive: false),
    );

    return (hasKeyword || isBankSender) && hasAmount;
  }

  /// Extract amount from SMS
  static double? _extractAmount(String body) {
    // Pattern to match amount: Rs. 1000, Rs 1000, INR 1000, ₹1000, Rs.1,000.00, etc.
    final patterns = [
      RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'([\d,]+\.?\d*)\s*(?:rs\.?|inr|₹)', caseSensitive: false),
      RegExp(
        r'amount\s*(?:of\s*)?(?:rs\.?|inr|₹)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }

    return null;
  }

  /// Extract transaction type (debit/credit)
  static String _extractTransactionType(String body) {
    final lowerBody = body.toLowerCase();

    // Credit keywords
    final creditKeywords = [
      'credited',
      'received',
      'refund',
      'cashback',
      'deposit',
    ];
    if (creditKeywords.any((keyword) => lowerBody.contains(keyword))) {
      return 'income';
    }

    // Debit keywords (default)
    return 'expense';
  }

  /// Extract merchant/description
  static String _extractMerchant(String body) {
    // Pattern to extract merchant name after "to", "at", "from"
    final patterns = [
      RegExp(
        r'(?:to|at|from)\s+([A-Z][A-Za-z0-9\s&\-\.]+?)(?:\s+(?:on|for|upi|a\/c|account))',
        caseSensitive: true,
      ),
      RegExp(
        r'(?:paid to|sent to)\s+([A-Z][A-Za-z0-9\s&\-\.]+?)(?:\s|$)',
        caseSensitive: true,
      ),
      RegExp(
        r'merchant\s+([A-Z][A-Za-z0-9\s&\-\.]+?)(?:\s|$)',
        caseSensitive: true,
      ),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown';
      }
    }

    return 'SMS Transaction';
  }

  /// Extract account information
  static String? _extractAccountInfo(String body) {
    // Pattern to extract account number (last 4 digits typically)
    final patterns = [
      RegExp(r'a\/c\s*(?:no\.?)?\s*[xX*]*(\d{4})', caseSensitive: false),
      RegExp(r'account\s*(?:ending\s*)?[xX*]*(\d{4})', caseSensitive: false),
      RegExp(r'card\s*(?:ending\s*)?[xX*]*(\d{4})', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return 'A/C ***${match.group(1)}';
      }
    }

    return null;
  }

  /// Extract UPI ID
  static String? _extractUpiId(String body) {
    // Pattern to match UPI IDs: username@bank
    final pattern = RegExp(
      r'([a-zA-Z0-9._-]+@[a-zA-Z]+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(body);
    return match?.group(1);
  }

  /// Get category based on merchant or keywords
  static String suggestCategory(String merchant, String smsBody) {
    final lowerMerchant = merchant.toLowerCase();
    final lowerBody = smsBody.toLowerCase();

    // Food & Dining
    if (lowerMerchant.contains('zomato') ||
        lowerMerchant.contains('swiggy') ||
        lowerMerchant.contains('restaurant') ||
        lowerBody.contains('food') ||
        lowerBody.contains('dining')) {
      return 'Food';
    }

    // Shopping
    if (lowerMerchant.contains('amazon') ||
        lowerMerchant.contains('flipkart') ||
        lowerMerchant.contains('myntra') ||
        lowerBody.contains('shopping')) {
      return 'Shopping';
    }

    // Transport
    if (lowerMerchant.contains('uber') ||
        lowerMerchant.contains('ola') ||
        lowerMerchant.contains('rapido') ||
        lowerBody.contains('fuel') ||
        lowerBody.contains('petrol')) {
      return 'Transport';
    }

    // Utilities
    if (lowerBody.contains('electricity') ||
        lowerBody.contains('water') ||
        lowerBody.contains('gas') ||
        lowerBody.contains('bill')) {
      return 'Bills';
    }

    // Entertainment
    if (lowerMerchant.contains('netflix') ||
        lowerMerchant.contains('amazon prime') ||
        lowerMerchant.contains('spotify') ||
        lowerMerchant.contains('movie')) {
      return 'Entertainment';
    }

    // Groceries
    if (lowerMerchant.contains('dmart') ||
        lowerMerchant.contains('bigbasket') ||
        lowerMerchant.contains('grocery') ||
        lowerBody.contains('grocery')) {
      return 'Groceries';
    }

    return 'Other';
  }

  /// Request SMS permission
  static Future<bool> requestSmsPermission() async {
    try {
      final status = await Permission.sms.request();
      return status.isGranted;
    } catch (e) {
      // Error requesting SMS permission
      return false;
    }
  }

  /// Get recent SMS messages
  static Future<List<SmsMessage>> getRecentSms({int days = 30}) async {
    try {
      // Check permission first
      final hasPermission = await Permission.sms.isGranted;
      if (!hasPermission) {
        return [];
      }

      // Get all messages
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500, // Limit to last 500 messages
      );

      // Filter messages from last N days
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      return messages
          .where((msg) => msg.date != null && msg.date!.isAfter(cutoffDate))
          .toList();
    } catch (e) {
      // Error reading SMS
      return [];
    }
  }

  /// Parse multiple SMS messages and return transactions
  static Future<List<Map<String, dynamic>>> parseRecentTransactions({
    int days = 30,
  }) async {
    final messages = await getRecentSms(days: days);

    // Parse messages in parallel for better performance
    final transactions = messages
        .map((message) => parseTransactionFromSms(message))
        .where((parsed) => parsed != null)
        .cast<Map<String, dynamic>>()
        .toList();

    return transactions;
  }
}
