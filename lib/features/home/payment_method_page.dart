import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Method')),
        body: const Center(child: Text('Sign in to view payment methods.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('paymentMethods')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final methods = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: methods.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == methods.length) {
                return OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add payment method'),
                  onPressed: () {},
                );
              }

              final method = methods[index].data();
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.payment,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(method['title']?.toString() ?? 'Payment method'),
                  subtitle: Text(method['subtitle']?.toString() ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
