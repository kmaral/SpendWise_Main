import 'package:flutter/material.dart';
import '../../services/group_service.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim().toUpperCase();
      final group = await GroupService.joinGroup(code);

      if (group != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "${group.name}"!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Family Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_add,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Join a Family Group',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the invite code shared by your family admin',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Invite Code Field
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'Enter 8-character code',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
                helperText: 'Example: ABC123XY',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the invite code';
                }
                if (value.trim().length != 8) {
                  return 'Invite code must be 8 characters';
                }
                return null;
              },
              onChanged: (value) {
                // Auto-capitalize
                final upperCase = value.toUpperCase();
                if (value != upperCase) {
                  _codeController.value = _codeController.value.copyWith(
                    text: upperCase,
                    selection: TextSelection.collapsed(
                      offset: upperCase.length,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'What happens when you join?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoPoint(
                      'You\'ll see all group transactions and budgets',
                    ),
                    _buildInfoPoint(
                      'Your transactions will be visible to other members',
                    ),
                    _buildInfoPoint('The admin can manage group members'),
                    _buildInfoPoint('You can leave the group anytime'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Join Button
            ElevatedButton(
              onPressed: _isLoading ? null : _joinGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Join Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
