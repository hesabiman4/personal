import 'package:flutter_test/flutter_test.dart';
import 'package:income_expense_tracker/models/transaction.dart';
import 'package:income_expense_tracker/models/account.dart';
import 'package:income_expense_tracker/models/category.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction constructor sets values correctly', () {
      final transaction = Transaction(
        id: '1',
        amount: 100.50,
        type: TransactionType.income,
        accountId: 'acc1',
        categoryId: 'cat1',
        date: DateTime(2024, 1, 15),
        note: 'Test transaction',
        clientId: 'client1',
      );

      expect(transaction.id, '1');
      expect(transaction.amount, 100.50);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc1');
      expect(transaction.categoryId, 'cat1');
      expect(transaction.date, DateTime(2024, 1, 15));
      expect(transaction.note, 'Test transaction');
      expect(transaction.clientId, 'client1');
    });

    test('Transaction toJson and fromJson work correctly', () {
      final original = Transaction(
        id: '2',
        amount: 250.75,
        type: TransactionType.expense,
        accountId: 'acc2',
        categoryId: 'cat2',
        date: DateTime(2024, 2, 20),
        note: 'Serialization test',
      );

      final json = original.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.type, original.type);
      expect(restored.accountId, original.accountId);
      expect(restored.categoryId, original.categoryId);
      expect(restored.date, original.date);
      expect(restored.note, original.note);
    });

    test('Transaction copyWith creates modified copy', () {
      final original = Transaction(
        id: '3',
        amount: 100.0,
        type: TransactionType.income,
        accountId: 'acc1',
        categoryId: 'cat1',
        date: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(amount: 200.0, note: 'Updated');

      expect(modified.id, original.id); // Unchanged
      expect(modified.amount, 200.0); // Changed
      expect(modified.note, 'Updated'); // Changed
      expect(modified.type, original.type); // Unchanged
    });

    test('Transaction validation - negative amount rejected', () {
      expect(
        () => Transaction(
          id: '4',
          amount: -50.0,
          type: TransactionType.income,
          accountId: 'acc1',
          categoryId: 'cat1',
          date: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Account Model Tests', () {
    test('Account constructor sets values correctly', () {
      final account = Account(
        id: 'acc1',
        name: 'Cash Wallet',
        type: AccountType.cash,
        balance: 500.0,
        color: 0xFF2196F3,
        isDefault: true,
      );

      expect(account.name, 'Cash Wallet');
      expect(account.type, AccountType.cash);
      expect(account.balance, 500.0);
      expect(account.isDefault, true);
    });

    test('Account balance updates correctly', () {
      final account = Account(
        id: 'acc1',
        name: 'Bank Account',
        type: AccountType.bank,
        balance: 1000.0,
        color: 0xFF4CAF50,
      );

      final updated = account.copyWith(balance: 1500.0);
      expect(updated.balance, 1500.0);
      expect(updated.name, account.name); // Unchanged
    });
  });

  group('Category Model Tests', () {
    test('Category constructor sets values correctly', () {
      final category = Category(
        id: 'cat1',
        name: 'Food',
        type: CategoryType.expense,
        icon: '🍔',
        color: 0xFFFF9800,
      );

      expect(category.name, 'Food');
      expect(category.type, CategoryType.expense);
      expect(category.icon, '🍔');
    });

    test('Category expense vs income types', () {
      final expenseCat = Category(
        id: 'cat1',
        name: 'Rent',
        type: CategoryType.expense,
        icon: '🏠',
        color: 0xFFF44336,
      );

      final incomeCat = Category(
        id: 'cat2',
        name: 'Salary',
        type: CategoryType.income,
        icon: '💰',
        color: 0xFF4CAF50,
      );

      expect(expenseCat.type, CategoryType.expense);
      expect(incomeCat.type, CategoryType.income);
    });
  });
}
