/// INTEGRATION EXAMPLES
/// This file demonstrates how to integrate permission checks into existing screens
library;

import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../utils/permission_utils.dart';

// ============================================================================
// EXAMPLE 1: Transaction Screen with Permission Gates
// ============================================================================

class TransactionScreenExample extends StatefulWidget {
  const TransactionScreenExample({super.key});

  @override
  State<TransactionScreenExample> createState() =>
      _TransactionScreenExampleState();
}

class _TransactionScreenExampleState extends State<TransactionScreenExample>
    with PermissionCheckerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Show export button only if user has permission
          PermissionGate(
            permission: 'exportData',
            child: IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportData,
            ),
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: checkPermission('viewTransactions'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data != true) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'You don\'t have permission to view transactions',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return _buildTransactionList();
        },
      ),
      floatingActionButton: PermissionGate(
        permission: 'addTransactions',
        child: FloatingActionButton(
          onPressed: _addTransaction,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    // Your transaction list implementation
    return ListView.builder(
      itemCount: 10, // Example
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Transaction $index'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button - only if user has permission
              PermissionGate(
                permission: 'editTransactions',
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editTransaction(index),
                ),
              ),
              // Delete button - only if user has permission
              PermissionGate(
                permission: 'deleteTransactions',
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTransaction(index),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTransaction() async {
    if (!await checkPermissionWithFeedback(context, 'addTransactions')) {
      return;
    }
    // Proceed with adding transaction
    // Navigator.push(...);
  }

  Future<void> _editTransaction(int index) async {
    if (!await checkPermissionWithFeedback(context, 'editTransactions')) {
      return;
    }
    // Proceed with editing transaction
  }

  Future<void> _deleteTransaction(int index) async {
    if (!await checkPermissionWithFeedback(context, 'deleteTransactions')) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete transaction
    }
  }

  Future<void> _exportData() async {
    // Export logic
  }
}

// ============================================================================
// EXAMPLE 2: Settings Screen with Admin Options
// ============================================================================

class SettingsScreenExample extends StatelessWidget {
  const SettingsScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Regular settings
          const ListTile(leading: Icon(Icons.person), title: Text('Profile')),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
          ),

          const Divider(),

          // Group settings section
          FutureBuilder<bool>(
            future: GroupService.isCurrentUserAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Admin Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Group Feature Permissions'),
                    subtitle: const Text('Control what members can access'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to admin settings
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => GroupAdminSettingsScreen(
                      //       groupId: currentGroupId,
                      //     ),
                      //   ),
                      // );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Manage Members'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to member management
                    },
                  ),
                  const Divider(),
                ],
              );
            },
          ),

          // More settings
          const ListTile(leading: Icon(Icons.info), title: Text('About')),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Account Management with Permissions
// ============================================================================

class AccountManagementExample extends StatefulWidget {
  const AccountManagementExample({super.key});

  @override
  State<AccountManagementExample> createState() =>
      _AccountManagementExampleState();
}

class _AccountManagementExampleState extends State<AccountManagementExample>
    with PermissionCheckerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: FutureBuilder<bool>(
        future: checkPermission('viewAccounts'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data != true) {
            return _buildNoPermissionView();
          }

          return _buildAccountList();
        },
      ),
      floatingActionButton: PermissionGate(
        permission: 'manageAccounts',
        child: FloatingActionButton.extended(
          onPressed: _addAccount,
          icon: const Icon(Icons.add),
          label: const Text('Add Account'),
        ),
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 80, color: Colors.grey),
          SizedBox(height: 24),
          Text(
            'Access Restricted',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'You don\'t have permission to view accounts',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_balance)),
            title: Text('Account $index'),
            subtitle: Text('Balance: \$${(index + 1) * 1000}'),
            trailing: FutureBuilder<bool>(
              future: checkPermission('manageAccounts'),
              builder: (context, snapshot) {
                if (snapshot.data != true) {
                  return const SizedBox.shrink();
                }

                return PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleAccountAction(value, index),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _addAccount() async {
    if (!await checkPermissionWithFeedback(context, 'manageAccounts')) {
      return;
    }
    // Navigate to add account screen
  }

  Future<void> _handleAccountAction(dynamic action, int index) async {
    if (!await checkPermissionWithFeedback(context, 'manageAccounts')) {
      return;
    }

    switch (action) {
      case 'edit':
        // Edit account
        break;
      case 'delete':
        // Delete account
        break;
    }
  }
}

// ============================================================================
// EXAMPLE 4: Reports Screen with Export Permission
// ============================================================================

class ReportsScreenExample extends StatelessWidget {
  const ReportsScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          PermissionGate(
            permission: 'exportData',
            child: IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export Reports',
              onPressed: () => _exportReports(context),
            ),
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: GroupService.canPerformAction('viewReports'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data != true) {
            return const Center(
              child: Text('You don\'t have permission to view reports'),
            );
          }

          return _buildReportsContent(context);
        },
      ),
    );
  }

  Widget _buildReportsContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard('Monthly Summary', Icons.calendar_month),
        _buildReportCard('Category Analysis', Icons.pie_chart),
        _buildReportCard('Trends', Icons.trending_up),
        _buildReportCard('Budget Overview', Icons.account_balance_wallet),
      ],
    );
  }

  Widget _buildReportCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to detailed report
        },
      ),
    );
  }

  Future<void> _exportReports(BuildContext context) async {
    if (!await checkPermissionWithFeedback(context, 'exportData')) {
      return;
    }

    // Show export options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                // Export as CSV
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                // Export as Excel
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                // Export as PDF
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: SMS Import with Permission Check
// ============================================================================

class SmsImportExample extends StatelessWidget {
  const SmsImportExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Transactions')),
      body: FutureBuilder<bool>(
        future: GroupService.canPerformAction('importSMS'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data != true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'SMS import is restricted',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact your group admin for access',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return _buildImportUI(context);
        },
      ),
    );
  }

  Widget _buildImportUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Import Transactions from SMS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Automatically detect and import transactions from your SMS messages',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _startImport(context),
              icon: const Icon(Icons.upload),
              label: const Text('Start Import'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startImport(BuildContext context) async {
    // Import SMS logic
  }
}
