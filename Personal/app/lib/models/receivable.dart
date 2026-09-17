/// Receivable model representing an invoice or money owed by a client
class Receivable {
  final String id;
  final String clientId;
  final String reference; // Invoice number or reference
  final String description;
  final int amountMinor;
  final DateTime issuedOn;
  final DateTime? dueOn;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receivable({
    required this.id,
    required this.clientId,
    required this.reference,
    required this.description,
    required this.amountMinor,
    required this.issuedOn,
    this.dueOn,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Receivable from database map
  factory Receivable.fromMap(Map<String, dynamic> map) {
    return Receivable(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      reference: map['reference'] as String,
      description: map['description'] as String,
      amountMinor: map['amount_minor'] as int,
      issuedOn: DateTime.parse(map['issued_on'] as String),
      dueOn: map['due_on'] != null ? DateTime.parse(map['due_on'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Receivable to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'reference': reference,
      'description': description,
      'amount_minor': amountMinor,
      'issued_on': issuedOn.toIso8601String(),
      'due_on': dueOn?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Receivable copyWith({
    String? id,
    String? clientId,
    String? reference,
    String? description,
    int? amountMinor,
    DateTime? issuedOn,
    DateTime? dueOn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receivable(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      amountMinor: amountMinor ?? this.amountMinor,
      issuedOn: issuedOn ?? this.issuedOn,
      dueOn: dueOn ?? this.dueOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if invoice is overdue
  bool get isOverdue {
    if (dueOn == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueOn!.isBefore(today);
  }

  /// Check if due today
  bool get isDueToday {
    if (dueOn == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(dueOn!.year, dueOn!.month, dueOn!.day);
    return dueDate.isAtSameMomentAs(today);
  }
  
  /// Get amount due in minor units (outstanding balance)
  int get amountDueMinor => amountMinor; // This should be calculated with payments
  
  /// Get total amount in minor units (alias for amountMinor)
  int get amountTotalMinor => amountMinor;
}

/// Receivable summary with payment status
class ReceivableSummary {
  final Receivable receivable;
  final int totalPaidMinor;
  final int outstandingMinor;
  final double paymentPercentage;

  ReceivableSummary({
    required this.receivable,
    required this.totalPaidMinor,
    required this.outstandingMinor,
    required this.paymentPercentage,
  });

  /// Calculate receivable summary from payment data
  factory ReceivableSummary.calculate({
    required Receivable receivable,
    required int totalPaidMinor,
  }) {
    final outstandingMinor = receivable.amountMinor - totalPaidMinor;
    final paymentPercentage = receivable.amountMinor > 0
        ? (totalPaidMinor / receivable.amountMinor * 100)
        : 0.0;

    return ReceivableSummary(
      receivable: receivable,
      totalPaidMinor: totalPaidMinor,
      outstandingMinor: outstandingMinor,
      paymentPercentage: paymentPercentage,
    );
  }

  /// Check if fully paid
  bool get isFullyPaid => outstandingMinor == 0;

  /// Check if partially paid
  bool get isPartiallyPaid => totalPaidMinor > 0 && outstandingMinor > 0;

  /// Check if unpaid
  bool get isUnpaid => totalPaidMinor == 0;
}
