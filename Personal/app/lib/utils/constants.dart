/// Application-wide constants
class AppConstants {
  static const String appName = 'Personal Income Tracker';
  static const String appVersion = '1.0.0';
  
  // Database
  static const int databaseVersion = 1;
  static const String databaseName = 'personal_tracker.db';
  
  // Currencies
  static const String defaultCurrency = 'USD';
  static const List<String> supportedCurrencies = ['USD', 'AFN', 'EUR'];
  
  // Account types
  static const String accountTypeCash = 'cash';
  static const String accountTypeCard = 'card';
  static const String accountTypeBank = 'bank';
  
  // Transaction types
  static const String transactionTypeIncome = 'income';
  static const String transactionTypeExpense = 'expense';
  
  // Category types
  static const String categoryTypeIncome = 'income';
  static const String categoryTypeExpense = 'expense';
  
  // Default accounts
  static const List<Map<String, dynamic>> defaultAccounts = [
    {'name': 'Cash', 'kind': accountTypeCash, 'opening_balance_minor': 0},
    {'name': 'Card', 'kind': accountTypeCard, 'opening_balance_minor': 0},
    {'name': 'Bank Account', 'kind': accountTypeBank, 'opening_balance_minor': 0},
  ];
  
  // Default categories
  static const List<Map<String, dynamic>> defaultIncomeCategories = [
    {'name': 'Salary', 'icon_key': 'work'},
    {'name': 'Freelance', 'icon_key': 'laptop'},
    {'name': 'Investment', 'icon_key': 'trending_up'},
    {'name': 'Gift', 'icon_key': 'card_giftcard'},
    {'name': 'Other Income', 'icon_key': 'add_circle'},
  ];
  
  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {'name': 'Food', 'icon_key': 'restaurant'},
    {'name': 'Transport', 'icon_key': 'directions_car'},
    {'name': 'Shopping', 'icon_key': 'shopping_bag'},
    {'name': 'Bills & Utilities', 'icon_key': 'receipt'},
    {'name': 'Entertainment', 'icon_key': 'movie'},
    {'name': 'Health', 'icon_key': 'local_hospital'},
    {'name': 'Education', 'icon_key': 'school'},
    {'name': 'Other Expense', 'icon_key': 'remove_circle'},
  ];
  
  // Date formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Report periods
  static const List<String> reportPeriods = ['7D', '30D', '3M', '6M', '1Y'];
  
  // Client filters
  static const String clientFilterAll = 'all';
  static const String clientFilterOwesYou = 'owes_you';
  static const String clientFilterPaid = 'paid';
  static const String clientFilterOverdue = 'overdue';
}

/// Enum for transaction types
enum TransactionType { income, expense }

extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income:
        return AppConstants.transactionTypeIncome;
      case TransactionType.expense:
        return AppConstants.transactionTypeExpense;
    }
  }
  
  static TransactionType fromString(String value) {
    if (value == AppConstants.transactionTypeIncome) {
      return TransactionType.income;
    } else if (value == AppConstants.transactionTypeExpense) {
      return TransactionType.expense;
    }
    throw ArgumentError('Invalid transaction type: $value');
  }
}

/// Theme configurations
class AppThemes {
  // Primary colors based on mockups (teal/navy)
  static const Color primaryColor = Color(0xFF00897B);
  static const Color primaryDark = Color(0xFF005B4F);
  static const Color accentColor = Color(0xFF00BCD4);
  
  // Income/Expense colors
  static const Color incomeColor = Color(0xFF4CAF50);
  static const Color expenseColor = Color(0xFFF44336);
  
  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
  
  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[800],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
