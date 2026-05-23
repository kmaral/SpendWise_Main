import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/data_manager.dart';
import '../../models/models.dart';

class PaymentMethodReportScreen extends StatefulWidget {
  final String currency;

  const PaymentMethodReportScreen({super.key, required this.currency});

  @override
  State<PaymentMethodReportScreen> createState() =>
      _PaymentMethodReportScreenState();
}

class _PaymentMethodReportScreenState extends State<PaymentMethodReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<Transaction> _transactions = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await DataManager.getTransactions();
    final methods = await DataManager.getPaymentMethods();
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _paymentMethods = methods;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getPaymentMethodStats() {
    final filtered = _transactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month &&
          t.type != 'transfer';
    }).toList();

    // Group by payment method type
    final Map<String, List<Transaction>> groupedByType = {};
    final Map<String, double> totalByType = {};
    final Map<String, int> countByType = {};

    // Initialize with common types
    final types = ['debit_card', 'credit_card', 'upi', 'cash', 'net_banking'];
    for (var type in types) {
      groupedByType[type] = [];
      totalByType[type] = 0.0;
      countByType[type] = 0;
    }

    // Also track transactions by specific UPI IDs
    final Map<String, double> upiBreakdown = {};
    final Map<String, int> upiCount = {};

    for (var transaction in filtered) {
      if (transaction.paymentMethodId != null) {
        final method = _paymentMethods.firstWhere(
          (m) => m.id == transaction.paymentMethodId,
          orElse: () => PaymentMethod(id: '', name: '', type: 'cash'),
        );

        if (method.id.isNotEmpty) {
          final type = method.type;
          groupedByType[type] = groupedByType[type] ?? [];
          groupedByType[type]!.add(transaction);
          totalByType[type] = (totalByType[type] ?? 0) + transaction.amount;
          countByType[type] = (countByType[type] ?? 0) + 1;

          // Track UPI breakdown
          if (type == 'upi' && transaction.upiId != null) {
            final upiId = transaction.upiId!;
            upiBreakdown[upiId] =
                (upiBreakdown[upiId] ?? 0) + transaction.amount;
            upiCount[upiId] = (upiCount[upiId] ?? 0) + 1;
          }
        }
      }
    }

    return {
      'groupedByType': groupedByType,
      'totalByType': totalByType,
      'countByType': countByType,
      'upiBreakdown': upiBreakdown,
      'upiCount': upiCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Method Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _getPaymentMethodStats();
    final totalByType = stats['totalByType'] as Map<String, double>;
    final countByType = stats['countByType'] as Map<String, int>;
    final upiBreakdown = stats['upiBreakdown'] as Map<String, double>;
    final upiCount = stats['upiCount'] as Map<String, int>;

    // Calculate grand total
    final grandTotal = totalByType.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
    final grandCount = countByType.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method Report'), elevation: 0),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
              onPressed: () async {
                final date = await _showMonthYearPicker(
                  context,
                  _selectedMonth,
                );
                if (date != null) {
                  setState(() => _selectedMonth = date);
                }
              },
            ),
          ),

          // Summary Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Transactions',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.currency}${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$grandCount transactions',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Method Breakdown
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPaymentMethodCard(
                  'Debit Card',
                  Icons.credit_card,
                  const Color(0xFF3B82F6),
                  totalByType['debit_card'] ?? 0,
                  countByType['debit_card'] ?? 0,
                  grandTotal,
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodCard(
                  'Credit Card',
                  Icons.credit_card,
                  const Color(0xFF9C27B0),
                  totalByType['credit_card'] ?? 0,
                  countByType['credit_card'] ?? 0,
                  grandTotal,
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodCard(
                  'UPI',
                  Icons.phone_android,
                  const Color(0xFF10B981),
                  totalByType['upi'] ?? 0,
                  countByType['upi'] ?? 0,
                  grandTotal,
                  upiBreakdown: upiBreakdown,
                  upiCount: upiCount,
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodCard(
                  'Cash',
                  Icons.money,
                  const Color(0xFFFF9800),
                  totalByType['cash'] ?? 0,
                  countByType['cash'] ?? 0,
                  grandTotal,
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodCard(
                  'Net Banking',
                  Icons.account_balance,
                  const Color(0xFF06B6D4),
                  totalByType['net_banking'] ?? 0,
                  countByType['net_banking'] ?? 0,
                  grandTotal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String title,
    IconData icon,
    Color color,
    double amount,
    int count,
    double grandTotal, {
    Map<String, double>? upiBreakdown,
    Map<String, int>? upiCount,
  }) {
    final hasUpiBreakdown = upiBreakdown != null && upiBreakdown.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasUpiBreakdown
            ? () {
                _showUpiBreakdownDialog(upiBreakdown, upiCount!);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasUpiBreakdown) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count transactions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.currency}${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (amount > 0 && grandTotal > 0)
                        Text(
                          '${((amount / grandTotal) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpiBreakdownDialog(
    Map<String, double> upiBreakdown,
    Map<String, int> upiCount,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UPI Breakdown'),
        content: SizedBox(
          width: double.maxFinite,
          child: upiBreakdown.isEmpty
              ? const Text('No UPI transactions this month')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: upiBreakdown.length,
                  itemBuilder: (context, index) {
                    final upiId = upiBreakdown.keys.elementAt(index);
                    final amount = upiBreakdown[upiId]!;
                    final count = upiCount[upiId] ?? 0;

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF10B981),
                        child: Icon(Icons.account_circle, color: Colors.white),
                      ),
                      title: Text(
                        upiId,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('$count transactions'),
                      trailing: Text(
                        '${widget.currency}${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _showMonthYearPicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    final currentYear = DateTime.now().year;

    return showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Month and Year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: List.generate(15, (index) => currentYear - 5 + index)
                    .map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    })
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedYear = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                items: List.generate(12, (index) {
                  final monthDate = DateTime(selectedYear, index + 1);
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(DateFormat('MMMM').format(monthDate)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedMonth = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, DateTime(selectedYear, selectedMonth));
              },
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}
