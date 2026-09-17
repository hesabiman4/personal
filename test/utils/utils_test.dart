import 'package:flutter_test/flutter_test.dart';
import 'package:income_expense_tracker/utils/formatters.dart';
import 'package:income_expense_tracker/utils/validators.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Format amount with default currency', () {
      expect(CurrencyFormatter.format(100), '\$100.00');
      expect(CurrencyFormatter.format(50.5), '\$50.50');
      expect(CurrencyFormatter.format(1000), '\$1,000.00');
      expect(CurrencyFormatter.format(0), '\$0.00');
    });

    test('Format negative amounts', () {
      expect(CurrencyFormatter.format(-100), '-\$100.00');
      expect(CurrencyFormatter.format(-50.75), '-\$50.75');
    });

    test('Format with custom currency symbol', () {
      expect(CurrencyFormatter.format(100, symbol: '€'), '€100.00');
      expect(CurrencyFormatter.format(500, symbol: '£'), '£500.00');
    });

    test('Format large numbers', () {
      expect(CurrencyFormatter.format(1000000), '\$1,000,000.00');
      expect(CurrencyFormatter.format(9999999.99), '\$9,999,999.99');
    });
  });

  group('DateFormatter Tests', () {
    test('Format date to short format', () {
      final date = DateTime(2024, 1, 15);
      expect(DateFormatter.toShort(date), contains('2024'));
    });

    test('Format date to long format', () {
      final date = DateTime(2024, 1, 15, 10, 30);
      expect(DateFormatter.toLong(date), contains('January'));
      expect(DateFormatter.toLong(date), contains('2024'));
    });

    test('Format date to time only', () {
      final date = DateTime(2024, 1, 15, 14, 45, 30);
      expect(DateFormatter.toTime(date), contains('14:45'));
    });

    test('Format relative date (today)', () {
      final now = DateTime.now();
      expect(DateFormatter.toRelative(now), contains('Today') || contains('Just now'));
    });

    test('Format relative date (yesterday)', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.toRelative(yesterday), contains('Yesterday'));
    });
  });

  group('InputValidator Tests', () {
    test('Validate positive amount', () {
      expect(InputValidator.validateAmount('100'), isNull);
      expect(InputValidator.validateAmount('50.50'), isNull);
      expect(InputValidator.validateAmount('0.01'), isNull);
    });

    test('Reject negative amount', () {
      expect(InputValidator.validateAmount('-100'), isNotNull);
      expect(InputValidator.validateAmount('-50.50'), isNotNull);
    });

    test('Reject non-numeric input', () {
      expect(InputValidator.validateAmount('abc'), isNotNull);
      expect(InputValidator.validateAmount('100abc'), isNotNull);
      expect(InputValidator.validateAmount(''), isNotNull);
    });

    test('Reject too many decimal places', () {
      expect(InputValidator.validateAmount('100.123'), isNotNull);
      expect(InputValidator.validateAmount('50.9999'), isNotNull);
    });

    test('Validate required field', () {
      expect(InputValidator.validateRequired('test'), isNull);
      expect(InputValidator.validateRequired('   '), isNotNull);
      expect(InputValidator.validateRequired(''), isNotNull);
    });

    test('Validate email format', () {
      expect(InputValidator.validateEmail('test@example.com'), isNull);
      expect(InputValidator.validateEmail('user.name@domain.org'), isNull);
      
      expect(InputValidator.validateEmail('invalid'), isNotNull);
      expect(InputValidator.validateEmail('no@domain'), isNotNull);
      expect(InputValidator.validateEmail('@nodomain.com'), isNotNull);
    });

    test('Validate phone number', () {
      expect(InputValidator.validatePhone('+1234567890'), isNull);
      expect(InputValidator.validatePhone('123-456-7890'), isNull);
      
      expect(InputValidator.validatePhone('123'), isNotNull); // Too short
      expect(InputValidator.validatePhone('abcdefghij'), isNotNull);
    });
  });

  group('NumberFormatter Tests', () {
    test('Format percentage', () {
      expect(NumberFormatter.toPercentage(0.5), '50.0%');
      expect(NumberFormatter.toPercentage(0.75), '75.0%');
      expect(NumberFormatter.toPercentage(1.0), '100.0%');
      expect(NumberFormatter.toPercentage(0.1234), '12.3%');
    });

    test('Format compact numbers', () {
      expect(NumberFormatter.toCompact(1000), '1K');
      expect(NumberFormatter.toCompact(1500), '1.5K');
      expect(NumberFormatter.toCompact(1000000), '1M');
      expect(NumberFormatter.toCompact(500), '500');
    });
  });
}
