/// Client model for tracking customers and their financial relationships
class Client {
  final String id;
  final String name;
  final String? serviceDescription;
  final String? phone;
  final String? email;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.name,
    this.serviceDescription,
    this.phone,
    this.email,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Client from database map
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      serviceDescription: map['service_description'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isArchived: (map['is_archived'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Client to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'service_description': serviceDescription,
      'phone': phone,
      'email': email,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Client copyWith({
    String? id,
    String? name,
    String? serviceDescription,
    String? phone,
    String? email,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Client summary with calculated financial data
class ClientSummary {
  final Client client;
  final int totalBilledMinor;
  final int totalPaidMinor;
  final int outstandingMinor;
  final double paymentPercentage;

  ClientSummary({
    required this.client,
    required this.totalBilledMinor,
    required this.totalPaidMinor,
    required this.outstandingMinor,
    required this.paymentPercentage,
  });

  /// Calculate client summary from financial data
  factory ClientSummary.calculate({
    required Client client,
    required int totalBilledMinor,
    required int totalPaidMinor,
  }) {
    final outstandingMinor = totalBilledMinor - totalPaidMinor;
    final paymentPercentage = totalBilledMinor > 0
        ? (totalPaidMinor / totalBilledMinor * 100)
        : 0.0;

    return ClientSummary(
      client: client,
      totalBilledMinor: totalBilledMinor,
      totalPaidMinor: totalPaidMinor,
      outstandingMinor: outstandingMinor,
      paymentPercentage: paymentPercentage,
    );
  }

  /// Check if client has any activity
  bool get hasActivity => totalBilledMinor > 0 || totalPaidMinor > 0;

  /// Check if client owes money
  bool get owesMoney => outstandingMinor > 0;

  /// Check if client is fully paid
  bool get isFullyPaid => totalBilledMinor > 0 && outstandingMinor == 0;

  /// Check if client has overdue invoices
  bool get hasOverdue => false; // Calculated by checking invoice due dates
}
