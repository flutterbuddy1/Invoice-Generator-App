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

  @HiveField(13)
  String clientPhone;

  @HiveField(14)
  String clientEmail;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.clientName,
    required this.clientAddress,
    required this.items,
    this.clientPhone = '',
    this.clientEmail = '',
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

  // JSON serialization for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'clientName': clientName,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'customerGSTIN': customerGSTIN,
      'isIGST': isIGST,
      'transportMode': transportMode,
      'vehicleNumber': vehicleNumber,
      'termsOfPayment': termsOfPayment,
      'termsOfDelivery': termsOfDelivery,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      clientName: json['clientName'] as String,
      clientAddress: json['clientAddress'] as String,
      clientPhone: json['clientPhone'] as String? ?? '',
      clientEmail: json['clientEmail'] as String? ?? '',
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      customerGSTIN: json['customerGSTIN'] as String? ?? '',
      isIGST: json['isIGST'] as bool? ?? false,
      transportMode: json['transportMode'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      termsOfPayment: json['termsOfPayment'] as String? ?? '',
      termsOfDelivery: json['termsOfDelivery'] as String? ?? '',
    );
  }
}
