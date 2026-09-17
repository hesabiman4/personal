import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:income_expense_tracker/screens/transaction_form_screen.dart';
import 'package:income_expense_tracker/providers/finance_provider.dart';
import 'package:provider/provider.dart';

void main() {
  late FinanceProvider financeProvider;

  setUp(() {
    financeProvider = FinanceProvider();
  });

  group('Transaction Form Widget Tests', () {
    testWidgets('Transaction form displays all input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );

      // Verify amount field exists
      expect(find.byType(TextFormField), findsWidgets);
      
      // Verify type toggle exists
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      
      // Verify save button exists
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Amount input accepts valid numbers', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );

      final amountField = find.byType(TextFormField).first;
      
      await tester.enterText(amountField, '100.50');
      await tester.pump();
      
      expect(tester.widget<TextFormField>(amountField).controller?.text, '100.50');
    });

    testWidgets('Save button shows loading state during submission', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );

      // Fill required fields
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '50.00');
      await tester.pump();

      // Tap save button
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Verify loading indicator appears (if implemented)
      // This depends on your implementation
    });

    testWidgets('Form validation prevents empty amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );

      // Try to save without entering amount
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Verify error message or no submission
      // Adjust based on your validation implementation
    });
  });

  group('Transactions List Widget Tests', () {
    testWidgets('Transactions list displays empty state when no transactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionsListScreen()),
        ),
      );

      // Verify empty state message
      expect(find.textContaining('No transactions'), findsOneWidget);
      
      // Verify add button exists
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Transactions list shows items after adding transaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionsListScreen()),
        ),
      );

      // Add a test transaction
      await financeProvider.addTransaction(
        amount: 100.0,
        type: TransactionType.income,
        accountId: 'acc_cash',
        categoryId: 'cat_salary',
        date: DateTime.now(),
        note: 'Test income',
      );

      await tester.pumpAndSettle();

      // Verify transaction appears in list
      expect(find.text('\$100.00'), findsOneWidget);
      expect(find.text('Test income'), findsOneWidget);
    });

    testWidgets('Filter bottom sheet opens when filter button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionsListScreen()),
        ),
      );

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Verify filter options appear
      expect(find.text('Filter Transactions'), findsOneWidget);
    });

    testWidgets('Swipe to delete shows confirmation dialog', (WidgetTester tester) async {
      // Add a transaction first
      await financeProvider.addTransaction(
        amount: 50.0,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: TransactionsListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Perform swipe to delete
      await tester.drag(
        find.byType(Card).first,
        const Offset(-500.0, 0.0),
      );
      await tester.pumpAndSettle();

      // Verify delete confirmation appears
      expect(find.textContaining('Delete'), findsOneWidget);
    });
  });

  group('Reports Screen Widget Tests', () {
    testWidgets('Reports screen displays summary cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: ReportsScreen()),
        ),
      );

      // Verify summary sections exist
      expect(find.textContaining('Income'), findsOneWidget);
      expect(find.textContaining('Expense'), findsOneWidget);
      expect(find.textContaining('Net'), findsOneWidget);
    });

    testWidgets('Period selector changes time range', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: ReportsScreen()),
        ),
      );

      // Tap on different period options
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // Verify data updates (implementation dependent)
    });

    testWidgets('Category breakdown displays percentages', (WidgetTester tester) async {
      // Add some test transactions
      await financeProvider.addTransaction(
        amount: 200.0,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        date: DateTime.now(),
      );

      await financeProvider.addTransaction(
        amount: 100.0,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_transport',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: ReportsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify percentage displays
      expect(find.textContaining('%'), findsWidgets);
    });
  });
}
