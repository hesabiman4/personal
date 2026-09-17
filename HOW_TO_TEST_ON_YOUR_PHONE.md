# 📱 How to Test the Personal Income/Expense Tracker

Since the project files are in the cloud workspace and your physical phone is connected to your **local machine**, follow these steps:

## Option 1: Copy Files to Local Machine (Recommended)

### Step 1: Download Project Files
Copy the entire `/workspace` directory from the cloud to your local machine:
```bash
# On your local machine, use SCP, rsync, or your cloud provider's download feature
# Example with SCP:
scp -r user@cloud-server:/workspace ~/PersonalFinanceTracker
```

Or download as a ZIP archive if your cloud IDE supports it.

### Step 2: Install Flutter (if not already installed)
Follow the official guide: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### Step 3: Run the Testing Script
Navigate to the project and run:
```bash
cd ~/PersonalFinanceTracker
chmod +x RUN_TESTS_LOCALLY.sh
./RUN_TESTS_LOCALLY.sh
```

This script will:
- ✅ Get dependencies
- ✅ Check for your connected phone
- ✅ Run static analysis
- ✅ Execute all unit/widget tests
- ✅ Build and install on your device (optional)

---

## Option 2: Manual Testing Steps

If you prefer manual control:

### 1. Copy Project Files
Ensure `Personal/app` directory is on your local machine.

### 2. Navigate and Setup
```bash
cd Personal/app
flutter clean
flutter pub get
```

### 3. Verify Device Connection
```bash
flutter devices
```
You should see your physical phone listed.

### 4. Run Tests (Optional but Recommended)
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test files
flutter test test/models/transaction_test.dart
flutter test test/services/database_service_test.dart
```

### 5. Static Analysis
```bash
flutter analyze
```

### 6. Run on Device
```bash
# Debug mode (with hot reload)
flutter run

# Or build release APK
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Manual Testing Checklist

After installing on your phone, test these flows:

### Core Features
- [ ] Add income transaction
- [ ] Add expense transaction
- [ ] View transactions list
- [ ] Filter transactions by type/date/category
- [ ] Edit a transaction
- [ ] Delete a transaction

### Client & Invoice Management
- [ ] Add new client
- [ ] Create invoice for client
- [ ] Mark invoice as paid
- [ ] View client details with invoice history
- [ ] Search clients

### Budgets & Reports
- [ ] Set budget for a category
- [ ] View budget progress in Reports
- [ ] Check income/expense breakdown
- [ ] Change report period (Week/Month/Year)

### Settings & Export
- [ ] Change app theme
- [ ] Export data to CSV
- [ ] Backup database
- [ ] Restore from backup

---

## 📊 Test Coverage Report

After running `flutter test --coverage`, view the report:

**Text Format:**
```bash
cat coverage/lcov.info | grep -E "^(SF|DA):" | head -50
```

**HTML Format** (requires lcov):
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

---

## 🐛 Troubleshooting

### "No devices found"
- Enable USB debugging on your phone
- Accept the RSA key prompt on your phone
- Try `adb devices` to verify connection
- Restart adb: `adb kill-server && adb start-server`

### "Flutter not found"
- Add Flutter to your PATH
- Restart terminal after installation

### Build fails
- Run `flutter clean` and `flutter pub get`
- Check Android SDK setup: `flutter doctor --android-licenses`

### Tests fail
- Review error messages in terminal
- Check if mocks need updating
- Ensure database is properly initialized in tests

---

## 📞 Need Help?

Refer to these documentation files:
- `TESTING_GUIDE.md` - Detailed testing procedures
- `QUICK_START_TESTING.md` - Fast reference
- `TEST_SUMMARY.md` - What's tested and what's not

Happy Testing! 🎉
