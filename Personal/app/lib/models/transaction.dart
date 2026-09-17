/// Transaction model representing income or expense records
class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final int amountMinor;
  final String accountId;
  final String categoryId;
  final DateTime occurredOn;
  final String occurredTime; // Stored as HH:mm string
  final String? note;
  final String? clientId;
  final String? receivableId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.accountId,
    required this.categoryId,
    required this.occurredOn,
    required this.occurredTime,
    this.note,
    this.clientId,
    this.receivableId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Transaction from database map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      type: map['type'] as String,
      amountMinor: map['amount_minor'] as int,
      accountId: map['account_id'] as String,
      categoryId: map['category_id'] as String,
      occurredOn: DateTime.parse(map['occurred_on'] as String),
      occurredTime: map['occurred_time'] as String,
      note: map['note'] as String?,
      clientId: map['client_id'] as String?,
      receivableId: map['receivable_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Transaction to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount_minor': amountMinor,
      'account_id': accountId,
      'category_id': categoryId,
      'occurred_on': occurredOn.toIso8601String(),
      'occurred_time': occurredTime,
      'note': note,
      'client_id': clientId,
      'receivable_id': receivableId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? type,
    int? amountMinor,
    String? accountId,
    String? categoryId,
    DateTime? occurredOn,
    String? occurredTime,
    String? note,
    String? clientId,
    String? receivableId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amountMinor: amountMinor ?? this.amountMinor,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      occurredOn: occurredOn ?? this.occurredOn,
      occurredTime: occurredTime ?? this.occurredTime,
      note: note ?? this.note,
      clientId: clientId ?? this.clientId,
      receivableId: receivableId ?? this.receivableId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get signed amount (positive for income, negative for expense)
  int get signedAmount => type == 'income' ? amountMinor : -amountMinor;

  /// Check if transaction is linked to a receivable (invoice payment)
  bool get isInvoicePayment => receivableId != null;

  /// Check if transaction is linked to a client
  bool get hasClient => clientId != null;
}

/// Transaction with related data for display
class TransactionWithDetails {
  final Transaction transaction;
  final String accountName;
  final String categoryName;
  final String categoryIconKey;
  final String? clientName;
  final String currencyCode;

  TransactionWithDetails({
    required this.transaction,
    required this.accountName,
    required this.categoryName,
    required this.categoryIconKey,
    this.clientName,
    required this.currencyCode,
  });

  /// Get formatted amount with currency and sign
  String get formattedAmount {
    final amount = transaction.amountMinor / 100.0;
    final symbol = _getCurrencySymbol();
    final sign = transaction.type == 'income' ? '+' : '-';
    return '$sign$symbol${amount.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol() {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'AFN':
        return '؋';
      case 'EUR':
        return '€';
      default:
        return '';
    }
  }
}
