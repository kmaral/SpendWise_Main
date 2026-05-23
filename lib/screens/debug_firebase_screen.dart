import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';

class DebugFirebaseScreen extends StatefulWidget {
  const DebugFirebaseScreen({super.key});

  @override
  State<DebugFirebaseScreen> createState() => _DebugFirebaseScreenState();
}

class _DebugFirebaseScreenState extends State<DebugFirebaseScreen> {
  String _status = 'Checking Firebase connection...';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkFirebase();
  }

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  Future<void> _checkFirebase() async {
    try {
      _log('Starting Firebase check...');

      // Check if Firebase is initialized
      _log('Checking Firebase initialization...');
      _log('Firebase Database instance obtained');

      // Try to read from categories
      _log('Attempting to read categories from Firebase...');
      final categories = await FirebaseService.getCategories();
      _log('Categories fetched: ${categories.length} items');

      // Try to read from transactions
      _log('Attempting to read transactions from Firebase...');
      final transactions = await FirebaseService.getTransactions();
      _log('Transactions fetched: ${transactions.length} items');

      // Try to read from accounts
      _log('Attempting to read accounts from Firebase...');
      final accounts = await FirebaseService.getAccounts();
      _log('Accounts fetched: ${accounts.length} items');

      setState(() {
        _status = 'Firebase is working! Data loaded successfully.';
      });
    } catch (e, stackTrace) {
      _log('ERROR: $e');
      _log('Stack trace: ${stackTrace.toString().substring(0, 200)}...');
      setState(() {
        _status = 'Firebase connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _logs.clear();
                _status = 'Checking Firebase connection...';
              });
              _checkFirebase();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: _status.contains('failed') || _status.contains('ERROR')
                  ? Colors.red.shade100
                  : _status.contains('working')
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Logs:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: log.contains('ERROR')
                              ? Colors.red
                              : log.contains('fetched')
                              ? Colors.green
                              : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Test saving a category to Firebase
                _log('Testing Firebase write operation...');
                try {
                  await FirebaseService.saveCategory(
                    Category(
                      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
                      name: 'Test Category',
                      icon: 'TestIcon',
                      color: '#FF0000',
                    ),
                  );
                  _log('Write operation successful!');
                } catch (e) {
                  _log('Write operation failed: $e');
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Test Firebase Write'),
            ),
          ],
        ),
      ),
    );
  }
}
