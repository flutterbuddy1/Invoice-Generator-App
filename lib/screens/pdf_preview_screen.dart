import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/business_provider.dart';
import '../providers/template_provider.dart';
import '../utils/pdf_generator.dart';
import '../services/ad_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  @override
  void initState() {
    super.initState();
    // Preload the interstitial ad when the preview screen opens
    AdService().createInterstitialAd();
  }

  void _handleBack() {
    // Show ad when leaving the screen
    AdService().showInterstitialAd();
    Navigator.of(context).pop();
  }

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

    final templateProvider = Provider.of<TemplateProvider>(context);

    if (templateProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final styles = templateProvider.currentStyles;
    final template = templateProvider.selectedTemplate;

    if (styles == null || template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Template not loaded!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoice.invoiceNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          _handleBack();
        },
        child: PdfPreview(
          build: (format) => PdfGenerator.generate(
            widget.invoice,
            profile,
            styles: styles,
            labels: templateProvider.currentLabels!,
            features: templateProvider.currentFeatures,
          ),
          canChangeOrientation: false,
          canChangePageFormat: false,
        ),
      ),
    );
  }
}
