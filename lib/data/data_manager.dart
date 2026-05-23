import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/firebase_service.dart';

class DataManager {
  static bool _useFirebase =
      true; // Toggle this to switch between Firebase and local storage

  // Set Firebase usage mode
  static void setFirebaseMode(bool enabled) {
    _useFirebase = enabled;
  }

  // Transactions
  static Future<List<Transaction>> getTransactions() async {
    if (_useFirebase) {
      try {
        final result = await FirebaseService.getTransactions();
        return result.cast<Transaction>();
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('transactions');
    if (data == null) return [];
    return (json.decode(data) as List)
        .map((e) => Transaction.fromJson(e))
        .toList();
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveTransactions(transactions);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'transactions',
      json.encode(transactions.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> saveTransaction(Transaction transaction) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveTransaction(transaction);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString(
    //   'transactions',
    //   json.encode(transactions.map((e) => e.toJson()).toList()),
    // );
  }

  static Future<void> deleteTransaction(String id) async {
    if (_useFirebase) {
      try {
        await FirebaseService.deleteTransaction(id);
        return;
      } catch (e) {
        print('Firebase error deleting transaction: $e');
        _useFirebase = false;
      }
    }
  }

  static Stream<List<Transaction>>? watchTransactions() {
    if (_useFirebase) {
      try {
        return FirebaseService.watchTransactions().map(
          (list) => list.cast<Transaction>(),
        );
      } catch (e) {
        print('Firebase streaming error: $e');
        return null;
      }
    }
    return null;
  }

  // Categories
  static Future<List<Category>> getCategories() async {
    if (_useFirebase) {
      try {
        final categories = await FirebaseService.getCategories();
        if (categories.isEmpty) {
          final defaults = _defaultCategories();
          await FirebaseService.saveCategories(defaults);
          return defaults;
        }
        return categories;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('categories');
    if (data == null) {
      final defaults = _defaultCategories();
      await saveCategories(defaults);
      return defaults;
    }
    return (json.decode(data) as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }

  static Future<void> deleteCategory(String id) async {
    if (_useFirebase) {
      try {
        await FirebaseService.deleteCategory(id);
        return;
      } catch (e) {
        print('Firebase error deleting category: $e');
        _useFirebase = false;
      }
    }

    final categories = await getCategories();
    categories.removeWhere((c) => c.id == id);
    await saveCategories(categories);
  }

  static Future<void> saveCategories(List<Category> categories) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveCategories(categories);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'categories',
      json.encode(categories.map((e) => e.toJson()).toList()),
    );
  }

  static Stream<List<Category>>? watchCategories() {
    if (_useFirebase) {
      try {
        return FirebaseService.watchCategories();
      } catch (e) {
        print('Firebase streaming error: $e');
        return null;
      }
    }
    return null;
  }

  // Loans
  static Future<List<Loan>> getLoans() async {
    if (_useFirebase) {
      try {
        return await FirebaseService.getLoans();
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('loans');
    if (data == null) return [];
    return (json.decode(data) as List).map((e) => Loan.fromJson(e)).toList();
  }

  static Future<void> saveLoans(List<Loan> loans) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveLoans(loans);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'loans',
      json.encode(loans.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> saveLoan(Loan loan) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveLoan(loan);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    // For local storage, need to update the list
    final loans = await getLoans();
    final index = loans.indexWhere((l) => l.id == loan.id);
    if (index >= 0) {
      loans[index] = loan;
    } else {
      loans.add(loan);
    }
    await saveLoans(loans);
  }

  static Future<void> deleteLoan(String loanId) async {
    if (_useFirebase) {
      try {
        await FirebaseService.deleteLoan(loanId);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    // For local storage, need to update the list
    final loans = await getLoans();
    loans.removeWhere((l) => l.id == loanId);
    await saveLoans(loans);
  }

  static Stream<List<Loan>>? watchLoans() {
    if (_useFirebase) {
      try {
        return FirebaseService.watchLoans();
      } catch (e) {
        print('Firebase streaming error: $e');
        return null;
      }
    }
    return null;
  }

  // Credit Cards
  static Future<List<CreditCard>> getCreditCards() async {
    if (_useFirebase) {
      try {
        return await FirebaseService.getCreditCards();
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('creditCards');
    if (data == null) return [];
    return (json.decode(data) as List)
        .map((e) => CreditCard.fromJson(e))
        .toList();
  }

  static Future<void> saveCreditCards(List<CreditCard> cards) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveCreditCards(cards);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'creditCards',
      json.encode(cards.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> saveCreditCard(CreditCard card) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveCreditCard(card);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    // For local storage, need to update the list
    final cards = await getCreditCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    await saveCreditCards(cards);
  }

  static Future<void> deleteCreditCard(String cardId) async {
    if (_useFirebase) {
      try {
        await FirebaseService.deleteCreditCard(cardId);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    // For local storage, need to update the list
    final cards = await getCreditCards();
    cards.removeWhere((c) => c.id == cardId);
    await saveCreditCards(cards);
  }

  static Stream<List<CreditCard>>? watchCreditCards() {
    if (_useFirebase) {
      try {
        return FirebaseService.watchCreditCards();
      } catch (e) {
        print('Firebase streaming error: $e');
        return null;
      }
    }
    return null;
  }

  // Accounts
  static Future<List<Account>> getAccounts() async {
    if (_useFirebase) {
      try {
        final accounts = await FirebaseService.getAccounts();
        if (accounts.isEmpty) {
          final defaults = _defaultAccounts();
          await FirebaseService.saveAccounts(defaults);
          return defaults;
        }
        return accounts;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('accounts');
    if (data == null) {
      final defaults = _defaultAccounts();
      await saveAccounts(defaults);
      return defaults;
    }
    return (json.decode(data) as List).map((e) => Account.fromJson(e)).toList();
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveAccounts(accounts);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'accounts',
      json.encode(accounts.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> saveAccount(Account account) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveAccount(account);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    // For local storage, need to update the list
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    await saveAccounts(accounts);
  }

  static Future<void> deleteAccount(String accountId) async {
    if (_useFirebase) {
      try {
        await FirebaseService.deleteAccount(accountId);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    // For local storage, need to update the list
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await saveAccounts(accounts);
  }

  static Stream<List<Account>>? watchAccounts() {
    if (_useFirebase) {
      try {
        return FirebaseService.watchAccounts();
      } catch (e) {
        print('Firebase streaming error: $e');
        return null;
      }
    }
    return null;
  }

  // Payment Methods
  static Future<List<PaymentMethod>> getPaymentMethods() async {
    if (_useFirebase) {
      try {
        final methods = await FirebaseService.getPaymentMethods();
        if (methods.isEmpty) {
          final defaults = _defaultPaymentMethods();
          await FirebaseService.savePaymentMethods(defaults);
          return defaults;
        }
        return methods;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('paymentMethods');
    if (data == null) {
      final defaults = _defaultPaymentMethods();
      await savePaymentMethods(defaults);
      return defaults;
    }
    return (json.decode(data) as List)
        .map((e) => PaymentMethod.fromJson(e))
        .toList();
  }

  static Future<void> savePaymentMethods(List<PaymentMethod> methods) async {
    if (_useFirebase) {
      try {
        await FirebaseService.savePaymentMethods(methods);
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
        _useFirebase = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'paymentMethods',
      json.encode(methods.map((e) => e.toJson()).toList()),
    );
  }

  static Stream<List<PaymentMethod>>? watchPaymentMethods() {
    if (_useFirebase) {
      try {
        return FirebaseService.watchPaymentMethods();
      } catch (e) {
        print('Firebase streaming error: $e');
        return null;
      }
    }
    return null;
  }

  static List<Account> _defaultAccounts() => [
    Account(id: '1', name: 'Cash', type: 'cash', balance: 0),
    Account(
      id: '2',
      name: 'Savings Account',
      type: 'bank',
      balance: 0,
      bankName: 'My Bank',
      accountNumber: null,
      ifscCode: null,
      debitCardNumber: null,
      debitCardExpiry: null,
    ),
  ];

  static List<PaymentMethod> _defaultPaymentMethods() => [
    PaymentMethod(id: '1', name: 'Cash', type: 'cash'),
  ];

  static List<Category> _defaultCategories() => [
    // Expense categories
    Category(
      id: '1',
      name: 'Groceries',
      icon: 'ShoppingCart',
      color: '#4CAF50',
      iconCode: 0xe59c,
      colorValue: 0xFF4CAF50,
      budgetLimit: 5000,
      type: 'expense',
    ),
    Category(
      id: '2',
      name: 'Rent',
      icon: 'Home',
      color: '#2196F3',
      iconCode: 0xe88a,
      colorValue: 0xFF2196F3,
      budgetLimit: 15000,
      type: 'expense',
    ),
    Category(
      id: '3',
      name: 'Entertainment',
      icon: 'Movie',
      color: '#9C27B0',
      iconCode: 0xe8da,
      colorValue: 0xFF9C27B0,
      budgetLimit: 3000,
      type: 'expense',
    ),
    Category(
      id: '4',
      name: 'Transport',
      icon: 'Car',
      color: '#FF9800',
      iconCode: 0xe531,
      colorValue: 0xFFFF9800,
      budgetLimit: 2000,
      type: 'expense',
    ),
    Category(
      id: '5',
      name: 'Food',
      icon: 'UtensilsCrossed',
      color: '#F44336',
      iconCode: 0xe56c,
      colorValue: 0xFFF44336,
      budgetLimit: 4000,
      type: 'expense',
    ),
    Category(
      id: '6',
      name: 'Bills',
      icon: 'Receipt',
      color: '#795548',
      iconCode: 0xe8b0,
      colorValue: 0xFF795548,
      budgetLimit: 3000,
      type: 'expense',
    ),
    Category(
      id: '7',
      name: 'Shopping',
      icon: 'ShoppingCart',
      color: '#E91E63',
      iconCode: 0xe8cb,
      colorValue: 0xFFE91E63,
      budgetLimit: 5000,
      type: 'expense',
    ),
    Category(
      id: '8',
      name: 'Health',
      icon: 'MedicalServices',
      color: '#009688',
      iconCode: 0xf03d5,
      colorValue: 0xFF009688,
      budgetLimit: 3000,
      type: 'expense',
    ),
    // Income categories
    Category(
      id: '101',
      name: 'Salary',
      icon: 'Briefcase',
      color: '#10B981',
      iconCode: 0xe8d0,
      colorValue: 0xFF10B981,
      type: 'income',
    ),
    Category(
      id: '102',
      name: 'Freelance',
      icon: 'Laptop',
      color: '#3B82F6',
      iconCode: 0xe30a,
      colorValue: 0xFF3B82F6,
      type: 'income',
    ),
    Category(
      id: '103',
      name: 'Investment',
      icon: 'TrendingUp',
      color: '#8B5CF6',
      iconCode: 0xe926,
      colorValue: 0xFF8B5CF6,
      type: 'income',
    ),
    Category(
      id: '104',
      name: 'Business',
      icon: 'Business',
      color: '#06B6D4',
      iconCode: 0xe0af,
      colorValue: 0xFF06B6D4,
      type: 'income',
    ),
    Category(
      id: '105',
      name: 'Gift',
      icon: 'Gift',
      color: '#EC4899',
      iconCode: 0xe5c6,
      colorValue: 0xFFEC4899,
      type: 'income',
    ),
    Category(
      id: '106',
      name: 'Bonus',
      icon: 'Stars',
      color: '#F59E0B',
      iconCode: 0xe838,
      colorValue: 0xFFF59E0B,
      type: 'income',
    ),
    Category(
      id: '107',
      name: 'Refund',
      icon: 'Refund',
      color: '#14B8A6',
      iconCode: 0xe8d4,
      colorValue: 0xFF14B8A6,
      type: 'income',
    ),
    Category(
      id: '108',
      name: 'Transfer',
      icon: 'CompareArrows',
      color: '#6366F1',
      iconCode: 0xe8d5,
      colorValue: 0xFF6366F1,
      type: 'income',
    ),
    Category(
      id: '109',
      name: 'Other Income',
      icon: 'AttachMoney',
      color: '#22C55E',
      iconCode: 0xe147,
      colorValue: 0xFF22C55E,
      type: 'income',
    ),
  ];

  // User Profile Management
  static Future<UserProfile?> getUserProfile(String userId) async {
    if (_useFirebase) {
      try {
        return await FirebaseService.getUserProfile(userId);
      } catch (e) {
        print('Firebase error getting user profile: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_profile_$userId');
    if (data == null) return null;
    return UserProfile.fromMap(json.decode(data));
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveUserProfile(profile);
        return;
      } catch (e) {
        print('Firebase error saving user profile: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_profile_${profile.id}',
      json.encode(profile.toMap()),
    );
  }

  // Group Management
  static Future<Group?> getGroup(String groupId) async {
    if (_useFirebase) {
      try {
        return await FirebaseService.getGroup(groupId);
      } catch (e) {
        print('Firebase error getting group: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('group_$groupId');
    if (data == null) return null;
    return Group.fromMap(json.decode(data));
  }

  static Future<void> saveGroup(Group group) async {
    if (_useFirebase) {
      try {
        await FirebaseService.saveGroup(group);
        return;
      } catch (e) {
        print('Firebase error saving group: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('group_${group.id}', json.encode(group.toMap()));

    // Also store in group list
    final groupsList = await _getGroupsList();
    if (!groupsList.contains(group.id)) {
      groupsList.add(group.id);
      await prefs.setString('groups_list', json.encode(groupsList));
    }
  }

  static Future<void> deleteGroup(String groupId) async {
    if (_useFirebase) {
      try {
        await FirebaseService.deleteGroup(groupId);
        return;
      } catch (e) {
        print('Firebase error deleting group: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('group_$groupId');

    final groupsList = await _getGroupsList();
    groupsList.remove(groupId);
    await prefs.setString('groups_list', json.encode(groupsList));
  }

  static Future<Group?> getGroupByInviteCode(String inviteCode) async {
    if (_useFirebase) {
      try {
        return await FirebaseService.getGroupByInviteCode(inviteCode);
      } catch (e) {
        print('Firebase error getting group by invite code: $e');
      }
    }

    // Local storage: search through all groups
    final groupsList = await _getGroupsList();
    for (final groupId in groupsList) {
      final group = await getGroup(groupId);
      if (group != null && group.inviteCode == inviteCode) {
        return group;
      }
    }
    return null;
  }

  static Future<List<Group>> getUserGroups(String userId) async {
    if (_useFirebase) {
      try {
        return await FirebaseService.getUserGroups(userId);
      } catch (e) {
        print('Firebase error getting user groups: $e');
      }
    }

    // Local storage: search through all groups
    final groupsList = await _getGroupsList();
    final userGroups = <Group>[];
    for (final groupId in groupsList) {
      final group = await getGroup(groupId);
      if (group != null && group.hasMember(userId)) {
        userGroups.add(group);
      }
    }
    return userGroups;
  }

  static Future<List<String>> _getGroupsList() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('groups_list');
    if (data == null) return [];
    return (json.decode(data) as List).cast<String>();
  }
}
