import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    final methods = const [
      {'title': 'Personal Visa', 'subtitle': '**** **** **** 1234'},
      {'title': 'Mobile Money', 'subtitle': 'MTN Mobile Money'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: methods.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == methods.length) {
            return OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add payment method'),
              onPressed: () {},
            );
          }
          final method = methods[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.payment, color: AppTheme.primaryGreen),
              title: Text(method['title']!),
              subtitle: Text(method['subtitle']!),
            ),
          );
        },
      ),
    );
  }
}
