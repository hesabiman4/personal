/// Input validation utilities
class Validators {
  /// Validate that amount is positive and not zero
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
    
    if (cleaned.isEmpty || cleaned == '-') {
      return 'Please enter a valid amount';
    }
    
    try {
      final amount = double.parse(cleaned);
      if (amount <= 0) {
        return 'Amount must be greater than zero';
      }
      
      // Check decimal places (max 2 for currency)
      if (cleaned.contains('.')) {
        final decimalPart = cleaned.split('.')[1];
        if (decimalPart.length > 2) {
          return 'Maximum 2 decimal places allowed';
        }
      }
      
      return null;
    } catch (e) {
      return 'Invalid amount format';
    }
  }
  
  /// Validate required text field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Validate email (optional field)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate phone number (optional field)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    // Basic phone validation - allows digits, spaces, dashes, plus, parentheses
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  /// Validate date is not in the future (for transactions)
  static String? validateDateNotFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isAfter(today)) {
      return 'Date cannot be in the future';
    }
    
    return null;
  }
  
  /// Validate invoice amount is greater than payments received
  static String? validateInvoiceAmount(
    int amountMinor,
    int paymentsReceivedMinor,
  ) {
    if (amountMinor <= paymentsReceivedMinor) {
      return 'Invoice amount must be greater than payments already received';
    }
    return null;
  }
}
