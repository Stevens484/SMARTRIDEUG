import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/authentication_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/core/services/local_notification_service.dart';
import 'package:smartrideug/features/admin/admin_dashboard_page.dart';
import 'package:smartrideug/features/driver/driver_dashboard_page.dart';
import 'package:smartrideug/features/home/home_page.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({
    super.key,
    this.register = false,
    this.operator = false,
    this.role = 'driver',
  });

  static const routeName = '/auth';
  final bool register;
  final bool operator;
  final String role;

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
<<<<<<< HEAD
  final _name = TextEditingController();
  late bool _register = widget.operator ? false : widget.register;
  late final bool _operator = widget.operator;
  late final String _role = widget.role;
  bool _busy = false;
  bool _passwordVisible = false;

=======
  final _employeeId = TextEditingController();
  late bool _register = widget.register;
  late final bool _operator = widget.operator;
  late final String _role = widget.role;
  bool _busy = false;
  bool _obscurePassword = true;
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _goToRoleHome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String role = 'passenger';
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      role = doc.data()?['role']?.toString() ?? 'passenger';
    }

    if (!mounted) return;

    final Widget destination = switch (role) {
      'admin' => const AdminDashboardPage(),
      'driver' => const DriverDashboardPage(),
      _ => const HomePage(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
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
<<<<<<< HEAD
      if (_register) {
        await auth.registerWithEmail(
          email: _email.text,
          password: _password.text,
        );
      } else {
        if (_operator) {
          await auth.signInWithEmail(_email.text, _password.text, role: _role);
        } else {
          await auth.signInWithEmail(_email.text, _password.text);
        }
      }
      if (!_operator && await auth.claimWelcomeNotification()) {
        await LocalNotificationService.instance.requestPermission();
        await LocalNotificationService.instance.showWelcome();
      }
      await _goToRoleHome();
=======
      final credential = _register
          ? await _registerUser(auth)
          : await _signInUser(auth);
      // Every email/password account is routed from its saved role. The public
      // Login button is also used by administrators and drivers, so treating
      // it as passenger-only would send them to the wrong workspace.
      final role = await auth.roleForUser(credential.user!);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => _dashboardFor(role)),
          (_) => false,
        );
      }
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

<<<<<<< HEAD
  String get _headline {
    if (_operator) {
      return _role == 'admin' ? 'Admin sign in' : 'Driver sign in';
    }
    return _register ? 'Create your account' : 'Welcome back';
  }

  String get _subtitle {
    if (_operator) {
      return 'Staff accounts are created by an administrator.';
    }
    return _register
        ? 'Start riding SmartRide UG.'
        : 'Sign in to continue your journey.';
  }

=======
  Future<dynamic> _registerUser(AuthenticationService auth) {
    if (_operator) {
      return auth.registerWithEmail(
        email: _email.text,
        password: _password.text,
        role: _role,
        employeeId: _employeeId.text,
      );
    }
    return auth.registerWithEmail(
      email: _email.text,
      password: _password.text,
      role: 'passenger',
      employeeId: '',
    );
  }

  Future<dynamic> _signInUser(AuthenticationService auth) {
    if (_operator) {
      return auth.signInWithEmail(
        _email.text,
        _password.text,
        role: _role,
        employeeId: _employeeId.text,
      );
    }
    return auth.signInWithEmail(_email.text, _password.text);
  }

  Widget _dashboardFor(String role) => switch (role) {
    'admin' => const AdminDashboardPage(),
    'driver' => const DriverDashboardPage(),
    _ => const HomePage(),
  };

>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.grey50,
    appBar: AppBar(
      backgroundColor: AppTheme.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
<<<<<<< HEAD
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Card(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 LOGO: Replaced Icon with Image.asset
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      shape: BoxShape.circle,
=======
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
                    Image.asset(
                      'assets/images/logo.png',
                      width: 68,
                      height: 68,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                    ),
                    child: Image.asset(
                      'assets/images/smartride_mark.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _headline,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.grey500),
                  ),
                  const SizedBox(height: 28),

                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _password,
                    obscureText: !_passwordVisible,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _passwordVisible
                            ? 'Hide password'
                            : 'Show password',
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _busy
                            ? 'Please wait...'
                            : _register
                            ? 'Create Account'
                            : 'Sign In',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (!_operator) ...[
                    const SizedBox(height: 12),
<<<<<<< HEAD
=======
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
                      obscureText: _obscurePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: _operator
                            ? 'Password (employee ID for staff accounts)'
                            : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    if (_operator) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _employeeId,
                        decoration: const InputDecoration(
                          labelText: 'Employee ID',
                          helperText:
                              'For accounts added by an admin, use this as the password too.',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Operator role',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        child: Text(
                          _role == 'admin' ? 'Admin' : 'Driver',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _register = !_register),
                      child: Text(
                        _register
                            ? 'Already have an account? Sign in'
                            : 'New to SmartRide UG? Create account',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
