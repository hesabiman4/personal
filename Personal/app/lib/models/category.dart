/// Category model for income and expense categorization
class Category {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String iconKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Category from database map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      iconKey: map['icon_key'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Category to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon_key': iconKey,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? iconKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
