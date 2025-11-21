import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/business_profile.dart';
import '../models/invoice.dart';
import 'number_to_words.dart';

class PdfGenerator {
  static Future<Uint8List> generate(
    Invoice invoice,
    BusinessProfile profile,
  ) async {
    final pdf = pw.Document();
    try {
      final image = _tryLoadImage(profile.logoPath);
      final signature = _tryLoadImage(profile.signaturePath);

      // Use standard fonts to avoid network dependency issues
      final font = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context context) {
            return [
              _buildTitle(),
              _buildHeaderSection(invoice, profile, image),
              _buildConsigneeSection(invoice),
              _buildItemsTable(invoice),
              _buildFooterSection(invoice, profile, signature),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      final errorPdf = pw.Document();
      errorPdf.addPage(
        pw.Page(
          build: (context) =>
              pw.Center(child: pw.Text('Error generating PDF: $e')),
        ),
      );
      return errorPdf.save();
    }
  }

  static pw.MemoryImage? _tryLoadImage(String? path) {
    if (path == null) return null;
    try {
      final file = File(path);
      if (file.existsSync()) {
        return pw.MemoryImage(file.readAsBytesSync());
      }
    } catch (e) {
      // Silently fail if image cannot be loaded
      return null;
    }
    return null;
  }

  static pw.Widget _buildTitle() {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Text(
        'ESTIMATE',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
      ),
    );
  }

  static pw.Widget _buildHeaderSection(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? image,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Business Details
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.businessName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    profile.address,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Ph: ${profile.phone}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'GSTIN: ${profile.gstin}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Middle: Invoice Details
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                children: [
                  _buildHeaderRow('Invoice No.', invoice.invoiceNumber),
                  _buildHeaderRow(
                    'Dated',
                    DateFormat('dd.MM.yyyy').format(invoice.date),
                  ),
                  _buildHeaderRow(
                    'Due Date',
                    DateFormat('dd.MM.yyyy').format(invoice.dueDate),
                  ),
                ],
              ),
            ),
          ),
          // Right: Logo
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              alignment: pw.Alignment.center,
              height: 80,
              child: image != null
                  ? pw.Image(image, fit: pw.BoxFit.contain)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderRow(String label, String value) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide()),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildConsigneeSection(Invoice invoice) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CONSIGNEE DETAILS',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    invoice.clientName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    invoice.clientAddress,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    final headers = ['Description of Goods', 'Qty', 'Rate', 'Total'];

    // Calculate total tax (simplified as we don't have per-item tax breakdown in UI fully matching the complex table)
    // We will show basic columns: Desc, Qty, Rate, Total.
    // The user image has complex tax columns. I will stick to a cleaner version but with borders.

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple900),
          children: headers
              .map(
                (h) => pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Rows
        ...invoice.items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  item.description,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '${item.quantity}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  item.unitPrice.toStringAsFixed(2),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  item.total.toStringAsFixed(2),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        // Empty rows filler (optional, to make it look like the sheet)
        for (int i = 0; i < (10 - invoice.items.length).clamp(0, 10); i++)
          pw.TableRow(
            children: List.generate(4, (index) => pw.Container(height: 20)),
          ),

        // Total Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Total',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Container(),
            pw.Container(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                invoice.totalAmount.toStringAsFixed(2),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooterSection(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? signature,
  ) {
    final totalInWords = NumberToWords.convert(invoice.totalAmount.toInt());

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Amount in words & Declaration
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Amount Chargeable (in words):',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    '$totalInWords Only',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Declaration:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  if (profile.bankName != null &&
                      profile.bankName!.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Bank Details:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Bank: ${profile.bankName}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'A/c No: ${profile.accountNumber}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'IFSC: ${profile.ifscCode}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Branch: ${profile.branchName}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Right: Totals & Signature
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide()),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Grand Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        invoice.totalAmount.toStringAsFixed(2),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  height: 80,
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.bottomCenter,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      if (signature != null)
                        pw.Container(
                          height: 40,
                          child: pw.Image(signature, fit: pw.BoxFit.contain),
                        ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Authorised Signatory',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
