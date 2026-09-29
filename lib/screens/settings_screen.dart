import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.policy_outlined, color: Colors.orange),
            title: const Text('Disclaimer & Sources'),
            subtitle: const Text('Government policy compliance & info sources'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Disclaimer & Official Sources'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Sarkari Marg is an independent private informational application.\n\n'
                      '1. NO GOVERNMENT AFFILIATION:\n'
                      'We do NOT represent any government entity, department, or ministry. We are NOT affiliated with, endorsed by, or authorized by any government agency.\n\n'
                      '2. SOURCES OF INFORMATION:\n'
                      'All government job updates, exam schedules, admit cards, and results displayed in this application are aggregated directly from the official, publicly accessible government employment portals listed below:\n'
                      '• Union Public Service Commission: upsc.gov.in\n'
                      '• Staff Selection Commission: ssc.gov.in\n'
                      '• Indian Railways Portal: indianrailways.gov.in\n'
                      '• Institute of Banking Personnel Selection: ibps.in\n'
                      '• National Career Service: ncs.gov.in\n'
                      '• Employment News: employmentnews.gov.in\n\n'
                      '3. VERIFICATION:\n'
                      'Users are strictly advised to visit and verify details on the respective official government websites before submitting any application.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('GOT IT'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Sarkari Marg',
            applicationVersion: '1.0.4',
            applicationLegalese: '© 2026 Sarkari Marg - Independent Educational Platform',
          ),
        ],
      ),
    );
  }
}