import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';
import '../../utils/excel_helper.dart';

class CreditCardsScreen extends StatelessWidget {
  final List<CreditCard> cards;
  final String currency;
  final VoidCallback onChanged;

  const CreditCardsScreen({
    super.key,
    required this.cards,
    required this.currency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Cards'),
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
          IconButton(
            tooltip: 'Download Excel',
            icon: const Icon(Icons.download),
            onPressed: cards.isEmpty ? null : () => _exportExcel(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No credit cards',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add a credit card',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Note: Synced with Cloud Firestore',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cards.length,
                    itemBuilder: (context, i) {
                      final card = cards[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditCreditCardScreen(
                                    card: card,
                                    currency: currency,
                                  ),
                                ),
                              );
                              onChanged();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        card.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (card.isOverdue)
                                        Chip(
                                          label: const Text(
                                            'OVERDUE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (card.isOverdue)
                                        const SizedBox(width: 8),
                                      if (card.isOverdue)
                                        InkWell(
                                          onTap: () async {
                                            // Mark payment as done
                                            final cards =
                                                await DataManager.getCreditCards();
                                            final index = cards.indexWhere(
                                              (c) => c.id == card.id,
                                            );
                                            if (index != -1) {
                                              cards[index].status = 'active';
                                              // Move due date to next billing cycle
                                              cards[index].dueDate =
                                                  cards[index].dueDate.add(
                                                    Duration(
                                                      days: cards[index]
                                                          .billingCycle,
                                                    ),
                                                  );
                                              await DataManager.saveCreditCards(
                                                cards,
                                              );
                                            }
                                          },
                                          child: Chip(
                                            label: const Text(
                                              'PAID',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRow(
                                    'Credit Limit',
                                    card.creditLimit,
                                    currency,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRow(
                                    'Outstanding',
                                    card.outstanding,
                                    currency,
                                    Colors.red,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRow(
                                    'Available',
                                    card.available,
                                    currency,
                                    Colors.green,
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Utilization: ${card.utilizationPercent.toStringAsFixed(1)}%',
                                      ),
                                      Text(
                                        'Due: ${DateFormat('dd MMM').format(card.dueDate)}',
                                        style: TextStyle(
                                          color: card.isOverdue
                                              ? Colors.red
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCreditCardScreen(currency: currency),
            ),
          );
          onChanged();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final filePath = await ExcelHelper.exportCreditCards(cards, currency);
    if (!context.mounted) return;
    Navigator.pop(context);

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export credit cards')),
      );
      return;
    }

    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Text(
          'Exported ${cards.length} card${cards.length == 1 ? '' : 's'}.\n\n$filePath',
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
    if (open == true) await ExcelHelper.openExcelFile(filePath);
  }

  static Widget _buildRow(
    String label,
    double amount,
    String currency, [
    Color? color,
  ]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          '$currency${amount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class AddCreditCardScreen extends StatefulWidget {
  final String currency;

  const AddCreditCardScreen({super.key, required this.currency});

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _creditLimitCtrl = TextEditingController();
  final _outstandingCtrl = TextEditingController(text: '0');
  final _minimumDueCtrl = TextEditingController();
  final _rewardPointsCtrl = TextEditingController(text: '0');
  final _billingCycleCtrl = TextEditingController(text: '45');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _status = 'active';

  double get _calculatedAvailable {
    final limit = double.tryParse(_creditLimitCtrl.text) ?? 0;
    final outstanding = double.tryParse(_outstandingCtrl.text) ?? 0;
    return limit - outstanding;
  }

  @override
  void initState() {
    super.initState();
    _outstandingCtrl.addListener(_updateMinimumDue);
  }

  void _updateMinimumDue() {
    final outstanding = double.tryParse(_outstandingCtrl.text) ?? 0;
    final minPayment = outstanding * 0.05;
    _minimumDueCtrl.text = minPayment.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Credit Card'),
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
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Card Name',
                hintText: 'e.g., HDFC Regalia, SBI Card',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.credit_card),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
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
            TextFormField(
              controller: _cardNumberCtrl,
              decoration: InputDecoration(
                labelText: 'Last 4 Digits (Optional)',
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
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitCtrl,
              decoration: InputDecoration(
                labelText: 'Credit Limit',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.account_balance_wallet),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _outstandingCtrl,
              decoration: InputDecoration(
                labelText: 'Outstanding Amount',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.payments),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Available Limit:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '${widget.currency}${_calculatedAvailable.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimumDueCtrl,
              decoration: InputDecoration(
                labelText: 'Minimum Due',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.money),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _billingCycleCtrl,
              decoration: InputDecoration(
                labelText: 'Billing Cycle (Days)',
                hintText: 'e.g., 30, 45',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_month),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.info),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              tileColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              onTap: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate.isBefore(now) ? now : _dueDate,
                  firstDate: now,
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _dueDate = date);
              },
            ),
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
                'Add Credit Card',
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

    final creditLimit = double.parse(_creditLimitCtrl.text);
    final outstandingAmount = double.parse(_outstandingCtrl.text);

    final card = CreditCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      bank: _bankCtrl.text.isEmpty ? null : _bankCtrl.text,
      cardNumber: _cardNumberCtrl.text.isEmpty ? null : _cardNumberCtrl.text,
      creditLimit: creditLimit,
      availableLimit: creditLimit - outstandingAmount,
      outstandingAmount: outstandingAmount,
      minimumDue: double.parse(_minimumDueCtrl.text),
      billingCycle: int.parse(_billingCycleCtrl.text),
      dueDate: _dueDate,
      rewardPoints: int.parse(_rewardPointsCtrl.text),
      status: _status,
    );

    await DataManager.saveCreditCard(card);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credit Card added')));
      Navigator.pop(context);
    }
  }
}

class EditCreditCardScreen extends StatefulWidget {
  final CreditCard card;
  final String currency;

  const EditCreditCardScreen({
    super.key,
    required this.card,
    required this.currency,
  });

  @override
  State<EditCreditCardScreen> createState() => _EditCreditCardScreenState();
}

class _EditCreditCardScreenState extends State<EditCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _cardNumberCtrl;
  late TextEditingController _creditLimitCtrl;
  late TextEditingController _outstandingCtrl;
  late TextEditingController _minimumDueCtrl;
  late TextEditingController _rewardPointsCtrl;
  late TextEditingController _billingCycleCtrl;
  late DateTime _dueDate;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.card.name);
    _bankCtrl = TextEditingController(text: widget.card.bank ?? '');
    _cardNumberCtrl = TextEditingController(text: widget.card.cardNumber ?? '');
    _creditLimitCtrl = TextEditingController(
      text: widget.card.creditLimit.toString(),
    );
    _outstandingCtrl = TextEditingController(
      text: widget.card.outstandingAmount.toString(),
    );
    _minimumDueCtrl = TextEditingController(
      text: widget.card.minimumDue.toString(),
    );
    _rewardPointsCtrl = TextEditingController(
      text: widget.card.rewardPoints.toString(),
    );
    _billingCycleCtrl = TextEditingController(
      text: widget.card.billingCycle.toString(),
    );
    _dueDate = widget.card.dueDate;
    _status = widget.card.status;
  }

  double get _calculatedAvailable {
    final limit = double.tryParse(_creditLimitCtrl.text) ?? 0;
    final outstanding = double.tryParse(_outstandingCtrl.text) ?? 0;
    return limit - outstanding;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Credit Card'),
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
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Card Name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.credit_card),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankCtrl,
              decoration: InputDecoration(
                labelText: 'Bank Name (Optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberCtrl,
              decoration: InputDecoration(
                labelText: 'Last 4 Digits (Optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitCtrl,
              decoration: InputDecoration(
                labelText: 'Credit Limit',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.account_balance_wallet),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _outstandingCtrl,
              decoration: InputDecoration(
                labelText: 'Outstanding Amount',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.payments),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Available Limit:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '${widget.currency}${_calculatedAvailable.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimumDueCtrl,
              decoration: InputDecoration(
                labelText: 'Minimum Due',
                border: const OutlineInputBorder(),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.money),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _billingCycleCtrl,
              decoration: InputDecoration(
                labelText: 'Billing Cycle (Days)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_month),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.info),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              tileColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              onTap: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate.isBefore(now) ? now : _dueDate,
                  firstDate: now,
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _dueDate = date);
              },
            ),
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
            label: const Text('Update Credit Card'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFF9C27B0),
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

    final creditLimit = double.parse(_creditLimitCtrl.text);
    final outstandingAmount = double.parse(_outstandingCtrl.text);

    final updated = CreditCard(
      id: widget.card.id,
      name: _nameCtrl.text,
      bank: _bankCtrl.text.isEmpty ? null : _bankCtrl.text,
      cardNumber: _cardNumberCtrl.text.isEmpty ? null : _cardNumberCtrl.text,
      creditLimit: creditLimit,
      availableLimit: creditLimit - outstandingAmount,
      outstandingAmount: outstandingAmount,
      minimumDue: double.parse(_minimumDueCtrl.text),
      billingCycle: int.parse(_billingCycleCtrl.text),
      dueDate: _dueDate,
      rewardPoints: int.parse(_rewardPointsCtrl.text),
      status: _status,
      createdAt: widget.card.createdAt,
    );

    await DataManager.saveCreditCard(updated);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credit Card updated')));
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credit Card'),
        content: const Text(
          'Are you sure you want to delete this credit card? This action cannot be undone.',
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
      await DataManager.deleteCreditCard(widget.card.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Credit Card deleted')));
        Navigator.pop(context);
      }
    }
  }
}
