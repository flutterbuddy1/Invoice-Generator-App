import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/business_provider.dart';
import '../utils/pdf_generator.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    final profile = businessProvider.businessProfile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Business Profile not found!')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Invoice #${invoice.invoiceNumber}')),
      body: PdfPreview(
        build: (format) => PdfGenerator.generate(invoice, profile),
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
