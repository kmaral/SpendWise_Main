import 'package:flutter/material.dart';
import '/utils/migration_helper.dart';
import '/data/data_manager.dart';

/// Example settings screen showing Firebase integration options
/// You can integrate this into your existing settings screen
class FirebaseSettingsScreen extends StatefulWidget {
  const FirebaseSettingsScreen({super.key});

  @override
  State<FirebaseSettingsScreen> createState() => _FirebaseSettingsScreenState();
}

class _FirebaseSettingsScreenState extends State<FirebaseSettingsScreen> {
  bool _isLoading = false;
  bool _useFirebase = true;
  Map<String, int> _firebaseCounts = {};
  Map<String, int> _localCounts = {};

  @override
  void initState() {
    super.initState();
    _loadDataCounts();
  }

  Future<void> _loadDataCounts() async {
    setState(() => _isLoading = true);

    final firebaseCounts = await MigrationHelper.getFirebaseDataCounts();
    final localCounts = await MigrationHelper.getLocalDataCounts();

    setState(() {
      _firebaseCounts = firebaseCounts;
      _localCounts = localCounts;
      _isLoading = false;
    });
  }

  Future<void> _migrateToFirebase() async {
    setState(() => _isLoading = true);

    final success = await MigrationHelper.migrateLocalToFirebase();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully migrated data to Firebase!'
                : 'Migration failed. Check console for errors.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        await _loadDataCounts();
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _migrateToLocal() async {
    setState(() => _isLoading = true);

    final success = await MigrationHelper.migrateFirebaseToLocal();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully migrated data to local storage!'
                : 'Migration failed. Check console for errors.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        await _loadDataCounts();
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Firebase toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Use Firebase'),
                    subtitle: const Text(
                      'Enable to sync data with Firebase Realtime Database',
                    ),
                    value: _useFirebase,
                    onChanged: (value) {
                      setState(() => _useFirebase = value);
                      DataManager.setFirebaseMode(value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Switched to Firebase storage'
                                : 'Switched to local storage',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Firebase data counts
                Text(
                  'Firebase Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataRow(
                          'Transactions',
                          _firebaseCounts['transactions'] ?? 0,
                        ),
                        _buildDataRow(
                          'Categories',
                          _firebaseCounts['categories'] ?? 0,
                        ),
                        _buildDataRow(
                          'Accounts',
                          _firebaseCounts['accounts'] ?? 0,
                        ),
                        _buildDataRow('Loans', _firebaseCounts['loans'] ?? 0),
                        _buildDataRow(
                          'Credit Cards',
                          _firebaseCounts['creditCards'] ?? 0,
                        ),
                        _buildDataRow(
                          'Payment Methods',
                          _firebaseCounts['paymentMethods'] ?? 0,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Local data counts
                Text(
                  'Local Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataRow(
                          'Transactions',
                          _localCounts['transactions'] ?? 0,
                        ),
                        _buildDataRow(
                          'Categories',
                          _localCounts['categories'] ?? 0,
                        ),
                        _buildDataRow(
                          'Accounts',
                          _localCounts['accounts'] ?? 0,
                        ),
                        _buildDataRow('Loans', _localCounts['loans'] ?? 0),
                        _buildDataRow(
                          'Credit Cards',
                          _localCounts['creditCards'] ?? 0,
                        ),
                        _buildDataRow(
                          'Payment Methods',
                          _localCounts['paymentMethods'] ?? 0,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Migration buttons
                Text(
                  'Data Migration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: _migrateToFirebase,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Migrate Local Data to Firebase'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: _migrateToLocal,
                  icon: const Icon(Icons.download),
                  label: const Text('Migrate Firebase Data to Local'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: _loadDataCounts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data Counts'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Instructions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Toggle "Use Firebase" to switch between storage modes\n'
                          '2. Use migration buttons to copy data between storages\n'
                          '3. Check data counts to verify successful migration\n'
                          '4. Firebase data syncs across devices automatically',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDataRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
