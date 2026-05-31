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
        if (mounted) setState(() => _paymentMethods = methods);
      });
    }
  }

  Future<void> _loadData() async {
    final methods = await DataManager.getPaymentMethods();
    if (mounted) setState(() => _paymentMethods = methods);
  }

  @override
  Widget build(BuildContext context) {
    final upiPaymentMethods =
        _paymentMethods.where((m) => m.type == 'upi').toList();

    final monthTransAll = widget.transactions
        .where(
          (t) =>
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month &&
              t.paymentMethodId != null &&
              upiPaymentMethods.any((m) => m.id == t.paymentMethodId),
        )
        .toList();

    final paymentMethodData = <String, Map<String, dynamic>>{};
    for (var method in upiPaymentMethods) {
      final methodTrans =
          monthTransAll.where((t) => t.paymentMethodId == method.id).toList();
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
          'count': methodTrans.length,
          'net': income - expense,
          'list': methodTrans,
        };
      }
    }

    final totalIncome = paymentMethodData.values
        .fold(0.0, (s, e) => s + (e['income'] as double));
    final totalExpense = paymentMethodData.values
        .fold(0.0, (s, e) => s + (e['expense'] as double));
    final totalCount = paymentMethodData.values
        .fold(0, (s, e) => s + (e['count'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Reports'),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Month picker ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InkWell(
                onTap: () async {
                  final date =
                      await _showMonthYearPicker(context, _selectedMonth);
                  if (date != null) setState(() => _selectedMonth = date);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (paymentMethodData.isEmpty) ...[
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No UPI transactions this month',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // ── Summary card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF8B5CF6)
                                ]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.qr_code_scanner,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('UPI Summary',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                Text(
                                  '$totalCount transactions · ${paymentMethodData.length} apps',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildSumChip(
                                    'Income',
                                    totalIncome,
                                    const Color(0xFF10B981),
                                    widget.currency)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildSumChip(
                                    'Expense',
                                    totalExpense,
                                    const Color(0xFFEF4444),
                                    widget.currency)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildSumChip(
                                    'Net',
                                    totalIncome - totalExpense,
                                    const Color(0xFF3B82F6),
                                    widget.currency)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Per-method cards ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry =
                        paymentMethodData.entries.elementAt(index);
                    final data = entry.value;
                    final income = data['income'] as double;
                    final expense = data['expense'] as double;
                    final count = data['count'] as int;
                    final net = data['net'] as double;
                    final name = data['name'] as String;
                    final upiId = data['upiId'] as String?;
                    final list = data['list'] as List<Transaction>;
                    final total = income + expense;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom:
                              index < paymentMethodData.length - 1 ? 12 : 0),
                      child: _UpiMethodCard(
                        name: name,
                        upiId: upiId,
                        income: income,
                        expense: expense,
                        net: net,
                        total: total,
                        count: count,
                        transactions: list,
                        currency: widget.currency,
                      ),
                    );
                  },
                  childCount: paymentMethodData.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSumChip(
      String label, double amount, Color color, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '$currency${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _showMonthYearPicker(
      BuildContext context, DateTime initialDate) async {
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
                items: List.generate(15, (i) => currentYear - 5 + i)
                    .map((y) =>
                        DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedYear = v);
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
                items: List.generate(12, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                        DateFormat('MMMM').format(DateTime(selectedYear, i + 1))),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedMonth = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, DateTime(selectedYear, selectedMonth)),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Per-method tappable card ─────────────────────────────────────────────────

class _UpiMethodCard extends StatelessWidget {
  final String name;
  final String? upiId;
  final double income;
  final double expense;
  final double net;
  final double total;
  final int count;
  final List<Transaction> transactions;
  final String currency;

  const _UpiMethodCard({
    required this.name,
    required this.upiId,
    required this.income,
    required this.expense,
    required this.net,
    required this.total,
    required this.count,
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8B5CF6);
    const green = Color(0xFF10B981);
    const red = Color(0xFFEF4444);
    const blue = Color(0xFF3B82F6);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: purple.withValues(alpha: 0.25), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showTransactionsSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code,
                        size: 20, color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        if (upiId != null)
                          Text(upiId!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // transaction count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$count txns',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: purple)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 14),
              // Stats row
              Row(
                children: [
                  Expanded(
                      child: _miniStat(
                          '↓ Income', income, green, currency)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _miniStat(
                          '↑ Expense', expense, red, currency)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _miniStat('Net', net, blue, currency)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(
      String label, double amount, Color color, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            '$currency${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _showTransactionsSheet(BuildContext context) {
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Sheet header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF4CAF50).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code,
                          size: 22, color: Color(0xFF4CAF50)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (upiId != null)
                            Text(upiId!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$count txns',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Summary strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                        child: _sheetStatChip('Income', income,
                            const Color(0xFF10B981), currency)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _sheetStatChip('Expense', expense,
                            const Color(0xFFEF4444), currency)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _sheetStatChip(
                            'Net', net, const Color(0xFF3B82F6), currency)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              // Transaction list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) =>
                      _TransactionTile(t: sorted[i], currency: currency),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sheetStatChip(
      String label, double amount, Color color, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('$currency${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction t;
  final String currency;

  const _TransactionTile({required this.t, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isIncome = t.type == 'income';
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(t.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  if (t.category.isNotEmpty)
                    Text(t.category,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  if (t.notes != null && t.notes!.isNotEmpty)
                    Text(
                      t.notes!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(2)}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
