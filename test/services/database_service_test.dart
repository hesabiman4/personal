import 'package:flutter_test/flutter_test.dart';
import 'package:income_expense_tracker/services/database_service.dart';
import 'package:income_expense_tracker/models/transaction.dart';
import 'package:income_expense_tracker/models/account.dart';
import 'package:income_expense_tracker/models/category.dart';

void main() {
  late DatabaseService databaseService;

  setUp(() async {
    databaseService = DatabaseService();
    await databaseService.initialize();
  });

  tearDown(() async {
    // Clean up test data if needed
  });

  group('Database Service - Account Tests', () {
    test('Create account successfully', () async {
      final account = Account(
        id: 'test_acc_1',
        name: 'Test Wallet',
        type: AccountType.cash,
        balance: 100.0,
        color: 0xFF2196F3,
      );

      await databaseService.insertAccount(account);
      final retrieved = await databaseService.getAccountById('test_acc_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test Wallet');
      expect(retrieved.type, AccountType.cash);
      expect(retrieved.balance, 100.0);
    });

    test('Update account balance', () async {
      final account = Account(
        id: 'test_acc_2',
        name: 'Bank Account',
        type: AccountType.bank,
        balance: 500.0,
        color: 0xFF4CAF50,
      );

      await databaseService.insertAccount(account);
      
      final updated = account.copyWith(balance: 750.0);
      await databaseService.updateAccount(updated);
      
      final retrieved = await databaseService.getAccountById('test_acc_2');
      expect(retrieved!.balance, 750.0);
    });

    test('Delete account', () async {
      final account = Account(
        id: 'test_acc_3',
        name: 'To Delete',
        type: AccountType.cash,
        balance: 0.0,
        color: 0xFFF44336,
      );

      await databaseService.insertAccount(account);
      await databaseService.deleteAccount('test_acc_3');
      
      final retrieved = await databaseService.getAccountById('test_acc_3');
      expect(retrieved, isNull);
    });

    test('Get all accounts', () async {
      final accounts = await databaseService.getAllAccounts();
      expect(accounts, isNotNull);
      expect(accounts.length, greaterThan(0)); // Should have default accounts
    });
  });

  group('Database Service - Transaction Tests', () {
    test('Create transaction successfully', () async {
      final transaction = Transaction(
        id: 'test_txn_1',
        amount: 50.0,
        type: TransactionType.expense,
        accountId: 'acc_cash', // Use default account
        categoryId: 'cat_food', // Use default category
        date: DateTime.now(),
        note: 'Test expense',
      );

      await databaseService.insertTransaction(transaction);
      final retrieved = await databaseService.getTransactionById('test_txn_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.amount, 50.0);
      expect(retrieved.type, TransactionType.expense);
      expect(retrieved.note, 'Test expense');
    });

    test('Get transactions by type', () async {
      final incomeTxn = Transaction(
        id: 'test_txn_income',
        amount: 1000.0,
        type: TransactionType.income,
        accountId: 'acc_bank',
        categoryId: 'cat_salary',
        date: DateTime.now(),
      );

      final expenseTxn = Transaction(
        id: 'test_txn_expense',
        amount: 100.0,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        date: DateTime.now(),
      );

      await databaseService.insertTransaction(incomeTxn);
      await databaseService.insertTransaction(expenseTxn);

      final incomes = await databaseService.getTransactionsByType(TransactionType.income);
      final expenses = await databaseService.getTransactionsByType(TransactionType.expense);

      expect(incomes.any((t) => t.id == 'test_txn_income'), true);
      expect(expenses.any((t) => t.id == 'test_txn_expense'), true);
    });

    test('Update transaction', () async {
      final transaction = Transaction(
        id: 'test_txn_update',
        amount: 75.0,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_transport',
        date: DateTime.now(),
        note: 'Original note',
      );

      await databaseService.insertTransaction(transaction);
      
      final updated = transaction.copyWith(amount: 100.0, note: 'Updated note');
      await databaseService.updateTransaction(updated);
      
      final retrieved = await databaseService.getTransactionById('test_txn_update');
      expect(retrieved!.amount, 100.0);
      expect(retrieved.note, 'Updated note');
    });

    test('Delete transaction', () async {
      final transaction = Transaction(
        id: 'test_txn_delete',
        amount: 25.0,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        date: DateTime.now(),
      );

      await databaseService.insertTransaction(transaction);
      await databaseService.deleteTransaction('test_txn_delete');
      
      final retrieved = await databaseService.getTransactionById('test_txn_delete');
      expect(retrieved, isNull);
    });
  });

  group('Database Service - Category Tests', () {
    test('Get all expense categories', () async {
      final categories = await databaseService.getCategoriesByType(CategoryType.expense);
      expect(categories, isNotNull);
      expect(categories.length, greaterThan(0));
    });

    test('Get all income categories', () async {
      final categories = await databaseService.getCategoriesByType(CategoryType.income);
      expect(categories, isNotNull);
      expect(categories.length, greaterThan(0));
    });
  });

  group('Database Service - Aggregation Tests', () {
    test('Calculate total income for period', () async {
      final now = DateTime.now();
      final txn1 = Transaction(
        id: 'test_agg_1',
        amount: 500.0,
        type: TransactionType.income,
        accountId: 'acc_bank',
        categoryId: 'cat_salary',
        date: now.subtract(const Duration(days: 5)),
      );

      final txn2 = Transaction(
        id: 'test_agg_2',
        amount: 300.0,
        type: TransactionType.income,
        accountId: 'acc_cash',
        categoryId: 'cat_freelance',
        date: now.subtract(const Duration(days: 2)),
      );

      await databaseService.insertTransaction(txn1);
      await databaseService.insertTransaction(txn2);

      final total = await databaseService.getTotalByPeriod(
        TransactionType.income,
        now.subtract(const Duration(days: 7)),
        now,
      );

      expect(total, equals(800.0));
    });

    test('Calculate total expenses for period', () async {
      final now = DateTime.now();
      final txn = Transaction(
        id: 'test_agg_exp',
        amount: 150.0,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        date: now.subtract(const Duration(days: 1)),
      );

      await databaseService.insertTransaction(txn);

      final total = await databaseService.getTotalByPeriod(
        TransactionType.expense,
        now.subtract(const Duration(days: 7)),
        now,
      );

      expect(total, equals(150.0));
    });
  });
}
