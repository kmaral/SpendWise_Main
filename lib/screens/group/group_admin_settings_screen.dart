import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/group_feature_permissions.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';

class GroupAdminSettingsScreen extends StatefulWidget {
  final String groupId;

  const GroupAdminSettingsScreen({super.key, required this.groupId});

  @override
  State<GroupAdminSettingsScreen> createState() =>
      _GroupAdminSettingsScreenState();
}

class _GroupAdminSettingsScreenState extends State<GroupAdminSettingsScreen> {
  Group? _group;
  bool _isLoading = true;
  bool _isSaving = false;

  // Permission states
  late bool _canViewTransactions;
  late bool _canAddTransactions;
  late bool _canEditTransactions;
  late bool _canDeleteTransactions;
  late bool _canViewAccounts;
  late bool _canManageAccounts;
  late bool _canViewReports;
  late bool _canExportData;
  late bool _canViewPaymentMethods;
  late bool _canManagePaymentMethods;
  late bool _canViewLoans;
  late bool _canManageLoans;
  late bool _canViewCreditCards;
  late bool _canManageCreditCards;
  late bool _canImportSMS;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final group = await GroupService.getGroup(widget.groupId);
      if (group == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Group not found')));
        }
        return;
      }

      // Check if current user is admin
      final currentUser = AuthService.currentProfile;
      if (currentUser == null || !group.isAdmin(currentUser.id)) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only admins can access this page')),
          );
        }
        return;
      }

      final permissions = group.featurePermissions;
      setState(() {
        _group = group;
        _canViewTransactions = permissions.canViewTransactions;
        _canAddTransactions = permissions.canAddTransactions;
        _canEditTransactions = permissions.canEditTransactions;
        _canDeleteTransactions = permissions.canDeleteTransactions;
        _canViewAccounts = permissions.canViewAccounts;
        _canManageAccounts = permissions.canManageAccounts;
        _canViewReports = permissions.canViewReports;
        _canExportData = permissions.canExportData;
        _canViewPaymentMethods = permissions.canViewPaymentMethods;
        _canManagePaymentMethods = permissions.canManagePaymentMethods;
        _canViewLoans = permissions.canViewLoans;
        _canManageLoans = permissions.canManageLoans;
        _canViewCreditCards = permissions.canViewCreditCards;
        _canManageCreditCards = permissions.canManageCreditCards;
        _canImportSMS = permissions.canImportSMS;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading group: $e')));
      }
    }
  }

  Future<void> _savePermissions() async {
    if (_group == null) return;

    setState(() => _isSaving = true);

    try {
      final newPermissions = GroupFeaturePermissions(
        canViewTransactions: _canViewTransactions,
        canAddTransactions: _canAddTransactions,
        canEditTransactions: _canEditTransactions,
        canDeleteTransactions: _canDeleteTransactions,
        canViewAccounts: _canViewAccounts,
        canManageAccounts: _canManageAccounts,
        canViewReports: _canViewReports,
        canExportData: _canExportData,
        canViewPaymentMethods: _canViewPaymentMethods,
        canManagePaymentMethods: _canManagePaymentMethods,
        canViewLoans: _canViewLoans,
        canManageLoans: _canManageLoans,
        canViewCreditCards: _canViewCreditCards,
        canManageCreditCards: _canManageCreditCards,
        canImportSMS: _canImportSMS,
      );

      await GroupService.updateFeaturePermissions(
        widget.groupId,
        newPermissions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildPermissionSection(
    String title,
    List<Map<String, dynamic>> permissions,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...permissions.map(
            (perm) => _buildPermissionSwitch(
              perm['title'] as String,
              perm['description'] as String,
              perm['value'] as bool,
              perm['onChanged'] as Function(bool),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSwitch(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      value: value,
      onChanged: (val) {
        setState(() => onChanged(val));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Feature Settings'),
        actions: [
          if (!_isLoading && _group != null)
            TextButton.icon(
              onPressed: _isSaving ? null : _savePermissions,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                'Save',
                style: TextStyle(
                  color: _isSaving ? Colors.white54 : Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _group == null
          ? const Center(child: Text('Group not found'))
          : ListView(
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _group!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure what features group members can access',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Members: ${_group!.memberCount}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Transactions Permissions
                _buildPermissionSection('Transactions', [
                  {
                    'title': 'View Transactions',
                    'description': 'Allow members to view transaction history',
                    'value': _canViewTransactions,
                    'onChanged': (bool val) => _canViewTransactions = val,
                  },
                  {
                    'title': 'Add Transactions',
                    'description': 'Allow members to add new transactions',
                    'value': _canAddTransactions,
                    'onChanged': (bool val) => _canAddTransactions = val,
                  },
                  {
                    'title': 'Edit Transactions',
                    'description':
                        'Allow members to edit existing transactions',
                    'value': _canEditTransactions,
                    'onChanged': (bool val) => _canEditTransactions = val,
                  },
                  {
                    'title': 'Delete Transactions',
                    'description': 'Allow members to delete transactions',
                    'value': _canDeleteTransactions,
                    'onChanged': (bool val) => _canDeleteTransactions = val,
                  },
                ]),

                // Accounts Permissions
                _buildPermissionSection('Accounts', [
                  {
                    'title': 'View Accounts',
                    'description': 'Allow members to view account information',
                    'value': _canViewAccounts,
                    'onChanged': (bool val) => _canViewAccounts = val,
                  },
                  {
                    'title': 'Manage Accounts',
                    'description':
                        'Allow members to create, edit, and delete accounts',
                    'value': _canManageAccounts,
                    'onChanged': (bool val) => _canManageAccounts = val,
                  },
                ]),

                // Payment Methods Permissions
                _buildPermissionSection('Payment Methods', [
                  {
                    'title': 'View Payment Methods',
                    'description': 'Allow members to view payment methods',
                    'value': _canViewPaymentMethods,
                    'onChanged': (bool val) => _canViewPaymentMethods = val,
                  },
                  {
                    'title': 'Manage Payment Methods',
                    'description':
                        'Allow members to add, edit, and delete payment methods',
                    'value': _canManagePaymentMethods,
                    'onChanged': (bool val) => _canManagePaymentMethods = val,
                  },
                ]),

                // Loans Permissions
                _buildPermissionSection('Loans', [
                  {
                    'title': 'View Loans',
                    'description': 'Allow members to view loan information',
                    'value': _canViewLoans,
                    'onChanged': (bool val) => _canViewLoans = val,
                  },
                  {
                    'title': 'Manage Loans',
                    'description':
                        'Allow members to create, edit, and manage loans',
                    'value': _canManageLoans,
                    'onChanged': (bool val) => _canManageLoans = val,
                  },
                ]),

                // Credit Cards Permissions
                _buildPermissionSection('Credit Cards', [
                  {
                    'title': 'View Credit Cards',
                    'description':
                        'Allow members to view credit card information',
                    'value': _canViewCreditCards,
                    'onChanged': (bool val) => _canViewCreditCards = val,
                  },
                  {
                    'title': 'Manage Credit Cards',
                    'description':
                        'Allow members to add, edit, and manage credit cards',
                    'value': _canManageCreditCards,
                    'onChanged': (bool val) => _canManageCreditCards = val,
                  },
                ]),

                // Reports & Data Permissions
                _buildPermissionSection('Reports & Data', [
                  {
                    'title': 'View Reports',
                    'description':
                        'Allow members to view financial reports and analytics',
                    'value': _canViewReports,
                    'onChanged': (bool val) => _canViewReports = val,
                  },
                  {
                    'title': 'Export Data',
                    'description': 'Allow members to export data to CSV/Excel',
                    'value': _canExportData,
                    'onChanged': (bool val) => _canExportData = val,
                  },
                  {
                    'title': 'Import SMS',
                    'description':
                        'Allow members to import transactions from SMS',
                    'value': _canImportSMS,
                    'onChanged': (bool val) => _canImportSMS = val,
                  },
                ]),

                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: !_isLoading && _group != null
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _savePermissions,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Permissions'),
            )
          : null,
    );
  }
}
