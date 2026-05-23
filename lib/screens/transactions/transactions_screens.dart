import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';

class TransactionsListScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;
  final VoidCallback onChanged;

  const TransactionsListScreen({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currency,
    required this.onChanged,
  });

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _selectedFilter = 'all'; // all, accounts, cards, loans
  List<Account> _accounts = [];
  List<PaymentMethod> _paymentMethods = [];
  List<CreditCard> _creditCards = [];
  List<Loan> _loans = [];

  StreamSubscription<List<Account>>? _accountsSubscription;
  StreamSubscription<List<PaymentMethod>>? _paymentMethodsSubscription;
  StreamSubscription<List<CreditCard>>? _creditCardsSubscription;
  StreamSubscription<List<Loan>>? _loansSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _paymentMethodsSubscription?.cancel();
    _creditCardsSubscription?.cancel();
    _loansSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    final accountsStream = DataManager.watchAccounts();
    if (accountsStream != null) {
      _accountsSubscription = accountsStream.listen((accounts) {
        if (mounted) {
          setState(() {
            _accounts = accounts;
          });
        }
      });
    }

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

    final cardsStream = DataManager.watchCreditCards();
    if (cardsStream != null) {
      _creditCardsSubscription = cardsStream.listen((cards) {
        if (mounted) {
          setState(() {
            _creditCards = cards;
          });
        }
      });
    }

    final loansStream = DataManager.watchLoans();
    if (loansStream != null) {
      _loansSubscription = loansStream.listen((loans) {
        if (mounted) {
          setState(() {
            _loans = loans;
          });
        }
      });
    }
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      DataManager.getAccounts(),
      DataManager.getPaymentMethods(),
      DataManager.getCreditCards(),
      DataManager.getLoans(),
    ]);
    if (mounted) {
      setState(() {
        _accounts = results[0] as List<Account>;
        _paymentMethods = results[1] as List<PaymentMethod>;
        _creditCards = results[2] as List<CreditCard>;
        _loans = results[3] as List<Loan>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthTransactions = widget.transactions
        .where(
          (t) =>
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month,
        )
        .toList();
    var filtered = [...monthTransactions];

    // Apply account type filter
    if (_selectedFilter == 'cards') {
      filtered = filtered
          .where((t) => t.accountId?.startsWith('card_') ?? false)
          .toList();
    } else if (_selectedFilter == 'loans') {
      filtered = filtered
          .where((t) => t.accountId?.startsWith('loan_') ?? false)
          .toList();
    } else if (_selectedFilter == 'accounts') {
      filtered = filtered.where((t) {
        final accountId = t.accountId;
        return accountId != null &&
            !accountId.startsWith('card_') &&
            !accountId.startsWith('loan_');
      }).toList();
    }

    final monthIncome = filtered
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final monthExpense = filtered
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final monthBalance = monthIncome - monthExpense;

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
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
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedFilter,
                icon: const Icon(Icons.filter_list, size: 20),
                underline: Container(),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.all_inclusive, size: 16),
                        SizedBox(width: 4),
                        Text('All'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'accounts',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 16),
                        SizedBox(width: 4),
                        Text('Accounts'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'cards',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 16,
                          color: Color(0xFF9C27B0),
                        ),
                        SizedBox(width: 4),
                        Text('Cards'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'loans',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 16,
                          color: Color(0xFFFF9800),
                        ),
                        SizedBox(width: 4),
                        Text('Loans'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFilter = value);
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _buildMonthlySummary(
            income: monthIncome,
            expense: monthExpense,
            balance: monthBalance,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No transactions'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    final cat = widget.categories.isNotEmpty
                        ? widget.categories.firstWhere(
                            (c) => c.name == t.category,
                            orElse: () => widget.categories.first,
                          )
                        : Category(
                            id: '0',
                            name: 'Other',
                            icon: 'Category',
                            color: '#607D8B',
                            iconCode: 0xe3af,
                            colorValue: 0xFF607D8B,
                          );
                    // Check if accountId is a credit card or loan
                    final isCreditCard =
                        t.accountId?.startsWith('card_') ?? false;
                    final isLoan = t.accountId?.startsWith('loan_') ?? false;
                    final account =
                        !isCreditCard && !isLoan && t.accountId != null
                        ? _accounts.firstWhere(
                            (a) => a.id == t.accountId,
                            orElse: () => Account(
                              id: '',
                              name: 'Unknown',
                              type: 'cash',
                              balance: 0,
                            ),
                          )
                        : null;
                    final method = t.paymentMethodId != null
                        ? _paymentMethods.firstWhere(
                            (m) => m.id == t.paymentMethodId,
                            orElse: () => PaymentMethod(
                              id: '',
                              name: 'Payment',
                              type: 'cash',
                            ),
                          )
                        : null;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cat.colorData.withOpacity(0.2),
                                cat.colorData.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cat.iconData,
                            color: cat.colorData,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(t.title)),
                            if (isCreditCard)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF9C27B0,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF9C27B0,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      size: 12,
                                      color: Color(0xFF9C27B0),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'CARD',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9C27B0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isLoan)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF9800,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF9800,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_balance,
                                      size: 12,
                                      color: Color(0xFFFF9800),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'LOAN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF9800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(t.date)),
                            if (account != null)
                              Row(
                                children: [
                                  Icon(
                                    account.icon,
                                    size: 14,
                                    color: account.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    account.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: account.color,
                                    ),
                                  ),
                                ],
                              ),
                            if (isCreditCard && t.accountId != null)
                              Builder(
                                builder: (context) {
                                  final cardId = t.accountId!.substring(
                                    5,
                                  ); // Remove 'card_' prefix
                                  final card = _creditCards.firstWhere(
                                    (c) => c.id == cardId,
                                    orElse: () => CreditCard(
                                      id: '',
                                      name: 'Credit Card',
                                      creditLimit: 0,
                                      dueDate: DateTime.now(),
                                    ),
                                  );
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.credit_card,
                                        size: 14,
                                        color: Color(0xFF9C27B0),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        card.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            if (isLoan && t.accountId != null)
                              Builder(
                                builder: (context) {
                                  final loanId = t.accountId!.substring(
                                    5,
                                  ); // Remove 'loan_' prefix
                                  final loan = _loans.firstWhere(
                                    (l) => l.id == loanId,
                                    orElse: () => Loan(
                                      id: '',
                                      name: 'Loan',
                                      interestRate: 0,
                                      startDate: DateTime.now(),
                                      endDate: DateTime.now(),
                                      principalAmount: 0,
                                      totalPaid: 0,
                                      remainingAmount: 0,
                                      emiAmount: 0,
                                      tenureMonths: 0,
                                      status: 'active',
                                      nextDueDate: DateTime.now(),
                                    ),
                                  );
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance,
                                        size: 14,
                                        color: Color(0xFFFF9800),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        loan.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            if (t.type == 'transfer' && t.toAccountId != null)
                              Builder(
                                builder: (context) {
                                  final toAccount = _accounts.firstWhere(
                                    (a) => a.id == t.toAccountId,
                                    orElse: () => Account(
                                      id: '',
                                      name: 'Unknown',
                                      type: 'cash',
                                      balance: 0,
                                    ),
                                  );
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 14,
                                        color: Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        toAccount.icon,
                                        size: 14,
                                        color: toAccount.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          toAccount.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: toAccount.color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            if (method != null)
                              Row(
                                children: [
                                  Icon(
                                    method.icon,
                                    size: 14,
                                    color: method.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      method.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: method.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (method.type == 'upi' &&
                                      method.upiId != null)
                                    Flexible(
                                      child: Text(
                                        ' (${method.upiId})',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                        trailing: t.type == 'transfer'
                            ? Text(
                                '${widget.currency}${t.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : Text(
                                '${t.type == 'expense' ? '-' : '+'}${widget.currency}${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: t.type == 'expense'
                                      ? const Color(0xFFEF4444)
                                      : (isCreditCard && t.type == 'income')
                                      ? const Color(
                                          0xFF9C27B0,
                                        ) // Purple for card payments
                                      : (isLoan && t.type == 'income')
                                      ? const Color(
                                          0xFFFF9800,
                                        ) // Orange for loan payments
                                      : const Color(
                                          0xFF10B981,
                                        ), // Green for regular income
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTransactionScreen(
                                transaction: t,
                                categories: widget.categories,
                                currency: widget.currency,
                              ),
                            ),
                          );
                          widget.onChanged();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary({
    required double income,
    required double expense,
    required double balance,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryTile(
              label: 'Income',
              amount: income,
              color: const Color(0xFF10B981),
              icon: Icons.south_west,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryTile(
              label: 'Expense',
              amount: expense,
              color: const Color(0xFFEF4444),
              icon: Icons.north_east,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryTile(
              label: 'Balance',
              amount: balance,
              color: balance >= 0
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFEF4444),
              icon: Icons.account_balance_wallet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${widget.currency}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _showMonthYearPicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2011),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (date != null) {
      // Return the first day of the selected month
      return DateTime(date.year, date.month, 1);
    }
    return null;
  }
}

class AddTransactionScreen extends StatefulWidget {
  final List<Category> categories;
  final String currency;

  const AddTransactionScreen({
    super.key,
    required this.categories,
    required this.currency,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'expense'; // expense, income, transfer
  late String _category;
  DateTime _date = DateTime.now();
  List<Account> _accounts = [];
  String? _selectedAccountId;
  String? _toAccountId; // For transfers
  List<PaymentMethod> _paymentMethods = [];
  String? _selectedPaymentMethodId;
  List<CreditCard> _creditCards = [];
  List<Loan> _loans = [];

  StreamSubscription<List<Account>>? _accountsSubscription;
  StreamSubscription<List<PaymentMethod>>? _paymentMethodsSubscription;
  StreamSubscription<List<CreditCard>>? _creditCardsSubscription;
  StreamSubscription<List<Loan>>? _loansSubscription;

  @override
  void initState() {
    super.initState();
    _updateCategoryForType();
    _loadData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _paymentMethodsSubscription?.cancel();
    _creditCardsSubscription?.cancel();
    _loansSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    final accountsStream = DataManager.watchAccounts();
    if (accountsStream != null) {
      _accountsSubscription = accountsStream.listen((accounts) {
        if (mounted) {
          setState(() {
            _accounts = accounts;
            if (_selectedAccountId == null && accounts.isNotEmpty) {
              _selectedAccountId = accounts.first.id;
            }
          });
        }
      });
    }

    final methodsStream = DataManager.watchPaymentMethods();
    if (methodsStream != null) {
      _paymentMethodsSubscription = methodsStream.listen((methods) {
        if (mounted) {
          setState(() {
            _paymentMethods = methods;
            if (_selectedPaymentMethodId == null && methods.isNotEmpty) {
              _selectedPaymentMethodId = methods.first.id;
            }
          });
        }
      });
    }

    final cardsStream = DataManager.watchCreditCards();
    if (cardsStream != null) {
      _creditCardsSubscription = cardsStream.listen((cards) {
        if (mounted) {
          setState(() {
            _creditCards = cards;
          });
        }
      });
    }
  }

  void _updateCategoryForType() {
    final filteredCategories = widget.categories
        .where((c) => c.type == _type)
        .toList();
    if (filteredCategories.isNotEmpty) {
      _category = filteredCategories.first.name;
    } else {
      _category = widget.categories.isNotEmpty
          ? widget.categories.first.name
          : 'Other';
    }
  }

  List<Category> _getUniqueCategories(String type) {
    final seen = <String>{};
    return widget.categories
        .where((c) => c.type == type)
        .where((c) => seen.add(c.name))
        .toList();
  }

  String _normalizedCategoryName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'others' ? 'other' : normalized;
  }

  String? _categoryValueForType(String type) {
    final categories = _getUniqueCategories(type);
    final exactMatches = categories.where((c) => c.name == _category).toList();
    if (exactMatches.length == 1) return exactMatches.first.name;

    final normalizedCategory = _normalizedCategoryName(_category);
    final normalizedMatches = categories
        .where((c) => _normalizedCategoryName(c.name) == normalizedCategory)
        .toList();
    if (normalizedMatches.length == 1) return normalizedMatches.first.name;

    return null;
  }

  Future<void> _loadData() async {
    final accounts = await DataManager.getAccounts();
    final methods = await DataManager.getPaymentMethods();
    final cards = await DataManager.getCreditCards();
    final loans = await DataManager.getLoans();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _paymentMethods = methods;
        _creditCards = cards;
        _loans = loans;
        if (accounts.isNotEmpty) {
          _selectedAccountId = accounts.first.id;
        }
        if (methods.isNotEmpty) {
          _selectedPaymentMethodId = methods.first.id;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
                ButtonSegment(value: 'transfer', label: Text('Transfer')),
              ],
              selected: {_type},
              onSelectionChanged: (v) {
                setState(() {
                  _type = v.first;
                  if (_type != 'transfer') {
                    _toAccountId = null;
                  }
                  _updateCategoryForType();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (_type != 'transfer')
              DropdownButtonFormField<String>(
                initialValue: _categoryValueForType(_type),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _getUniqueCategories(_type)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.name,
                        child: Row(
                          children: [
                            Icon(c.iconData, size: 20, color: c.colorData),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            if (_type != 'transfer') const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue:
                  _accounts.any((a) => a.id == _selectedAccountId) ||
                      _creditCards.any(
                        (c) => 'card_${c.id}' == _selectedAccountId,
                      ) ||
                      _loans.any((l) => 'loan_${l.id}' == _selectedAccountId)
                  ? _selectedAccountId
                  : null,
              decoration: InputDecoration(
                labelText: _type == 'transfer'
                    ? 'From Account'
                    : 'Account / Credit Card / Loan',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet),
              ),
              items: [
                // Add accounts
                ..._accounts.map((a) {
                  final linkedCard = a.linkedCardId != null
                      ? _creditCards.firstWhere(
                          (c) => c.id == a.linkedCardId,
                          orElse: () => CreditCard(
                            id: '',
                            name: '',
                            creditLimit: 0,
                            dueDate: DateTime.now(),
                          ),
                        )
                      : null;

                  return DropdownMenuItem(
                    value: a.id,
                    child: Row(
                      children: [
                        Icon(a.icon, size: 20, color: a.color),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(a.name, overflow: TextOverflow.ellipsis),
                              if (linkedCard != null &&
                                  linkedCard.id.isNotEmpty)
                                Text(
                                  linkedCard.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Add credit cards (active only)
                ..._creditCards
                    .where(
                      (card) =>
                          card.outstanding < card.creditLimit ||
                          'card_${card.id}' == _selectedAccountId,
                    )
                    .map((card) {
                      return DropdownMenuItem(
                        value: 'card_${card.id}',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.credit_card,
                              size: 20,
                              color: Color(0xFF9C27B0),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 200,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    card.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Credit Card',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                // Add loans (active only)
                ..._loans.where((loan) => loan.status == 'active').map((loan) {
                  return DropdownMenuItem(
                    value: 'loan_${loan.id}',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance,
                          size: 20,
                          color: Color(0xFFFF9800),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(loan.name, overflow: TextOverflow.ellipsis),
                              Text(
                                'Loan',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _selectedAccountId = v),
              validator: (v) => v == null
                  ? _type == 'transfer'
                        ? 'Please select source account'
                        : 'Please select an account, credit card, or loan'
                  : null,
            ),
            const SizedBox(height: 16),
            if (_type == 'transfer')
              DropdownButtonFormField<String>(
                initialValue:
                    _accounts.any((a) => a.id == _toAccountId) ||
                        _loans.any((l) => 'loan_${l.id}' == _toAccountId)
                    ? _toAccountId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'To Account / Loan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: [
                  // Add regular accounts
                  ..._accounts.where((a) => a.id != _selectedAccountId).map((
                    a,
                  ) {
                    final linkedCard = a.linkedCardId != null
                        ? _creditCards.firstWhere(
                            (c) => c.id == a.linkedCardId,
                            orElse: () => CreditCard(
                              id: '',
                              name: '',
                              creditLimit: 0,
                              dueDate: DateTime.now(),
                            ),
                          )
                        : null;

                    return DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(a.icon, size: 20, color: a.color),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(a.name, overflow: TextOverflow.ellipsis),
                                if (linkedCard != null &&
                                    linkedCard.id.isNotEmpty)
                                  Text(
                                    linkedCard.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Add loans (active only)
                  ..._loans.where((loan) => loan.status == 'active').map((
                    loan,
                  ) {
                    return DropdownMenuItem(
                      value: 'loan_${loan.id}',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 20,
                            color: Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loan.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Loan Payment',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _toAccountId = v),
                validator: (v) => _type == 'transfer' && v == null
                    ? 'Please select destination account or loan'
                    : null,
              ),
            if (_type == 'transfer') const SizedBox(height: 16),
            if (_type != 'transfer')
              DropdownButtonFormField<String?>(
                initialValue:
                    _paymentMethods.any((m) => m.id == _selectedPaymentMethodId)
                    ? _selectedPaymentMethodId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Payment Method (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _paymentMethods
                    .map(
                      (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaymentMethodId = v),
              ),
            if (_type != 'transfer') const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2011),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _date = date);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text);

    // Get UPI ID from selected payment method if it's a UPI payment
    String? upiId;
    if (_selectedPaymentMethodId != null && _paymentMethods.isNotEmpty) {
      final paymentMethod = _paymentMethods.firstWhere(
        (m) => m.id == _selectedPaymentMethodId,
        orElse: () => PaymentMethod(id: '', name: '', type: 'cash'),
      );
      if (paymentMethod.type == 'upi' && paymentMethod.id.isNotEmpty) {
        upiId = paymentMethod.upiId;
      }
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: _titleCtrl.text,
      amount: amount,
      category: _type == 'transfer'
          ? 'Transfer'
          : (_categoryValueForType(_type) ?? _category),
      type: _type,
      date: _date,
      upiId: upiId,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      accountId: _selectedAccountId,
      paymentMethodId: _type != 'transfer' ? _selectedPaymentMethodId : null,
      toAccountId: _type == 'transfer' ? _toAccountId : null,
    );

    await DataManager.saveTransaction(transaction);

    // Handle account balance updates
    if (_type == 'transfer') {
      // Transfer: deduct from source, add to destination
      if (_selectedAccountId != null && _toAccountId != null) {
        final accounts = await DataManager.getAccounts();

        // Deduct from source account
        final sourceIndex = accounts.indexWhere(
          (a) => a.id == _selectedAccountId,
        );
        if (sourceIndex != -1) {
          accounts[sourceIndex].balance -= amount;
        }

        // Check if destination is a loan account
        if (_toAccountId!.startsWith('loan_')) {
          // Transfer to loan - treat as loan payment
          final loanId = _toAccountId!.substring(5);
          final loans = await DataManager.getLoans();
          final loanIndex = loans.indexWhere((l) => l.id == loanId);
          if (loanIndex != -1) {
            loans[loanIndex].paidAmount += amount;
            loans[loanIndex].remainingAmount -= amount;
            await DataManager.saveLoans(loans);
          }
        } else {
          // Add to destination account
          final destIndex = accounts.indexWhere((a) => a.id == _toAccountId);
          if (destIndex != -1) {
            accounts[destIndex].balance += amount;
          }
        }

        await DataManager.saveAccounts(accounts);
      }
    } else {
      // Regular income/expense transaction
      if (_selectedAccountId != null) {
        // Check if it's a credit card
        if (_selectedAccountId!.startsWith('card_')) {
          final cardId = _selectedAccountId!.substring(5);
          final cards = await DataManager.getCreditCards();
          final cardIndex = cards.indexWhere((c) => c.id == cardId);

          if (cardIndex != -1) {
            final card = cards[cardIndex];
            final wasOverdue = card.isOverdue;

            if (_type == 'income') {
              // Payment to credit card - reduce outstanding
              card.outstandingAmount -= amount;

              // If card was overdue and payment is made, mark as active and move due date forward
              if (wasOverdue) {
                card.status = 'active';
                // Move due date to next billing cycle
                card.dueDate = card.dueDate.add(
                  Duration(days: card.billingCycle),
                );
              }
            } else {
              // Expense on credit card - increase outstanding
              card.outstandingAmount += amount;

              // Check if this expense makes the card overdue
              if (card.isOverdue) {
                card.status = 'overdue';
              }
            }

            await DataManager.saveCreditCards(cards);
          }
        } else if (_selectedAccountId!.startsWith('loan_')) {
          // Handle loan payments
          final loanId = _selectedAccountId!.substring(5);
          final loans = await DataManager.getLoans();
          final loanIndex = loans.indexWhere((l) => l.id == loanId);

          if (loanIndex != -1 && _type == 'income') {
            // Payment towards loan
            loans[loanIndex].paidAmount += amount;
            loans[loanIndex].remainingAmount -= amount;
            await DataManager.saveLoans(loans);
          }
        } else {
          // Regular account
          final accounts = await DataManager.getAccounts();
          final accountIndex = accounts.indexWhere(
            (a) => a.id == _selectedAccountId,
          );
          if (accountIndex != -1) {
            if (_type == 'income') {
              accounts[accountIndex].balance += amount;
            } else {
              accounts[accountIndex].balance -= amount;
            }
            await DataManager.saveAccounts(accounts);
          }
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }
}

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;
  final List<Category> categories;
  final String currency;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.categories,
    required this.currency,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  late String _type;
  late String _category;
  late DateTime _date;
  List<Account> _accounts = [];
  String? _selectedAccountId;
  String? _toAccountId; // For transfers
  List<PaymentMethod> _paymentMethods = [];
  String? _selectedPaymentMethodId;
  List<CreditCard> _creditCards = [];
  List<Loan> _loans = [];

  StreamSubscription<List<Account>>? _accountsSubscription;
  StreamSubscription<List<PaymentMethod>>? _paymentMethodsSubscription;
  StreamSubscription<List<CreditCard>>? _creditCardsSubscription;
  StreamSubscription<List<Loan>>? _loansSubscription;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.transaction.title);
    _amountCtrl = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _notesCtrl = TextEditingController(text: widget.transaction.notes ?? '');
    _type = widget.transaction.type;
    _category = widget.transaction.category;
    _date = widget.transaction.date;
    _selectedAccountId = widget.transaction.accountId;
    _selectedPaymentMethodId = widget.transaction.paymentMethodId;
    _toAccountId = widget.transaction.toAccountId;
    _loadData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _paymentMethodsSubscription?.cancel();
    _creditCardsSubscription?.cancel();
    _loansSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    final accountsStream = DataManager.watchAccounts();
    if (accountsStream != null) {
      _accountsSubscription = accountsStream.listen((accounts) {
        if (mounted) {
          setState(() {
            _accounts = accounts;
          });
        }
      });
    }

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

    final cardsStream = DataManager.watchCreditCards();
    if (cardsStream != null) {
      _creditCardsSubscription = cardsStream.listen((cards) {
        if (mounted) {
          setState(() {
            _creditCards = cards;
          });
        }
      });
    }

    final loansStream = DataManager.watchLoans();
    if (loansStream != null) {
      _loansSubscription = loansStream.listen((loans) {
        if (mounted) {
          setState(() {
            _loans = loans;
          });
        }
      });
    }
  }

  void _updateCategoryForType() {
    final filteredCategories = widget.categories
        .where((c) => c.type == _type)
        .toList();
    if (filteredCategories.isNotEmpty) {
      // Check if current category matches the type
      final currentCategory = widget.categories
          .where(
            (c) =>
                _normalizedCategoryName(c.name) ==
                _normalizedCategoryName(_category),
          )
          .firstOrNull;
      if (currentCategory == null || currentCategory.type != _type) {
        _category = filteredCategories.first.name;
      }
    }
  }

  List<Category> _getUniqueCategories(String type) {
    final seen = <String>{};
    return widget.categories
        .where((c) => c.type == type)
        .where((c) => seen.add(c.name))
        .toList();
  }

  String _normalizedCategoryName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'others' ? 'other' : normalized;
  }

  String? _categoryValueForType(String type) {
    final categories = _getUniqueCategories(type);
    final exactMatches = categories.where((c) => c.name == _category).toList();
    if (exactMatches.length == 1) return exactMatches.first.name;

    final normalizedCategory = _normalizedCategoryName(_category);
    final normalizedMatches = categories
        .where((c) => _normalizedCategoryName(c.name) == normalizedCategory)
        .toList();
    if (normalizedMatches.length == 1) return normalizedMatches.first.name;

    return null;
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      DataManager.getAccounts(),
      DataManager.getPaymentMethods(),
      DataManager.getCreditCards(),
      DataManager.getLoans(),
    ]);
    if (mounted) {
      setState(() {
        _accounts = results[0] as List<Account>;
        _paymentMethods = results[1] as List<PaymentMethod>;
        _creditCards = results[2] as List<CreditCard>;
        _loans = results[3] as List<Loan>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
                ButtonSegment(value: 'transfer', label: Text('Transfer')),
              ],
              selected: {_type},
              onSelectionChanged: (v) {
                setState(() {
                  _type = v.first;
                  if (_type != 'transfer') {
                    _toAccountId = null;
                  }
                  _updateCategoryForType();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (_type != 'transfer')
              DropdownButtonFormField<String>(
                initialValue: _categoryValueForType(_type),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _getUniqueCategories(_type)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.name,
                        child: Row(
                          children: [
                            Icon(c.iconData, size: 20, color: c.colorData),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            if (_type != 'transfer') const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue:
                  _accounts.any((a) => a.id == _selectedAccountId) ||
                      _creditCards.any(
                        (c) => 'card_${c.id}' == _selectedAccountId,
                      ) ||
                      _loans.any((l) => 'loan_${l.id}' == _selectedAccountId)
                  ? _selectedAccountId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Account / Credit Card / Loan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              items: [
                // Add accounts
                ..._accounts.map((a) {
                  final linkedCard = a.linkedCardId != null
                      ? _creditCards.firstWhere(
                          (c) => c.id == a.linkedCardId,
                          orElse: () => CreditCard(
                            id: '',
                            name: '',
                            creditLimit: 0,
                            dueDate: DateTime.now(),
                          ),
                        )
                      : null;

                  return DropdownMenuItem(
                    value: a.id,
                    child: Row(
                      children: [
                        Icon(a.icon, size: 20, color: a.color),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(a.name, overflow: TextOverflow.ellipsis),
                              if (linkedCard != null &&
                                  linkedCard.id.isNotEmpty)
                                Text(
                                  linkedCard.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Add credit cards (active only)
                ..._creditCards
                    .where(
                      (card) =>
                          card.outstanding < card.creditLimit ||
                          'card_${card.id}' == _selectedAccountId,
                    )
                    .map((card) {
                      return DropdownMenuItem(
                        value: 'card_${card.id}',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.credit_card,
                              size: 20,
                              color: Color(0xFF9C27B0),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 200,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    card.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Credit Card',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                // Add loans (active only)
                ..._loans.where((loan) => loan.status == 'active').map((loan) {
                  return DropdownMenuItem(
                    value: 'loan_${loan.id}',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance,
                          size: 20,
                          color: Color(0xFFFF9800),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(loan.name, overflow: TextOverflow.ellipsis),
                              Text(
                                'Loan',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _selectedAccountId = v),
              validator: (v) => v == null
                  ? _type == 'transfer'
                        ? 'Please select source account'
                        : 'Please select an account, credit card, or loan'
                  : null,
            ),
            const SizedBox(height: 16),
            if (_type == 'transfer')
              DropdownButtonFormField<String?>(
                initialValue: _toAccountId,
                decoration: const InputDecoration(
                  labelText: 'To Account / Loan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: [
                  // Add regular accounts
                  ..._accounts.where((a) => a.id != _selectedAccountId).map((
                    a,
                  ) {
                    final linkedCard = a.linkedCardId != null
                        ? _creditCards.firstWhere(
                            (c) => c.id == a.linkedCardId,
                            orElse: () => CreditCard(
                              id: '',
                              name: '',
                              creditLimit: 0,
                              dueDate: DateTime.now(),
                            ),
                          )
                        : null;

                    return DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(a.icon, size: 20, color: a.color),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(a.name, overflow: TextOverflow.ellipsis),
                                if (linkedCard != null &&
                                    linkedCard.id.isNotEmpty)
                                  Text(
                                    linkedCard.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Add loans (active only)
                  ..._loans.where((loan) => loan.status == 'active').map((
                    loan,
                  ) {
                    return DropdownMenuItem(
                      value: 'loan_${loan.id}',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 20,
                            color: Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loan.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Loan Payment',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _toAccountId = v),
                validator: (v) => _type == 'transfer' && v == null
                    ? 'Please select destination account or loan'
                    : null,
              ),
            if (_type == 'transfer') const SizedBox(height: 16),
            if (_type != 'transfer')
              DropdownButtonFormField<String?>(
                initialValue:
                    _paymentMethods.any((m) => m.id == _selectedPaymentMethodId)
                    ? _selectedPaymentMethodId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _paymentMethods
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaymentMethodId = v),
              ),
            if (_type != 'transfer') const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2011),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _date = date);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _update,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text(
                'Update Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    final oldAmount = widget.transaction.amount;
    final oldType = widget.transaction.type;
    final oldAccountId = widget.transaction.accountId;
    final newAmount = double.parse(_amountCtrl.text);

    // Get UPI ID from selected payment method if it's a UPI payment
    String? upiId;
    if (_selectedPaymentMethodId != null && _paymentMethods.isNotEmpty) {
      final paymentMethod = _paymentMethods.firstWhere(
        (m) => m.id == _selectedPaymentMethodId,
        orElse: () => PaymentMethod(id: '', name: '', type: 'cash'),
      );
      if (paymentMethod.type == 'upi' && paymentMethod.id.isNotEmpty) {
        upiId = paymentMethod.upiId;
      }
    }

    final updated = Transaction(
      id: widget.transaction.id,
      description: _titleCtrl.text,
      amount: newAmount,
      category: _type == 'transfer'
          ? 'Transfer'
          : (_categoryValueForType(_type) ?? _category),
      type: _type,
      date: _date,
      createdAt: widget.transaction.createdAt,
      upiId: upiId,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      accountId: _selectedAccountId,
      paymentMethodId: _type != 'transfer' ? _selectedPaymentMethodId : null,
      toAccountId: _type == 'transfer' ? _toAccountId : null,
    );

    // Save the updated transaction and fetch related data in parallel
    final results = await Future.wait([
      DataManager.saveTransaction(updated),
      DataManager.getAccounts(),
      DataManager.getCreditCards(),
      DataManager.getLoans(),
    ]);
    final accounts = results[1] as List<Account>;
    final cards = results[2] as List<CreditCard>;
    final loans = results[3] as List<Loan>;
    final oldToAccountId = widget.transaction.toAccountId;

    // Reverse old transaction effects
    if (oldType == 'transfer') {
      // Reverse old transfer: add back to source, deduct from destination
      if (oldAccountId != null) {
        final oldSourceIndex = accounts.indexWhere((a) => a.id == oldAccountId);
        if (oldSourceIndex != -1) {
          accounts[oldSourceIndex].balance += oldAmount;
        }
      }
      if (oldToAccountId != null) {
        // Check if old destination was a loan
        if (oldToAccountId.startsWith('loan_')) {
          final loanId = oldToAccountId.substring(5);
          final loanIndex = loans.indexWhere((l) => l.id == loanId);
          if (loanIndex != -1) {
            // Reverse loan payment
            loans[loanIndex].paidAmount -= oldAmount;
            loans[loanIndex].remainingAmount += oldAmount;
          }
        } else {
          final oldDestIndex = accounts.indexWhere(
            (a) => a.id == oldToAccountId,
          );
          if (oldDestIndex != -1) {
            accounts[oldDestIndex].balance -= oldAmount;
          }
        }
      }
    } else {
      // Reverse old income/expense
      if (oldAccountId != null) {
        if (oldAccountId.startsWith('card_')) {
          // Reverse credit card transaction
          final cardId = oldAccountId.substring(5);
          final cardIndex = cards.indexWhere((c) => c.id == cardId);
          if (cardIndex != -1) {
            final card = cards[cardIndex];
            if (oldType == 'income') {
              // Reversing a payment - increase outstanding back
              card.outstandingAmount += oldAmount;
            } else {
              // Reversing an expense - decrease outstanding
              card.outstandingAmount -= oldAmount;
            }

            // Update status based on current overdue condition
            if (card.isOverdue) {
              card.status = 'overdue';
            }
          }
        } else if (oldAccountId.startsWith('loan_')) {
          // Reverse loan payment
          final loanId = oldAccountId.substring(5);
          final loanIndex = loans.indexWhere((l) => l.id == loanId);
          if (loanIndex != -1 && oldType == 'income') {
            loans[loanIndex].paidAmount -= oldAmount;
            loans[loanIndex].remainingAmount += oldAmount;
          }
        } else {
          // Reverse regular account transaction
          final oldAccountIndex = accounts.indexWhere(
            (a) => a.id == oldAccountId,
          );
          if (oldAccountIndex != -1) {
            if (oldType == 'income') {
              accounts[oldAccountIndex].balance -= oldAmount;
            } else {
              accounts[oldAccountIndex].balance += oldAmount;
            }
          }
        }
      }
    }

    // Apply new transaction effects
    if (_type == 'transfer') {
      // Apply new transfer: deduct from source, add to destination
      if (_selectedAccountId != null) {
        final sourceIndex = accounts.indexWhere(
          (a) => a.id == _selectedAccountId,
        );
        if (sourceIndex != -1) {
          accounts[sourceIndex].balance -= newAmount;
        }
      }
      if (_toAccountId != null) {
        // Check if destination is a loan
        if (_toAccountId!.startsWith('loan_')) {
          final loanId = _toAccountId!.substring(5);
          final loanIndex = loans.indexWhere((l) => l.id == loanId);
          if (loanIndex != -1) {
            // Apply loan payment
            loans[loanIndex].paidAmount += newAmount;
            loans[loanIndex].remainingAmount -= newAmount;
          }
        } else {
          final destIndex = accounts.indexWhere((a) => a.id == _toAccountId);
          if (destIndex != -1) {
            accounts[destIndex].balance += newAmount;
          }
        }
      }
    } else {
      // Apply new income/expense
      if (_selectedAccountId != null) {
        if (_selectedAccountId!.startsWith('card_')) {
          // Apply credit card transaction
          final cardId = _selectedAccountId!.substring(5);
          final cardIndex = cards.indexWhere((c) => c.id == cardId);
          if (cardIndex != -1) {
            final card = cards[cardIndex];
            final wasOverdue = card.isOverdue;

            if (_type == 'income') {
              // Payment to credit card - reduce outstanding
              card.outstandingAmount -= newAmount;

              // If card was overdue and payment is made, mark as active and move due date forward
              if (wasOverdue) {
                card.status = 'active';
                // Move due date to next billing cycle
                card.dueDate = card.dueDate.add(
                  Duration(days: card.billingCycle),
                );
              }
            } else {
              // Expense on credit card - increase outstanding
              card.outstandingAmount += newAmount;

              // Check if this expense makes the card overdue
              if (card.isOverdue) {
                card.status = 'overdue';
              }
            }
          }
        } else if (_selectedAccountId!.startsWith('loan_')) {
          // Apply loan payment
          final loanId = _selectedAccountId!.substring(5);
          final loanIndex = loans.indexWhere((l) => l.id == loanId);
          if (loanIndex != -1 && _type == 'income') {
            loans[loanIndex].paidAmount += newAmount;
            loans[loanIndex].remainingAmount -= newAmount;
          }
        } else {
          // Apply regular account transaction
          final newAccountIndex = accounts.indexWhere(
            (a) => a.id == _selectedAccountId,
          );
          if (newAccountIndex != -1) {
            if (_type == 'income') {
              accounts[newAccountIndex].balance += newAmount;
            } else {
              accounts[newAccountIndex].balance -= newAmount;
            }
          }
        }
      }
    }

    await Future.wait([
      DataManager.saveAccounts(accounts),
      DataManager.saveCreditCards(cards),
      DataManager.saveLoans(loans),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final results = await Future.wait([
        DataManager.getAccounts(),
        DataManager.getCreditCards(),
        DataManager.getLoans(),
      ]);
      final accounts = results[0] as List<Account>;
      final cards = results[1] as List<CreditCard>;
      final loans = results[2] as List<Loan>;

      // Reverse transaction effects on accounts
      if (widget.transaction.type == 'transfer') {
        // Reverse transfer: add back to source, deduct from destination
        if (widget.transaction.accountId != null) {
          final sourceIndex = accounts.indexWhere(
            (a) => a.id == widget.transaction.accountId,
          );
          if (sourceIndex != -1) {
            accounts[sourceIndex].balance += widget.transaction.amount;
          }
        }
        if (widget.transaction.toAccountId != null) {
          // Check if destination was a loan
          if (widget.transaction.toAccountId!.startsWith('loan_')) {
            final loanId = widget.transaction.toAccountId!.substring(5);
            final loanIndex = loans.indexWhere((l) => l.id == loanId);
            if (loanIndex != -1) {
              // Reverse loan payment
              loans[loanIndex].paidAmount -= widget.transaction.amount;
              loans[loanIndex].remainingAmount += widget.transaction.amount;
            }
          } else {
            final destIndex = accounts.indexWhere(
              (a) => a.id == widget.transaction.toAccountId,
            );
            if (destIndex != -1) {
              accounts[destIndex].balance -= widget.transaction.amount;
            }
          }
        }
      } else {
        // Reverse income/expense
        if (widget.transaction.accountId != null) {
          if (widget.transaction.accountId!.startsWith('card_')) {
            // Reverse credit card transaction
            final cardId = widget.transaction.accountId!.substring(5);
            final cardIndex = cards.indexWhere((c) => c.id == cardId);
            if (cardIndex != -1) {
              final card = cards[cardIndex];
              if (widget.transaction.type == 'income') {
                // Reversing a payment - increase outstanding back
                card.outstandingAmount += widget.transaction.amount;
              } else {
                // Reversing an expense - decrease outstanding
                card.outstandingAmount -= widget.transaction.amount;
              }

              // Update status based on current overdue condition
              if (card.isOverdue) {
                card.status = 'overdue';
              }
            }
          } else if (widget.transaction.accountId!.startsWith('loan_')) {
            // Reverse loan payment
            final loanId = widget.transaction.accountId!.substring(5);
            final loanIndex = loans.indexWhere((l) => l.id == loanId);
            if (loanIndex != -1 && widget.transaction.type == 'income') {
              loans[loanIndex].paidAmount -= widget.transaction.amount;
              loans[loanIndex].remainingAmount += widget.transaction.amount;
            }
          } else {
            // Reverse regular account transaction
            final accountIndex = accounts.indexWhere(
              (a) => a.id == widget.transaction.accountId,
            );
            if (accountIndex != -1) {
              if (widget.transaction.type == 'income') {
                accounts[accountIndex].balance -= widget.transaction.amount;
              } else {
                accounts[accountIndex].balance += widget.transaction.amount;
              }
            }
          }
        }
      }

      await Future.wait([
        DataManager.saveAccounts(accounts),
        DataManager.saveCreditCards(cards),
        DataManager.saveLoans(loans),
        DataManager.deleteTransaction(widget.transaction.id),
      ]);
      if (mounted) Navigator.pop(context);
    }
  }
}
