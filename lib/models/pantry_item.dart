import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  final String id;
  final String userId;
  final String name;
  final String quantity; // Ex: "2kg"
  final double numericValue; // Ex: 2000.0
  final String unit; // Ex: "g"
  final String category;
  final double reservedValue;
  final DateTime createdAt;
  final DateTime? expiryDate;

  PantryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.numericValue,
    required this.unit,
    required this.category,
    required this.reservedValue,
    required this.createdAt,
    this.expiryDate,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return PantryItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      numericValue: (json['numeric_value'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
      category: json['category'] ?? 'Mercearia',
      reservedValue: (json['reserved_value'] ?? 0.0).toDouble(),
      createdAt: parseDate(json['created_at']),
      expiryDate: json['expiry_date'] != null ? parseDate(json['expiry_date']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'quantity': quantity,
    'numeric_value': numericValue,
    'unit': unit,
    'category': category,
    'reserved_value': reservedValue,
    'expiry_date': expiryDate?.toIso8601String().split('T')[0],
  };
}
