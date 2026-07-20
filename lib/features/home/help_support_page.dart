import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & Support')),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('appSettings').doc('support').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final support = snapshot.data!.data();
        if (support == null) return const Center(child: Text('Support information is currently unavailable.'));
        final faqs = (support['faqs'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Need help?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Contact us using one of the options below.'),
          const SizedBox(height: 24),
          if (support['email'] != null) ListTile(leading: const Icon(Icons.email), title: Text(support['email'].toString())),
          if (support['phone'] != null) ListTile(leading: const Icon(Icons.phone), title: Text(support['phone'].toString())),
          if (faqs.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Frequently asked questions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...faqs.map((faq) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(faq))),
          ],
        ]);
      },
    ),
  );
}
