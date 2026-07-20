import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  static const routeName = '/';
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  int _taps = 0;
  void _tap() {
    setState(() => _taps++);
    if (_taps == 5) _showOperators();
  }

  void _showOperators() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Operator access',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Choose your operational workspace.'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(
                        register: false,
                        operator: true,
                        role: 'admin',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_eta),
                title: const Text('Driver dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(
                        register: false,
                        operator: true,
                        role: 'driver',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: InkWell(
      onTap: _tap,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                child: IntrinsicHeight(
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 96,
                ),
                const SizedBox(height: 16),
                const Text(
                  'SmartRide UG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live, reliable city travel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(register: true),
                    ),
                  ),
                  child: const Text('Get started'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  child: const Text('Login'),
                ),
              ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
