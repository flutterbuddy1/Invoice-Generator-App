import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 2)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double unitPrice;

  @HiveField(3)
  double gstRate; // Percentage, e.g., 18.0

  @HiveField(4)
  String hsnCode;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.gstRate = 0.0,
    this.hsnCode = '',
  });

  double get total => (quantity * unitPrice) * (1 + gstRate / 100);

  // JSON serialization for export
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'gstRate': gstRate,
      'hsnCode': hsnCode,
      'total': total,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0.0,
      hsnCode: json['hsnCode'] as String? ?? '',
    );
  }
}
