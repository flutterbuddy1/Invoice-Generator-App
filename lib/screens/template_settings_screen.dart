import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/template_provider.dart';
import '../providers/business_provider.dart';
import '../utils/template_ui_helper.dart';
import '../utils/pdf_generator.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/business_profile.dart';
import '../models/template.dart';

class TemplateSettingsScreen extends StatefulWidget {
  const TemplateSettingsScreen({super.key});

  @override
  State<TemplateSettingsScreen> createState() => _TemplateSettingsScreenState();
}

class _TemplateSettingsScreenState extends State<TemplateSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Invoice _getDummyInvoice() {
    return Invoice(
      id: 'dummy-1',
      invoiceNumber: 'INV-2024-001',
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      clientName: 'John Doe / Client Name',
      clientAddress: '123 Business Avenue, New York, NY',
      customerGSTIN: '27AAAAA0000A1Z5',
      items: [
        InvoiceItem(
          description: 'Professional Service',
          hsnCode: '9983',
          quantity: 2,
          unitPrice: 500.0,
          gstRate: 18.0,
        ),
        InvoiceItem(
          description: 'Product Sample',
          hsnCode: '8471',
          quantity: 1,
          unitPrice: 1200.0,
          gstRate: 12.0,
        ),
      ],
      transportMode: 'Road',
      vehicleNumber: 'NY-01-AB-1234',
      termsOfPayment: 'Net 30',
      termsOfDelivery: 'Doorstep',
    );
  }

  BusinessProfile _getDummyProfile(BusinessProfile? realProfile) {
    return realProfile ??
        BusinessProfile(
          businessName: 'Your Company Name',
          address: '456 My Street, My City, State, Country',
          phone: '+1 234 567 890',
          email: 'contact@mybusiness.com',
          gstin: '27BBBBB1111B1Z5',
          bankName: 'Global Bank',
          accountNumber: '1234567890',
          ifscCode: 'GLOB0001234',
        );
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);
    final provider = Provider.of<TemplateProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dummyInvoice = _getDummyInvoice();
    final profile = _getDummyProfile(businessProvider.businessProfile);
    
    final styles = provider.currentStyles;
    final labels = provider.currentLabels;
    final features = provider.currentFeatures;

    if (styles == null || labels == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Design Workspace')),
        body: const Center(
          child: Text('No template selected or styles missing.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Workspace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Styles', icon: Icon(Icons.palette_outlined)),
            Tab(text: 'Features', icon: Icon(Icons.toggle_on_outlined)),
            Tab(text: 'Labels', icon: Icon(Icons.text_fields)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: () => _showResetConfirmation(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Preview Section
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey.shade200,
              child: Stack(
                children: [
                  PdfPreview(
                    build: (format) => PdfGenerator.generate(
                      dummyInvoice,
                      profile,
                      styles: styles,
                      labels: labels,
                      features: features,
                    ),
                    allowPrinting: false,
                    allowSharing: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    dynamicLayout: false,
                    maxPageWidth: 400,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Live Preview',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Configuration Tabs Section
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStylesTab(context, provider, styles),
                  _buildFeaturesTab(context, provider, features),
                  _buildLabelsTab(context, provider, labels),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylesTab(BuildContext context, TemplateProvider provider, TemplateStyles styles) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Template Selection'),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final template = provider.templates[index];
              final isSelected = provider.selectedTemplate?.id == template.id;
              final icon = TemplateUIHelper.getIconForTemplate(template.id);
              
              return GestureDetector(
                onTap: () => provider.selectTemplate(template.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Brand Colors'),
        const SizedBox(height: 12),
        _buildColorTile(context, 'Primary Color', styles.primaryColor, (c) => provider.updateColor('primaryColor', c)),
        _buildColorTile(context, 'Accent Color', styles.secondaryColor, (c) => provider.updateColor('secondaryColor', c)),
        _buildColorTile(context, 'Table Header', styles.tableHeaderColor, (c) => provider.updateColor('tableHeaderColor', c)),
        _buildColorTile(context, 'Footer Background', styles.footerBackgroundColor, (c) => provider.updateColor('footerBackgroundColor', c)),
      ],
    );
  }

  Widget _buildFeaturesTab(BuildContext context, TemplateProvider provider, Map<String, bool> features) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Layout Options'),
        const SizedBox(height: 8),
        _buildFeatureSwitch('showGst', 'Show GST Columns', features, provider),
        _buildFeatureSwitch('showHsn', 'Show HSN/SAC Codes', features, provider),
        _buildFeatureSwitch('showDueDate', 'Show Due Date', features, provider),
        _buildFeatureSwitch('showTransportFields', 'Show Transport Fields', features, provider),
        _buildFeatureSwitch('showPaymentTerms', 'Show Terms of Payment', features, provider),
        _buildFeatureSwitch('showCustomerGstin', 'Show Customer GSTIN', features, provider),
      ],
    );
  }

  Widget _buildLabelsTab(BuildContext context, TemplateProvider provider, TemplateLabels labels) {
    final labelMap = labels.toMap();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Customize Text Labels'),
        const SizedBox(height: 8),
        ...labelMap.keys.map((key) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: labelMap[key],
            decoration: InputDecoration(
              labelText: _getLabelDisplayName(key),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) => provider.updateLabel(key, val),
          ),
        )),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFeatureSwitch(String key, String label, Map<String, bool> features, TemplateProvider provider) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: features[key] ?? false,
      onChanged: (val) => provider.toggleFeature(key),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildColorTile(BuildContext context, String label, Color color, Function(Color) onSelected) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      onTap: () => _showColorPicker(context, onSelected),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  void _showColorPicker(BuildContext context, Function(Color) onColorSelected) {
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange,
      Colors.teal, Colors.indigo, Colors.brown, Colors.black87, Colors.grey,
      const Color(0xFF4A148C), const Color(0xFF00796B), const Color(0xFFC62828), const Color(0xFF1976D2),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pick a Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: colors.map((color) => GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _getLabelDisplayName(String key) {
    final result = key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    return result[0].toUpperCase() + result.substring(1);
  }

  void _showResetConfirmation(BuildContext context, TemplateProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Design?'),
        content: const Text('This will revert all colors and labels to the original template defaults.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.resetStyles();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
