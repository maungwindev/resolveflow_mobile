import 'package:equatable/equatable.dart';

/// Immutable deduction log stored in Appwrite Parts Ledger (`work_order_parts`).
class WorkOrderPart extends Equatable {
  const WorkOrderPart({
    required this.id,
    required this.workOrderId,
    required this.sku,
    required this.partName,
    this.quantityDeducted = 1,
    required this.timestamp,
  });

  final String id;
  final String workOrderId;
  final String sku;
  final String partName;
  final int quantityDeducted;
  final DateTime timestamp;

  factory WorkOrderPart.fromJson(Map<String, dynamic> json) {
    final id = json['\$id']?.toString() ?? json['id']?.toString() ?? '';
    final workOrderId = json['work_order_id']?.toString() ?? '';
    final sku = json['sku']?.toString() ?? '';
    final partName = json['part_name']?.toString() ?? '';
    final qRaw = json['quantity_deducted'];
    final quantityDeducted = qRaw is num ? qRaw.toInt() : 1;

    DateTime parsedDate;
    final dateRaw = json['timestamp'] ?? json['\$createdAt'];
    if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return WorkOrderPart(
      id: id,
      workOrderId: workOrderId,
      sku: sku,
      partName: partName,
      quantityDeducted: quantityDeducted,
      timestamp: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'work_order_id': workOrderId,
        'sku': sku,
        'part_name': partName,
        'quantity_deducted': quantityDeducted,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        workOrderId,
        sku,
        partName,
        quantityDeducted,
        timestamp,
      ];
}

