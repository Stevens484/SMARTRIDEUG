import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:smartrideug/core/services/authentication_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartrideug/core/services/authentication_service.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/admin/admin_dashboard_page.dart';
import 'package:smartrideug/features/driver/driver_dashboard_page.dart';
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
import 'package:smartrideug/features/home/home_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const routeName = '/';
<<<<<<< HEAD

  Future<void> _continueAsGuest(BuildContext context) async {
    try {
      await AuthenticationService().signInAnonymously();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage(guestMode: true)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Guest login failed: $error')));
    }
  }

  void _openAuth(BuildContext context, {bool register = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuthenticationPage(register: register)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/landing.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBF0B1F3A),
                  Color(0xC7102B4E),
                  Color(0xCF16365F),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => _LandingLayout(
                constraints: constraints,
                onGuest: () => _continueAsGuest(context),
                onGetStarted: () => _openAuth(context, register: true),
                onLogin: () => _openAuth(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingLayout extends StatelessWidget {
  const _LandingLayout({
    required this.constraints,
    required this.onGuest,
    required this.onGetStarted,
    required this.onLogin,
  });

  final BoxConstraints constraints;
  final VoidCallback onGuest;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final landscape = constraints.maxWidth > constraints.maxHeight;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: landscape ? 24 : 20,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
        child: landscape ? _landscapeLayout() : _portraitLayout(),
      ),
    );
  }

  Widget _brand({bool compact = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 250 : 340,
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: .4),
            width: 1,
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF1A1A3A),
                Color(0xFF0A0E1A),
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF10B981),
              ],
              stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
            ),
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

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 15,
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
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
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
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

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
                    foregroundColor: const Color(0xFF10B981),
                    elevation: 6,
                    shadowColor: Colors.white.withValues(alpha: 0.2),
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
=======
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  int _taps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  Future<void> _restoreSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final String role;
    try {
      role = await AuthenticationService().roleForUser(user);
    } catch (_) {
      // Do not assume passenger when an operator's role cannot be verified.
      // That would open the wrong workspace for an admin or driver.
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not verify your account role. Please sign in again.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => _dashboardFor(role)));
  }

  Widget _dashboardFor(String role) => switch (role) {
    'admin' => const AdminDashboardPage(),
    'driver' => const DriverDashboardPage(),
    _ => const HomePage(),
  };

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/landing.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x4D0F2345), Color(0xB30F2345)],
              ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    MediaQuery.orientationOf(context) == Orientation.landscape;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Align(
                          child: FractionallySizedBox(
                            widthFactor: isLandscape ? .48 : .88,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .94),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                'assets/images/smartride_wordmark.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AuthenticationPage(
                                        register: true,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Get started'),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AuthenticationPage(),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white70,
                                    ),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: .08,
                                    ),
                                  ),
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ],
),
  );

  Widget _portraitLayout() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [_brand(), const SizedBox(height: 28), _actions()],
  );

  Widget _landscapeLayout() => Row(
    children: [
      Expanded(child: Center(child: _brand(compact: true))),
      const SizedBox(width: 24),
      Expanded(flex: 2, child: Center(child: _actions(compact: true))),
    ],
  );

  Widget _actions({bool compact = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Label('GUEST', compact: compact),
      SizedBox(height: compact ? 6 : 12),
      _LandingButton(
        icon: Icons.person_outline_rounded,
        label: 'Continue as Guest',
        outlined: true,
        compact: compact,
        onPressed: onGuest,
      ),
      SizedBox(height: compact ? 4 : 10),
      Text(
        'Explore live bus locations without${compact ? ' ' : '\n'}creating an account.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: compact ? 12 : 16,
          height: 1.55,
        ),
      ),
      SizedBox(height: compact ? 8 : 18),
      Row(
        children: [
          const Expanded(child: Divider(color: Color(0x66FFFFFF))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 26),
            child: _Label('OR', compact: compact),
          ),
          const Expanded(child: Divider(color: Color(0x66FFFFFF))),
        ],
      ),
      SizedBox(height: compact ? 8 : 18),
      _LandingButton(
        icon: Icons.rocket_launch_outlined,
        label: 'Get Started',
        compact: compact,
        onPressed: onGetStarted,
      ),
      SizedBox(height: compact ? 4 : 10),
      Text(
        'Create an account to book rides,${compact ? ' ' : '\n'}save locations and more',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: compact ? 12 : 16,
          height: 1.55,
        ),
      ),
      SizedBox(height: compact ? 8 : 16),
      _LandingButton(
        icon: Icons.login_rounded,
        label: 'Login',
        outlined: true,
        compact: compact,
        onPressed: onLogin,
      ),
      SizedBox(height: compact ? 4 : 10),
      Text(
        'Already have an account? Login to continue',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: compact ? 11 : 15),
      ),
    ],
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.compact = false});
  final String text;
  final bool compact;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Colors.white70,
      letterSpacing: 2,
      fontSize: compact ? 12 : 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _LandingButton extends StatelessWidget {
  const _LandingButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final bool compact;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: compact ? 20 : 24),
            label: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(Icons.rocket_launch_outlined, size: compact ? 20 : 24),
            label: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
  );
}
