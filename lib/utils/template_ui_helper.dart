import 'package:flutter/material.dart';

class TemplateUIHelper {
  static IconData getIconForTemplate(String templateId) {
    switch (templateId) {
      case 'car_service':
        return Icons.directions_car;
      case 'freelancer':
        return Icons.person_outline;
      case 'retail':
        return Icons.shopping_basket;
      case 'medical':
        return Icons.medical_services;
      case 'it_services':
        return Icons.terminal;
      case 'real_estate':
        return Icons.home_work;
      case 'law_firm':
        return Icons.balance;
      case 'photography':
        return Icons.camera_alt;
      case 'construction':
        return Icons.engineering;
      case 'education':
        return Icons.school;
      case 'ecommerce':
        return Icons.local_mall;
      case 'marketing':
        return Icons.campaign;
      case 'minimalist':
        return Icons.web_asset;
      case 'custom':
        return Icons.auto_awesome;
      default:
        return Icons.description;
    }
  }

  static String getCategoryForTemplate(String templateId) {
    switch (templateId) {
      case 'car_service':
        return 'Automotive';
      case 'freelancer':
        return 'Personal';
      case 'retail':
        return 'Sales';
      case 'medical':
        return 'Healthcare';
      case 'it_services':
        return 'Technology';
      case 'real_estate':
        return 'Property';
      case 'law_firm':
        return 'Legal';
      case 'photography':
        return 'Creative';
      case 'construction':
        return 'Contracting';
      case 'education':
        return 'Academic';
      case 'ecommerce':
        return 'Online Store';
      case 'marketing':
        return 'Agency';
      case 'minimalist':
        return 'Modern';
      case 'custom':
        return 'Builder';
      default:
        return 'General';
    }
  }
}
