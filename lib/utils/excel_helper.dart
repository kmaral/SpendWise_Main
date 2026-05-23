import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../models/models.dart';

class ExcelHelper {
  static double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.-]'), '')
        .trim();

    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Export transactions to Excel file
  static Future<String?> exportTransactions(
    List<Transaction> transactions,
    List<Account> accounts,
    String currency,
  ) async {
    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Transactions'];

      // Add headers
      sheet.appendRow([
        TextCellValue('S.no'),
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Credit'),
        TextCellValue('Debit'),
        TextCellValue('Balance'),
        TextCellValue('Remarks'),
      ]);

      // Sort transactions by date
      final sortedTransactions = [...transactions]
        ..sort((a, b) => a.date.compareTo(b.date));

      // Add transaction data
      double runningBalance = 0;
      for (int i = 0; i < sortedTransactions.length; i++) {
        final t = sortedTransactions[i];
        final dateStr = DateFormat('dd-MM-yyyy').format(t.date);

        // Calculate running balance
        if (t.type == 'income' || t.type == 'transfer') {
          runningBalance += t.amount;
        } else if (t.type == 'expense') {
          runningBalance -= t.amount;
        }

        // Get account name for remarks
        String remarks = t.title;
        if (t.accountId != null) {
          final account = accounts.firstWhere(
            (a) => a.id == t.accountId,
            orElse: () =>
                Account(id: '', name: 'Unknown', type: 'cash', balance: 0),
          );
          remarks = account.name;
        }

        // Add notes if present
        if (t.notes != null && t.notes!.isNotEmpty) {
          remarks += ' - ${t.notes}';
        }

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(dateStr),
          TextCellValue(t.category),
          t.type == 'income' ? DoubleCellValue(t.amount) : TextCellValue(''),
          t.type == 'expense' ? DoubleCellValue(t.amount) : TextCellValue(''),
          DoubleCellValue(runningBalance),
          TextCellValue(remarks),
        ]);
      }

      // Style headers
      for (int col = 0; col < 7; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Auto-fit columns
      for (int col = 0; col < 7; col++) {
        sheet.setColumnWidth(col, 15);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/transactions_$timestamp.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }

      return null;
    } catch (e) {
      print('Error exporting to Excel: $e');
      return null;
    }
  }

  /// Export loans to Excel file. Caller passes the already-filtered list.
  static Future<String?> exportLoans(List<Loan> loans, String currency) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Loans'];

      sheet.appendRow([
        TextCellValue('S.no'),
        TextCellValue('Name'),
        TextCellValue('Lender'),
        TextCellValue('Type'),
        TextCellValue('Principal ($currency)'),
        TextCellValue('Paid ($currency)'),
        TextCellValue('Remaining ($currency)'),
        TextCellValue('EMI ($currency)'),
        TextCellValue('Interest Rate (%)'),
        TextCellValue('Tenure (Months)'),
        TextCellValue('Payments Done'),
        TextCellValue('Status'),
        TextCellValue('Start Date'),
        TextCellValue('End Date'),
        // TextCellValue('Next Payment'),
      ]);

      final sorted = [...loans]
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      for (int i = 0; i < sorted.length; i++) {
        final l = sorted[i];
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(l.name),
          TextCellValue(l.lender ?? ''),
          TextCellValue(l.type ?? ''),
          DoubleCellValue(l.principalAmount),
          DoubleCellValue(l.totalPaid),
          DoubleCellValue(l.remainingAmount),
          DoubleCellValue(l.emiAmount),
          l.interestRate != null
              ? DoubleCellValue(l.interestRate!)
              : TextCellValue(''),
          IntCellValue(l.tenureMonths),
          IntCellValue(l.paymentsCompleted),
          TextCellValue(l.status),
          TextCellValue(DateFormat('dd-MM-yyyy').format(l.startDate)),
          TextCellValue(DateFormat('dd-MM-yyyy').format(l.endDate)),
          // TextCellValue(DateFormat('dd-MM-yyyy').format(l.nextDueDate)),
        ]);
      }

      const columnCount = 15;
      for (int col = 0; col < columnCount; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
        sheet.setColumnWidth(col, 18);
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/loans_$timestamp.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await File(filePath).writeAsBytes(fileBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      print('Error exporting loans to Excel: $e');
      return null;
    }
  }

  /// Export credit cards to Excel file. Caller passes the already-filtered list.
  static Future<String?> exportCreditCards(
    List<CreditCard> cards,
    String currency,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['CreditCards'];

      sheet.appendRow([
        TextCellValue('S.no'),
        TextCellValue('Name'),
        TextCellValue('Bank'),
        TextCellValue('Card Number'),
        TextCellValue('Credit Limit ($currency)'),
        TextCellValue('Outstanding ($currency)'),
        TextCellValue('Available ($currency)'),
        TextCellValue('Minimum Due ($currency)'),
        TextCellValue('Utilization (%)'),
        TextCellValue('Billing Cycle (Days)'),
        TextCellValue('Due Date'),
        // TextCellValue('Reward Points'),
        TextCellValue('Status'),
      ]);

      final sorted = [...cards]..sort((a, b) => a.name.compareTo(b.name));

      for (int i = 0; i < sorted.length; i++) {
        final c = sorted[i];
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(c.name),
          TextCellValue(c.bank ?? ''),
          TextCellValue(c.cardNumber ?? ''),
          DoubleCellValue(c.creditLimit),
          DoubleCellValue(c.outstandingAmount),
          DoubleCellValue(c.availableLimit),
          DoubleCellValue(c.minimumDue),
          DoubleCellValue(c.utilizationPercent),
          IntCellValue(c.billingCycle),
          TextCellValue(DateFormat('dd-MM-yyyy').format(c.dueDate)),
          // IntCellValue(c.rewardPoints),
          TextCellValue(c.isOverdue ? 'overdue' : c.status),
        ]);
      }

      const columnCount = 13;
      for (int col = 0; col < columnCount; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
        sheet.setColumnWidth(col, 18);
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/credit_cards_$timestamp.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await File(filePath).writeAsBytes(fileBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      print('Error exporting credit cards to Excel: $e');
      return null;
    }
  }

  /// Import transactions from Excel file
  static Future<List<Transaction>> importTransactions() async {
    try {
      // Pick Excel file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) {
        return [];
      }

      final filePath = result.files.single.path!;
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      // Get first sheet
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        return [];
      }

      final transactions = <Transaction>[];

      // Skip header row
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        if (row.length < 3) {
          continue; // Need at least date, category, and amount
        }

        try {
          // Parse date (column B - index 1)
          final dateCell = row[1];
          if (dateCell == null || dateCell.value == null) continue;

          DateTime date;
          final dateValue = dateCell.value.toString();
          try {
            // Try parsing dd-MM-yyyy format
            date = DateFormat('dd-MM-yyyy').parse(dateValue);
          } catch (e) {
            try {
              // Try parsing other common formats
              date = DateFormat('dd/MM/yyyy').parse(dateValue);
            } catch (e2) {
              try {
                date = DateFormat('yyyy-MM-dd').parse(dateValue);
              } catch (e3) {
                continue; // Skip if date can't be parsed
              }
            }
          }

          // Parse category (column C - index 2)
          final categoryCell = row[2];
          final category = categoryCell?.value?.toString() ?? 'Other';

          // Parse credit (column D - index 3)
          final creditCell = row.length > 3 ? row[3] : null;
          final credit = _parseAmount(creditCell?.value);

          // Parse debit (column E - index 4)
          final debitCell = row.length > 4 ? row[4] : null;
          final debit = _parseAmount(debitCell?.value);

          // Parse remarks (column G - index 6)
          final remarksCell = row.length > 6 ? row[6] : null;
          final remarks = remarksCell?.value?.toString();

          // Determine transaction type and amount
          String type;
          double amount;

          if (credit != null && credit > 0) {
            type = 'income';
            amount = credit;
          } else if (debit != null && debit > 0) {
            type = 'expense';
            amount = debit;
          } else {
            continue; // Skip if no valid amount
          }

          // Create transaction
          final transaction = Transaction(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            description: remarks ?? category,
            amount: amount,
            category: category,
            type: type,
            date: date,
            notes: remarks,
          );

          transactions.add(transaction);
        } catch (e) {
          print('Error parsing row $i: $e');
          continue;
        }
      }

      return transactions;
    } catch (e) {
      print('Error importing from Excel: $e');
      return [];
    }
  }

  /// Open exported Excel file
  static Future<void> openExcelFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      print('Error opening file: $e');
    }
  }
}
