import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class SavedPlacesPage extends StatelessWidget {
  const SavedPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final places = const [
      {'name': 'Home', 'address': 'Makerere Main Gate, Kampala'},
      {'name': 'Work', 'address': 'Kampala City Centre'},
      {'name': 'Gym', 'address': 'Ntinda Shopping Mall'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Places')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          final place = places[index];
          return ListTile(
            leading: const Icon(
              Icons.location_on,
              color: AppTheme.primaryGreen,
            ),
            title: Text(place['name']!),
            subtitle: Text(place['address']!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
          );
        },
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemCount: places.length,
      ),
    );
  }
}
