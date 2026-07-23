import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/core/services/authentication_service.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/home/home_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  static const routeName = '/';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/landing_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryDark.withOpacity(0.85),
                AppTheme.primary.withOpacity(0.8),
                const Color(0xFF10B981).withOpacity(0.85),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const SizedBox(height: 20),

                // 🔥 LOGO
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'SmartRide UG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live, reliable city travel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 40),

                // GUEST
                _sectionLabel('GUEST'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await AuthenticationService().signInAnonymously();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomePage(guestMode: true),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Guest login failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore the map and bus locations without signing up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 24),

                // PASSENGER
                _sectionLabel('PASSENGER'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    elevation: 6,
                    shadowColor: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: const Text(
                    'Passenger Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(register: true),
                    ),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text(
                    'Register as passenger',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),

                const SizedBox(height: 24),

                // DRIVER
                _sectionLabel('DRIVER'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(
                        operator: true,
                        role: 'driver',
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 2),
                    elevation: 2,
                  ),
                  child: const Text('Driver Login'),
                ),

                const SizedBox(height: 24),

                // ADMIN
                _sectionLabel('ADMIN'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(
                        operator: true,
                        role: 'admin',
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 2),
                    elevation: 2,
                  ),
                  child: const Text('Admin Login'),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    ),
  );
}
