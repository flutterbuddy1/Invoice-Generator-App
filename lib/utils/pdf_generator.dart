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
          margin: pw.EdgeInsets.all(30),
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
            flex: 4,
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
                  _buildHeaderRow('Terms of Payment', invoice.termsOfPayment),
                  _buildHeaderRow('Suppliers Ref.', ''),
                  _buildHeaderRow('Other Reference(s)', ''),
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
              height: 100,
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
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
            ),
          ),
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
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
          // Left: Consignee Details
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CONSIGNEE DETAILS',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 10,
                      decoration: pw.TextDecoration.underline,
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
                  if (invoice.customerGSTIN.isNotEmpty)
                    pw.Text(
                      'GSTIN: ${invoice.customerGSTIN}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Right: Transport Details
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                _buildHeaderRow('Terms of Delivery', invoice.termsOfDelivery),
                _buildHeaderRow('Buyer\'s Order No.', ''),
                _buildHeaderRow('Transport Mode', invoice.transportMode),
                _buildHeaderRow('Vehicle No.', invoice.vehicleNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Desc
        1: const pw.FlexColumnWidth(1), // HSN
        2: const pw.FlexColumnWidth(0.8), // Qty
        3: const pw.FlexColumnWidth(1.2), // Rate
        4: const pw.FlexColumnWidth(1.2), // Total (Base)
        5: const pw.FlexColumnWidth(1.5), // IGST
        6: const pw.FlexColumnWidth(1.5), // SGST
        7: const pw.FlexColumnWidth(1.5), // CGST
        8: const pw.FlexColumnWidth(1.5), // Total Amount
      },
      children: [
        // Header Row 1 (Main Headers)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple900),
          children: [
            _buildTableHeader('Description of Goods'),
            _buildTableHeader('HSN Code'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Unit Price'),
            _buildTableHeader('Total'),
            _buildTableHeader('IGST'),
            _buildTableHeader('SGST'),
            _buildTableHeader('CGST'),
            _buildTableHeader('Total'),
          ],
        ),
        // Header Row 2 (Sub-headers for Taxes)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple100),
          children: [
            pw.Container(), // Desc
            pw.Container(), // HSN
            pw.Container(), // Qty
            pw.Container(), // Rate
            pw.Container(), // Total
            _buildSubHeader('Rate | Amt'), // IGST
            _buildSubHeader('Rate | Amt'), // SGST
            _buildSubHeader('Rate | Amt'), // CGST
            pw.Container(), // Total
          ],
        ),
        // Data Rows
        ...invoice.items.map((item) {
          final baseTotal = item.quantity * item.unitPrice;
          final taxAmount = item.total - baseTotal;

          double igstRate = 0, igstAmt = 0;
          double sgstRate = 0, sgstAmt = 0;
          double cgstRate = 0, cgstAmt = 0;

          if (invoice.isIGST) {
            igstRate = item.gstRate;
            igstAmt = taxAmount;
          } else {
            sgstRate = item.gstRate / 2;
            sgstAmt = taxAmount / 2;
            cgstRate = item.gstRate / 2;
            cgstAmt = taxAmount / 2;
          }

          return pw.TableRow(
            children: [
              _buildTableCell(item.description, align: pw.TextAlign.left),
              _buildTableCell(item.hsnCode),
              _buildTableCell('${item.quantity}'),
              _buildTableCell(item.unitPrice.toStringAsFixed(2)),
              _buildTableCell(baseTotal.toStringAsFixed(2)),
              _buildTableCell(
                '${igstRate.toStringAsFixed(0)}% | ${igstAmt.toStringAsFixed(2)}',
              ),
              _buildTableCell(
                '${sgstRate.toStringAsFixed(0)}% | ${sgstAmt.toStringAsFixed(2)}',
              ),
              _buildTableCell(
                '${cgstRate.toStringAsFixed(0)}% | ${cgstAmt.toStringAsFixed(2)}',
              ),
              _buildTableCell(item.total.toStringAsFixed(2)),
            ],
          );
        }),
        // Empty rows filler
        for (int i = 0; i < (8 - invoice.items.length).clamp(0, 8); i++)
          pw.TableRow(
            children: List.generate(9, (index) => pw.Container(height: 20)),
          ),
        // Total Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Total', isBold: true),
            pw.Container(),
            _buildTableCell(
              invoice.items
                  .fold<int>(0, (sum, item) => sum + item.quantity)
                  .toString(),
              isBold: true,
            ),
            pw.Container(),
            _buildTableCell(
              invoice.items
                  .fold<double>(
                    0,
                    (sum, item) => sum + (item.quantity * item.unitPrice),
                  )
                  .toStringAsFixed(2),
              isBold: true,
            ),
            _buildTableCell(
              invoice.isIGST
                  ? (invoice.totalAmount -
                            invoice.items.fold<double>(
                              0,
                              (sum, item) =>
                                  sum + (item.quantity * item.unitPrice),
                            ))
                        .toStringAsFixed(2)
                  : '-',
              isBold: true,
            ),
            _buildTableCell(
              !invoice.isIGST
                  ? ((invoice.totalAmount -
                                invoice.items.fold<double>(
                                  0,
                                  (sum, item) =>
                                      sum + (item.quantity * item.unitPrice),
                                )) /
                            2)
                        .toStringAsFixed(2)
                  : '-',
              isBold: true,
            ),
            _buildTableCell(
              !invoice.isIGST
                  ? ((invoice.totalAmount -
                                invoice.items.fold<double>(
                                  0,
                                  (sum, item) =>
                                      sum + (item.quantity * item.unitPrice),
                                )) /
                            2)
                        .toStringAsFixed(2)
                  : '-',
              isBold: true,
            ),
            _buildTableCell(
              invoice.totalAmount.toStringAsFixed(2),
              isBold: true,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSubHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildFooterSection(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? signature,
  ) {
    final totalInWords = NumberToWords.convert(invoice.totalAmount.toInt());
    final baseTotal = invoice.items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final totalTax = invoice.totalAmount - baseTotal;

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
                _buildFooterRow('Total Amount', baseTotal.toStringAsFixed(2)),
                if (invoice.isIGST)
                  _buildFooterRow('Add: IGST', totalTax.toStringAsFixed(2))
                else ...[
                  _buildFooterRow(
                    'Add: SGST',
                    (totalTax / 2).toStringAsFixed(2),
                  ),
                  _buildFooterRow(
                    'Add: CGST',
                    (totalTax / 2).toStringAsFixed(2),
                  ),
                ],
                _buildFooterRow('Round OFF', '-'),
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

  static pw.Widget _buildFooterRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide()),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
