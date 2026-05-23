import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';
import '../../utils/excel_helper.dart';

class LoansScreen extends StatefulWidget {
  final List<Loan> loans;
  final String currency;
  final VoidCallback onChanged;

  const LoansScreen({
    super.key,
    required this.loans,
    required this.currency,
    required this.onChanged,
  });

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  String _statusFilter = 'active';

  @override
  Widget build(BuildContext context) {
    var filtered = widget.loans;
    if (_statusFilter != 'all') {
      filtered = filtered.where((l) => l.status == _statusFilter).toList();
    }
    // Sort by status priority (active first, then closed) and then by next payment date
    filtered.sort((a, b) {
      final statusPriority = {'active': 0, 'closed': 1};
      final aPriority = statusPriority[a.status] ?? 2;
      final bPriority = statusPriority[b.status] ?? 2;
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      return a.nextPaymentDate.compareTo(b.nextPaymentDate);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
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
            onPressed: filtered.isEmpty ? null : () => _exportExcel(filtered),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'active', label: Text('Active')),
                    ButtonSegment(value: 'closed', label: Text('Closed')),
                  ],
                  selected: {_statusFilter},
                  onSelectionChanged: (v) =>
                      setState(() => _statusFilter = v.first),
                ),
                const SizedBox(height: 16),
                // Summary Cards
                if (_statusFilter != 'closed')
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade50,
                                  Colors.orange.shade100.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Outstanding',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${widget.currency}${filtered.fold<double>(0, (sum, loan) => sum + loan.remainingAmount).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${filtered.where((l) => l.status == 'active').length} active loans',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade50,
                                  Colors.blue.shade100.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Total EMI',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${widget.currency}${filtered.where((l) => l.status == 'active').fold<double>(0, (sum, loan) => sum + loan.emiAmount).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'per month',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No loans',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add a loan',
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
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final loan = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            loan.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Principal: ${widget.currency}${loan.principal.toStringAsFixed(0)}',
                              ),
                              Text(
                                'Paid: ${widget.currency}${loan.paidAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Remaining: ${widget.currency}${loan.remainingAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'EMI: ${widget.currency}${loan.emiAmount.toStringAsFixed(0)}/month',
                              ),
                              const Divider(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Start: ${DateFormat('dd MMM yy').format(loan.startDate)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'End: ${DateFormat('dd MMM yy').format(loan.endDate)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // child: Text(
                                //   'Next Payment: ${DateFormat('dd MMM yyyy').format(loan.nextPaymentDate)}',
                                //   style: const TextStyle(
                                //     fontSize: 12,
                                //     color: Color(0xFFF59E0B),
                                //     fontWeight: FontWeight.bold,
                                //   ),
                                // ),
                              ),
                              if (loan.paymentHistory.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Payments: ${loan.paymentsCompleted}/${loan.tenureMonths}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Repayment Progress',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${((loan.paidAmount / loan.principal) * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              loan.paidAmount >= loan.principal
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (loan.paidAmount / loan.principal)
                                          .clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        loan.paidAmount >= loan.principal
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: loan.status == 'active'
                                    ? [
                                        const Color(0xFF10B981),
                                        const Color(0xFF059669),
                                      ]
                                    : [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              loan.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditLoanScreen(
                                  loan: loan,
                                  currency: widget.currency,
                                ),
                              ),
                            );
                            widget.onChanged();
                          },
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
              builder: (context) => AddLoanScreen(currency: widget.currency),
            ),
          );
          widget.onChanged();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
      ),
    );
  }

  Future<void> _exportExcel(List<Loan> loans) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final filePath = await ExcelHelper.exportLoans(loans, widget.currency);
    if (!mounted) return;
    Navigator.pop(context);

    if (filePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export loans')));
      return;
    }

    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Text(
          'Exported ${loans.length} loan${loans.length == 1 ? '' : 's'}.\n\n$filePath',
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
}

class AddLoanScreen extends StatefulWidget {
  final String currency;

  const AddLoanScreen({super.key, required this.currency});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lenderCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _emiCtrl = TextEditingController();
  final _paidCtrl = TextEditingController(text: '0');
  final _tenureCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  String _status = 'active';
  String _type = 'personal';
  DateTime _startDate = DateTime.now();

  double get _calculatedRemaining {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    return principal - paid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loan'),
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
                labelText: 'Loan Name',
                hintText: 'e.g., Home Loan, Car Loan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.label),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lenderCtrl,
              decoration: InputDecoration(
                labelText: 'Lender / Bank Name',
                hintText: 'e.g., HDFC Bank, IDFC First Bank',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: 'Loan Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'personal',
                  child: Text('Personal Loan'),
                ),
                DropdownMenuItem(value: 'home', child: Text('Home Loan')),
                DropdownMenuItem(value: 'car', child: Text('Car Loan')),
                DropdownMenuItem(
                  value: 'education',
                  child: Text('Education Loan'),
                ),
                DropdownMenuItem(
                  value: 'business',
                  child: Text('Business Loan'),
                ),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _principalCtrl,
              decoration: InputDecoration(
                labelText: 'Principal Amount (Total Loan)',
                hintText: 'Total loan amount taken',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              controller: _emiCtrl,
              decoration: InputDecoration(
                labelText: 'EMI Amount',
                hintText: 'Monthly installment amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.payments),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateCtrl,
              decoration: InputDecoration(
                labelText: 'Interest Rate (% per annum)',
                hintText: 'e.g., 12.5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: '%',
                prefixIcon: const Icon(Icons.percent),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paidCtrl,
              decoration: InputDecoration(
                labelText: 'Paid Amount',
                hintText: 'Amount already paid',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: widget.currency,
                prefixIcon: const Icon(Icons.check_circle),
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
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.currency}${_calculatedRemaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tenureCtrl,
              decoration: InputDecoration(
                labelText: 'Tenure (Months)',
                hintText: 'e.g., 60 for 5 years',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.schedule),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.info),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2050),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'End Date:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(
                            DateTime(
                              _startDate.year,
                              _startDate.month +
                                  (int.tryParse(_tenureCtrl.text) ?? 0),
                              _startDate.day,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // const Text(
                        //   'Next Payment:',
                        //   style: TextStyle(fontWeight: FontWeight.bold),
                        // ),
                        // Text(
                        //   DateFormat('dd MMM yyyy').format(
                        //     DateTime(
                        //       _startDate.year,
                        //       _startDate.month + 1,
                        //       _startDate.day,
                        //     ),
                        //   ),
                        //   style: TextStyle(
                        //     color: Colors.orange.shade900,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
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
              ),
              child: const Text('Add Loan', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tenureMonths = int.parse(_tenureCtrl.text);
    final endDate = DateTime(
      _startDate.year,
      _startDate.month + tenureMonths,
      _startDate.day,
    );
    final nextPaymentDate = DateTime(
      _startDate.year,
      _startDate.month + 1,
      _startDate.day,
    );

    final loan = Loan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      lender: _lenderCtrl.text.isEmpty ? null : _lenderCtrl.text,
      type: _type,
      principalAmount: double.parse(_principalCtrl.text),
      totalPaid: double.parse(_paidCtrl.text),
      remainingAmount: _calculatedRemaining,
      emiAmount: double.parse(_emiCtrl.text),
      interestRate: _interestRateCtrl.text.isEmpty
          ? null
          : double.parse(_interestRateCtrl.text),
      tenureMonths: tenureMonths,
      status: _status,
      startDate: _startDate,
      endDate: endDate,
      nextDueDate: nextPaymentDate,
    );

    await DataManager.saveLoan(loan);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loan added successfully')));
      Navigator.pop(context);
    }
  }
}

class EditLoanScreen extends StatefulWidget {
  final Loan loan;
  final String currency;
  const EditLoanScreen({super.key, required this.loan, required this.currency});

  @override
  State<EditLoanScreen> createState() => _EditLoanScreenState();
}

class _EditLoanScreenState extends State<EditLoanScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _lenderCtrl;
  late TextEditingController _principalCtrl;
  late TextEditingController _paidCtrl;
  late TextEditingController _emiCtrl;
  late TextEditingController _tenureCtrl;
  late TextEditingController _interestRateCtrl;
  late String _status;
  late String _type;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _nextPaymentDate;

  double get _calculatedRemaining {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    return principal - paid;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.loan.name);
    _lenderCtrl = TextEditingController(text: widget.loan.lender ?? '');
    _principalCtrl = TextEditingController(
      text: widget.loan.principal.toString(),
    );
    _paidCtrl = TextEditingController(text: widget.loan.paidAmount.toString());
    _emiCtrl = TextEditingController(text: widget.loan.emiAmount.toString());
    _interestRateCtrl = TextEditingController(
      text: widget.loan.interestRate?.toString() ?? '',
    );
    _tenureCtrl = TextEditingController(
      text: widget.loan.tenureMonths.toString(),
    );
    _status = widget.loan.status;
    _type = widget.loan.type ?? 'personal';
    _startDate = widget.loan.startDate;
    _endDate = widget.loan.endDate;
    _nextPaymentDate = widget.loan.nextPaymentDate;
  }

  void _recalculateEndDate() {
    final tenure = int.tryParse(_tenureCtrl.text) ?? 0;
    if (tenure <= 0) return;
    _endDate = DateTime(
      _startDate.year,
      _startDate.month + tenure,
      _startDate.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Loan'),
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
      body: ListView(
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
              labelText: 'Loan Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.label),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lenderCtrl,
            decoration: InputDecoration(
              labelText: 'Lender / Bank Name',
              hintText: 'e.g., HDFC Bank, IDFC First Bank',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.account_balance),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(
              labelText: 'Loan Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.category),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            items: const [
              DropdownMenuItem(value: 'personal', child: Text('Personal Loan')),
              DropdownMenuItem(value: 'home', child: Text('Home Loan')),
              DropdownMenuItem(value: 'car', child: Text('Car Loan')),
              DropdownMenuItem(
                value: 'education',
                child: Text('Education Loan'),
              ),
              DropdownMenuItem(value: 'business', child: Text('Business Loan')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _principalCtrl,
            decoration: InputDecoration(
              labelText: 'Principal Amount (Total Loan)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixText: widget.currency,
              prefixIcon: const Icon(Icons.account_balance_wallet),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emiCtrl,
            decoration: InputDecoration(
              labelText: 'EMI Amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixText: widget.currency,
              prefixIcon: const Icon(Icons.payments),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _interestRateCtrl,
            decoration: InputDecoration(
              labelText: 'Interest Rate (% per annum)',
              hintText: 'e.g., 12.5',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: '%',
              prefixIcon: const Icon(Icons.percent),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paidCtrl,
            decoration: InputDecoration(
              labelText: 'Paid Amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixText: widget.currency,
              prefixIcon: const Icon(Icons.check_circle),
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
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.currency}${_calculatedRemaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tenureCtrl,
            decoration: InputDecoration(
              labelText: 'Tenure (Months)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.schedule),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(_recalculateEndDate),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Start Date'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2050),
              );
              if (date != null) {
                setState(() {
                  _startDate = date;
                  _recalculateEndDate();
                });
              }
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('End Date'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(_endDate)),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _endDate.isBefore(_startDate)
                    ? _startDate
                    : _endDate,
                firstDate: _startDate,
                lastDate: DateTime(2060),
              );
              if (date != null) setState(() => _endDate = date);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.info),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            items: ['active', 'closed']
                .map(
                  (s) =>
                      DropdownMenuItem(value: s, child: Text(s.toUpperCase())),
                )
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          //const SizedBox(height: 16),
          // ListTile(
          //   title: const Text('Next Payment Date'),
          //   subtitle: Text(DateFormat('dd MMM yyyy').format(_nextPaymentDate)),
          //   trailing: const Icon(Icons.calendar_today),
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(8),
          //     side: BorderSide(color: Colors.grey.shade400),
          //   ),
          //   onTap: () async {
          //     final date = await showDatePicker(
          //       context: context,
          //       initialDate: _nextPaymentDate,
          //       firstDate: DateTime.now(),
          //       lastDate: DateTime(2050),
          //     );
          //     if (date != null) setState(() => _nextPaymentDate = date);
          //   },
          // ),
          const SizedBox(height: 16),
          if (widget.loan.paymentHistory.isNotEmpty)
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment History (${widget.loan.paymentsCompleted} payments)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.loan.paymentHistory
                        .take(3)
                        .map(
                          (payment) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMM yy').format(payment.date),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${widget.currency}${payment.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (widget.loan.paymentHistory.length > 3)
                      Text(
                        '... and ${widget.loan.paymentHistory.length - 3} more',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Record Payment'),
                  onPressed: _recordPayment,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
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
            label: const Text('Update Loan Details'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recordPayment() async {
    final amountCtrl = TextEditingController(
      text: widget.loan.emiAmount.toString(),
    );
    final notesCtrl = TextEditingController();
    DateTime paymentDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
                  prefixText: widget.currency,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Payment Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(paymentDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: paymentDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => paymentDate = date);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final payment = LoanPayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(amountCtrl.text),
        date: paymentDate,
        notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
      );

      widget.loan.paymentHistory.add(payment);
      _paidCtrl.text = (double.parse(_paidCtrl.text) + payment.amount)
          .toString();

      _nextPaymentDate = DateTime(
        _nextPaymentDate.year,
        _nextPaymentDate.month + 1,
        _nextPaymentDate.day,
      );

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
    }
  }

  Future<void> _update() async {
    final tenureMonths = int.parse(_tenureCtrl.text);

    final updated = widget.loan.copyWith(
      name: _nameCtrl.text,
      lender: _lenderCtrl.text.isEmpty ? null : _lenderCtrl.text,
      type: _type,
      principalAmount: double.parse(_principalCtrl.text),
      totalPaid: double.parse(_paidCtrl.text),
      remainingAmount: _calculatedRemaining,
      emiAmount: double.parse(_emiCtrl.text),
      interestRate: _interestRateCtrl.text.isEmpty
          ? null
          : double.parse(_interestRateCtrl.text),
      tenureMonths: tenureMonths,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      nextDueDate: _nextPaymentDate,
    );

    await DataManager.saveLoan(updated);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loan updated')));
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
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
      await DataManager.deleteLoan(widget.loan.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Loan deleted')));
        Navigator.pop(context);
      }
    }
  }
}
