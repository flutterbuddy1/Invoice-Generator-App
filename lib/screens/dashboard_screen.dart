import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/invoice_provider.dart';
import '../services/ad_service.dart';
import 'create_invoice_screen.dart';
import 'pdf_preview_screen.dart';
import 'settings_screen.dart';
import 'export_invoices_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/pdf_generator.dart';
import '../providers/business_provider.dart';
import '../providers/template_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  String _searchQuery = '';
  bool _isSearching = false;
  final List<NativeAd?> _nativeAds = [];
  bool _isNativeAdsLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<InvoiceProvider>(context, listen: false).loadInvoices().then((_) => _loadNativeAds()),
    );
    _loadBannerAd();
    AdService().createInterstitialAd();
  }

  void _loadNativeAds() {
    final provider = Provider.of<InvoiceProvider>(context, listen: false);
    final count = (provider.invoices.length / 5).ceil();
    
    for (int i = 0; i < count; i++) {
      final ad = AdService().createNativeAd(
        onAdLoaded: (ad) {
          setState(() {
            _isNativeAdsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      );
      ad.load();
      _nativeAds.add(ad);
    }
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd();
    _bannerAd!.load().then((value) {
      if (mounted) {
        setState(() {
          _isBannerAdReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAd?.dispose();
    for (final ad in _nativeAds) {
      ad?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: false, // Align left
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: _isSearching
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black87),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: InputDecoration(
                    hintText: 'Search by Client or Invoice #',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              )
            : const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          if (!_isSearching) ...[
            Consumer<InvoiceProvider>(
              builder: (context, provider, child) {
                if (provider.invoices.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Export Invoices',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExportInvoicesScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_isBannerAdReady)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          Expanded(
            child: Consumer<InvoiceProvider>(
              builder: (context, provider, child) {
                final invoices = provider.invoices;
                final totalRevenue = invoices.fold<double>(
                  0,
                  (sum, item) => sum + item.totalAmount,
                );

                return Column(
                  children: [
                    // Summary Cards
                    if (!_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                'Total Invoices',
                                '${invoices.length}',
                                Icons.description,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                'Total Revenue',
                                '₹${totalRevenue.toStringAsFixed(0)}',
                                Icons.attach_money,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Invoice List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Invoices',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // List
                    Expanded(
                      child: invoices.isEmpty
                          ? _buildEmptyState(context)
                          : Builder(
                              builder: (context) {
                                final filteredInvoices = invoices.where((
                                  invoice,
                                ) {
                                  final name = invoice.clientName.toLowerCase();
                                  final number = invoice.invoiceNumber
                                      .toLowerCase();
                                  return name.contains(_searchQuery) ||
                                      number.contains(_searchQuery);
                                }).toList();

                                if (filteredInvoices.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No invoices found matching your search',
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredInvoices.length + (_isNativeAdsLoaded ? (filteredInvoices.length / 5).floor() : 0),
                                  itemBuilder: (context, index) {
                                    // Inject Ad every 5 items
                                    if (_isNativeAdsLoaded && index > 0 && (index + 1) % 6 == 0) {
                                      final adIndex = ((index + 1) / 6).floor() - 1;
                                      if (adIndex < _nativeAds.length && _nativeAds[adIndex] != null) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          height: 100,
                                          alignment: Alignment.center,
                                          child: AdWidget(ad: _nativeAds[adIndex]!),
                                        );
                                      }
                                    }

                                    // Adjust index for invoices
                                    final invoiceIndex = index - (_isNativeAdsLoaded ? (index / 6).floor() : 0);
                                    if (invoiceIndex >= filteredInvoices.length) return const SizedBox.shrink();
                                    
                                    final invoice = filteredInvoices[invoiceIndex];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PdfPreviewScreen(
                                                    invoice: invoice,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    invoice.clientName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${invoice.totalAmount.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '#${invoice.invoiceNumber}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat(
                                                      'dd MMM yyyy',
                                                    ).format(invoice.date),
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 24),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton.icon(
                                                    icon: const Icon(
                                                      Icons.share,
                                                      size: 18,
                                                      color: Colors.green,
                                                    ),
                                                    label: const Text(
                                                      'WhatsApp',
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    onPressed: () => _shareOnWhatsApp(invoice),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  TextButton.icon(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size: 18,
                                                    ),
                                                    label: const Text('Edit'),
                                                    onPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CreateInvoiceScreen(
                                                                invoice:
                                                                    invoice,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(width: 8),
                                                  TextButton.icon(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      size: 18,
                                                      color: Colors.red,
                                                    ),
                                                    label: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      _showDeleteDialog(
                                                        context,
                                                        invoice,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.01), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Invoices Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to get started',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _shareOnWhatsApp(dynamic invoice) async {
    final phone = invoice.clientPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number found for this client')),
      );
      return;
    }

    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    
    // Generate PDF
    final pdfBytes = await PdfGenerator.generate(
      invoice,
      businessProvider.businessProfile!,
      styles: templateProvider.currentStyles!,
      labels: templateProvider.currentLabels!,
      features: templateProvider.currentFeatures,
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/invoice_${invoice.invoiceNumber}.pdf';
    final file = File(path);
    await file.writeAsBytes(pdfBytes);

    // Share via share_plus (suggested for files)
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Hi ${invoice.clientName}, here is your invoice #${invoice.invoiceNumber}.',
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<InvoiceProvider>(
                context,
                listen: false,
              ).deleteInvoice(invoice);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
