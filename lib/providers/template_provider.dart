import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template.dart';
import '../data/default_templates.dart';

class TemplateProvider extends ChangeNotifier {
  List<InvoiceTemplate> _templates = [];
  InvoiceTemplate? _selectedTemplate;
  TemplateStyles? _customStyles;

  bool _isLoading = true;
  TemplateLabels? _customLabels;

  List<InvoiceTemplate> get templates => _templates;
  bool get isLoading => _isLoading;

  InvoiceTemplate? get selectedTemplate => _selectedTemplate;

  // Return custom styles/features if set, otherwise default from template
  TemplateStyles? get currentStyles =>
      _customStyles ?? _selectedTemplate?.styles;

  TemplateLabels? get currentLabels =>
      _customLabels ?? _selectedTemplate?.labels;

  Map<String, bool> get currentFeatures {
    if (_selectedTemplate == null) return <String, bool>{};

    try {
      // Merge template defaults with overrides
      // Cast to nullable to handle potential runtime issues during hot reload
      // catch any TypeError if the field is uninitialized
      final defaults =
          (_selectedTemplate!.features as Map<String, bool>?) ?? {};
      if (_customFeatures == null) return defaults;

      return {...defaults, ..._customFeatures!};
    } catch (e) {
      debugPrint('Error accessing features (Hot Reload state issue?): $e');
      return <String, bool>{};
    }
  }

  Map<String, bool>? _customFeatures;

  Future<void> loadTemplates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final templatePaths = manifestMap.keys
          .where(
            (String key) =>
                key.startsWith('assets/templates/') && key.endsWith('.json'),
          )
          .toList();

      List<InvoiceTemplate> loadedTemplates = [];
      for (final path in templatePaths) {
        try {
          final jsonString = await rootBundle.loadString(path);
          final jsonMap = json.decode(jsonString);
          loadedTemplates.add(InvoiceTemplate.fromJson(jsonMap));
        } catch (e) {
          debugPrint('Error loading template $path: $e');
        }
      }

      _templates = loadedTemplates;

      // Merge with built-in templates, avoiding duplicates by ID
      final builtIn = getBuiltInTemplates();
      for (final t in builtIn) {
        if (!_templates.any((existing) => existing.id == t.id)) {
          _templates.add(t);
        }
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
    } finally {
      // Ensure we have at least built-in templates
      if (_templates.isEmpty) {
        _templates = getBuiltInTemplates();
      }

      // Load saved selection and customizations
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('selected_template_id');

      if (savedId != null && _templates.any((t) => t.id == savedId)) {
        _selectedTemplate = _templates.firstWhere((t) => t.id == savedId);
      } else if (_selectedTemplate == null && _templates.isNotEmpty) {
        _selectedTemplate = _templates.firstWhere(
          (t) => t.id == 'car_service',
          orElse: () => _templates.first,
        );
      }

      // Load Customizations if they exist for the CURRENT template
      if (_selectedTemplate != null) {
        final prefix = 'custom_v1_${_selectedTemplate!.id}_';
        
        final stylesJson = prefs.getString('${prefix}styles');
        if (stylesJson != null) {
          try {
            _customStyles = TemplateStyles.fromJson(json.decode(stylesJson));
          } catch (e) {
            debugPrint('Error loading custom styles: $e');
          }
        }

        final labelsJson = prefs.getString('${prefix}labels');
        if (labelsJson != null) {
          try {
            _customLabels = TemplateLabels.fromJson(json.decode(labelsJson));
          } catch (e) {
            debugPrint('Error loading custom labels: $e');
          }
        }

        final featuresJson = prefs.getString('${prefix}features');
        if (featuresJson != null) {
          try {
            _customFeatures = Map<String, bool>.from(json.decode(featuresJson));
          } catch (e) {
            debugPrint('Error loading custom features: $e');
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCustomizations() async {
    if (_selectedTemplate == null) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'custom_v1_${_selectedTemplate!.id}_';

    // Improved persistence: Save to JSON
    // Note: InvoiceTemplate parts don't have toJson, so we map them
    if (_customStyles != null) {
      final styleMap = {
        'primaryColor': '#${_customStyles!.primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'secondaryColor': '#${_customStyles!.secondaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'textColor': '#${_customStyles!.textColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'tableHeaderColor': '#${_customStyles!.tableHeaderColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'tableHeaderTextColor': '#${_customStyles!.tableHeaderTextColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'tableSubHeaderColor': '#${_customStyles!.tableSubHeaderColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'footerBackgroundColor': '#${_customStyles!.footerBackgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'borderColor': '#${_customStyles!.borderColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      };
      await prefs.setString('${prefix}styles', json.encode(styleMap));
    }

    if (_customLabels != null) {
      await prefs.setString('${prefix}labels', json.encode(_customLabels!.toMap()));
    }

    if (_customFeatures != null) {
      await prefs.setString('${prefix}features', json.encode(_customFeatures));
    }
  }

  Future<void> selectTemplate(String id) async {
    final template = _templates.firstWhere(
      (t) => t.id == id,
      orElse: () => _templates.first,
    );
    _selectedTemplate = template;
    
    // Load customizations for the NEWLY selected template
    _customStyles = null;
    _customFeatures = null;
    _customLabels = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_template_id', id);
    
    // We should reload customizations here too
    final prefix = 'custom_v1_${id}_';
    final stylesJson = prefs.getString('${prefix}styles');
    if (stylesJson != null) _customStyles = TemplateStyles.fromJson(json.decode(stylesJson));
    final labelsJson = prefs.getString('${prefix}labels');
    if (labelsJson != null) _customLabels = TemplateLabels.fromJson(json.decode(labelsJson));
    final featuresJson = prefs.getString('${prefix}features');
    if (featuresJson != null) _customFeatures = Map<String, bool>.from(json.decode(featuresJson));

    notifyListeners();
  }

  void updateColor(String key, Color color) {
    if (_selectedTemplate == null) return;
    _customStyles ??= _selectedTemplate!.styles;

    switch (key) {
      case 'primaryColor':
        _customStyles = _customStyles!.copyWith(primaryColor: color);
        break;
      case 'secondaryColor':
        _customStyles = _customStyles!.copyWith(secondaryColor: color);
        break;
      case 'textColor':
        _customStyles = _customStyles!.copyWith(textColor: color);
        break;
      case 'tableHeaderColor':
        _customStyles = _customStyles!.copyWith(tableHeaderColor: color);
        break;
      case 'footerBackgroundColor':
        _customStyles = _customStyles!.copyWith(footerBackgroundColor: color);
        break;
    }
    notifyListeners();
    _saveCustomizations();
  }

  void resetStyles() async {
    _customStyles = null;
    _customFeatures = null;
    _customLabels = null;
    notifyListeners();
    
    if (_selectedTemplate != null) {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'custom_v1_${_selectedTemplate!.id}_';
      await prefs.remove('${prefix}styles');
      await prefs.remove('${prefix}labels');
      await prefs.remove('${prefix}features');
    }
  }

  void updateLabel(String key, String value) {
    if (_selectedTemplate == null) return;
    _customLabels ??= _selectedTemplate!.labels;

    switch (key) {
      case 'title': _customLabels = _customLabels!.copyWith(title: value); break;
      case 'businessDetails': _customLabels = _customLabels!.copyWith(businessDetails: value); break;
      case 'consigneeDetailsTitle': _customLabels = _customLabels!.copyWith(consigneeDetailsTitle: value); break;
      case 'invoiceNo': _customLabels = _customLabels!.copyWith(invoiceNo: value); break;
      case 'dated': _customLabels = _customLabels!.copyWith(dated: value); break;
      case 'termsOfPayment': _customLabels = _customLabels!.copyWith(termsOfPayment: value); break;
      case 'dueDate': _customLabels = _customLabels!.copyWith(dueDate: value); break;
      case 'tableDescription': _customLabels = _customLabels!.copyWith(tableDescription: value); break;
      case 'tableHsn': _customLabels = _customLabels!.copyWith(tableHsn: value); break;
      case 'tableQty': _customLabels = _customLabels!.copyWith(tableQty: value); break;
      case 'tableRate': _customLabels = _customLabels!.copyWith(tableRate: value); break;
      case 'tableTotal': _customLabels = _customLabels!.copyWith(tableTotal: value); break;
      case 'totalAmount': _customLabels = _customLabels!.copyWith(totalAmount: value); break;
      case 'amountInWords': _customLabels = _customLabels!.copyWith(amountInWords: value); break;
      case 'declaration': _customLabels = _customLabels!.copyWith(declaration: value); break;
      case 'bankDetails': _customLabels = _customLabels!.copyWith(bankDetails: value); break;
      case 'authorizedSignatory': _customLabels = _customLabels!.copyWith(authorizedSignatory: value); break;
    }
    notifyListeners();
    _saveCustomizations();
  }

  void toggleFeature(String key) {
    if (_selectedTemplate == null) return;
    final currentVal = currentFeatures[key] ?? false;
    _customFeatures ??= <String, bool>{};
    _customFeatures![key] = !currentVal;
    notifyListeners();
    _saveCustomizations();
  }
}
