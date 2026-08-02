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

  Future<void> _openProfileDetails() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _ProfileDetailsPage()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text('Dark mode'),
            subtitle: const Text('Use the darker SmartRide colour scheme'),
            value: isDarkMode,
            onChanged: (value) {
              themeNotifier.toggleTheme(value);
              setState(() {});
            },
            secondary: const Icon(Icons.dark_mode_outlined),
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

class _ProfileDetailsPage extends StatefulWidget {
  const _ProfileDetailsPage();

  @override
  State<_ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<_ProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to update your profile.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await user.updateDisplayName(_nameController.text.trim());
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile details updated.')));
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to update your profile. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile details')),
      body: SafeArea(
        child: user == null
            ? const _SignInRequired(message: 'Sign in to view your profile.')
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 42,
                        foregroundImage: user.photoURL == null
                            ? null
                            : NetworkImage(user.photoURL!),
                        child: user.photoURL == null
                            ? const Icon(Icons.person_outline, size: 42)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the name shown on your profile.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user.email ?? 'No email address available',
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: user.emailVerified
                            ? const Tooltip(
                                message: 'Email verified',
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: Colors.green,
                                ),
                              )
                            : const Tooltip(
                                message: 'Email not verified',
                                child: Icon(Icons.info_outline),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your display name appears across SmartRide, including the home greeting.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      _ErrorMessage(_error!),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      setState(
        () => _error = 'Sign in with an email account to change a password.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been changed.')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to change your password. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasPasswordProvider =
        user?.providerData.any(
          (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: user == null
            ? const _SignInRequired(message: 'Sign in to change your password.')
            : !hasPasswordProvider
            ? const _ProviderManagedPassword()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Choose a strong new password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For your security, confirm your current password before making this change.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 26),
                    _PasswordField(
                      controller: _currentPasswordController,
                      label: 'Current password',
                      obscureText: _hideCurrentPassword,
                      onVisibilityChanged: () => setState(
                        () => _hideCurrentPassword = !_hideCurrentPassword,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your current password.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      controller: _newPasswordController,
                      label: 'New password',
                      obscureText: _hideNewPassword,
                      onVisibilityChanged: () =>
                          setState(() => _hideNewPassword = !_hideNewPassword),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Use at least 6 characters.';
                        }
                        if (value == _currentPasswordController.text) {
                          return 'Choose a different password.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm new password',
                      obscureText: _hideNewPassword,
                      onVisibilityChanged: () =>
                          setState(() => _hideNewPassword = !_hideNewPassword),
                      validator: (value) => value != _newPasswordController.text
                          ? 'Passwords do not match.'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      _ErrorMessage(_error!),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _isSaving ? null : _changePassword,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Change password'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onVisibilityChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onVisibilityChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: obscureText ? 'Show password' : 'Hide password',
        onPressed: onVisibilityChanged,
        icon: Icon(
          obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: validator,
  );
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_person_outlined, size: 56),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ProviderManagedPassword extends StatelessWidget {
  const _ProviderManagedPassword();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_circle_outlined, size: 56),
          SizedBox(height: 16),
          Text(
            'This account uses an external sign-in provider. Manage your password with that provider.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  );
}

String _messageFor(FirebaseAuthException error) {
  switch (error.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'Your current password is incorrect.';
    case 'weak-password':
      return 'Choose a stronger password and try again.';
    case 'requires-recent-login':
      return 'Sign in again, then retry this security-sensitive change.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Check your internet connection and try again.';
    default:
      return error.message ?? 'Something went wrong. Please try again.';
  }
}
