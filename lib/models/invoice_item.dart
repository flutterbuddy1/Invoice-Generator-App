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

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.gstRate = 0.0,
  });

  double get total => (quantity * unitPrice) * (1 + gstRate / 100);
}
