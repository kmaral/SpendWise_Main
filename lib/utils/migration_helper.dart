import '../data/data_manager.dart';
import '../services/firebase_service.dart';

/// Utility class for migrating data between local storage and Firebase
class MigrationHelper {
  /// Migrate all data from local storage (SharedPreferences) to Firebase
  /// Returns true if successful, false otherwise
  static Future<bool> migrateLocalToFirebase() async {
    try {
      print('Starting migration from local storage to Firebase...');

      // Temporarily disable Firebase to read local data
      DataManager.setFirebaseMode(false);

      // Read all local data
      print('Reading local data...');
      final transactions = await DataManager.getTransactions();
      final categories = await DataManager.getCategories();
      final accounts = await DataManager.getAccounts();
      final loans = await DataManager.getLoans();
      final creditCards = await DataManager.getCreditCards();
      final paymentMethods = await DataManager.getPaymentMethods();

      print('Local data counts:');
      print('  Transactions: ${transactions.length}');
      print('  Categories: ${categories.length}');
      print('  Accounts: ${accounts.length}');
      print('  Loans: ${loans.length}');
      print('  Credit Cards: ${creditCards.length}');
      print('  Payment Methods: ${paymentMethods.length}');

      // Enable Firebase and upload all data
      DataManager.setFirebaseMode(true);

      print('Uploading to Firebase...');
      await FirebaseService.saveTransactions(transactions);
      await FirebaseService.saveCategories(categories);
      await FirebaseService.saveAccounts(accounts);
      await FirebaseService.saveLoans(loans);
      await FirebaseService.saveCreditCards(creditCards);
      await FirebaseService.savePaymentMethods(paymentMethods);

      print('Migration complete!');
      return true;
    } catch (e) {
      print('Migration error: $e');
      // Re-enable local storage mode on error
      DataManager.setFirebaseMode(false);
      return false;
    }
  }

  /// Migrate all data from Firebase to local storage
  /// Returns true if successful, false otherwise
  static Future<bool> migrateFirebaseToLocal() async {
    try {
      print('Starting migration from Firebase to local storage...');

      // Read all Firebase data
      DataManager.setFirebaseMode(true);

      print('Reading Firebase data...');
      final transactions = await DataManager.getTransactions();
      final categories = await DataManager.getCategories();
      final accounts = await DataManager.getAccounts();
      final loans = await DataManager.getLoans();
      final creditCards = await DataManager.getCreditCards();
      final paymentMethods = await DataManager.getPaymentMethods();

      print('Firebase data counts:');
      print('  Transactions: ${transactions.length}');
      print('  Categories: ${categories.length}');
      print('  Accounts: ${accounts.length}');
      print('  Loans: ${loans.length}');
      print('  Credit Cards: ${creditCards.length}');
      print('  Payment Methods: ${paymentMethods.length}');

      // Switch to local storage and save
      DataManager.setFirebaseMode(false);

      print('Saving to local storage...');
      await DataManager.saveTransactions(transactions);
      await DataManager.saveCategories(categories);
      await DataManager.saveAccounts(accounts);
      await DataManager.saveLoans(loans);
      await DataManager.saveCreditCards(creditCards);
      await DataManager.savePaymentMethods(paymentMethods);

      print('Migration complete!');
      return true;
    } catch (e) {
      print('Migration error: $e');
      return false;
    }
  }

  /// Check if Firebase is accessible
  static Future<bool> isFirebaseAvailable() async {
    try {
      await FirebaseService.getTransactions();
      return true;
    } catch (e) {
      print('Firebase not available: $e');
      return false;
    }
  }

  /// Get data counts from Firebase
  static Future<Map<String, int>> getFirebaseDataCounts() async {
    try {
      final transactions = await FirebaseService.getTransactions();
      final categories = await FirebaseService.getCategories();
      final accounts = await FirebaseService.getAccounts();
      final loans = await FirebaseService.getLoans();
      final creditCards = await FirebaseService.getCreditCards();
      final paymentMethods = await FirebaseService.getPaymentMethods();

      return {
        'transactions': transactions.length,
        'categories': categories.length,
        'accounts': accounts.length,
        'loans': loans.length,
        'creditCards': creditCards.length,
        'paymentMethods': paymentMethods.length,
      };
    } catch (e) {
      print('Error getting Firebase counts: $e');
      return {};
    }
  }

  /// Get data counts from local storage
  static Future<Map<String, int>> getLocalDataCounts() async {
    try {
      DataManager.setFirebaseMode(false);

      final transactions = await DataManager.getTransactions();
      final categories = await DataManager.getCategories();
      final accounts = await DataManager.getAccounts();
      final loans = await DataManager.getLoans();
      final creditCards = await DataManager.getCreditCards();
      final paymentMethods = await DataManager.getPaymentMethods();

      return {
        'transactions': transactions.length,
        'categories': categories.length,
        'accounts': accounts.length,
        'loans': loans.length,
        'creditCards': creditCards.length,
        'paymentMethods': paymentMethods.length,
      };
    } catch (e) {
      print('Error getting local counts: $e');
      return {};
    }
  }
}
