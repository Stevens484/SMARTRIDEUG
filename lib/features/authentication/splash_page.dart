import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/authentication_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/home/home_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const routeName = '/';

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
          Image.asset('assets/images/landscreen.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE60B1F3A),
                  Color(0xED102B4E),
                  Color(0xF516365F),
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
        child: Image.asset(
          'assets/images/smartride_wordmark.png',
          fit: BoxFit.contain,
        ),
      ),
    ],
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
