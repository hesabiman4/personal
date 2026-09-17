# Testing Guide for Personal Income/Expense Tracker

## Overview
This document provides comprehensive instructions on how to test the implemented features of the Personal Income/Expense Tracker Flutter application.

## Test Structure

```
test/
├── models/              # Unit tests for data models
│   └── model_test.dart
├── services/            # Unit tests for business logic
│   └── database_service_test.dart
├── utils/               # Unit tests for utility functions
│   └── utils_test.dart
├── widgets/             # Widget tests for UI components
│   └── screens_test.dart
└── integration/         # Integration tests for full workflows
    └── invoice_test.dart
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
# Models
flutter test test/models/model_test.dart

# Database Service
flutter test test/services/database_service_test.dart

# Utilities
flutter test test/utils/utils_test.dart

# Widget Tests
flutter test test/widgets/screens_test.dart

# Integration Tests
flutter test test/integration/invoice_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Tests in Debug Mode
```bash
flutter test --debug
```

### Run Specific Test by Name
```bash
flutter test --name "Transaction"
flutter test --name "Invoice"
flutter test --name "validation"
```

## Test Categories

### 1. Model Tests (`test/models/model_test.dart`)
**What it tests:**
- Transaction model creation, serialization, and validation
- Account model operations
- Category model operations

**Key test cases:**
- Constructor parameter validation
- JSON serialization/deserialization
- copyWith functionality
- Negative amount rejection

### 2. Database Service Tests (`test/services/database_service_test.dart`)
**What it tests:**
- CRUD operations for accounts, transactions, and categories
- Data aggregation queries
- Period-based calculations

**Key test cases:**
- Create/Read/Update/Delete operations
- Filtering by type
- Total calculations for periods
- Default data seeding

### 3. Utility Tests (`test/utils/utils_test.dart`)
**What it tests:**
- Currency formatting
- Date formatting
- Input validation
- Number formatting

**Key test cases:**
- Currency symbol handling
- Negative number formatting
- Email/phone validation
- Percentage calculations

### 4. Widget Tests (`test/widgets/screens_test.dart`)
**What it tests:**
- Transaction form UI
- Transactions list display
- Reports screen rendering
- User interactions

**Key test cases:**
- Field presence verification
- Input acceptance
- Empty states
- Filter functionality
- Swipe actions

### 5. Integration Tests (`test/integration/invoice_test.dart`)
**What it tests:**
- Complete invoice workflow
- Client-invoice relationships
- Payment status changes
- Multi-step user flows

**Key test cases:**
- Invoice creation with line items
- Automatic total calculation
- Status filtering
- Mark as paid workflow
- Delete confirmation

## Manual Testing Checklist

### Core Features
- [ ] Add income transaction
- [ ] Add expense transaction
- [ ] Edit existing transaction
- [ ] Delete transaction (swipe)
- [ ] Filter transactions by type/date/category
- [ ] View transaction details

### Accounts
- [ ] Create new account
- [ ] Edit account balance
- [ ] Delete account
- [ ] Switch between accounts

### Categories
- [ ] View expense categories
- [ ] View income categories
- [ ] Category icons display correctly

### Clients
- [ ] Add new client
- [ ] Edit client information
- [ ] Archive client
- [ ] View client details

### Invoices
- [ ] Create invoice with multiple items
- [ ] Auto-calculate invoice total
- [ ] Mark invoice as paid/unpaid
- [ ] Filter invoices by status
- [ ] Delete invoice
- [ ] Convert invoice to transaction

### Reports
- [ ] View income/expense summary
- [ ] Change period (Week/Month/Year)
- [ ] Category breakdown percentages
- [ ] Budget progress indicators

### Settings
- [ ] Change currency symbol
- [ ] Export data to CSV
- [ ] Backup database
- [ ] Restore from backup

## Performance Testing

### Load Testing
Test with large datasets:
```dart
// Add 1000 transactions
for (int i = 0; i < 1000; i++) {
  await financeProvider.addTransaction(
    amount: 100.0,
    type: TransactionType.expense,
    accountId: 'acc_cash',
    categoryId: 'cat_food',
    date: DateTime.now().subtract(Duration(days: i)),
  );
}
```

**Metrics to check:**
- App launch time (< 3 seconds)
- List scroll performance (60 FPS)
- Search response time (< 500ms)
- Database query time (< 1 second)

## Edge Cases to Test

### Input Validation
- [ ] Very large amounts (999,999,999.99)
- [ ] Zero amounts (should be rejected)
- [ ] Negative amounts (should be rejected)
- [ ] Special characters in notes
- [ ] Empty required fields
- [ ] Future dates
- [ ] Dates far in the past

### Network/Storage
- [ ] No storage space
- [ ] Database corruption recovery
- [ ] Concurrent modifications
- [ ] App restart with data intact

### UI/UX
- [ ] Small screen devices
- [ ] Large screen devices
- [ ] Landscape orientation
- [ ] Dark mode (if implemented)
- [ ] Font scaling (accessibility)

## Continuous Integration

### GitHub Actions Example
Create `.github/workflows/test.yml`:
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze
```

## Troubleshooting

### Common Issues

**Test fails with "Null check operator used on a null value"**
- Check if async operations are properly awaited
- Ensure pumpAndSettle() is called after state changes

**Widget not found error**
- Verify widget keys or text match exactly
- Check if widget is rendered conditionally

**Database locked error**
- Ensure proper tearDown() cleanup
- Close database connections in tests

**Timeout errors**
- Increase timeout: `testWidgets('name', tester, timeout: Timeout.none)`
- Optimize async operations

## Best Practices

1. **Test Independence**: Each test should run independently
2. **Mock External Dependencies**: Use mock objects for APIs, file system
3. **Descriptive Names**: Test names should describe expected behavior
4. **Arrange-Act-Assert**: Follow AAA pattern in test structure
5. **Clean Up**: Always clean up test data in tearDown()
6. **Edge Cases**: Test boundary conditions and error scenarios
7. **Documentation**: Comment complex test logic

## Next Steps

1. Run all tests: `flutter test`
2. Fix any failing tests
3. Add more edge case tests
4. Implement missing integration tests
5. Set up CI/CD pipeline
6. Monitor test coverage
7. Add performance benchmarks

## Support

For issues or questions:
- Check existing test files for examples
- Review Flutter testing documentation
- Consult the IMPLEMENTATION_PROGRESS.md file
- Review specific screen implementations
