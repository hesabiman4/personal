/// Account model representing a money account (cash, card, bank)
class Account {
  final String id;
  final String name;
  final String kind; // 'cash', 'card', 'bank'
  final int openingBalanceMinor;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.openingBalanceMinor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Account from database map
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: map['kind'] as String,
      openingBalanceMinor: map['opening_balance_minor'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Account to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'kind': kind,
      'opening_balance_minor': openingBalanceMinor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Account copyWith({
    String? id,
    String? name,
    String? kind,
    int? openingBalanceMinor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get current balance (opening + income - expenses)
  /// This is calculated by the database service
  int getCurrentBalance(int totalIncome, int totalExpenses) {
    return openingBalanceMinor + totalIncome - totalExpenses;
  }
}
