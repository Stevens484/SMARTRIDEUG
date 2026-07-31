import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentMethodPage extends StatelessWidget {
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Your default method is used for the simulated checkout.',
              ),
              const SizedBox(height: 12),
              ...methods.map((method) {
                final data = method.data();
                final isDefault = data['isDefault'] == true;
                return Card(
                  child: ListTile(
                    onTap: isDefault
                        ? null
                        : () => _makeDefault(uid, method.reference),
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFFFC107),
                    ),
                    title: Text(data['title']?.toString() ?? 'MTN MoMo'),
                    subtitle: Text(data['subtitle']?.toString() ?? ''),
                    trailing: isDefault
                        ? const Chip(label: Text('Default'))
                        : const Text('Set default'),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () => _addMomo(context, uid),
                icon: const Icon(Icons.add),
                label: const Text('Add MTN MoMo number'),
              ),
            ],
          );
        },
      ),
    );
  }
}
