import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';

class ReportsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;

  const ReportsScreen({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _reportType = 'monthly';
  DateTime _selectedDate = DateTime.now();

  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when transactions or categories change
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.categories != widget.categories) {
      setState(() {
        // Trigger rebuild with new data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'monthly', label: Text('Monthly')),
                  ButtonSegment(value: 'yearly', label: Text('Yearly')),
                  ButtonSegment(value: 'category', label: Text('Category')),
                ],
                selected: {_reportType},
                onSelectionChanged: (v) =>
                    setState(() => _reportType = v.first),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _reportType == 'yearly'
                      ? _selectedDate.year.toString()
                      : DateFormat('MMMM yyyy').format(_selectedDate),
                ),
                onPressed: () async {
                  if (_reportType == 'yearly') {
                    final date = await _showYearPicker(context, _selectedDate);
                    if (date != null) setState(() => _selectedDate = date);
                  } else {
                    final date = await _showMonthYearPicker(
                      context,
                      _selectedDate,
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _reportType == 'monthly'
              ? _buildMonthlyReport()
              : _reportType == 'yearly'
              ? _buildYearlyReport()
              : _buildCategoryReport(),
        ),
      ],
    );
  }

  Widget _buildMonthlyReport() {
    final monthTrans = widget.transactions
        .where(
          (t) =>
              t.date.year == _selectedDate.year &&
              t.date.month == _selectedDate.month,
        )
        .toList();

    final income = monthTrans
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = monthTrans
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final categoryData = <String, double>{};
    for (var t in monthTrans.where((t) => t.type == 'expense')) {
      categoryData[t.category] = (categoryData[t.category] ?? 0) + t.amount;
    }

    return ListView(
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
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildSummaryRow(
                  'Total Income',
                  income,
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Total Expense',
                  expense,
                  const Color(0xFFEF4444),
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  'Net Balance',
                  income - expense,
                  const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (categoryData.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No data'),
                    ),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: categoryData.entries.map((e) {
                          final cat = widget.categories.firstWhere(
                            (c) => c.name == e.key,
                            orElse: () => widget.categories.first,
                          );
                          return PieChartSectionData(
                            value: e.value,
                            title:
                                '${(e.value / (expense > 0 ? expense : 1) * 100).toStringAsFixed(1)}%',
                            color: cat.colorData,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ...categoryData.entries.map((e) {
                  final cat = widget.categories.firstWhere(
                    (c) => c.name == e.key,
                    orElse: () => widget.categories.first,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: cat.colorData,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.key)),
                        Text('${widget.currency}${e.value.toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyReport() {
    final yearTrans = widget.transactions
        .where((t) => t.date.year == _selectedDate.year)
        .toList();

    final monthlyData = <int, Map<String, double>>{};
    for (var i = 1; i <= 12; i++) {
      monthlyData[i] = {'income': 0, 'expense': 0};
    }

    for (var t in yearTrans) {
      final month = t.date.month;
      if (t.type == 'income') {
        monthlyData[month]!['income'] =
            monthlyData[month]!['income']! + t.amount;
      } else {
        monthlyData[month]!['expense'] =
            monthlyData[month]!['expense']! + t.amount;
      }
    }

    final totalIncome = yearTrans
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = yearTrans
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${_selectedDate.year} Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _buildSummaryRow('Total Income', totalIncome, Colors.green),
                const SizedBox(height: 8),
                _buildSummaryRow('Total Expense', totalExpense, Colors.red),
                const Divider(height: 24),
                _buildSummaryRow(
                  'Net Balance',
                  totalIncome - totalExpense,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              final label = (idx >= 1 && idx <= 12)
                                  ? DateFormat.MMM().format(DateTime(0, idx))
                                  : '';
                              return Text(
                                label,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: monthlyData.entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value['income']!,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.3),
                                const Color(0xFF10B981).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: monthlyData.entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value['expense']!,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFEF4444).withOpacity(0.3),
                                const Color(0xFFEF4444).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(const Color(0xFF10B981), 'Income'),
                    const SizedBox(width: 24),
                    _buildLegend(const Color(0xFFEF4444), 'Expense'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryReport() {
    final monthTrans = widget.transactions
        .where(
          (t) =>
              t.date.year == _selectedDate.year &&
              t.date.month == _selectedDate.month,
        )
        .toList();

    final categoryData = <String, Map<String, dynamic>>{};
    for (var cat in widget.categories) {
      final catTrans = monthTrans
          .where((t) => t.category == cat.name && t.type == 'expense')
          .toList();
      final total = catTrans.fold(0.0, (sum, t) => sum + t.amount);
      categoryData[cat.name] = {
        'total': total,
        'count': catTrans.length,
        'budget': cat.budgetLimit,
        'color': cat.colorData,
        'icon': cat.iconData,
      };
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: categoryData.entries.map((e) {
        final budget = e.value['budget'] as double?;
        final total = e.value['total'] as double;
        final count = e.value['count'] as int;
        final percentage = (budget != null && budget > 0)
            ? (total / budget * 100).clamp(0, 100)
            : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(e.value['icon'], color: e.value['color']),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${widget.currency}${total.toStringAsFixed(2)}',
                    ),
                    Text('$count transactions'),
                  ],
                ),
                if (budget != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget: ${widget.currency}${budget.toStringAsFixed(2)}',
                      ),
                      Text('${percentage.toStringAsFixed(1)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage > 90
                            ? const Color(0xFFEF4444)
                            : percentage > 70
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          '${widget.currency}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 3, color: color),
        const SizedBox(width: 8),
        Text(label),
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

  Future<DateTime?> _showYearPicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    int selectedYear = initialDate.year;
    final currentYear = DateTime.now().year;

    return showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Year'),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, DateTime(selectedYear));
              },
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}
