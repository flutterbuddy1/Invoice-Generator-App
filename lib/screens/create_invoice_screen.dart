import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../providers/invoice_provider.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _clientNameController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _customerGstinController = TextEditingController();

  final _invoiceNumberController = TextEditingController();
  final _transportModeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _termsPaymentController = TextEditingController();
  final _termsDeliveryController = TextEditingController();
  bool _isIGST = false;

  DateTime _date = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  List<InvoiceItem> _items = [];

  // Item Controllers
  final _itemDescController = TextEditingController();
  final _itemHsnController = TextEditingController();
  final _itemQtyController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemGstController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _loadInvoiceData();
    } else {
      _invoiceNumberController.text =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  void _loadInvoiceData() {
    final inv = widget.invoice!;
    _clientNameController.text = inv.clientName;
    _clientAddressController.text = inv.clientAddress;
    _customerGstinController.text = inv.customerGSTIN;
    _invoiceNumberController.text = inv.invoiceNumber;
    _transportModeController.text = inv.transportMode;
    _vehicleNumberController.text = inv.vehicleNumber;
    _termsPaymentController.text = inv.termsOfPayment;
    _termsDeliveryController.text = inv.termsOfDelivery;
    _isIGST = inv.isIGST;
    _date = inv.date;
    _dueDate = inv.dueDate;
    _items = List.from(inv.items);
  }

  void _addItem() {
    if (_itemDescController.text.isNotEmpty &&
        _itemQtyController.text.isNotEmpty &&
        _itemPriceController.text.isNotEmpty) {
      setState(() {
        _items.add(
          InvoiceItem(
            description: _itemDescController.text,
            hsnCode: _itemHsnController.text,
            quantity: int.parse(_itemQtyController.text),
            unitPrice: double.parse(_itemPriceController.text),
            gstRate: double.tryParse(_itemGstController.text) ?? 0.0,
          ),
        );
      });
      _itemDescController.clear();
      _itemHsnController.clear();
      _itemQtyController.clear();
      _itemPriceController.clear();
      _itemGstController.text = '0';
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _dueDate : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  void _saveInvoice() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }

    final invoice = Invoice(
      id: widget.invoice?.id ?? const Uuid().v4(),
      invoiceNumber: _invoiceNumberController.text,
      date: _date,
      dueDate: _dueDate,
      clientName: _clientNameController.text,
      clientAddress: _clientAddressController.text,
      customerGSTIN: _customerGstinController.text,
      isIGST: _isIGST,
      transportMode: _transportModeController.text,
      vehicleNumber: _vehicleNumberController.text,
      termsOfPayment: _termsPaymentController.text,
      termsOfDelivery: _termsDeliveryController.text,
      items: List.from(_items),
    );

    if (widget.invoice != null) {
      Provider.of<InvoiceProvider>(
        context,
        listen: false,
      ).updateInvoice(widget.invoice!, invoice);
    } else {
      Provider.of<InvoiceProvider>(context, listen: false).addInvoice(invoice);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice != null ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              _saveInvoice();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              Navigator.of(context).pop();
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(
                        _currentStep == 3 ? 'Save Invoice' : 'Continue',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Client'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clientAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerGstinController,
                    decoration: const InputDecoration(
                      labelText: 'Customer GSTIN',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Details'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(labelText: 'Invoice #'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              prefixIcon: Icon(Icons.event),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_dueDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Inter-state Supply (IGST)'),
                    value: _isIGST,
                    onChanged: (val) => setState(() => _isIGST = val),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _transportModeController,
                    decoration: const InputDecoration(
                      labelText: 'Transport Mode',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: const InputDecoration(labelText: 'Vehicle No.'),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Items'),
              content: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _itemDescController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _itemHsnController,
                                  decoration: const InputDecoration(
                                    labelText: 'HSN',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _itemQtyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _itemPriceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _itemGstController,
                                  decoration: const InputDecoration(
                                    labelText: 'GST %',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_items.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item.description),
                          subtitle: Text(
                            '${item.quantity} x ${item.unitPrice} (+${item.gstRate}%)',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Review'),
              content: Column(
                children: [
                  _buildReviewRow('Client', _clientNameController.text),
                  _buildReviewRow('Invoice #', _invoiceNumberController.text),
                  _buildReviewRow(
                    'Date',
                    DateFormat('dd/MM/yyyy').format(_date),
                  ),
                  _buildReviewRow('Total Items', _items.length.toString()),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_items.fold(0.0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
