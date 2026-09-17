import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/receivable.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// Finance provider for managing financial data state
class FinanceProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  List<Client> _clients = [];
  List<Receivable> _receivables = [];
  List<Transaction> _transactions = [];
  
  int _currentBalance = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Account> get accounts => _accounts;
  List<Category> get incomeCategories => _incomeCategories;
  List<Category> get expenseCategories => _expenseCategories;
  List<Client> get clients => _clients;
  List<Receivable> get receivables => _receivables;
  List<Transaction> get transactions => _transactions;
  int get currentBalance => _currentBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all financial data
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadAccounts(),
        _loadCategories(),
        _loadClients(),
        _loadReceivables(),
        _loadTransactions(),
        _loadBalance(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAccounts() async {
    _accounts = await DatabaseService().getAllAccounts();
  }

  Future<void> _loadCategories() async {
    _incomeCategories = await DatabaseService().getCategoriesByType('income');
    _expenseCategories = await DatabaseService().getCategoriesByType('expense');
  }

  Future<void> _loadClients() async {
    _clients = await DatabaseService().getAllClients();
  }

  Future<void> _loadReceivables() async {
    _receivables = await DatabaseService().getAllReceivables();
  }

  Future<void> _loadTransactions() async {
    _transactions = await DatabaseService().getAllTransactions();
  }

  Future<void> _loadBalance() async {
    _currentBalance = await DatabaseService().getCurrentBalance();
  }

  // ==================== Transaction Operations ====================

  /// Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await DatabaseService().insertTransaction(transaction);
      await loadData(); // Reload all data
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await DatabaseService().updateTransaction(transaction);
      await loadData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await DatabaseService().deleteTransaction(id);
      await loadData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ==================== Client Operations ====================

  /// Add a new client
  Future<void> addClient(Client client) async {
    try {
      await DatabaseService().insertClient(client);
      await _loadClients();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update existing client
  Future<void> updateClient(Client client) async {
    try {
      await DatabaseService().updateClient(client);
      await _loadClients();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Archive client
  Future<void> archiveClient(String id) async {
    try {
      await DatabaseService().archiveClient(id);
      await _loadClients();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ==================== Receivable Operations ====================

  /// Add a new receivable (invoice)
  Future<void> addReceivable(Receivable receivable) async {
    try {
      await DatabaseService().insertReceivable(receivable);
      await _loadReceivables();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update existing receivable
  Future<void> updateReceivable(Receivable receivable) async {
    try {
      await DatabaseService().updateReceivable(receivable);
      await _loadReceivables();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete receivable
  Future<void> deleteReceivable(String id) async {
    try {
      await DatabaseService().deleteReceivable(id);
      await _loadReceivables();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ==================== Helper Methods ====================

  /// Get account by ID
  Account? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get category by ID
  Category? getCategoryById(String id) {
    try {
      return [
        ..._incomeCategories,
        ..._expenseCategories,
      ].firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get client by ID
  Client? getClientById(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get receivable by ID
  Receivable? getReceivableById(String id) {
    try {
      return _receivables.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get filtered transactions
  List<Transaction> getFilteredTransactions({
    String? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId,
  }) {
    return _transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (accountId != null && t.accountId != accountId) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (clientId != null && t.clientId != clientId) return false;
      
      if (startDate != null) {
        final tDate = DateTime(t.occurredOn.year, t.occurredOn.month, t.occurredOn.day);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        if (tDate.isBefore(start)) return false;
      }
      
      if (endDate != null) {
        final tDate = DateTime(t.occurredOn.year, t.occurredOn.month, t.occurredOn.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        if (tDate.isAfter(end)) return false;
      }
      
      return true;
    }).toList();
  }

  /// Get recent transactions
  List<Transaction> getRecentTransactions({int limit = 5}) {
    return _transactions.take(limit).toList();
  }

  /// Get outstanding clients summary
  Future<List<Map<String, dynamic>>> getOutstandingClientsSummary() async {
    return await DatabaseService().getOutstandingClients(limit: 5);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
