import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

/// Formats numbers and currency values
class Formatters {
  /// Format amount in minor units to display string with currency symbol
  static String formatCurrency(int amountMinor, String currencyCode) {
    final double amount = amountMinor / 100.0;
    
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$${formatNumber(amount)}';
      case 'AFN':
        return '؋${formatNumber(amount)}';
      case 'EUR':
        return '€${formatNumber(amount)}';
      default:
        return '${formatNumber(amount)} $currencyCode';
    }
  }
  
  /// Format a number with decimal places
  static String formatNumber(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }
  
  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }
  
  /// Format date and time for display
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }
  
  /// Format time for display
  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('h:mm a').format(dateTime);
  }
  
  /// Parse currency string to minor units
  /// Returns null if parsing fails
  static int? parseCurrency(String input) {
    // Remove any non-numeric characters except decimal point and minus
    final cleaned = input.replaceAll(RegExp(r'[^\d.-]'), '');
    
    if (cleaned.isEmpty || cleaned == '-') {
      return null;
    }
    
    try {
      final value = double.parse(cleaned);
      // Convert to minor units (cents)
      return (value * 100).round();
    } catch (e) {
      return null;
    }
  }
  
  /// Get initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }
  
  /// Format relative date (Today, Yesterday, etc.)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(dateOnly).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return formatDate(date);
    }
  }
  
  /// Convert amount in minor units to decimal string for input fields
  static String amountToDecimalString(int amountMinor) {
    final amount = amountMinor / 100.0;
    return amount.toStringAsFixed(2);
  }
  
  /// Convert decimal string to amount in minor units
  static int decimalStringToAmount(String decimalString) {
    final cleaned = decimalString.replaceAll(RegExp(r'[^\\d.-]'), '');
    if (cleaned.isEmpty || cleaned == '-') {
      return 0;
    }
    final value = double.parse(cleaned);
    return (value * 100).round();
  }
}
