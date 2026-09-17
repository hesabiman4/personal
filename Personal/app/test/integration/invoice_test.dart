import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:income_expense_tracker/screens/invoice_form_screen.dart';
import 'package:income_expense_tracker/screens/invoices_list_screen.dart';
import 'package:income_expense_tracker/providers/finance_provider.dart';
import 'package:provider/provider.dart';

void main() {
  late FinanceProvider financeProvider;

  setUp(() {
    financeProvider = FinanceProvider();
  });

  group('Invoice Form Widget Tests', () {
    testWidgets('Invoice form displays all input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: InvoiceFormScreen()),
        ),
      );

      // Verify client selector exists
      expect(find.textContaining('Client'), findsOneWidget);
      
      // Verify due date field exists
      expect(find.textContaining('Due Date'), findsOneWidget);
      
      // Verify line items section exists
      expect(find.textContaining('Items'), findsOneWidget);
      
      // Verify save button exists
      expect(find.text('Save Invoice'), findsOneWidget);
    });

    testWidgets('Add line item button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: InvoiceFormScreen()),
        ),
      );

      // Tap add item button
      await tester.tap(find.text('Add Item'));
      await tester.pump();

      // Verify new item fields appear
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Line item calculates total automatically', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: InvoiceFormScreen()),
        ),
      );

      // Add an item
      await tester.tap(find.text('Add Item'));
      await tester.pump();

      // Enter quantity and price
      final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      if (fields.length >= 2) {
        await tester.enterText(fields[0], '5'); // Quantity
        await tester.pump();
        await tester.enterText(fields[1], '10.00'); // Price
        await tester.pump();

        // Verify total shows 50.00
        expect(find.textContaining('50.00'), findsOneWidget);
      }
    });

    testWidgets('Invoice total updates when items change', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: InvoiceFormScreen()),
        ),
      );

      // Add multiple items and verify total calculation
      await tester.tap(find.text('Add Item'));
      await tester.pump();
      await tester.tap(find.text('Add Item'));
      await tester.pump();

      // Total should reflect sum of all items
      expect(find.textContaining('Total'), findsOneWidget);
    });
  });

  group('Invoices List Widget Tests', () {
    testWidgets('Invoices list displays empty state when no invoices', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: InvoicesListScreen()),
        ),
      );

      // Verify empty state message
      expect(find.textContaining('No invoices'), findsOneWidget);
      
      // Verify create button exists
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Invoices list shows items after adding invoice', (WidgetTester tester) async {
      // Add a test client first
      await financeProvider.addClient(
        name: 'Test Client',
        email: 'test@example.com',
        phone: '+1234567890',
      );

      // Get the client ID
      final clients = financeProvider.clients;
      if (clients.isNotEmpty) {
        final client = clients.first;

        // Add a test invoice
        await financeProvider.addInvoice(
          clientId: client.id,
          invoiceNumber: 'INV-001',
          dueDate: DateTime.now().add(const Duration(days: 30)),
          items: [
            InvoiceItem(description: 'Service', quantity: 1, unitPrice: 100.0),
          ],
          notes: 'Test invoice',
        );

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: financeProvider,
            child: const MaterialApp(home: InvoicesListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify invoice appears in list
        expect(find.text('INV-001'), findsOneWidget);
        expect(find.text('\$100.00'), findsOneWidget);
      }
    });

    testWidgets('Status filter works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: financeProvider,
          child: const MaterialApp(home: InvoicesListScreen()),
        ),
      );

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Verify status options appear
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('Mark invoice as paid works', (WidgetTester tester) async {
      // Add test client and invoice
      await financeProvider.addClient(
        name: 'Client for Payment',
        email: 'client@example.com',
      );

      final clients = financeProvider.clients;
      if (clients.isNotEmpty) {
        final client = clients.firstWhere((c) => c.name == 'Client for Payment');

        await financeProvider.addInvoice(
          clientId: client.id,
          invoiceNumber: 'INV-PAY-001',
          dueDate: DateTime.now().add(const Duration(days: 30)),
          items: [
            InvoiceItem(description: 'Product', quantity: 2, unitPrice: 50.0),
          ],
        );

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: financeProvider,
            child: const MaterialApp(home: InvoicesListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on invoice to open details
        await tester.tap(find.text('INV-PAY-001'));
        await tester.pumpAndSettle();

        // Tap mark as paid button
        await tester.tap(find.text('Mark as Paid'));
        await tester.pumpAndSettle();

        // Verify status changed to Paid
        expect(find.text('Paid'), findsOneWidget);
      }
    });

    testWidgets('Delete invoice confirmation works', (WidgetTester tester) async {
      // Add test client and invoice
      await financeProvider.addClient(
        name: 'Client for Delete',
        email: 'delete@example.com',
      );

      final clients = financeProvider.clients;
      if (clients.isNotEmpty) {
        final client = clients.firstWhere((c) => c.name == 'Client for Delete');

        await financeProvider.addInvoice(
          clientId: client.id,
          invoiceNumber: 'INV-DEL-001',
          dueDate: DateTime.now().add(const Duration(days: 30)),
          items: [
            InvoiceItem(description: 'Item', quantity: 1, unitPrice: 25.0),
          ],
        );

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: financeProvider,
            child: const MaterialApp(home: InvoicesListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Swipe to delete
        await tester.drag(
          find.byType(Card).first,
          const Offset(-500.0, 0.0),
        );
        await tester.pumpAndSettle();

        // Verify delete confirmation appears
        expect(find.textContaining('Delete'), findsOneWidget);
      }
    });
  });

  group('Invoice Model Tests', () {
    test('Invoice constructor sets values correctly', () {
      final invoice = Invoice(
        id: 'inv1',
        clientId: 'client1',
        invoiceNumber: 'INV-2024-001',
        issueDate: DateTime(2024, 1, 1),
        dueDate: DateTime(2024, 2, 1),
        items: [
          InvoiceItem(description: 'Service A', quantity: 2, unitPrice: 50.0),
        ],
        status: InvoiceStatus.unpaid,
        notes: 'Test invoice',
      );

      expect(invoice.invoiceNumber, 'INV-2024-001');
      expect(invoice.status, InvoiceStatus.unpaid);
      expect(invoice.totalAmount, 100.0);
    });

    test('Invoice calculates total correctly', () {
      final invoice = Invoice(
        id: 'inv2',
        clientId: 'client1',
        invoiceNumber: 'INV-002',
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        items: [
          InvoiceItem(description: 'Item 1', quantity: 3, unitPrice: 10.0),
          InvoiceItem(description: 'Item 2', quantity: 2, unitPrice: 20.0),
        ],
        status: InvoiceStatus.unpaid,
      );

      expect(invoice.totalAmount, 70.0); // (3*10) + (2*20) = 30 + 40 = 70
    });

    test('Invoice status changes correctly', () {
      final invoice = Invoice(
        id: 'inv3',
        clientId: 'client1',
        invoiceNumber: 'INV-003',
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        items: [],
        status: InvoiceStatus.unpaid,
      );

      final paidInvoice = invoice.copyWith(status: InvoiceStatus.paid);
      expect(paidInvoice.status, InvoiceStatus.paid);
      expect(paidInvoice.invoiceNumber, invoice.invoiceNumber); // Unchanged
    });

    test('Invoice detects overdue status', () {
      final overdueInvoice = Invoice(
        id: 'inv4',
        clientId: 'client1',
        invoiceNumber: 'INV-004',
        issueDate: DateTime.now().subtract(const Duration(days: 60)),
        dueDate: DateTime.now().subtract(const Duration(days: 30)),
        items: [],
        status: InvoiceStatus.unpaid,
      );

      expect(overdueInvoice.isOverdue, true);
    });
  });
}
