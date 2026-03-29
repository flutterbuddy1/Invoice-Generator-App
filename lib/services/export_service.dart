import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import '../models/business_profile.dart';
import '../models/template.dart';
import '../models/export_models.dart';
import '../utils/pdf_generator.dart';

/// Service for exporting invoices in various formats
class ExportService {
  /// Export selected invoices by their IDs
  Future<ExportResult> exportSelectedInvoices(
    List<Invoice> allInvoices,
    List<String> selectedIds,
    ExportFormat format,
    BusinessProfile profile,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) async {
    try {
      // Filter invoices by selected IDs
      final selectedInvoices = allInvoices
          .where((invoice) => selectedIds.contains(invoice.id))
          .toList();

      if (selectedInvoices.isEmpty) {
        return ExportResult.error('No invoices selected');
      }

      return await _exportInvoices(
        selectedInvoices,
        format,
        profile,
        styles,
        labels,
        features,
      );
    } catch (e) {
      return ExportResult.error('Export failed: $e');
    }
  }

  /// Export invoices within a date range
  Future<ExportResult> exportByDateRange(
    List<Invoice> allInvoices,
    DateTime startDate,
    DateTime endDate,
    ExportFormat format,
    BusinessProfile profile,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) async {
    try {
      // Filter invoices by date range
      final filteredInvoices = allInvoices.where((invoice) {
        return invoice.date.isAfter(
              startDate.subtract(const Duration(days: 1)),
            ) &&
            invoice.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      if (filteredInvoices.isEmpty) {
        return ExportResult.error(
          'No invoices found in the selected date range',
        );
      }

      return await _exportInvoices(
        filteredInvoices,
        format,
        profile,
        styles,
        labels,
        features,
      );
    } catch (e) {
      return ExportResult.error('Export failed: $e');
    }
  }

  /// Internal method to export invoices based on format
  Future<ExportResult> _exportInvoices(
    List<Invoice> invoices,
    ExportFormat format,
    BusinessProfile profile,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) async {
    switch (format) {
      case ExportFormat.json:
        return await _exportAsJson(invoices);
      case ExportFormat.pdf:
        if (invoices.length == 1) {
          return await _exportSinglePdf(
            invoices.first,
            profile,
            styles,
            labels,
            features,
          );
        } else {
          // For multiple invoices, create individual PDFs and zip them
          return await _exportMultiplePdfsAsZip(
            invoices,
            profile,
            styles,
            labels,
            features,
          );
        }
      case ExportFormat.zip:
        return await _exportMultiplePdfsAsZip(
          invoices,
          profile,
          styles,
          labels,
          features,
        );
    }
  }

  /// Export invoices as JSON
  Future<ExportResult> _exportAsJson(List<Invoice> invoices) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Create invoices subfolder if it doesn't exist
      final invoicesDir = Directory('${directory.path}/invoices');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'invoices_export_$timestamp.json';
      final filePath = '${invoicesDir.path}/$fileName';

      // Convert invoices to JSON
      final jsonData = {
        'exportDate': DateTime.now().toIso8601String(),
        'invoiceCount': invoices.length,
        'invoices': invoices.map((invoice) => _invoiceToJson(invoice)).toList(),
      };

      // Write to file
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );

      return ExportResult.success(filePath, invoices.length);
    } catch (e) {
      return ExportResult.error('JSON export failed: $e');
    }
  }

  /// Convert invoice to JSON (helper method)
  Map<String, dynamic> _invoiceToJson(Invoice invoice) {
    return {
      'id': invoice.id,
      'invoiceNumber': invoice.invoiceNumber,
      'date': invoice.date.toIso8601String(),
      'dueDate': invoice.dueDate.toIso8601String(),
      'clientName': invoice.clientName,
      'clientAddress': invoice.clientAddress,
      'customerGSTIN': invoice.customerGSTIN,
      'totalAmount': invoice.totalAmount,
      'items': invoice.items
          .map(
            (item) => {
              'description': item.description,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'gstRate': item.gstRate,
              'hsnCode': item.hsnCode,
              'total': item.total,
            },
          )
          .toList(),
    };
  }

  /// Export a single invoice as PDF
  Future<ExportResult> _exportSinglePdf(
    Invoice invoice,
    BusinessProfile profile,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Create invoices subfolder if it doesn't exist
      final invoicesDir = Directory('${directory.path}/invoices');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      final fileName = 'invoice_${invoice.invoiceNumber}.pdf';
      final filePath = '${invoicesDir.path}/$fileName';

      // Generate PDF
      final pdfBytes = await PdfGenerator.generate(
        invoice,
        profile,
        styles: styles,
        labels: labels,
        features: features,
      );

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      return ExportResult.success(filePath, 1);
    } catch (e) {
      return ExportResult.error('PDF export failed: $e');
    }
  }

  /// Export multiple invoices as a single merged PDF
  /// Invoices will be sorted by date (oldest first)
  Future<ExportResult> exportMergedPdf(
    List<Invoice> invoices,
    BusinessProfile profile,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Create invoices subfolder if it doesn't exist
      final invoicesDir = Directory('${directory.path}/invoices');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'invoices_merged_$timestamp.pdf';
      final filePath = '${invoicesDir.path}/$fileName';

      // Use the new generateMultiple method from PdfGenerator
      final pdfBytes = await PdfGenerator.generateMultiple(
        invoices,
        profile,
        styles: styles,
        labels: labels,
        features: features,
      );

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      return ExportResult.success(filePath, invoices.length);
    } catch (e) {
      return ExportResult.error('Merged PDF export failed: $e');
    }
  }

  /// Helper to load images
  pw.MemoryImage? _tryLoadImage(String? path) {
    if (path == null) return null;
    try {
      final file = File(path);
      if (file.existsSync()) {
        return pw.MemoryImage(file.readAsBytesSync());
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Export multiple invoices as individual PDFs in a ZIP file
  Future<ExportResult> _exportMultiplePdfsAsZip(
    List<Invoice> invoices,
    BusinessProfile profile,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Create invoices subfolder if it doesn't exist
      final invoicesDir = Directory('${directory.path}/invoices');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      final tempDir = Directory('${invoicesDir.path}/temp_export');

      // Create temp directory if it doesn't exist
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      // Generate PDFs for each invoice
      final pdfFiles = <File>[];
      for (final invoice in invoices) {
        final fileName = 'invoice_${invoice.invoiceNumber}.pdf';
        final filePath = '${tempDir.path}/$fileName';

        final pdfBytes = await PdfGenerator.generate(
          invoice,
          profile,
          styles: styles,
          labels: labels,
          features: features,
        );

        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        pdfFiles.add(file);
      }

      // Create ZIP file
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final zipFileName = 'invoices_export_$timestamp.zip';
      final zipFilePath = '${invoicesDir.path}/$zipFileName';

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);

      for (final file in pdfFiles) {
        await encoder.addFile(file);
      }

      encoder.close();

      // Clean up temp directory
      await tempDir.delete(recursive: true);

      return ExportResult.success(zipFilePath, invoices.length);
    } catch (e) {
      return ExportResult.error('ZIP export failed: $e');
    }
  }

  /// Share a file using the system share sheet
  Future<bool> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final xFile = XFile(filePath);
      await Share.shareXFiles([xFile], subject: 'Invoice Export');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in human-readable format
  String getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return '0 KB';

      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return '0 KB';
    }
  }
}
