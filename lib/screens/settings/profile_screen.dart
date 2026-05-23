import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  final String currency;

  const ProfileScreen({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'KharchaBook User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: const Text('user@kharchabook.com'),
                ),
                ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: const Text('Currency'),
                  subtitle: Text(currency),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Member Since'),
                  subtitle: Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
