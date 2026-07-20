import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class SavedPlacesPage extends StatelessWidget {
  const SavedPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Places')),
        body: const Center(child: Text('Sign in to view your saved places.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Places')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('savedPlaces')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final places = snapshot.data!.docs;
          if (places.isEmpty) {
            return const Center(child: Text('You have no saved places yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: places.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final place = places[index].data();
              return ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryGreen,
                ),
                title: Text(place['name']?.toString() ?? 'Unnamed place'),
                subtitle: Text(
                  place['address']?.toString() ?? 'No address provided',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              );
            },
          );
        },
      ),
    );
  }
}
