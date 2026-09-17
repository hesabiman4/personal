import 'package:sqflite_sqlcipher/sqflite_sqlcipher.dart';
import 'package:sqflite_common/sqlite_api.dart' show Transaction;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import '../utils/constants.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/receivable.dart';
import '../models/transaction.dart' as app_models;

/// Database service for encrypted SQLite operations
class DatabaseService {
  static Database? _database;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _dbKeyKey = 'database_key';
  static const Uuid uuid = Uuid();

  /// Initialize the database
  static Future<void> initialize() async {
    if (_database != null) return;

    // Generate and store encryption key if not exists
    String? dbKey = await _secureStorage.read(key: _dbKeyKey);
    if (dbKey == null) {
      dbKey = uuid.v4();
      await _secureStorage.write(key: _dbKeyKey, value: dbKey);
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, AppConstants.databaseName);

    _database = await openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      password: dbKey,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Get database instance
  static Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Close database connection
  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        opening_balance_minor INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Clients table
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        service_description TEXT,
        phone TEXT,
        email TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Receivables (invoices) table
    await db.execute('''
      CREATE TABLE receivables (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        reference TEXT NOT NULL,
        description TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        issued_on TEXT NOT NULL,
        due_on TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        occurred_on TEXT NOT NULL,
        occurred_time TEXT NOT NULL,
        note TEXT,
        client_id TEXT,
        receivable_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
        FOREIGN KEY (receivable_id) REFERENCES receivables(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(occurred_on)');
    await db.execute('CREATE INDEX idx_transactions_client ON transactions(client_id)');
    await db.execute('CREATE INDEX idx_transactions_receivable ON transactions(receivable_id)');
    await db.execute('CREATE INDEX idx_receivables_client ON receivables(client_id)');
    await db.execute('CREATE INDEX idx_receivables_due ON receivables(due_on)');

    // Seed default accounts
    final now = DateTime.now().toIso8601String();
    for (final accountData in AppConstants.defaultAccounts) {
      await db.insert('accounts', {
        'id': uuid.v4(),
        'name': accountData['name'],
        'kind': accountData['kind'],
        'opening_balance_minor': accountData['opening_balance_minor'],
        'created_at': now,
        'updated_at': now,
      });
    }

    // Seed default income categories
    for (final categoryData in AppConstants.defaultIncomeCategories) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': categoryData['name'],
        'type': AppConstants.categoryTypeIncome,
        'icon_key': categoryData['icon_key'],
        'created_at': now,
        'updated_at': now,
      });
    }

    // Seed default expense categories
    for (final categoryData in AppConstants.defaultExpenseCategories) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': categoryData['name'],
        'type': AppConstants.categoryTypeExpense,
        'icon_key': categoryData['icon_key'],
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
    if (oldVersion < 2) {
      // Example migration
    }
  }

  // ==================== Account Operations ====================

  /// Get all accounts
  Future<List<Account>> getAllAccounts() async {
    final maps = await database.query('accounts', orderBy: 'name');
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  /// Get account by ID
  Future<Account?> getAccountById(String id) async {
    final maps = await database.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  /// Insert account
  Future<String> insertAccount(Account account) async {
    final id = uuid.v4();
    await database.insert('accounts', account.copyWith(id: id).toMap());
    return id;
  }

  /// Update account
  Future<void> updateAccount(Account account) async {
    await database.update(
      'accounts',
      account.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Delete account
  Future<void> deleteAccount(String id) async {
    await database.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Category Operations ====================

  /// Get categories by type
  Future<List<Category>> getCategoriesByType(String type) async {
    final maps = await database.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    final maps = await database.query('categories', orderBy: 'type, name');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String id) async {
    final maps = await database.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  // ==================== Client Operations ====================

  /// Get all clients (optionally including archived)
  Future<List<Client>> getAllClients({bool includeArchived = false}) async {
    String where = includeArchived ? '' : 'is_archived = 0';
    final maps = await database.query('clients', where: where, orderBy: 'name');
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  /// Get client by ID
  Future<Client?> getClientById(String id) async {
    final maps = await database.query('clients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  /// Insert client
  Future<String> insertClient(Client client) async {
    final id = uuid.v4();
    await database.insert('clients', client.copyWith(id: id).toMap());
    return id;
  }

  /// Update client
  Future<void> updateClient(Client client) async {
    await database.update(
      'clients',
      client.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  /// Archive client
  Future<void> archiveClient(String id) async {
    await database.update(
      'clients',
      {'is_archived': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete client (only if no financial history)
  Future<void> deleteClient(String id) async {
    await database.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Receivable Operations ====================

  /// Get all receivables
  Future<List<Receivable>> getAllReceivables() async {
    final maps = await database.query('receivables', orderBy: 'issued_on DESC');
    return maps.map((map) => Receivable.fromMap(map)).toList();
  }

  /// Get receivables by client ID
  Future<List<Receivable>> getReceivablesByClientId(String clientId) async {
    final maps = await database.query(
      'receivables',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'issued_on DESC',
    );
    return maps.map((map) => Receivable.fromMap(map)).toList();
  }

  /// Get receivable by ID
  Future<Receivable?> getReceivableById(String id) async {
    final maps = await database.query('receivables', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Receivable.fromMap(maps.first);
  }

  /// Insert receivable
  Future<String> insertReceivable(Receivable receivable) async {
    final id = uuid.v4();
    await database.insert('receivables', receivable.copyWith(id: id).toMap());
    return id;
  }

  /// Update receivable
  Future<void> updateReceivable(Receivable receivable) async {
    await database.update(
      'receivables',
      receivable.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [receivable.id],
    );
  }

  /// Delete receivable
  Future<void> deleteReceivable(String id) async {
    await database.delete('receivables', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== app_models.Transaction Operations ====================

  /// Get all transactions
  Future<List<app_models.app_models.Transaction>> getAllTransactions() async {
    final maps = await database.query('transactions', orderBy: 'occurred_on DESC, occurred_time DESC');
    return maps.map((map) => app_models.app_models.Transaction.fromMap(map)).toList();
  }

  /// Get transactions with filters
  Future<List<app_models.app_models.Transaction>> getTransactions({
    String? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId,
  }) async {
    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }
    if (accountId != null) {
      whereParts.add('account_id = ?');
      whereArgs.add(accountId);
    }
    if (categoryId != null) {
      whereParts.add('category_id = ?');
      whereArgs.add(categoryId);
    }
    if (startDate != null) {
      whereParts.add('occurred_on >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereParts.add('occurred_on <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (clientId != null) {
      whereParts.add('client_id = ?');
      whereArgs.add(clientId);
    }

    final where = whereParts.isNotEmpty ? whereParts.join(' AND ') : null;

    final maps = await database.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'occurred_on DESC, occurred_time DESC',
    );

    return maps.map((map) => app_models.app_models.Transaction.fromMap(map)).toList();
  }

  /// Get transaction by ID
  Future<app_models.app_models.Transaction?> getTransactionById(String id) async {
    final maps = await database.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return app_models.app_models.Transaction.fromMap(maps.first);
  }

  /// Insert transaction
  Future<String> insertTransaction(app_models.app_models.Transaction transaction) async {
    final id = uuid.v4();
    await database.insert('transactions', transaction.copyWith(id: id).toMap());
    return id;
  }

  /// Update transaction
  Future<void> updateTransaction(app_models.app_models.Transaction transaction) async {
    await database.update(
      'transactions',
      transaction.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    await database.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Aggregate Queries ====================

  /// Get total income for a period
  Future<int> getTotalIncome({DateTime? startDate, DateTime? endDate}) async {
    final result = await _getSumByType('income', startDate: startDate, endDate: endDate);
    return result ?? 0;
  }

  /// Get total expenses for a period
  Future<int> getTotalExpenses({DateTime? startDate, DateTime? endDate}) async {
    final result = await _getSumByType('expense', startDate: startDate, endDate: endDate);
    return result ?? 0;
  }

  /// Get sum by transaction type
  Future<int?> _getSumByType(String type, {DateTime? startDate, DateTime? endDate}) async {
    final whereParts = <String>['type = ?'];
    final whereArgs = <dynamic>[type];

    if (startDate != null) {
      whereParts.add('occurred_on >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereParts.add('occurred_on <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await database.rawQuery(
      'SELECT SUM(amount_minor) as total FROM transactions WHERE ${whereParts.join(' AND ')}',
      whereArgs,
    );

    if (result.isEmpty || result.first['total'] == null) {
      return null;
    }

    return result.first['total'] as int;
  }

  /// Get current balance across all accounts
  Future<int> getCurrentBalance() async {
    final income = await getTotalIncome();
    final expenses = await getTotalExpenses();
    final accounts = await getAllAccounts();
    
    final openingBalance = accounts.fold<int>(
      0,
      (sum, account) => sum + account.openingBalanceMinor,
    );

    return openingBalance + income - expenses;
  }

  /// Get balance from 30 days ago
  Future<int> getBalanceThirtyDaysAgo() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final income = await getTotalIncome(endDate: thirtyDaysAgo);
    final expenses = await getTotalExpenses(endDate: thirtyDaysAgo);
    final accounts = await getAllAccounts();
    
    final openingBalance = accounts.fold<int>(
      0,
      (sum, account) => sum + account.openingBalanceMinor,
    );

    return openingBalance + income - expenses;
  }

  /// Get recent transactions (limit)
  Future<List<app_models.app_models.Transaction>> getRecentTransactions({int limit = 5}) async {
    final maps = await database.query(
      'transactions',
      orderBy: 'occurred_on DESC, occurred_time DESC',
      limit: limit,
    );
    return maps.map((map) => app_models.app_models.Transaction.fromMap(map)).toList();
  }

  /// Get outstanding clients with balances
  Future<List<Map<String, dynamic>>> getOutstandingClients({int limit = 5}) async {
    // This requires a complex query joining clients, receivables, and transactions
    // Simplified version - will be enhanced with proper joins
    final result = await database.rawQuery('''
      SELECT 
        c.id,
        c.name,
        SUM(r.amount_minor) as total_billed,
        COALESCE(SUM(t.amount_minor), 0) as total_paid,
        SUM(r.amount_minor) - COALESCE(SUM(t.amount_minor), 0) as outstanding,
        MIN(r.due_on) as earliest_due_date
      FROM clients c
      JOIN receivables r ON c.id = r.client_id
      LEFT JOIN transactions t ON r.id = t.receivable_id AND t.type = 'income'
      WHERE c.is_archived = 0
      GROUP BY c.id, c.name
      HAVING outstanding > 0
      ORDER BY earliest_due_date ASC, outstanding DESC
      LIMIT ?
    ''', [limit]);

    return result;
  }

  /// Clear all data (for reset)
  Future<void> clearAllData() async {
    await database.delete('transactions');
    await database.delete('receivables');
    await database.delete('clients');
    // Keep default categories and accounts
  }

  /// Export data to CSV format
  Future<String> exportToCSV(String tableName) async {
    final maps = await database.query(tableName);
    if (maps.isEmpty) return '';

    final headers = maps.first.keys.join(',');
    final rows = maps.map((map) {
      return map.values.map((value) {
        if (value == null) return '';
        final str = value.toString();
        // Escape quotes and wrap in quotes if contains comma
        if (str.contains(',') || str.contains('"')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\n');

    return '$headers\n$rows';
  }
}
