import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
=======
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const routeName = '/notifications';

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Could not load notifications.'));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();
                final read = data['read'] == true;
                final title = data['title']?.toString() ?? '';
                final body = data['body']?.toString() ?? '';

                return ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: read
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(body),
                  trailing: read
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () {
                    if (!read) {
                      doc.reference.update({'read': true});
                    }
                  },
                );
              },
=======
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Notifications are unavailable.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data!.docs.where((document) {
          final audience = document.data()['audience']?.toString();
          return audience == null ||
              audience == 'all' ||
              audience == 'passengers';
        }).toList()..sort((a, b) => _date(b.data()).compareTo(_date(a.data())));
        if (notifications.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No announcements yet.'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final data = notifications[index].data();
            final createdAt = _date(data);
            return ListTile(
              leading: Icon(
                data['type']?.toString() == 'promotion'
                    ? Icons.local_offer_outlined
                    : Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(data['title']?.toString() ?? 'SmartRide update'),
              subtitle: Text(data['body']?.toString() ?? ''),
              trailing: Text(
                '${createdAt.day}/${createdAt.month}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
            );
          },
        );
      },
    ),
  );

  static DateTime _date(Map<String, dynamic> data) {
    final value = data['publishedAt'] ?? data['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
