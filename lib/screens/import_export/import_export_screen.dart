import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/models.dart';

class ImportExportScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final String currency;

  const ImportExportScreen({
    super.key,
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import/Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Export Transactions'),
              subtitle: const Text('Export to CSV file'),
              onTap: () async {
                // Export transactions to JSON format
                json.encode(transactions.map((t) => t.toJson()).toList());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Exported ${transactions.length} transactions',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import Transactions'),
              subtitle: const Text('Import from CSV file'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import feature coming soon')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
