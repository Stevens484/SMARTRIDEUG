import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  Future<void> _addMethod(String uid) async {
    final phoneController = TextEditingController();
    String provider = 'MTN Mobile Money';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add payment method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: provider,
                decoration: const InputDecoration(labelText: 'Provider'),
                items: const [
                  DropdownMenuItem(
                    value: 'MTN Mobile Money',
                    child: Text('MTN Mobile Money'),
                  ),
                  DropdownMenuItem(
                    value: 'Airtel Money',
                    child: Text('Airtel Money'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => provider = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && phoneController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('paymentMethods')
          .add({
            'title': provider,
            'subtitle': phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
  }

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
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == methods.length) {
                return OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add payment method'),
                  onPressed: () => _addMethod(uid),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => methods[index].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
