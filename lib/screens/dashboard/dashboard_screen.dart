import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';

// ─── Widget config ────────────────────────────────────────────────────────────

class _WCfg {
  final String id;
  final String title;
  final IconData icon;
  bool visible;

  _WCfg(this.id, this.title, this.icon, {this.visible = true});

  _WCfg copy() => _WCfg(id, title, icon, visible: visible);
  Map<String, dynamic> toJson() => {'id': id, 'visible': visible};
}

List<_WCfg> _defaultCfg() => [
      _WCfg('monthly_summary', 'Monthly Summary', Icons.calendar_today_outlined),
      _WCfg('account_balance', 'Account Balance & Net Worth', Icons.account_balance_wallet),
      _WCfg('assets_liabilities', 'Assets & Liabilities', Icons.savings),
      _WCfg('loans_cards', 'Loans & Credit Cards', Icons.credit_card),
      _WCfg('upi_summary', 'UPI Summary', Icons.qr_code_scanner),
      _WCfg('spending_by_category', 'Spending by Category', Icons.pie_chart_rounded),
      _WCfg('budget_overview', 'Budget Overview', Icons.track_changes),
      _WCfg('upi_breakdown', 'UPI Breakdown', Icons.account_balance_wallet_outlined),
    ];

const _kDashPrefs = 'dashboard_widget_order';

// ─── DashboardScreen ──────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  final List<CreditCard> creditCards;
  final List<Loan> loans;
  final List<Account> accounts;
  final String currency;

  const DashboardScreen({
    super.key,
    required this.transactions,
    required this.categories,
    required this.paymentMethods,
    required this.creditCards,
    required this.loans,
    required this.accounts,
    required this.currency,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<_WCfg> _widgets = _defaultCfg();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kDashPrefs);
    if (saved == null) return;

    final raw = jsonDecode(saved) as List;
    final defaults = _defaultCfg();
    final loaded = <_WCfg>[];

    for (final item in raw) {
      final id = item['id'] as String;
      final visible = item['visible'] as bool? ?? true;
      final match = defaults.firstWhere(
        (d) => d.id == id,
        orElse: () => _WCfg(id, id, Icons.widgets),
      );
      match.visible = visible;
      loaded.add(match);
    }
    for (final d in defaults) {
      if (!loaded.any((w) => w.id == d.id)) loaded.add(d);
    }

    if (mounted) setState(() => _widgets = loaded);
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kDashPrefs,
      jsonEncode(_widgets.map((w) => w.toJson()).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthTrans = widget.transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    final income = monthTrans
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = monthTrans
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final categorySpending = <String, double>{};
    final categoryTransactionCount = <String, int>{};
    for (var t in monthTrans.where((t) => t.type == 'expense')) {
      categorySpending[t.category] = (categorySpending[t.category] ?? 0) + t.amount;
      categoryTransactionCount[t.category] =
          (categoryTransactionCount[t.category] ?? 0) + 1;
    }
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final upiPaymentMethods =
        widget.paymentMethods.where((m) => m.type == 'upi').toList();
    final upiTransactionsMonth = monthTrans
        .where((t) =>
            t.paymentMethodId != null &&
            upiPaymentMethods.any((m) => m.id == t.paymentMethodId))
        .toList();
    final upiIncomeMonth = upiTransactionsMonth
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final upiExpenseMonth = upiTransactionsMonth
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);

    final upiTransactionsAll = widget.transactions
        .where((t) =>
            t.paymentMethodId != null &&
            upiPaymentMethods.any((m) => m.id == t.paymentMethodId))
        .toList();
    final upiIncomeAll = upiTransactionsAll
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final upiExpenseAll = upiTransactionsAll
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);

    final upiBreakdown = <String, Map<String, dynamic>>{};
    for (var t in upiTransactionsMonth) {
      final method = upiPaymentMethods.firstWhere(
        (m) => m.id == t.paymentMethodId,
        orElse: () => PaymentMethod(id: '', name: 'Unknown', type: 'upi'),
      );
      upiBreakdown.putIfAbsent(method.name, () => {
        'income': 0.0,
        'expense': 0.0,
        'count': 0,
        'upiId': method.upiId,
      });
      if (t.type == 'income') {
        upiBreakdown[method.name]!['income'] =
            (upiBreakdown[method.name]!['income'] as double) + t.amount;
      } else {
        upiBreakdown[method.name]!['expense'] =
            (upiBreakdown[method.name]!['expense'] as double) + t.amount;
      }
      upiBreakdown[method.name]!['count'] =
          (upiBreakdown[method.name]!['count'] as int) + 1;
    }

    final activeCreditCards =
        widget.creditCards.where((c) => c.isActive).toList();
    final totalCreditLimit =
        activeCreditCards.fold(0.0, (s, c) => s + c.creditLimit);
    final totalCreditUsed =
        activeCreditCards.fold(0.0, (s, c) => s + c.outstandingAmount);
    final activeLoans =
        widget.loans.where((l) => l.status == 'active').toList();
    final totalLoanAmount =
        activeLoans.fold(0.0, (s, l) => s + l.remainingAmount);
    final totalAccountBalance =
        widget.accounts.fold(0.0, (s, a) => s + a.balance);
    final totalAssets = totalAccountBalance;
    final totalLiabilities = totalLoanAmount + totalCreditUsed;

    Widget widgetFor(String id) {
      switch (id) {
        case 'monthly_summary':
          return _buildMonthlySummary(context, now, income, expense);
        case 'account_balance':
          return _buildAccountBalanceRow(
              context, totalAccountBalance, totalAssets, totalLiabilities);
        case 'assets_liabilities':
          return _buildAssetsLiabilitiesRow(
              context, totalAssets, totalLiabilities);
        case 'loans_cards':
          return _buildLoansCardsRow(context, totalLoanAmount, activeLoans,
              totalCreditUsed, activeCreditCards, totalCreditLimit);
        case 'upi_summary':
          return _buildUpiSummaryRow(
              context, upiIncomeAll, upiExpenseAll, upiTransactionsAll);
        case 'spending_by_category':
          return _buildSpendingByCategory(context, sortedCategories, expense,
              categoryTransactionCount, monthTrans);
        case 'budget_overview':
          return _buildBudgetOverview(context, categorySpending);
        case 'upi_breakdown':
          if (upiTransactionsMonth.isEmpty) return const SizedBox.shrink();
          return _buildUpiBreakdown(context, upiIncomeMonth, upiExpenseMonth,
              upiTransactionsMonth, upiBreakdown);
        default:
          return const SizedBox.shrink();
      }
    }

    final visible = _widgets.where((w) => w.visible).toList();

    return RepaintBoundary(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _openCustomize(context),
                    icon: const Icon(Icons.dashboard_customize, size: 16),
                    label: const Text('Customize'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.only(
                      bottom: i < visible.length - 1 ? 16 : 0),
                  child: widgetFor(visible[i].id),
                ),
                childCount: visible.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCustomize(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomizeScreen(
          widgets: _widgets,
          onSave: (updated) {
            setState(() => _widgets = updated);
            _saveConfig();
          },
        ),
      ),
    );
  }

  // ── widget builders ─────────────────────────────────────────────────────────

  Widget _buildMonthlySummary(
      BuildContext context, DateTime now, double income, double expense) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
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
              DateFormat('MMMM yyyy').format(now),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Income', income, const Color(0xFF10B981), context),
                _buildStat('Expense', expense, const Color(0xFFEF4444), context),
                _buildStat(
                    'Balance', income - expense, const Color(0xFF3B82F6), context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBalanceRow(BuildContext context, double balance,
      double assets, double liabilities) {
    return Row(
      children: [
        Expanded(
          child: _buildFinancialCard(
            context,
            'Account Balance',
            balance,
            Icons.account_balance_wallet,
            const Color(0xFF3B82F6),
            widget.currency,
            subtitle: '${widget.accounts.length} accounts',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFinancialCard(
            context,
            'Net Worth',
            assets - liabilities,
            Icons.trending_up,
            assets - liabilities >= 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            widget.currency,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsLiabilitiesRow(
      BuildContext context, double assets, double liabilities) {
    return Row(
      children: [
        Expanded(
          child: _buildFinancialCard(
            context,
            'Total Assets',
            assets,
            Icons.savings,
            const Color(0xFF10B981),
            widget.currency,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFinancialCard(
            context,
            'Total Liabilities',
            liabilities,
            Icons.warning_rounded,
            const Color(0xFFEF4444),
            widget.currency,
          ),
        ),
      ],
    );
  }

  Widget _buildLoansCardsRow(
      BuildContext context,
      double loanAmount,
      List<Loan> activeLoans,
      double creditUsed,
      List<CreditCard> activeCards,
      double creditLimit) {
    return Row(
      children: [
        Expanded(
          child: _buildFinancialCard(
            context,
            'Active Loans',
            loanAmount,
            Icons.request_quote,
            const Color(0xFFF59E0B),
            widget.currency,
            subtitle: '${activeLoans.length} loans',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFinancialCard(
            context,
            'Credit Cards',
            creditUsed,
            Icons.credit_card,
            const Color(0xFF9C27B0),
            widget.currency,
            subtitle: '${activeCards.length} cards',
            secondaryAmount: creditLimit,
          ),
        ),
      ],
    );
  }

  Widget _buildUpiSummaryRow(BuildContext context, double upiIncomeAll,
      double upiExpenseAll, List<Transaction> upiTransactionsAll) {
    return Row(
      children: [
        Expanded(
          child: _buildFinancialCard(
            context,
            'UPI Transactions',
            upiIncomeAll + upiExpenseAll,
            Icons.qr_code_scanner,
            const Color(0xFF8B5CF6),
            widget.currency,
            subtitle: '${upiTransactionsAll.length} transactions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFinancialCard(
            context,
            'UPI Net',
            upiIncomeAll - upiExpenseAll,
            Icons.account_balance_wallet_outlined,
            upiIncomeAll - upiExpenseAll >= 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            widget.currency,
            subtitle:
                '↑${widget.currency}${upiIncomeAll.toStringAsFixed(0)} ↓${widget.currency}${upiExpenseAll.toStringAsFixed(0)}',
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingByCategory(
      BuildContext context,
      List<MapEntry<String, double>> sortedCategories,
      double expense,
      Map<String, int> categoryTransactionCount,
      List<Transaction> monthTrans) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pie_chart_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending by Category',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${sortedCategories.length} categories',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.currency}${expense.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (sortedCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('No expenses this month',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              ...sortedCategories.map((e) {
                final cat = widget.categories.firstWhere(
                  (c) => c.name == e.key,
                  orElse: () => Category(
                    id: '0',
                    name: e.key,
                    icon: 'Category',
                    color: '#607D8B',
                    iconCode: 0xe3af,
                    colorValue: 0xFF607D8B,
                  ),
                );
                final pct = expense > 0 ? (e.value / expense * 100) : 0;
                final txnCount = categoryTransactionCount[e.key] ?? 0;
                final categoryTransactions = monthTrans
                    .where((t) => t.category == e.key && t.type == 'expense')
                    .toList();

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryTransactionsScreen(
                          categoryName: e.key,
                          transactions: categoryTransactions,
                          category: cat,
                          currency: widget.currency,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cat.colorData.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cat.colorData.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cat.colorData.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(cat.iconData,
                                  color: cat.colorData, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  Text(
                                    '$txnCount transaction${txnCount != 1 ? 's' : ''}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${widget.currency}${e.value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: cat.colorData),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cat.colorData.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${pct.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: cat.colorData),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: cat.colorData.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                cat.colorData),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview(
      BuildContext context, Map<String, double> categorySpending) {
    final budgeted =
        widget.categories.where((c) => c.budgetLimit != null).toList();
    if (budgeted.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...budgeted.map((cat) {
              final spent = categorySpending[cat.name] ?? 0;
              final budget = cat.budgetLimit!;
              final pct = (spent / budget * 100).clamp(0, 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat.name),
                        Text(
                          '${widget.currency}${spent.toStringAsFixed(0)} / ${widget.currency}${budget.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      color: pct > 90
                          ? const Color(0xFFEF4444)
                          : pct > 70
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiBreakdown(
      BuildContext context,
      double upiIncomeMonth,
      double upiExpenseMonth,
      List<Transaction> upiTransactionsMonth,
      Map<String, Map<String, dynamic>> upiBreakdown) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'UPI Breakdown',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${upiTransactionsMonth.length} txns',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildUpiStat(
                        'Income', upiIncomeMonth, const Color(0xFF10B981), context)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildUpiStat(
                        'Expense', upiExpenseMonth, const Color(0xFFEF4444), context)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildUpiStat('Net', upiIncomeMonth - upiExpenseMonth,
                        const Color(0xFF3B82F6), context)),
              ],
            ),
            if (upiBreakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'UPI Apps',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...upiBreakdown.entries.map((entry) {
                final inc = entry.value['income'] as double;
                final exp = entry.value['expense'] as double;
                final count = entry.value['count'] as int;
                final upiId = entry.value['upiId'] as String?;
                final total = inc + exp;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code,
                                size: 16, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      overflow: TextOverflow.ellipsis),
                                  if (upiId != null)
                                    Text(upiId,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600]),
                                        overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$count txns',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B5CF6))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                            Text(
                              '${widget.currency}${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B5CF6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (inc > 0)
                              Text(
                                '↓ ${widget.currency}${inc.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600),
                              ),
                            if (inc > 0 && exp > 0) const SizedBox(width: 12),
                            if (exp > 0)
                              Text(
                                '↑ ${widget.currency}${exp.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ── shared helpers ───────────────────────────────────────────────────────────

  Widget _buildStat(
      String label, double amount, Color color, BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          '${widget.currency}${amount.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildUpiStat(
      String label, double amount, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '${widget.currency}${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
    String currency, {
    String? subtitle,
    double? secondaryAmount,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$currency${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            if (secondaryAmount != null) ...[
              const SizedBox(height: 4),
              Text('of $currency${secondaryAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Customize Screen ─────────────────────────────────────────────────────────

class _CustomizeScreen extends StatefulWidget {
  final List<_WCfg> widgets;
  final void Function(List<_WCfg>) onSave;

  const _CustomizeScreen({required this.widgets, required this.onSave});

  @override
  State<_CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<_CustomizeScreen> {
  late List<_WCfg> _visible;
  late List<_WCfg> _hidden;

  @override
  void initState() {
    super.initState();
    _visible =
        widget.widgets.where((w) => w.visible).map((w) => w.copy()).toList();
    _hidden =
        widget.widgets.where((w) => !w.visible).map((w) => w.copy()).toList();
  }

  void _hide(int index) {
    setState(() {
      final w = _visible.removeAt(index);
      w.visible = false;
      _hidden.add(w);
    });
  }

  void _show(int index) {
    setState(() {
      final w = _hidden.removeAt(index);
      w.visible = true;
      _visible.add(w);
    });
  }

  void _save() {
    widget.onSave([..._visible, ..._hidden]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        children: [
          _sectionHeader(context, 'Active Widgets',
              'Drag to reorder • tap − to remove'),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visible.length,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black26,
              child: child,
            ),
            itemBuilder: (context, index) {
              final w = _visible[index];
              return ListTile(
                key: ValueKey(w.id),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(w.icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(w.title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFFEF4444)),
                      tooltip: 'Remove',
                      onPressed: () => _hide(index),
                    ),
                    const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _visible.removeAt(oldIndex);
                _visible.insert(newIndex, item);
              });
            },
          ),
          if (_hidden.isNotEmpty) ...[
            _sectionHeader(context, 'Available Widgets', 'Tap + to add'),
            ..._hidden.asMap().entries.map((e) {
              final w = e.value;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(w.icon, size: 20, color: Colors.grey),
                ),
                title: Text(w.title,
                    style: TextStyle(color: Colors.grey[600])),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF10B981)),
                  tooltip: 'Add',
                  onPressed: () => _show(e.key),
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ─── Category Transactions Screen ─────────────────────────────────────────────

class CategoryTransactionsScreen extends StatelessWidget {
  final String categoryName;
  final List<Transaction> transactions;
  final Category category;
  final String currency;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryName,
    required this.transactions,
    required this.category,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [category.colorData, category.colorData.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.colorData.withValues(alpha: 0.1),
                  category.colorData.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(category.iconData, size: 48, color: category.colorData),
                const SizedBox(height: 12),
                Text(
                  '${transactions.length} Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$currency${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: category.colorData,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sortedTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No transactions',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = sortedTransactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: category.colorData.withValues(alpha: 0.2),
                              width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  category.colorData.withValues(alpha: 0.2),
                                  category.colorData.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(category.iconData,
                                color: category.colorData, size: 24),
                          ),
                          title: Text(transaction.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(transaction.date),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              if (transaction.notes != null &&
                                  transaction.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  transaction.notes!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: category.colorData.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-$currency${transaction.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: category.colorData,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
