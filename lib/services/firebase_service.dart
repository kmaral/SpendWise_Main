import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart' as models;
import '../models/models.dart'
    show Category, Account, Loan, CreditCard, PaymentMethod;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections references
  static CollectionReference get _transactionsRef =>
      _firestore.collection('transactions');
  static CollectionReference get _categoriesRef =>
      _firestore.collection('categories');
  static CollectionReference get _accountsRef =>
      _firestore.collection('accounts');
  static CollectionReference get _loansRef => _firestore.collection('loans');
  static CollectionReference get _creditCardsRef =>
      _firestore.collection('creditCards');
  static CollectionReference get _paymentMethodsRef =>
      _firestore.collection('paymentMethods');

  // Transactions
  static Future<List<models.Transaction>> getTransactions({
    String? groupId,
    String? userId,
  }) async {
    try {
      Query query = _transactionsRef;

      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }

      if (userId != null) {
        query = query.where('profileId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => models.Transaction.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  static Future<void> saveTransaction(models.Transaction transaction) async {
    try {
      await _transactionsRef.doc(transaction.id).set(transaction.toJson());
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  static Future<void> deleteTransaction(String id) async {
    try {
      await _transactionsRef.doc(id).delete();
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  static Stream<List<models.Transaction>> watchTransactions({
    String? groupId,
    String? userId,
  }) {
    Query query = _transactionsRef;

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (userId != null) {
      query = query.where('profileId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => models.Transaction.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    });
  }

  // Categories
  static Future<List<models.Category>> getCategories() async {
    try {
      final snapshot = await _categoriesRef.get();
      return snapshot.docs
          .map(
            (doc) => Category.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  static Future<void> saveCategory(Category category) async {
    try {
      await _categoriesRef.doc(category.id).set(category.toJson());
    } catch (e) {
      print('Error saving category: $e');
      rethrow;
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      await _categoriesRef.doc(id).delete();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  static Stream<List<Category>> watchCategories({
    String? groupId,
    String? userId,
  }) {
    Query query = _categoriesRef;

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (userId != null) {
      query = query.where('profileId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Category.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    });
  }

  // Accounts
  static Future<List<models.Account>> getAccounts({
    String? groupId,
    String? userId,
  }) async {
    try {
      Query query = _accountsRef;

      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }

      if (userId != null) {
        query = query.where('profileId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      final List<Account> accounts = [];
      for (var doc in snapshot.docs) {
        try {
          accounts.add(
            Account.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          );
        } catch (e) {
          print('Error parsing account ${doc.id}: $e');
          // Skip this document and continue
        }
      }
      return accounts;
    } catch (e) {
      print('Error fetching accounts: $e');
      return [];
    }
  }

  static Future<void> saveAccount(Account account) async {
    try {
      await _accountsRef.doc(account.id).set(account.toJson());
    } catch (e) {
      print('Error saving account: $e');
      rethrow;
    }
  }

  static Future<void> deleteAccount(String id) async {
    try {
      await _accountsRef.doc(id).delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  static Stream<List<Account>> watchAccounts({
    String? groupId,
    String? userId,
  }) {
    Query query = _accountsRef;

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (userId != null) {
      query = query.where('profileId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      final List<Account> accounts = [];
      for (var doc in snapshot.docs) {
        try {
          accounts.add(
            Account.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          );
        } catch (e) {
          print('Error parsing account ${doc.id}: $e');
          // Skip this document and continue
        }
      }
      return accounts;
    });
  }

  // Loans
  static Future<List<Loan>> getLoans({String? groupId, String? userId}) async {
    try {
      Query query = _loansRef;

      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }

      if (userId != null) {
        query = query.where('profileId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => Loan.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching loans: $e');
      return [];
    }
  }

  static Future<void> saveLoan(Loan loan) async {
    try {
      await _loansRef.doc(loan.id).set(loan.toJson());
    } catch (e) {
      print('Error saving loan: $e');
      rethrow;
    }
  }

  static Future<void> deleteLoan(String id) async {
    try {
      await _loansRef.doc(id).delete();
    } catch (e) {
      print('Error deleting loan: $e');
      rethrow;
    }
  }

  static Stream<List<Loan>> watchLoans({String? groupId, String? userId}) {
    Query query = _loansRef;

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (userId != null) {
      query = query.where('profileId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Loan.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    });
  }

  // Credit Cards
  static Future<List<CreditCard>> getCreditCards({
    String? groupId,
    String? userId,
  }) async {
    try {
      Query query = _creditCardsRef;

      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }

      if (userId != null) {
        query = query.where('profileId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => CreditCard.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching credit cards: $e');
      return [];
    }
  }

  static Future<void> saveCreditCard(CreditCard card) async {
    try {
      await _creditCardsRef.doc(card.id).set(card.toJson());
    } catch (e) {
      print('Error saving credit card: $e');
      rethrow;
    }
  }

  static Future<void> deleteCreditCard(String id) async {
    try {
      await _creditCardsRef.doc(id).delete();
    } catch (e) {
      print('Error deleting credit card: $e');
      rethrow;
    }
  }

  static Stream<List<CreditCard>> watchCreditCards({
    String? groupId,
    String? userId,
  }) {
    Query query = _creditCardsRef;

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (userId != null) {
      query = query.where('profileId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => CreditCard.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    });
  }

  // Payment Methods
  static Future<List<PaymentMethod>> getPaymentMethods({
    String? groupId,
    String? userId,
  }) async {
    try {
      Query query = _paymentMethodsRef;

      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }

      if (userId != null) {
        query = query.where('profileId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      final List<PaymentMethod> methods = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Skip if this looks like credit card data (has creditLimit field)
          if (data.containsKey('creditLimit') || data.containsKey('dueDate')) {
            print(
              'Skipping invalid payment method data (credit card): ${doc.id}',
            );
            continue;
          }
          // Skip if this looks like account data (has balance field)
          if (data.containsKey('balance') ||
              data.containsKey('accountNumber')) {
            print('Skipping invalid payment method data (account): ${doc.id}');
            continue;
          }
          methods.add(PaymentMethod.fromJson({...data, 'id': doc.id}));
        } catch (e) {
          print('Error parsing payment method ${doc.id}: $e');
          // Skip this document and continue
        }
      }
      return methods;
    } catch (e) {
      print('Error fetching payment methods: $e');
      return [];
    }
  }

  static Future<void> savePaymentMethod(PaymentMethod method) async {
    try {
      await _paymentMethodsRef.doc(method.id).set(method.toJson());
    } catch (e) {
      print('Error saving payment method: $e');
      rethrow;
    }
  }

  static Future<void> deletePaymentMethod(String id) async {
    try {
      await _paymentMethodsRef.doc(id).delete();
    } catch (e) {
      print('Error deleting payment method: $e');
      rethrow;
    }
  }

  static Stream<List<PaymentMethod>> watchPaymentMethods({
    String? groupId,
    String? userId,
  }) {
    Query query = _paymentMethodsRef;

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (userId != null) {
      query = query.where('profileId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      final List<PaymentMethod> methods = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Skip if this looks like credit card data (has creditLimit field)
          if (data.containsKey('creditLimit') || data.containsKey('dueDate')) {
            print(
              'Skipping invalid payment method data (credit card): ${doc.id}',
            );
            continue;
          }
          // Skip if this looks like account data (has balance field)
          if (data.containsKey('balance') ||
              data.containsKey('accountNumber')) {
            print('Skipping invalid payment method data (account): ${doc.id}');
            continue;
          }
          methods.add(PaymentMethod.fromJson({...data, 'id': doc.id}));
        } catch (e) {
          print('Error parsing payment method ${doc.id}: $e');
          // Skip this document and continue
        }
      }
      return methods;
    });
  }

  // Batch operations for saving multiple items
  static Future<void> saveCategories(List<Category> categories) async {
    final batch = _firestore.batch();
    for (var category in categories) {
      batch.set(_categoriesRef.doc(category.id), category.toJson());
    }
    await batch.commit();
  }

  static Future<void> saveTransactions(
    List<models.Transaction> transactions,
  ) async {
    final batch = _firestore.batch();
    for (var transaction in transactions) {
      batch.set(_transactionsRef.doc(transaction.id), transaction.toJson());
    }
    await batch.commit();
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    final batch = _firestore.batch();
    for (var account in accounts) {
      batch.set(_accountsRef.doc(account.id), account.toJson());
    }
    await batch.commit();
  }

  static Future<void> saveLoans(List<Loan> loans) async {
    final batch = _firestore.batch();
    for (var loan in loans) {
      batch.set(_loansRef.doc(loan.id), loan.toJson());
    }
    await batch.commit();
  }

  static Future<void> saveCreditCards(List<CreditCard> cards) async {
    final batch = _firestore.batch();
    for (var card in cards) {
      batch.set(_creditCardsRef.doc(card.id), card.toJson());
    }
    await batch.commit();
  }

  static Future<void> savePaymentMethods(List<PaymentMethod> methods) async {
    final batch = _firestore.batch();
    for (var method in methods) {
      batch.set(_paymentMethodsRef.doc(method.id), method.toJson());
    }
    await batch.commit();
  }

  // User Profile Management
  static CollectionReference get _usersRef => _firestore.collection('users');

  static Future<models.UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return null;
      return models.UserProfile.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<void> saveUserProfile(models.UserProfile profile) async {
    try {
      await _usersRef.doc(profile.id).set(profile.toMap());
    } catch (e) {
      print('Error saving user profile: $e');
      rethrow;
    }
  }

  // Group Management
  static CollectionReference get _groupsRef => _firestore.collection('groups');

  static Future<models.Group?> getGroup(String groupId) async {
    try {
      final doc = await _groupsRef.doc(groupId).get();
      if (!doc.exists) return null;
      return models.Group.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      print('Error fetching group: $e');
      return null;
    }
  }

  static Future<void> saveGroup(models.Group group) async {
    try {
      await _groupsRef.doc(group.id).set(group.toMap());
    } catch (e) {
      print('Error saving group: $e');
      rethrow;
    }
  }

  static Future<void> deleteGroup(String groupId) async {
    try {
      await _groupsRef.doc(groupId).delete();
    } catch (e) {
      print('Error deleting group: $e');
      rethrow;
    }
  }

  static Future<models.Group?> getGroupByInviteCode(String inviteCode) async {
    try {
      final snapshot = await _groupsRef
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return models.Group.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      print('Error fetching group by invite code: $e');
      return null;
    }
  }

  static Future<List<models.Group>> getUserGroups(String userId) async {
    try {
      final snapshot = await _groupsRef
          .where('members', arrayContains: {'userId': userId})
          .get();

      return snapshot.docs
          .map(
            (doc) => models.Group.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching user groups: $e');
      // Fallback: get all groups and filter locally
      try {
        final allGroups = await _groupsRef.get();
        return allGroups.docs
            .map(
              (doc) => models.Group.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .where((group) => group.hasMember(userId))
            .toList();
      } catch (e2) {
        print('Error in fallback fetch: $e2');
        return [];
      }
    }
  }
}
