import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  CollectionReference<Map<String, dynamic>> _methods(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('paymentMethods');

  Future<void> _addMomo(BuildContext context, String uid) async {
    final phone = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add MTN MoMo'),
        content: TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'MTN mobile number',
            hintText: '0770 000 000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    if (saved != true || digits.length < 9) {
      phone.dispose();
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid MTN mobile number.')),
        );
      }
      return;
    }
    final methods = _methods(uid);
    final existing = await methods.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final method in existing.docs) {
      batch.update(method.reference, {
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(methods.doc(), {
      'provider': 'mtn_momo_simulated',
      'title': 'MTN MoMo',
      'phone': phone.text.trim(),
      'subtitle': 'MTN number ending ${digits.substring(digits.length - 4)}',
      'isDefault': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    phone.dispose();
  }

  Future<void> _makeDefault(
    String uid,
    DocumentReference<Map<String, dynamic>> selected,
  ) async {
    final methods = await _methods(uid).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final method in methods.docs) {
      batch.update(method.reference, {
        'isDefault': method.reference.path == selected.path,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to manage payment methods.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Payment method')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _methods(
          uid,
        ).orderBy('createdAt', descending: true).snapshots(),
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
