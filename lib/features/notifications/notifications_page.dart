import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Booking confirmed',
        'body': 'Your booking for BUS 101 is confirmed.',
      },
      {'title': 'Seat available', 'body': 'A seat opened up on BUS 104.'},
      {'title': 'Promo', 'body': 'Get 10% off on weekend rides.'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final n = notifications[i];
            return ListTile(
              leading: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(n['title']!),
              subtitle: Text(n['body']!),
              onTap: () {},
            );
          },
        ),
      ),
    );
  }
}
