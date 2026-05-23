import 'package:flutter/material.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';

class AccountsScreen extends StatelessWidget {
  final List<Account> accounts;
  final String currency;
  final VoidCallback onChanged;
  final List<CreditCard> creditCards;

  const AccountsScreen({
    super.key,
    required this.accounts,
    required this.currency,
    required this.onChanged,
    required this.creditCards,
  });

  @override
  Widget build(BuildContext context) {
    final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

    return accounts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No accounts',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add an account',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Total Balance Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$currency${totalBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Across ${accounts.length} account${accounts.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Accounts List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: accounts.length,
                  itemBuilder: (context, i) {
                    final account = accounts[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: account.color,
                          child: Icon(account.icon, color: Colors.white),
                        ),
                        title: Text(
                          account.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          account.type.replaceAll('_', ' ').toUpperCase(),
                        ),
                        trailing: Text(
                          '$currency${account.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAccountScreen(
                                account: account,
                                currency: currency,
                                creditCards: creditCards,
                              ),
                            ),
                          );
                          onChanged();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}

class AddAccountScreen extends StatefulWidget {
  final String currency;
  final List<CreditCard> creditCards;

  const AddAccountScreen({
    super.key,
    required this.currency,
    required this.creditCards,
  });

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _accountHolderNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCodeCtrl = TextEditingController();
  final _debitCardNumberCtrl = TextEditingController();
  final _debitCardExpiryCtrl = TextEditingController();
  String _type = 'cash';
  bool _isDefault = false;
  String? _linkedCardId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., My Wallet, Savings',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountHolderNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Ketan Marali',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                // DropdownMenuItem(
                //   value: 'credit_card',
                //   child: Text('Credit Card'),
                // ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceCtrl,
              decoration: InputDecoration(
                labelText: 'Initial Balance',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            if (_type == 'bank' || _type == 'credit_card') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., HDFC, SBI',
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                  hintText: 'Your account number',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _branchNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Main Branch, Online',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Set as Default Account'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_type == 'bank') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _ifscCodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., HDFC0001234',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Debit Card Details (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _debitCardNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Debit Card Number',
                  border: OutlineInputBorder(),
                  hintText: 'Last 4 digits',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _debitCardExpiryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Card Expiry',
                  border: OutlineInputBorder(),
                  hintText: 'MM/YY',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
            if (_type == 'credit_card' && widget.creditCards.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _linkedCardId,
                decoration: const InputDecoration(
                  labelText: 'Link to Credit Card',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.creditCards.map(
                    (card) => DropdownMenuItem(
                      value: card.id,
                      child: Text(card.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _linkedCardId = v),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine icon name based on type
    String iconName = 'account_balance_wallet';
    if (_type == 'bank') {
      iconName = 'Building2';
    } else if (_type == 'cash')
      iconName = 'money';
    else if (_type == 'credit_card')
      iconName = 'credit_card';

    // Generate color based on type
    String colorHex = '#607D8B';
    if (_type == 'cash') {
      colorHex = '#4CAF50';
    } else if (_type == 'bank')
      colorHex = '#2196F3';
    else if (_type == 'credit_card')
      colorHex = '#9C27B0';

    final account = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      type: _type,
      balance: double.parse(_balanceCtrl.text),
      accountHolderName: _accountHolderNameCtrl.text.isEmpty
          ? null
          : _accountHolderNameCtrl.text,
      accountNumber: _accountNumberCtrl.text.isEmpty
          ? null
          : _accountNumberCtrl.text,
      bankName: _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
      branchName: _branchNameCtrl.text.isEmpty ? null : _branchNameCtrl.text,
      iconName: iconName,
      colorHex: colorHex,
      isDefault: _isDefault,
      ifscCode: _ifscCodeCtrl.text.isEmpty ? null : _ifscCodeCtrl.text,
      debitCardNumber: _debitCardNumberCtrl.text.isEmpty
          ? null
          : _debitCardNumberCtrl.text,
      debitCardExpiry: _debitCardExpiryCtrl.text.isEmpty
          ? null
          : _debitCardExpiryCtrl.text,
      linkedCardId: _linkedCardId,
    );

    await DataManager.saveAccount(account);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account added')));
      Navigator.pop(context);
    }
  }
}

class EditAccountScreen extends StatefulWidget {
  final Account account;
  final String currency;
  final List<CreditCard> creditCards;

  const EditAccountScreen({
    super.key,
    required this.account,
    required this.currency,
    required this.creditCards,
  });

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  late TextEditingController _accountHolderNameCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _branchNameCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _ifscCodeCtrl;
  late TextEditingController _debitCardNumberCtrl;
  late TextEditingController _debitCardExpiryCtrl;
  late String _type;
  late bool _isDefault;
  String? _linkedCardId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account.name);
    _balanceCtrl = TextEditingController(
      text: widget.account.balance.toString(),
    );
    _accountHolderNameCtrl = TextEditingController(
      text: widget.account.accountHolderName ?? '',
    );
    _bankNameCtrl = TextEditingController(text: widget.account.bankName ?? '');
    _branchNameCtrl = TextEditingController(
      text: widget.account.branchName ?? '',
    );
    _accountNumberCtrl = TextEditingController(
      text: widget.account.accountNumber ?? '',
    );
    _ifscCodeCtrl = TextEditingController(text: widget.account.ifscCode ?? '');
    _debitCardNumberCtrl = TextEditingController(
      text: widget.account.debitCardNumber ?? '',
    );
    _debitCardExpiryCtrl = TextEditingController(
      text: widget.account.debitCardExpiry ?? '',
    );
    _type = widget.account.type;
    _isDefault = widget.account.isDefault;
    _linkedCardId = widget.account.linkedCardId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountHolderNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Ketan Marali',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                // DropdownMenuItem(
                //   value: 'credit_card',
                //   child: Text('Credit Card'),
                // ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceCtrl,
              decoration: InputDecoration(
                labelText: 'Balance',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            if (_type == 'bank' || _type == 'credit_card') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _branchNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Main Branch, Online',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Set as Default Account'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_type == 'bank') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _ifscCodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., HDFC0001234',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Debit Card Details (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _debitCardNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Debit Card Number',
                  border: OutlineInputBorder(),
                  hintText: 'Last 4 digits',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _debitCardExpiryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Card Expiry',
                  border: OutlineInputBorder(),
                  hintText: 'MM/YY',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
            if (_type == 'credit_card' && widget.creditCards.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _linkedCardId,
                decoration: const InputDecoration(
                  labelText: 'Link to Credit Card',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.creditCards.map(
                    (card) => DropdownMenuItem(
                      value: card.id,
                      child: Text(card.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _linkedCardId = v),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _update,
            icon: const Icon(Icons.save),
            label: const Text('Update Account'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.account.copyWith(
      name: _nameCtrl.text,
      type: _type,
      balance: double.parse(_balanceCtrl.text),
      accountHolderName: _accountHolderNameCtrl.text.isEmpty
          ? null
          : _accountHolderNameCtrl.text,
      accountNumber: _accountNumberCtrl.text.isEmpty
          ? null
          : _accountNumberCtrl.text,
      bankName: _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
      branchName: _branchNameCtrl.text.isEmpty ? null : _branchNameCtrl.text,
      isDefault: _isDefault,
      ifscCode: _ifscCodeCtrl.text.isEmpty ? null : _ifscCodeCtrl.text,
      debitCardNumber: _debitCardNumberCtrl.text.isEmpty
          ? null
          : _debitCardNumberCtrl.text,
      debitCardExpiry: _debitCardExpiryCtrl.text.isEmpty
          ? null
          : _debitCardExpiryCtrl.text,
      linkedCardId: _linkedCardId,
    );

    await DataManager.saveAccount(updated);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account updated')));
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure?'),
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
      await DataManager.deleteAccount(widget.account.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Account deleted')));
        Navigator.pop(context);
      }
    }
  }
}
