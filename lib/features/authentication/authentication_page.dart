import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/authentication_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/home_page.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key, this.register = false});
  static const routeName = '/auth';
  final bool register;
  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _email = TextEditingController(), _password = TextEditingController();
  late bool _register = widget.register;
  bool _busy = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter an email and a password of at least 6 characters.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = AuthenticationService();
      if (_register) {
        await auth.registerWithEmail(_email.text, _password.text);
      } else {
        await auth.signInWithEmail(_email.text, _password.text);
      }
      if (mounted)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(HomePage.routeName, (_) => false);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      size: 68,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _register ? 'Create your account' : 'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _register
                          ? 'Start riding SmartRide UG.'
                          : 'Sign in to continue your journey.',
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(
                          _busy
                              ? 'Please wait...'
                              : _register
                              ? 'Register'
                              : 'Login',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _register = !_register),
                      child: Text(
                        _register
                            ? 'Already have an account? Login'
                            : 'New to SmartRide UG? Register',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
