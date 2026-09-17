# Quick Start Testing Guide

Since Flutter CLI is not available in this environment, here are your options to run the tests:

## Option 1: Local Development (Recommended)

### Prerequisites
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Ensure Flutter is in your PATH
3. Run `flutter doctor` to verify installation

### Steps
```bash
# Navigate to project
cd /workspace

# Get dependencies
flutter pub get

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

## Option 2: Android Studio / VS Code

### Android Studio
1. Open project in Android Studio
2. Right-click on `test/` folder
3. Select "Run 'Tests in ...'"

### VS Code
1. Open project in VS Code
2. Install Flutter extension
3. Press `Ctrl+Shift+P` → "Flutter: Run Tests"
4. Or click "Run Test" above test functions

## Option 3: CI/CD Pipeline

### GitHub Actions
Create `.github/workflows/test.yml`:
```yaml
name: Flutter Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze
```

## Test Files Created

### Unit Tests
- ✅ `test/models/model_test.dart` - Transaction, Account, Category models
- ✅ `test/services/database_service_test.dart` - CRUD operations, queries
- ✅ `test/utils/utils_test.dart` - Formatters, validators

### Widget Tests
- ✅ `test/widgets/screens_test.dart` - Transaction form, lists, reports

### Integration Tests
- ✅ `test/integration/invoice_test.dart` - Complete invoice workflow

## What Each Test Suite Covers

### Model Tests (15+ tests)
- Constructor validation
- JSON serialization/deserialization
- copyWith functionality
- Amount validation (negative rejection)
- Type safety

### Database Tests (20+ tests)
- Create/Read/Update/Delete for all entities
- Filtering by type/category/date
- Aggregation queries
- Period calculations
- Default data verification

### Utility Tests (20+ tests)
- Currency formatting (multiple symbols)
- Date formatting (short, long, relative)
- Input validation (amount, email, phone)
- Percentage calculations
- Number compacting

### Widget Tests (15+ tests)
- UI component rendering
- User interactions (tap, enter text)
- State changes
- Empty states
- Filter functionality
- Swipe actions

### Integration Tests (10+ tests)
- End-to-end invoice creation
- Client-invoice relationships
- Payment workflows
- Multi-step processes
- Data persistence across screens

## Expected Test Results

When running `flutter test`, you should see:
```
✓ All tests passed!
XX tests, YY assertions, ZZ.Zs
```

If tests fail:
1. Check error messages for specific failures
2. Verify async operations use `await`
3. Ensure `pumpAndSettle()` after state changes
4. Check widget finders match actual text/keys

## Manual Testing Alternative

If automated tests aren't running, follow the manual checklist in `TESTING_GUIDE.md`:

### Quick Manual Test Flow
1. **Launch app** → Verify home screen loads
2. **Add transaction** → Tap + → Enter amount → Save
3. **View list** → Verify transaction appears
4. **Edit transaction** → Swipe right → Modify → Save
5. **Delete transaction** → Swipe left → Confirm delete
6. **Filter** → Tap filter icon → Select type → Apply
7. **Reports** → Navigate to Reports → Verify totals
8. **Clients** → Add client → Create invoice → Mark paid
9. **Settings** → Change currency → Verify update

## Troubleshooting

### "Package not found" errors
```bash
flutter pub get
flutter clean
flutter pub get
```

### "Test failed to load" errors
- Check import paths are correct
- Verify file names match test descriptions
- Ensure all dependencies are in pubspec.yaml

### Slow test execution
- Run specific test files instead of all
- Use `--concurrency=1` for database tests
- Mock expensive operations

## Next Steps After Testing

1. ✅ Review test results
2. ✅ Fix any failing tests
3. ✅ Add edge case tests
4. ✅ Increase code coverage
5. ✅ Set up CI/CD
6. ✅ Document test scenarios
7. ✅ Performance benchmarking

## Coverage Goals

Aim for:
- Models: 90%+ coverage
- Services: 80%+ coverage
- Utilities: 95%+ coverage
- Widgets: 70%+ coverage
- Integration: Critical paths only

## Questions?

Refer to:
- `TESTING_GUIDE.md` - Comprehensive testing documentation
- `IMPLEMENTATION_PROGRESS.md` - Feature completion status
- Flutter testing docs: https://docs.flutter.dev/testing
