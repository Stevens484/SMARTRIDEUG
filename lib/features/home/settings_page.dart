import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/theme_notifier.dart';
import 'package:smartrideug/features/home/journey_ratings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> _editProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final profile = await _db.collection('users').doc(user.uid).get();
    if (!mounted) return;
    final data = profile.data() ?? const <String, dynamic>{};
    final name = TextEditingController(
      text:
          data['name']?.toString() ??
          data['displayName']?.toString() ??
          user.displayName ??
          '',
    );
    final phone = TextEditingController(text: data['phone']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profile details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final fullName = name.text.trim();
      if (fullName.isEmpty ||
          fullName.length > 120 ||
          phone.text.trim().length > 40) {
        _show('Enter a name and a valid phone number.');
      } else {
        try {
          await user.updateDisplayName(fullName);
          await _db.collection('users').doc(user.uid).set({
            'name': fullName,
            'displayName': fullName,
            'phone': phone.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          _show('Profile details updated.');
        } on FirebaseException catch (error) {
          _show(error.message ?? 'Unable to update your profile.');
        }
      }
    }
    name.dispose();
    phone.dispose();
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user?.email == null) {
      _show('Password changes are unavailable for this sign-in method.');
      return;
    }
    final current = TextEditingController();
    final replacement = TextEditingController();
    final confirm = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: replacement,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (submitted == true) {
      if (replacement.text.length < 6 || replacement.text != confirm.text) {
        _show('Use matching new passwords of at least 6 characters.');
      } else {
        try {
          final credential = EmailAuthProvider.credential(
            email: user!.email!,
            password: current.text,
          );
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(replacement.text);
          _show('Password changed successfully.');
        } on FirebaseAuthException catch (error) {
          _show(error.message ?? 'Unable to change password.');
        }
      }
    }
    current.dispose();
    replacement.dispose();
    confirm.dispose();
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.displayName ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile details'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Display name'),
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
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      final name = nameController.text.trim();
      try {
        await user.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
        }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email on this account.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send reset link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile details'),
<<<<<<< HEAD
=======
            subtitle: Text(_auth.currentUser?.email ?? ''),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
            trailing: const Icon(Icons.chevron_right),
            onTap: _editProfile,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
<<<<<<< HEAD
=======
          ),
          const SizedBox(height: 24),
          const Text(
            'Journey feedback',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate a journey'),
            subtitle: const Text('Rate the journey, driver, and bus'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JourneyRatingsPage()),
            ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          ),
        ],
      ),
    );
  }
}
