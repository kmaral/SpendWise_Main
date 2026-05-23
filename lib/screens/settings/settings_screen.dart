import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';
import '../../utils/excel_helper.dart';

class SettingsScreen extends StatefulWidget {
  final String currency;

  const SettingsScreen({super.key, required this.currency});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _currency;
  ThemeMode _themeMode = ThemeMode.light;
  String _dateFormat = 'DD/MM/YYYY';
  String _language = 'English';
  bool _pushNotifications = true;
  int _selectedYear = DateTime.now().year;
  String _selectedMonth = 'All months';
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _currency = widget.currency;
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await DataManager.getTransactions();
    final transactionYears = _getTransactionYears(transactions);
    if (!mounted) return;
    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
      _dateFormat = prefs.getString('dateFormat') ?? 'DD/MM/YYYY';
      _language = prefs.getString('language') ?? 'English';
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _transactions = transactions;
      if (!transactionYears.contains(_selectedYear)) {
        _selectedYear = transactionYears.first;
      }
    });
  }

  Future<void> _exportToExcel() async {
    try {
      // Show year/month selection dialog
      final now = DateTime.now();
      int? selectedYear;
      String? selectedMonth;

      final filterResult = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Select Export Period'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose the year and month to export:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedYear ?? now.year,
                  items: List.generate(10, (index) => now.year - 5 + index)
                      .map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedYear = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedMonth ?? 'All',
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All Months'),
                    ),
                    ...List.generate(12, (index) {
                      final monthNum = index + 1;
                      return DropdownMenuItem(
                        value: monthNum.toString(),
                        child: Text(
                          DateTime(
                            now.year,
                            monthNum,
                          ).toString().split(' ')[0].split('-')[1],
                        ),
                      );
                    }).map((item) {
                      final monthNum = int.parse(item.value!);
                      final monthName = [
                        'January',
                        'February',
                        'March',
                        'April',
                        'May',
                        'June',
                        'July',
                        'August',
                        'September',
                        'October',
                        'November',
                        'December',
                      ][monthNum - 1];
                      return DropdownMenuItem(
                        value: item.value,
                        child: Text(monthName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => selectedMonth = value);
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
                onPressed: () => Navigator.pop(context, {
                  'year': selectedYear ?? now.year,
                  'month': selectedMonth ?? 'All',
                }),
                child: const Text('Export'),
              ),
            ],
          ),
        ),
      );

      if (filterResult == null) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Exporting to Excel...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final allTransactions = await DataManager.getTransactions();
      final accounts = await DataManager.getAccounts();

      // Filter transactions by year and month
      final year = filterResult['year'] as int;
      final monthStr = filterResult['month'] as String;

      final filteredTransactions = allTransactions.where((t) {
        if (t.date.year != year) return false;
        if (monthStr != 'All') {
          final month = int.parse(monthStr);
          if (t.date.month != month) return false;
        }
        return true;
      }).toList();

      final filePath = await ExcelHelper.exportTransactions(
        filteredTransactions,
        accounts,
        _currency,
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (filePath != null) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Successful'),
              content: Text(
                'Exported ${filteredTransactions.length} transactions successfully!\n\nFile saved to:\n$filePath',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open File'),
                ),
              ],
            ),
          );

          if (result == true) {
            await ExcelHelper.openExcelFile(filePath);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to export transactions'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importFromExcel() async {
    try {
      // Show info dialog first
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import from Excel'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Excel file should have the following columns:'),
              SizedBox(height: 8),
              Text('• S.no'),
              Text('• Date (dd-MM-yyyy)'),
              Text('• Category'),
              Text('• Credit (for income)'),
              Text('• Debit (for expenses)'),
              Text('• Balance'),
              Text('• Remarks'),
              SizedBox(height: 16),
              Text(
                'Note: Existing transactions will not be deleted.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Importing from Excel...'),
                ],
              ),
            ),
          ),
        ),
      );

      final importedTransactions = await ExcelHelper.importTransactions();

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (importedTransactions.isNotEmpty) {
        // Save imported transactions
        for (final transaction in importedTransactions) {
          await DataManager.saveTransaction(transaction);
        }

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Successful'),
              content: Text(
                'Successfully imported ${importedTransactions.length} transaction${importedTransactions.length == 1 ? '' : 's'}!',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No transactions found in the file'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Customize your app preferences',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionCard(
            icon: Icons.brightness_6,
            title: 'Appearance',
            subtitle: 'Customize the look and feel',
            children: [
              _buildSettingTile(
                title: 'Theme',
                subtitle: 'Select your preferred theme',
                value: _themeMode == ThemeMode.light
                    ? 'System'
                    : _themeMode == ThemeMode.dark
                    ? 'Dark'
                    : 'Light',
                onTap: () async {
                  final result = await showDialog<ThemeMode>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Theme'),
                      children: [
                        SimpleDialogOption(
                          onPressed: () =>
                              Navigator.pop(context, ThemeMode.system),
                          child: const Text('System'),
                        ),
                        SimpleDialogOption(
                          onPressed: () =>
                              Navigator.pop(context, ThemeMode.light),
                          child: const Text('Light'),
                        ),
                        SimpleDialogOption(
                          onPressed: () =>
                              Navigator.pop(context, ThemeMode.dark),
                          child: const Text('Dark'),
                        ),
                      ],
                    ),
                  );
                  if (result != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('themeMode', result.index);
                    setState(() => _themeMode = result);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Regional Settings Section
          _buildSectionCard(
            icon: Icons.language,
            title: 'Regional Settings',
            subtitle: 'Configure regional preferences',
            children: [
              _buildSettingTile(
                title: 'Currency',
                subtitle: 'Your default currency',
                value: _currency,
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Currency'),
                      children:
                          [
                                {'symbol': '₹', 'name': '₹ INR'},
                                {'symbol': '\$', 'name': '\$ USD'},
                                {'symbol': '€', 'name': '€ EUR'},
                                {'symbol': '£', 'name': '£ GBP'},
                                {'symbol': '¥', 'name': '¥ JPY'},
                              ]
                              .map(
                                (c) => SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, c['symbol']),
                                  child: Text(c['name']!),
                                ),
                              )
                              .toList(),
                    ),
                  );
                  if (result != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('currency', result);
                    setState(() => _currency = result);
                  }
                },
              ),
              _buildSettingTile(
                title: 'Date Format',
                subtitle: 'How dates are displayed',
                value: _dateFormat,
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Date Format'),
                      children: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD']
                          .map(
                            (format) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, format),
                              child: Text(format),
                            ),
                          )
                          .toList(),
                    ),
                  );
                  if (result != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('dateFormat', result);
                    setState(() => _dateFormat = result);
                  }
                },
              ),
              _buildSettingTile(
                title: 'Language',
                subtitle: 'Interface language',
                value: _language,
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Language'),
                      children: ['English', 'Hindi', 'Spanish', 'French']
                          .map(
                            (lang) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, lang),
                              child: Text(lang),
                            ),
                          )
                          .toList(),
                    ),
                  );
                  if (result != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('language', result);
                    setState(() => _language = result);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionCard(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive alerts and reminders',
                value: _pushNotifications,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('pushNotifications', value);
                  setState(() => _pushNotifications = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // // Data Management Section
          // _buildSectionCard(
          //   icon: Icons.storage,
          //   title: 'Data Management',
          //   subtitle: 'Import, export, and manage your data',
          //   children: [
          //     ListTile(
          //       leading: Container(
          //         padding: const EdgeInsets.all(8),
          //         decoration: BoxDecoration(
          //           color: const Color(0xFF10B981).withOpacity(0.1),
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //         child: const Icon(
          //           Icons.file_download,
          //           color: Color(0xFF10B981),
          //         ),
          //       ),
          //       title: const Text('Export to Excel'),
          //       subtitle: const Text('Export all transactions to Excel file'),
          //       trailing: const Icon(Icons.chevron_right),
          //       onTap: _exportToExcel,
          //     ),
          //     ListTile(
          //       leading: Container(
          //         padding: const EdgeInsets.all(8),
          //         decoration: BoxDecoration(
          //           color: const Color(0xFF3B82F6).withOpacity(0.1),
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //         child: const Icon(
          //           Icons.file_upload,
          //           color: Color(0xFF3B82F6),
          //         ),
          //       ),
          //       title: const Text('Import from Excel'),
          //       subtitle: const Text('Import transactions from Excel file'),
          //       trailing: const Icon(Icons.chevron_right),
          //       onTap: _importFromExcel,
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 16),

          // // Danger Zone Section
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.red.withOpacity(0.05),
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          //   ),
          //   padding: const EdgeInsets.all(16),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(Icons.warning, color: Colors.red[700], size: 20),
          //           const SizedBox(width: 8),
          //           Text(
          //             'Danger Zone',
          //             style: TextStyle(
          //               fontSize: 16,
          //               fontWeight: FontWeight.bold,
          //               color: Colors.red[700],
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 4),
          //       Text(
          //         'Irreversible actions - proceed with caution',
          //         style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          //       ),
          //       const SizedBox(height: 16),

          //       // Delete Transactions by Period
          //       Container(
          //         decoration: BoxDecoration(
          //           color: Colors.red.withOpacity(0.05),
          //           borderRadius: BorderRadius.circular(12),
          //           border: Border.all(color: Colors.red.withOpacity(0.2)),
          //         ),
          //         padding: const EdgeInsets.all(16),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Row(
          //               children: [
          //                 Icon(
          //                   Icons.delete_outline,
          //                   color: Colors.red[700],
          //                   size: 20,
          //                 ),
          //                 const SizedBox(width: 8),
          //                 Expanded(
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Text(
          //                         'Delete Transactions by Period',
          //                         style: TextStyle(
          //                           fontWeight: FontWeight.bold,
          //                           color: Colors.red[700],
          //                         ),
          //                       ),
          //                       Text(
          //                         'Delete all transactions from a specific year or month',
          //                         style: TextStyle(
          //                           fontSize: 12,
          //                           color: Colors.grey[600],
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             const SizedBox(height: 16),
          //             Row(
          //               children: [
          //                 Expanded(
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       const Text(
          //                         'Year',
          //                         style: TextStyle(
          //                           fontSize: 12,
          //                           fontWeight: FontWeight.w500,
          //                         ),
          //                       ),
          //                       const SizedBox(height: 8),
          //                       DropdownButtonFormField<int>(
          //                         initialValue: _selectedYear,
          //                         decoration: InputDecoration(
          //                           border: OutlineInputBorder(
          //                             borderRadius: BorderRadius.circular(8),
          //                           ),
          //                           contentPadding: const EdgeInsets.symmetric(
          //                             horizontal: 12,
          //                             vertical: 8,
          //                           ),
          //                         ),
          //                         items: _getTransactionYears(_transactions)
          //                             .map(
          //                               (year) => DropdownMenuItem(
          //                                 value: year,
          //                                 child: Text(year.toString()),
          //                               ),
          //                             )
          //                             .toList(),
          //                         onChanged: (value) {
          //                           if (value != null) {
          //                             setState(() => _selectedYear = value);
          //                           }
          //                         },
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //                 const SizedBox(width: 12),
          //                 Expanded(
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       const Text(
          //                         'Month',
          //                         style: TextStyle(
          //                           fontSize: 12,
          //                           fontWeight: FontWeight.w500,
          //                         ),
          //                       ),
          //                       const SizedBox(height: 8),
          //                       DropdownButtonFormField<String>(
          //                         initialValue: _selectedMonth,
          //                         decoration: InputDecoration(
          //                           border: OutlineInputBorder(
          //                             borderRadius: BorderRadius.circular(8),
          //                           ),
          //                           contentPadding: const EdgeInsets.symmetric(
          //                             horizontal: 12,
          //                             vertical: 8,
          //                           ),
          //                         ),
          //                         items:
          //                             [
          //                                   'All months',
          //                                   'January',
          //                                   'February',
          //                                   'March',
          //                                   'April',
          //                                   'May',
          //                                   'June',
          //                                   'July',
          //                                   'August',
          //                                   'September',
          //                                   'October',
          //                                   'November',
          //                                   'December',
          //                                 ]
          //                                 .map(
          //                                   (month) => DropdownMenuItem(
          //                                     value: month,
          //                                     child: Text(
          //                                       month,
          //                                       style: const TextStyle(
          //                                         fontSize: 14,
          //                                       ),
          //                                     ),
          //                                   ),
          //                                 )
          //                                 .toList(),
          //                         onChanged: (value) {
          //                           if (value != null) {
          //                             setState(() => _selectedMonth = value);
          //                           }
          //                         },
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             const SizedBox(height: 16),
          //             SizedBox(
          //               width: double.infinity,
          //               child: ElevatedButton.icon(
          //                 onPressed: _getTransactionCount() == '0'
          //                     ? null
          //                     : _deleteTransactionsByPeriod,
          //                 style: ElevatedButton.styleFrom(
          //                   backgroundColor: Colors.red,
          //                   foregroundColor: Colors.white,
          //                   padding: const EdgeInsets.symmetric(vertical: 12),
          //                   shape: RoundedRectangleBorder(
          //                     borderRadius: BorderRadius.circular(8),
          //                   ),
          //                 ),
          //                 icon: const Icon(Icons.delete),
          //                 label: Text('Delete (${_getTransactionCount()})'),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       const SizedBox(height: 16),

          //       // Clear All Data
          //       Container(
          //         decoration: BoxDecoration(
          //           color: Colors.red.withOpacity(0.05),
          //           borderRadius: BorderRadius.circular(12),
          //           border: Border.all(color: Colors.red.withOpacity(0.2)),
          //         ),
          //         padding: const EdgeInsets.all(16),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Row(
          //               children: [
          //                 Icon(
          //                   Icons.warning_amber,
          //                   color: Colors.red[700],
          //                   size: 20,
          //                 ),
          //                 const SizedBox(width: 8),
          //                 Expanded(
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Text(
          //                         'Clear All Data',
          //                         style: TextStyle(
          //                           fontWeight: FontWeight.bold,
          //                           color: Colors.red[700],
          //                         ),
          //                       ),
          //                       Text(
          //                         'Permanently delete all transactions, categories, budgets, loans, credit cards, and settings',
          //                         style: TextStyle(
          //                           fontSize: 12,
          //                           color: Colors.grey[600],
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             const SizedBox(height: 16),
          //             SizedBox(
          //               width: double.infinity,
          //               child: ElevatedButton.icon(
          //                 onPressed: _clearAllData,
          //                 style: ElevatedButton.styleFrom(
          //                   backgroundColor: Colors.red[700],
          //                   foregroundColor: Colors.white,
          //                   padding: const EdgeInsets.symmetric(vertical: 12),
          //                   shape: RoundedRectangleBorder(
          //                     borderRadius: BorderRadius.circular(8),
          //                   ),
          //                 ),
          //                 icon: const Icon(Icons.delete_forever),
          //                 label: const Text('Clear All Data'),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 24),

          // App Info
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SpendWise - Expense Manager',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 2.0.0',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your finances with ease',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF10B981),
    );
  }

  List<int> _getTransactionYears(List<Transaction> transactions) {
    if (transactions.isEmpty) return [DateTime.now().year];

    final years = transactions.map((t) => t.date.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  int? _selectedMonthIndex() {
    if (_selectedMonth == 'All months') return null;

    return [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ].indexOf(_selectedMonth) +
        1;
  }

  String _getTransactionCount() {
    final monthIndex = _selectedMonthIndex();
    final count = _transactions.where((t) {
      if (t.date.year != _selectedYear) return false;
      return monthIndex == null || t.date.month == monthIndex;
    }).length;

    return count.toString();
  }

  Future<void> _deleteTransactionsByPeriod() async {
    final monthIndex = _selectedMonthIndex();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transactions'),
        content: Text(
          monthIndex == null
              ? 'Delete all transactions from year $_selectedYear?'
              : 'Delete all transactions from $_selectedMonth $_selectedYear?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final allTransactions = await DataManager.getTransactions();
      for (final t in allTransactions) {
        if (monthIndex == null) {
          if (t.date.year == _selectedYear) {
            await DataManager.deleteTransaction(t.id);
          }
        } else {
          if (t.date.year == _selectedYear && t.date.month == monthIndex) {
            await DataManager.deleteTransaction(t.id);
          }
        }
      }

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transactions deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete ALL your data including:\n\n'
          '• All transactions\n'
          '• All categories\n'
          '• All budgets\n'
          '• All loans and credit cards\n'
          '• All settings\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Second confirmation
      final doubleConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: const Text(
            'This is your last chance to cancel.\n\n'
            'All your data will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Delete Everything'),
            ),
          ],
        ),
      );

      if (doubleConfirm == true) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Clearing all data...'),
                  ],
                ),
              ),
            ),
          ),
        );

        try {
          // Delete all data from Firebase
          final transactions = await DataManager.getTransactions();
          for (final t in transactions) {
            await DataManager.deleteTransaction(t.id);
          }

          // Clear local preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All data cleared successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }
}
