import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import 'edit_profile_screen.dart';
import 'template_settings_screen.dart';
import 'export_invoices_screen.dart';
import 'file_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd()
      ..load().then((_) {
        setState(() {
          _isBannerAdReady = true;
        });
      });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (context.mounted) {
      showAboutDialog(
        context: context,
        applicationName: 'Invoice Generator',
        applicationVersion: 'v${packageInfo.version}',
        applicationLegalese: '© 2026 ScaleASkill',
        children: [
          const SizedBox(height: 16),
          const Text(
            'A simple and powerful invoice generator for your business.',
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'General'),
                _buildListTile(
                  context,
                  icon: Icons.business,
                  title: 'Business Profile',
                  subtitle: 'Manage your business details',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: Icons.palette,
                  title: 'Invoice Templates',
                  subtitle: 'Customize invoice design & features',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TemplateSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: Icons.upload_file,
                  title: 'Export Invoices',
                  subtitle: 'Backup or share your invoices',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExportInvoicesScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: Icons.folder,
                  title: 'File Manager',
                  subtitle: 'Manage exported files',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FileManagerScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 32),
                _buildSectionHeader(context, 'Legal & Support'),
                _buildListTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _launchUrl(
                    'https://docs.google.com/document/d/1HscMEAQp8t1L88xOU2Fq1b05lV9abIGCZ7x074lDeGw/edit?usp=sharing',
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => _launchUrl(
                    'https://docs.google.com/document/d/1A6ACXkcPe43xABxyTnEbJaMw_Wq6EkAGWH4nVwuP-5I/edit?usp=sharing',
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.star_rate_outlined,
                  title: 'Rate Us',
                  onTap: () => _launchUrl(
                    "https://play.google.com/store/apps/details?id=com.scaleaskill.invoiceapp",
                  ),
                ),
                const Divider(height: 32),
                _buildSectionHeader(context, 'App Info'),
                _buildListTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          if (_isBannerAdReady)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
