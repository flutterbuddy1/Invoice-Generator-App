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

  @HiveField(7)
  String customerGSTIN;

  @HiveField(8)
  bool isIGST;

  @HiveField(9)
  String transportMode;

  @HiveField(10)
  String vehicleNumber;

  @HiveField(11)
  String termsOfPayment;

  @HiveField(12)
  String termsOfDelivery;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.clientName,
    required this.clientAddress,
    required this.items,
    this.customerGSTIN = '',
    this.isIGST = false,
    this.transportMode = '',
    this.vehicleNumber = '',
    this.termsOfPayment = '',
    this.termsOfDelivery = '',
  });

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.total);
  }
}
