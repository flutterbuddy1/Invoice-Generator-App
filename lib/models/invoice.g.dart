// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 1;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as String,
      invoiceNumber: fields[1] as String,
      date: fields[2] as DateTime,
      dueDate: fields[3] as DateTime,
      clientName: fields[4] as String,
      clientAddress: fields[5] as String,
      items: (fields[6] as List).cast<InvoiceItem>(),
      customerGSTIN: fields[7] as String,
      isIGST: fields[8] as bool,
      transportMode: fields[9] as String,
      vehicleNumber: fields[10] as String,
      termsOfPayment: fields[11] as String,
      termsOfDelivery: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.clientName)
      ..writeByte(5)
      ..write(obj.clientAddress)
      ..writeByte(6)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.customerGSTIN)
      ..writeByte(8)
      ..write(obj.isIGST)
      ..writeByte(9)
      ..write(obj.transportMode)
      ..writeByte(10)
      ..write(obj.vehicleNumber)
      ..writeByte(11)
      ..write(obj.termsOfPayment)
      ..writeByte(12)
      ..write(obj.termsOfDelivery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
