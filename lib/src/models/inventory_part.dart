import 'package:equatable/equatable.dart';

/// Inventory item stored in Appwrite Inventory Catalog (`parts_inventory`).
class InventoryPart extends Equatable {
  const InventoryPart({
    required this.id,
    required this.sku,
    required this.name,
    required this.quantityOnHand,
    this.minThreshold = 2,
    this.unitPrice = 0.0,
    this.location = '',
  });

  final String id;
  final String sku;
  final String name;
  final int quantityOnHand;
  final int minThreshold;
  final double unitPrice;
  final String location;

  /// True if stock is completely depleted.
  bool get isOutOfStock => quantityOnHand <= 0;

  /// True if stock is equal or below minimum reorder threshold.
  bool get isLowStock => !isOutOfStock && quantityOnHand <= minThreshold;

  /// True if stock is healthy.
  bool get isHealthyStock => quantityOnHand > minThreshold;

  factory InventoryPart.fromJson(Map<String, dynamic> json) {
    final id = json['\$id']?.toString() ?? json['id']?.toString() ?? '';
    final sku = json['sku']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final qRaw = json['quantity_on_hand'] ?? json['quantity'];
    final quantityOnHand = qRaw is num ? qRaw.toInt() : 0;
    final minRaw = json['min_threshold'] ?? json['min_stock'];
    final minThreshold = minRaw is num ? minRaw.toInt() : 2;
    final pRaw = json['unit_price'];
    final unitPrice = pRaw is num ? pRaw.toDouble() : 0.0;
    final location = json['location']?.toString() ?? '';

    return InventoryPart(
      id: id,
      sku: sku,
      name: name,
      quantityOnHand: quantityOnHand,
      minThreshold: minThreshold,
      unitPrice: unitPrice,
      location: location,
    );
  }

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'name': name,
        'quantity_on_hand': quantityOnHand,
        'min_threshold': minThreshold,
        'unit_price': unitPrice,
        'location': location,
      };

  InventoryPart copyWith({
    String? id,
    String? sku,
    String? name,
    int? quantityOnHand,
    int? minThreshold,
    double? unitPrice,
    String? location,
  }) {
    return InventoryPart(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      minThreshold: minThreshold ?? this.minThreshold,
      unitPrice: unitPrice ?? this.unitPrice,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sku,
        name,
        quantityOnHand,
        minThreshold,
        unitPrice,
        location,
      ];
}

