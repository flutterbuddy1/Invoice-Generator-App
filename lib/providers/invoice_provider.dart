import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/invoice.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  static const String _boxName = 'invoices';

  List<Invoice> get invoices => _invoices;

  Future<void> loadInvoices() async {
    var box = await Hive.openBox<Invoice>(_boxName);
    _invoices = box.values.toList();
    // Sort by date descending
    _invoices.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addInvoice(Invoice invoice) async {
    var box = await Hive.openBox<Invoice>(_boxName);
    await box.add(invoice);
    _invoices.add(invoice);
    _invoices.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteInvoice(Invoice invoice) async {
    await invoice.delete();
    _invoices.remove(invoice);
    notifyListeners();
  }

  Future<void> updateInvoice(Invoice oldInvoice, Invoice newInvoice) async {
    // Hive objects are updated by modifying the object itself if it's already in the box.
    // However, since we are creating a new object in the UI, we might need to replace it.
    // Or better, we can just delete the old one and add the new one to keep it simple and avoid key issues,
    // OR we can update the fields of the old invoice if it extends HiveObject.
    // Given the current implementation where we pass a new Invoice object from the UI:

    // Option 1: Delete old, add new (Simple but changes ID/Key if not careful, but we use UUID for ID so it's fine)
    // Option 2: Update fields of oldInvoice (Requires copying values)

    // Let's go with Option 1 for simplicity with the current Immutable-style approach in UI
    // But wait, Hive keys are important.
    // Let's try to put the new invoice at the same key if possible, or just update the values.

    // Actually, the cleanest way with Hive is to save the new object.
    // If we want to keep the same Hive key, we should use putAt or put.

    // Let's find the index or key of the old invoice.
    var box = await Hive.openBox<Invoice>(_boxName);

    // If the old invoice is in the box, we can update it.
    if (oldInvoice.isInBox) {
      await oldInvoice.delete(); // Delete old
      await box.add(newInvoice); // Add new
    } else {
      // Fallback
      await box.add(newInvoice);
    }

    // Update local list
    final index = _invoices.indexOf(oldInvoice);
    if (index != -1) {
      _invoices[index] = newInvoice;
    } else {
      _invoices.add(newInvoice);
    }

    _invoices.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }
}
