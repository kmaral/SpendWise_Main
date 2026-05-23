import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final List<Account> accounts;
  final List<CreditCard> creditCards;
  final VoidCallback onChanged;

  const PaymentMethodsScreen({
    super.key,
    required this.accounts,
    required this.creditCards,
    required this.onChanged,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<PaymentMethod> _methods = [];
  StreamSubscription<List<PaymentMethod>>? _methodsSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _methodsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    final methodsStream = DataManager.watchPaymentMethods();
    if (methodsStream != null) {
      _methodsSubscription = methodsStream.listen((methods) {
        if (mounted) {
          setState(() {
            _methods = methods;
          });
        }
      });
    }
  }

  Future<void> _load() async {
    final methods = await DataManager.getPaymentMethods();
    setState(() => _methods = methods);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
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
      ),
      body: _methods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.payment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No payment methods yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first payment method',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _methods.length,
              itemBuilder: (context, i) {
                final m = _methods[i];
                final account = m.linkedAccountId != null
                    ? widget.accounts.firstWhere(
                        (a) => a.id == m.linkedAccountId,
                        orElse: () => Account(
                          id: '',
                          name: 'Account',
                          type: 'cash',
                          balance: 0,
                        ),
                      )
                    : null;
                final card = m.linkedCreditCardId != null
                    ? widget.creditCards.firstWhere(
                        (c) => c.id == m.linkedCreditCardId,
                        orElse: () => CreditCard(
                          id: '',
                          name: 'Card',
                          creditLimit: 0,
                          dueDate: DateTime.now(),
                        ),
                      )
                    : null;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(m.icon, color: m.color, size: 28),
                    ),
                    title: Text(
                      m.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          m.displayInfo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.type.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 12,
                            color: m.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (account != null && account.id.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Account: ${account.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (card != null && card.id.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Card: ${card.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPaymentMethodScreen(
                            method: m,
                            accounts: widget.accounts,
                            creditCards: widget.creditCards,
                          ),
                        ),
                      );
                      await _load();
                      widget.onChanged();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPaymentMethodScreen(
                accounts: widget.accounts,
                creditCards: widget.creditCards,
              ),
            ),
          );
          await _load();
          widget.onChanged();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Method'),
      ),
    );
  }
}

class AddPaymentMethodScreen extends StatefulWidget {
  final List<Account> accounts;
  final List<CreditCard> creditCards;

  const AddPaymentMethodScreen({
    super.key,
    required this.accounts,
    required this.creditCards,
  });

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _last4Ctrl = TextEditingController();
  String _type = 'upi';
  String? _linkedAccountId;
  String? _linkedCreditCardId;

  @override
  Widget build(BuildContext context) {
    final showUpi = _type == 'upi';
    final showCard = _type == 'debit_card' || _type == 'credit_card';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Method'),
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'upi',
                          label: Text('UPI'),
                          icon: Icon(Icons.qr_code),
                        ),
                        ButtonSegment(
                          value: 'debit_card',
                          label: Text('Debit'),
                          icon: Icon(Icons.credit_card),
                        ),
                        ButtonSegment(
                          value: 'credit_card',
                          label: Text('Credit'),
                          icon: Icon(Icons.credit_score),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (v) =>
                          setState(() => _type = v.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., BHIM, GPay, CRED, Cash',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (showUpi)
              TextFormField(
                controller: _upiCtrl,
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'e.g., yourname@upi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.alternate_email),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Required for UPI' : null,
              ),
            if (showUpi) const SizedBox(height: 16),
            if (showCard)
              TextFormField(
                controller: _last4Ctrl,
                decoration: InputDecoration(
                  labelText: 'Last 4 digits',
                  hintText: 'XXXX',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) =>
                    v != null && v.length == 4 ? null : 'Enter 4 digits',
              ),
            if (showCard) const SizedBox(height: 16),
            TextFormField(
              controller: _bankCtrl,
              decoration: InputDecoration(
                labelText: 'Bank Name (Optional)',
                hintText: 'e.g., HDFC Bank, SBI',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _linkedAccountId,
              decoration: InputDecoration(
                labelText: 'Link to Account (Optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...widget.accounts.map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Row(
                      children: [
                        Icon(a.icon, size: 20, color: a.color),
                        const SizedBox(width: 8),
                        Text(a.name),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _linkedAccountId = v),
            ),
            if (_type == 'credit_card' && widget.creditCards.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _linkedCreditCardId,
                decoration: InputDecoration(
                  labelText: 'Link to Credit Card (Optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.credit_card),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.creditCards.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _linkedCreditCardId = v),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final method = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      type: _type,
      upiId: _type == 'upi' ? _upiCtrl.text : null,
      last4Digits: _type == 'upi' ? null : _last4Ctrl.text,
      linkedAccountId: _linkedAccountId,
      linkedCreditCardId: _type == 'credit_card' ? _linkedCreditCardId : null,
      bankName: _bankCtrl.text.isEmpty ? null : _bankCtrl.text,
    );

    final methods = await DataManager.getPaymentMethods();
    methods.add(method);
    await DataManager.savePaymentMethods(methods);
    if (mounted) Navigator.pop(context);
  }
}

class EditPaymentMethodScreen extends StatefulWidget {
  final PaymentMethod method;
  final List<Account> accounts;
  final List<CreditCard> creditCards;

  const EditPaymentMethodScreen({
    super.key,
    required this.method,
    required this.accounts,
    required this.creditCards,
  });

  @override
  State<EditPaymentMethodScreen> createState() =>
      _EditPaymentMethodScreenState();
}

class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _upiCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _last4Ctrl;
  late String _type;
  String? _linkedAccountId;
  String? _linkedCreditCardId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.method.name);
    _upiCtrl = TextEditingController(text: widget.method.upiId ?? '');
    _bankCtrl = TextEditingController(text: widget.method.bankName ?? '');
    _last4Ctrl = TextEditingController(text: widget.method.last4Digits ?? '');
    _type = widget.method.type;
    _linkedAccountId = widget.method.linkedAccountId;
    _linkedCreditCardId = widget.method.linkedCreditCardId;
  }

  @override
  Widget build(BuildContext context) {
    final showUpi = _type == 'upi';
    final showCard = _type == 'debit_card' || _type == 'credit_card';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Payment Method'),
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
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'upi',
                          label: Text('UPI'),
                          icon: Icon(Icons.qr_code),
                        ),
                        ButtonSegment(
                          value: 'debit_card',
                          label: Text('Debit'),
                          icon: Icon(Icons.credit_card),
                        ),
                        ButtonSegment(
                          value: 'credit_card',
                          label: Text('Credit'),
                          icon: Icon(Icons.credit_score),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (v) =>
                          setState(() => _type = v.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., BHIM, GPay, CRED, Cash',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (showUpi)
              TextFormField(
                controller: _upiCtrl,
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'e.g., yourname@upi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.alternate_email),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Required for UPI' : null,
              ),
            if (showUpi) const SizedBox(height: 16),
            if (showCard)
              TextFormField(
                controller: _last4Ctrl,
                decoration: InputDecoration(
                  labelText: 'Last 4 digits',
                  hintText: 'XXXX',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) =>
                    v != null && v.length == 4 ? null : 'Enter 4 digits',
              ),
            if (showCard) const SizedBox(height: 16),
            TextFormField(
              controller: _bankCtrl,
              decoration: InputDecoration(
                labelText: 'Bank Name (Optional)',
                hintText: 'e.g., HDFC Bank, SBI',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _linkedAccountId,
              decoration: InputDecoration(
                labelText: 'Link to Account (Optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...widget.accounts.map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Row(
                      children: [
                        Icon(a.icon, size: 20, color: a.color),
                        const SizedBox(width: 8),
                        Text(a.name),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _linkedAccountId = v),
            ),
            if (_type == 'credit_card' && widget.creditCards.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _linkedCreditCardId,
                decoration: InputDecoration(
                  labelText: 'Link to Credit Card (Optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.credit_card),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.creditCards.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _linkedCreditCardId = v),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = PaymentMethod(
      id: widget.method.id,
      name: _nameCtrl.text,
      type: _type,
      upiId: _type == 'upi' ? _upiCtrl.text : null,
      last4Digits: _type == 'upi' ? null : _last4Ctrl.text,
      linkedAccountId: _linkedAccountId,
      linkedCreditCardId: _type == 'credit_card' ? _linkedCreditCardId : null,
      bankName: _bankCtrl.text.isEmpty ? null : _bankCtrl.text,
    );

    final methods = await DataManager.getPaymentMethods();
    final index = methods.indexWhere((m) => m.id == widget.method.id);
    if (index != -1) methods[index] = updated;
    await DataManager.savePaymentMethods(methods);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: const Text(
          'Are you sure you want to delete this payment method? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final methods = await DataManager.getPaymentMethods();
      methods.removeWhere((m) => m.id == widget.method.id);
      await DataManager.savePaymentMethods(methods);
      if (mounted) Navigator.pop(context);
    }
  }
}
