import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/theme_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: isDarkMode,
            onChanged: (value) {
              themeNotifier.toggleTheme(value);
              setState(() {});
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const SizedBox(height: 24),
          const Text(
            'Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile details'),
          ),
          const ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change password'),
          ),
        ],
      ),
    );
  }
}
