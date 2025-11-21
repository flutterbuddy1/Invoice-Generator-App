import 'package:hive/hive.dart';
import 'invoice_item.dart';

part 'invoice.g.dart';

@HiveType(typeId: 1)
class Invoice extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String invoiceNumber;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  String clientName;

  @HiveField(5)
  String clientAddress;

  @HiveField(6)
  List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.clientName,
    required this.clientAddress,
    required this.items,
  });

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.total);
  }
}
