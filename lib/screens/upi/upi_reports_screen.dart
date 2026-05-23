import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';

class UpiReportsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final String currency;

  const UpiReportsScreen({
    super.key,
    required this.transactions,
    required this.currency,
  });

  @override
  State<UpiReportsScreen> createState() => _UpiReportsScreenState();
}

class _UpiReportsScreenState extends State<UpiReportsScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<PaymentMethod> _paymentMethods = [];
  StreamSubscription<List<PaymentMethod>>? _paymentMethodsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _paymentMethodsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    final methodsStream = DataManager.watchPaymentMethods();
    if (methodsStream != null) {
      _paymentMethodsSubscription = methodsStream.listen((methods) {
        if (mounted) {
          setState(() {
            _paymentMethods = methods;
          });
        }
      });
    }
  }

  Future<void> _loadData() async {
    final methods = await DataManager.getPaymentMethods();
    if (mounted) {
      setState(() {
        _paymentMethods = methods;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get UPI payment methods
    final upiPaymentMethods = _paymentMethods
        .where((m) => m.type == 'upi')
        .toList();

    // Filter transactions for selected month that have UPI payment methods
    final monthTransAll = widget.transactions
        .where(
          (t) =>
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month &&
              t.paymentMethodId != null &&
              upiPaymentMethods.any((m) => m.id == t.paymentMethodId),
        )
        .toList();

    // Group transactions by payment method
    final paymentMethodData = <String, Map<String, dynamic>>{};
    for (var method in upiPaymentMethods) {
      final methodTrans = monthTransAll
          .where((t) => t.paymentMethodId == method.id)
          .toList();

      if (methodTrans.isNotEmpty) {
        final income = methodTrans
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final expense = methodTrans
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);

        paymentMethodData[method.id] = {
          'name': method.name,
          'upiId': method.upiId,
          'income': income,
          'expense': expense,
          'transactions': methodTrans.length,
          'net': income - expense,
          'transactionsList': methodTrans,
        };
      }
    }

    final totalIncome = paymentMethodData.values.fold(
      0.0,
      (s, e) => s + (e['income'] as double),
    );
    final totalExpense = paymentMethodData.values.fold(
      0.0,
      (s, e) => s + (e['expense'] as double),
    );
    final totalCount = paymentMethodData.values.fold(
      0,
      (s, e) => s + (e['transactions'] as int),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('UPI Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                  onPressed: () async {
                    final date = await _showMonthYearPicker(
                      context,
                      _selectedMonth,
                    );
                    if (date != null) setState(() => _selectedMonth = date);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: paymentMethodData.isEmpty
                ? const Center(child: Text('No UPI transactions this month'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withOpacity(0.1),
                                const Color(0xFF8B5CF6).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                'Total UPI Transactions',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                    'Transactions',
                                    totalCount.toString(),
                                    Colors.blue,
                                  ),
                                  _buildStatColumn(
                                    'Income',
                                    '${widget.currency}${totalIncome.toStringAsFixed(2)}',
                                    Colors.green,
                                  ),
                                  _buildStatColumn(
                                    'Expense',
                                    '${widget.currency}${totalExpense.toStringAsFixed(2)}',
                                    Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...paymentMethodData.entries.map((e) {
                        final data = e.value;
                        final list =
                            data['transactionsList'] as List<Transaction>;
                        final methodName = data['name'] as String;
                        final upiId = data['upiId'] as String?;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF4CAF50),
                              child: Icon(Icons.qr_code, color: Colors.white),
                            ),
                            title: Text(
                              methodName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data['transactions']} transactions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (upiId != null)
                                  Text(
                                    upiId,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildUpiRow(
                                      'Income',
                                      data['income'] as double,
                                      const Color(0xFF10B981),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildUpiRow(
                                      'Expense',
                                      data['expense'] as double,
                                      const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildUpiRow(
                                      'Net',
                                      data['net'] as double,
                                      const Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UpiTransactionsDetailScreen(
                                                  paymentMethodName: methodName,
                                                  upiId: upiId,
                                                  transactions: list,
                                                  currency: widget.currency,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text('View Transactions'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          '${widget.currency}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
              // Year Dropdown
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
              // Month Dropdown
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

class UpiTransactionsDetailScreen extends StatelessWidget {
  final String paymentMethodName;
  final String? upiId;
  final List<Transaction> transactions;
  final String currency;

  const UpiTransactionsDetailScreen({
    super.key,
    required this.paymentMethodName,
    this.upiId,
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTrans = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paymentMethodName),
            if (upiId != null)
              Text(
                upiId!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedTrans.length,
        itemBuilder: (context, i) {
          final t = sortedTrans[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: t.type == 'income'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                child: Icon(
                  t.type == 'income'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: t.type == 'income' ? Colors.green : Colors.red,
                ),
              ),
              title: Text(t.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(t.date)),
                  Text('Category: ${t.category}'),
                  if (t.notes != null && t.notes!.isNotEmpty)
                    Text(
                      'Note: ${t.notes}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: Text(
                '${t.type == 'expense' ? '-' : '+'}$currency${t.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: t.type == 'expense' ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
