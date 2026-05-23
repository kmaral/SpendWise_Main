import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';
import '../../services/sms_parser_service.dart';

class SmsImportScreen extends StatefulWidget {
  final String currency;
  final List<Category> categories;

  const SmsImportScreen({
    super.key,
    required this.currency,
    required this.categories,
  });

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  bool _isLoading = false;
  bool _hasPermission = false;
  List<Map<String, dynamic>> _parsedTransactions = [];
  Set<int> _selectedIndices = {};
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _isLoading = true);
    final hasPermission = await SmsParserService.requestSmsPermission();
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
    if (hasPermission) {
      _loadSmsTransactions();
    }
  }

  Future<void> _loadSmsTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await SmsParserService.parseRecentTransactions(
        days: _days,
      );
      setState(() {
        _parsedTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reading SMS: $e')));
      }
    }
  }

  Future<void> _importSelected() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select transactions to import')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existingTransactions = await DataManager.getTransactions();
      final accounts = await DataManager.getAccounts();
      final paymentMethods = await DataManager.getPaymentMethods();

      // Cache account and payment method IDs for faster access
      final defaultAccountId = accounts.isNotEmpty ? accounts.first.id : null;
      final defaultPaymentMethodId = paymentMethods.isNotEmpty
          ? paymentMethods.first.id
          : null;

      // Create a map for quick account lookups
      final accountMap = {for (var acc in accounts) acc.id: acc};

      // Track balance changes
      final balanceChanges = <String, double>{};

      // Process all selected transactions in batch
      final newTransactions = <Transaction>[];
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      for (var i = 0; i < _selectedIndices.length; i++) {
        final index = _selectedIndices.elementAt(i);
        final parsed = _parsedTransactions[index];

        // Create transaction
        final transaction = Transaction(
          id: '${baseTimestamp}_$i',
          description: parsed['merchant'] ?? 'SMS Transaction',
          amount: parsed['amount'],
          category: SmsParserService.suggestCategory(
            parsed['merchant'] ?? '',
            parsed['smsBody'] ?? '',
          ),
          type: parsed['type'],
          date: parsed['date'],
          upiId: parsed['upiId'],
          notes:
              'Auto-imported from SMS\nSender: ${parsed['sender']}\n${parsed['accountInfo'] ?? ''}',
          accountId: defaultAccountId,
          paymentMethodId: defaultPaymentMethodId,
        );

        newTransactions.add(transaction);

        // Accumulate balance changes
        if (transaction.accountId != null &&
            accountMap.containsKey(transaction.accountId)) {
          final change = transaction.type == 'income'
              ? transaction.amount
              : -transaction.amount;
          balanceChanges[transaction.accountId!] =
              (balanceChanges[transaction.accountId!] ?? 0) + change;
        }
      }

      // Apply all balance changes at once
      for (var entry in balanceChanges.entries) {
        final account = accountMap[entry.key];
        if (account != null) {
          account.balance += entry.value;
        }
      }

      // Add all new transactions to existing ones
      existingTransactions.addAll(newTransactions);

      // Batch save all data
      await Future.wait([
        // DataManager.saveTransactions(existingTransactions),
        DataManager.saveAccounts(accounts),
      ]);

      final imported = newTransactions.length;

      setState(() {
        _isLoading = false;
        _selectedIndices.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $imported transactions successfully'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from SMS'),
        actions: [
          if (_parsedTransactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _importSelected,
                icon: const Icon(Icons.download),
                label: Text('Import (${_selectedIndices.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
          ? _buildPermissionDenied()
          : _buildTransactionsList(),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'SMS Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'To import transactions from SMS, we need permission to read your messages. Only bank transaction SMS will be processed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkPermission,
              icon: const Icon(Icons.security),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_parsedTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transaction SMS found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing the date range',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildDateRangeSelector(),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${_parsedTransactions.length} transactions',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildDateRangeSelector(),
                  ],
                ),
              ),
              Checkbox(
                value: _selectedIndices.length == _parsedTransactions.length,
                tristate: true,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIndices = Set.from(
                        List.generate(_parsedTransactions.length, (i) => i),
                      );
                    } else {
                      _selectedIndices.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _parsedTransactions.length,
            itemBuilder: (context, index) {
              final trans = _parsedTransactions[index];
              final isSelected = _selectedIndices.contains(index);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                  ),
                  title: Text(
                    trans['merchant'] ?? 'SMS Transaction',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(trans['date']),
                      ),
                      if (trans['accountInfo'] != null)
                        Text(
                          trans['accountInfo'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (trans['upiId'] != null)
                        Text(
                          'UPI: ${trans['upiId']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          SmsParserService.suggestCategory(
                            trans['merchant'] ?? '',
                            trans['smsBody'] ?? '',
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${trans['type'] == 'expense' ? '-' : '+'}${widget.currency}${trans['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: trans['type'] == 'expense'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIndices.remove(index);
                      } else {
                        _selectedIndices.add(index);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return DropdownButton<int>(
      value: _days,
      items: const [
        DropdownMenuItem(value: 7, child: Text('Last 7 days')),
        DropdownMenuItem(value: 30, child: Text('Last 30 days')),
        DropdownMenuItem(value: 60, child: Text('Last 60 days')),
        DropdownMenuItem(value: 90, child: Text('Last 90 days')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _days = value);
          _loadSmsTransactions();
        }
      },
    );
  }
}
