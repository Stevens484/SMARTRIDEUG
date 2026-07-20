import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Contact us using one of the options below.'),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primaryGreen),
              title: const Text('support@smartrideug.com'),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryGreen),
              title: const Text('+256 701 234 567'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Frequently asked questions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('- How do I cancel a booking?'),
            const Text('- How do I change my payment method?'),
            const Text('- How do I update my profile details?'),
          ],
        ),
      ),
    );
  }
}
