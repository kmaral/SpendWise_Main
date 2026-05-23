import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/data_manager.dart';
import '../models/models.dart';
import 'accounts/accounts_screens.dart';
import 'cards/cards_screens.dart';
import 'categories/categories_screens.dart';
import 'dashboard/dashboard_screen.dart';
import 'dashboard/dashboard_skeleton.dart';
import 'loans/loans_screens.dart';
import 'payment_methods/payment_methods_screens.dart';
import 'reports/reports_screen.dart';
import 'settings/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/transactions_screens.dart';
import 'upi/upi_reports_screen.dart';
import 'reports/payment_method_report_screen.dart';

class MainScreen extends StatefulWidget {
  final String currency;
  final VoidCallback onSettingsChanged;

  const MainScreen({
    super.key,
    required this.currency,
    required this.onSettingsChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isFirstLoad = true;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Loan> _loans = [];
  List<CreditCard> _creditCards = [];
  List<Account> _accounts = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isConnected = true;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<Transaction>>? _transactionsSubscription;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<List<Loan>>? _loansSubscription;
  StreamSubscription<List<CreditCard>>? _creditCardsSubscription;
  StreamSubscription<List<Account>>? _accountsSubscription;
  StreamSubscription<List<PaymentMethod>>? _paymentMethodsSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeListeners();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _loansSubscription?.cancel();
    _creditCardsSubscription?.cancel();
    _accountsSubscription?.cancel();
    _paymentMethodsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Setup real-time listeners for Firestore data
    final transactionsStream = DataManager.watchTransactions();
    if (transactionsStream != null) {
      _transactionsSubscription = transactionsStream.listen((transactions) {
        if (mounted) {
          setState(() {
            _transactions = transactions;
          });
        }
      });
    }

    final categoriesStream = DataManager.watchCategories();
    if (categoriesStream != null) {
      _categoriesSubscription = categoriesStream.listen((categories) {
        if (mounted) {
          setState(() {
            _categories = categories;
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

    final creditCardsStream = DataManager.watchCreditCards();
    if (creditCardsStream != null) {
      _creditCardsSubscription = creditCardsStream.listen((cards) {
        if (mounted) {
          setState(() {
            _creditCards = cards;
          });
        }
      });
    }

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

    final paymentMethodsStream = DataManager.watchPaymentMethods();
    if (paymentMethodsStream != null) {
      _paymentMethodsSubscription = paymentMethodsStream.listen((methods) {
        if (mounted) {
          setState(() {
            _paymentMethods = methods;
          });
        }
      });
    }
  }

  Future<void> _checkConnectivity() async {
    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (mounted) {
      setState(() {
        _isConnected =
            result.isNotEmpty && !result.contains(ConnectivityResult.none);
      });
    }
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      DataManager.getTransactions(),
      DataManager.getCategories(),
      DataManager.getLoans(),
      DataManager.getCreditCards(),
      DataManager.getAccounts(),
      DataManager.getPaymentMethods(),
    ]);
    if (mounted) {
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _categories = results[1] as List<Category>;
        _loans = results[2] as List<Loan>;
        _creditCards = results[3] as List<CreditCard>;
        _accounts = results[4] as List<Account>;
        _paymentMethods = results[5] as List<PaymentMethod>;
        _isFirstLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _isFirstLoad
          ? const DashboardSkeleton()
          : DashboardScreen(
              transactions: _transactions,
              categories: _categories,
              creditCards: _creditCards,
              loans: _loans,
              accounts: _accounts,
              paymentMethods: _paymentMethods,
              currency: widget.currency,
            ),
      TransactionsListScreen(
        transactions: _transactions,
        categories: _categories,
        currency: widget.currency,
        onChanged: _loadData,
      ),
      AccountsScreen(
        accounts: _accounts,
        currency: widget.currency,
        onChanged: _loadData,
        creditCards: _creditCards,
      ),
      ReportsScreen(
        transactions: _transactions,
        categories: _categories,
        currency: widget.currency,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'SpendWise',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(width: 8),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Accounts',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(
                      categories: _categories,
                      currency: widget.currency,
                    ),
                  ),
                );
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              elevation: 4,
            )
          : _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAccountScreen(
                      currency: widget.currency,
                      creditCards: _creditCards,
                    ),
                  ),
                );
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              elevation: 4,
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const Image(
                    image: AssetImage('assets/icon/spendwise_rupee_spin.gif'),
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SpendWise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.credit_card,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Credit Cards'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreditCardsScreen(
                    cards: _creditCards,
                    currency: widget.currency,
                    onChanged: _loadData,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.account_balance,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Loans'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoansScreen(
                    loans: _loans,
                    currency: widget.currency,
                    onChanged: _loadData,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.payment,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Payment Methods'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentMethodsScreen(
                    accounts: _accounts,
                    creditCards: _creditCards,
                    onChanged: _loadData,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.category,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Manage Categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoriesScreen(currency: widget.currency),
                ),
              );
              _loadData();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.qr_code,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('UPI Reports'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpiReportsScreen(
                    transactions: _transactions,
                    currency: widget.currency,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.assessment,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Payment Method Report'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PaymentMethodReportScreen(currency: widget.currency),
                ),
              );
            },
          ),
          const Divider(),
          // ListTile(
          //   leading: Icon(
          //     Icons.person,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          //   title: const Text('Profile'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () async {
          //     Navigator.pop(context);
          //     await Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             ProfileScreen(currency: widget.currency),
          //       ),
          //     );
          //   },
          // ),
          // ListTile(
          //   leading: Icon(
          //     Icons.settings,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          //   title: const Text('Settings'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () async {
          //     Navigator.pop(context);
          //     await Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             SettingsScreen(currency: widget.currency),
          //       ),
          //     );
          //     widget.onSettingsChanged();
          //     _loadData();
          //   },
          // ),
        ],
      ),
    );
  }
}
