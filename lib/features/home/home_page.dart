import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/home/destination_page.dart';
import 'package:smartrideug/features/home/help_support_page.dart';
import 'package:smartrideug/features/home/payment_method_page.dart';
import 'package:smartrideug/features/home/saved_places_page.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';
import 'package:smartrideug/features/home/seat_reservations_page.dart';
import 'package:smartrideug/features/home/settings_page.dart';
import 'package:smartrideug/features/notifications/notifications_page.dart';
import 'package:smartrideug/features/home/home_dashboard.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final bool guestMode;
  const HomePage({super.key, this.guestMode = false});

  static const routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    'Smart Ride',
    'My Bookings',
    'Scan',
    'Profile',
  ];

  void _handleGuestAction(String feature) {
    if (!widget.guestMode) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in required'),
        content: Text('Please sign in or register to access $feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthenticationPage()),
              );
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: AppTheme.navy,
        elevation: 0,
        toolbarHeight: 74,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _selectedIndex == 0
            ? RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 27,
                    letterSpacing: -1.1,
                  ),
                  children: const [
                    TextSpan(text: 'Smart'),
                    TextSpan(
                      text: 'Ride',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ],
                ),
              )
            : Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: const [
                Icon(Icons.notifications_none_rounded, size: 28),
                Positioned(
                  right: 1,
                  top: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppTheme.navy, width: 1.5),
                      ),
                    ),
                    child: SizedBox(width: 10, height: 10),
                  ),
                ),
              ],
            ),
            onPressed: () {
              if (widget.guestMode) {
                _handleGuestAction('notifications');
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.guestMode
                    ? 'Guest User'
                    : FirebaseAuth.instance.currentUser?.displayName ??
                          'SmartRide passenger',
              ),
              accountEmail: Text(
                widget.guestMode
                    ? 'Sign up to access full features'
                    : FirebaseAuth.instance.currentUser?.email ?? '',
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundImage: widget.guestMode
                    ? null
                    : FirebaseAuth.instance.currentUser?.photoURL != null
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                child: widget.guestMode
                    ? const Icon(Icons.person_outline, size: 36)
                    : const Icon(Icons.person, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Saved places'),
              onTap: () {
                Navigator.pop(context);
                if (widget.guestMode) {
                  _handleGuestAction('saved places');
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedPlacesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('My bookings'),
              onTap: () {
                Navigator.pop(context);
                if (widget.guestMode) {
                  _handleGuestAction('bookings');
                  return;
                }
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_seat),
              title: const Text('Seat reservations'),
              onTap: () {
                Navigator.pop(context);
                if (widget.guestMode) {
                  _handleGuestAction('seat reservations');
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SeatReservationsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment method'),
              onTap: () {
                Navigator.pop(context);
                if (widget.guestMode) {
                  _handleGuestAction('payment methods');
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaymentMethodPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                if (widget.guestMode) {
                  _handleGuestAction('notifications');
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
            const Divider(),
            if (widget.guestMode)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Sign in / Register'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthenticationPage(),
                    ),
                  );
                },
              ),
            if (!widget.guestMode)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AuthenticationPage.routeName);
                },
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeDashboard(
              guestMode: widget.guestMode,
              onGuestAction: _handleGuestAction,
            ),
            widget.guestMode
                ? _GuestRestrictedTab(
                    title: 'Bookings',
                    icon: Icons.book,
                    onTap: () => _handleGuestAction('bookings'),
                  )
                : const _BookingsTab(),
            widget.guestMode
                ? _GuestRestrictedTab(
                    title: 'Scan',
                    icon: Icons.qr_code,
                    onTap: () => _handleGuestAction('QR scanning'),
                  )
                : const _ScanTab(),
            widget.guestMode
                ? _GuestRestrictedTab(
                    title: 'Profile',
                    icon: Icons.person,
                    onTap: () => _handleGuestAction('profile'),
                  )
                : const ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        height: 78,
        backgroundColor: AppTheme.navy,
        indicatorColor: const Color(0xFF233D60),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 28),
            selectedIcon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined, size: 28),
            selectedIcon: Icon(Icons.book, size: 28),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner, size: 28),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 28),
            selectedIcon: Icon(Icons.person, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🔥 GUEST RESTRICTED TAB
// ============================================================
class _GuestRestrictedTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GuestRestrictedTab({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              '$title not available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access your $title',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onTap, child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🔥 HOME CONTENT — FIXED
// ============================================================
class _HomeContent extends StatefulWidget {
  final bool guestMode;
  const _HomeContent({required this.guestMode});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final userName = widget.guestMode
        ? 'Guest'
        : user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? 'SmartRide rider';
    final userLocation = widget.guestMode
        ? 'Your current location'
        : user?.email ?? 'Your area';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primary,
            colorScheme.surface,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: widget.guestMode
                                ? 'Welcome, '
                                : 'Good Morning, ',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: userName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: widget.guestMode ? ' 🚀' : ' 👋'),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.guestMode
                        ? 'Explore buses near you without signing up'
                        : 'Where are you going today?',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search destination...',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const DestinationPage(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.tune,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Current Location
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            userLocation,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/live-map');
                        },
                        child: Text(
                          'View on Map',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Nearby Buses
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/smartride_mark.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby Buses',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '5 buses near you',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Route Map Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: 0.9,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    top: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.35,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_pin,
                                            size: 14,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Kampala',
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Icon(
                                      Icons.map,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                      size: 48,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route map',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Kampala to Mbarara',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '5 active buses',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 🔥 FIX 1: Live Map Section with VISIBLE View Full Map button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Map',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    // 🔥 NEW: White Gradient Button — VISIBLE!
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surface,
                            colorScheme.surfaceContainerHighest,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/live-map');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'View Full Map',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 160,
                    child: Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map,
                              size: 36,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tap "View Full Map" to see live buses',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: colorScheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '5 buses nearby',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 🔥 FIX 2: Upcoming Trips — NO OVERFLOW
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Trips',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 🔥 FIX: Smaller, tighter trip card
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Image.asset(
                          'assets/images/smartride_mark.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Kampala',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  color: colorScheme.primary,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Mbarara',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.8),
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '17 May 2025',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.8),
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.schedule,
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.8),
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '10:30 AM',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.8),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Seat A12',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'UGX 25,000',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Confirmed',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Your Tools
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Tools',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.book,
                        title: 'Bookings',
                        subtitle: widget.guestMode
                            ? 'Sign up to book'
                            : 'View all your\nbookings',
                        onTap: () {
                          if (widget.guestMode) {
                            _showSignUpDialog(context);
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SeatReservationsPage(),
                            ),
                          );
                        },
                        guestMode: widget.guestMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.star,
                        title: 'Saved Places',
                        subtitle: widget.guestMode
                            ? 'Sign up to save'
                            : 'Your favorite routes\nand locations',
                        onTap: () {
                          if (widget.guestMode) {
                            _showSignUpDialog(context);
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SavedPlacesPage(),
                            ),
                          );
                        },
                        guestMode: widget.guestMode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Promotional Banner
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Travel Smart with',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SmartRide UG',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.guestMode
                              ? 'Sign up now to book seats and track your trips.'
                              : 'Book, track and travel with ease.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.85),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.asset(
                      'assets/images/smartride_mark.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSignUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign up required'),
        content: const Text('Create a free account to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthenticationPage()),
              );
            },
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool guestMode;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.guestMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: guestMode ? 0.05 : 0.08),
          border: Border.all(
            color: guestMode
                ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: guestMode ? 0.1 : 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: guestMode
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: guestMode ? 0.4 : 0.72,
                ),
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Track the status of your next rides and see recent activity.',
          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        _BookingList(colorScheme: colorScheme),
        /*
        _StatusCard(
          title: 'Pending ride',
          subtitle: 'BUS 101 • Makerere → Ntinda',
          status: 'Waiting for confirmation',
          icon: Icons.hourglass_top,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SeatReservationsPage()),
          ),
          child: const Text('Open booking details'),
        ),
        */
      ],
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Sign in to view your bookings.')),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TransitRepository().myBookings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Your bookings could not be loaded. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final bookings = snapshot.data!.docs.toList()
          ..sort(
            (left, right) =>
                _bookingTime(right.data()).compareTo(_bookingTime(left.data())),
          );
        if (bookings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 56,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                const Text('You do not have any bookings yet.'),
              ],
            ),
          );
        }

        return Column(
          children: bookings
              .map(
                (document) => _LiveBookingCard(
                  bookingId: document.id,
                  booking: document.data(),
                ),
              )
              .toList(),
        );
      },
    );
  }

  static DateTime _bookingTime(Map<String, dynamic> booking) {
    final updatedAt = booking['updatedAt'];
    final createdAt = booking['createdAt'];
    if (updatedAt is Timestamp) return updatedAt.toDate();
    if (createdAt is Timestamp) return createdAt.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _LiveBookingCard extends StatelessWidget {
  const _LiveBookingCard({required this.bookingId, required this.booking});

  final String bookingId;
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = booking['status']?.toString() ?? 'unknown';
    final statusInfo = _bookingStatus(status, colors);
    final seats = (booking['seats'] as List<dynamic>? ?? const [])
        .map((seat) => seat.toString())
        .join(', ');
    final busNumber = booking['busNumber']?.toString().trim();
    final routeName = booking['routeName']?.toString().trim();
    final pickupName = booking['pickupStopName']?.toString().trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingStatusPage(bookingId: bookingId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusInfo.color.withValues(alpha: 0.14),
                    child: Icon(statusInfo.icon, color: statusInfo.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      busNumber?.isNotEmpty == true
                          ? 'Bus $busNumber'
                          : 'Bus details unavailable',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(statusInfo.label),
                    labelStyle: TextStyle(
                      color: statusInfo.color,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: statusInfo.color.withValues(alpha: 0.12),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailLine(
                context,
                Icons.route_outlined,
                routeName?.isNotEmpty == true
                    ? routeName!
                    : 'Route unavailable',
              ),
              const SizedBox(height: 8),
              _detailLine(
                context,
                Icons.location_on_outlined,
                pickupName?.isNotEmpty == true
                    ? 'Pickup: $pickupName'
                    : 'Pickup stop unavailable',
              ),
              const SizedBox(height: 8),
              _detailLine(
                context,
                Icons.event_seat_outlined,
                seats.isNotEmpty ? 'Seat(s): $seats' : 'Seat unavailable',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'UGX ${booking['fare'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    status == 'confirmed' ? 'View ticket' : 'View booking',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _detailLine(BuildContext context, IconData icon, String text) =>
      Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      );

  static _BookingStatusInfo _bookingStatus(String status, ColorScheme scheme) =>
      switch (status) {
        'confirmed' => const _BookingStatusInfo(
          'Confirmed',
          Icons.check_circle_outline,
          Colors.green,
        ),
        'pending_confirmation' => _BookingStatusInfo(
          'Awaiting bus',
          Icons.hourglass_top_outlined,
          Colors.orange.shade800,
        ),
        'cancelled' => _BookingStatusInfo(
          'Cancelled',
          Icons.cancel_outlined,
          scheme.error,
        ),
        'expired' => _BookingStatusInfo(
          'Expired',
          Icons.timer_off_outlined,
          scheme.onSurfaceVariant,
        ),
        _ => _BookingStatusInfo(
          'Updated',
          Icons.info_outline,
          scheme.onSurfaceVariant,
        ),
      };
}

class _BookingStatusInfo {
  const _BookingStatusInfo(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _ScanTab extends StatefulWidget {
  const _ScanTab();
  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  bool _handled = false;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: MobileScanner(
          onDetect: (capture) async {
            if (_handled) return;
            final value = capture.barcodes.isEmpty
                ? null
                : capture.barcodes.first.rawValue;
            if (value == null) return;
            _handled = true;
            await FirebaseFirestore.instance.collection('scanEvents').add({
              'value': value,
              'userId': FirebaseAuth.instance.currentUser?.uid,
              'scannedAt': FieldValue.serverTimestamp(),
            });
            if (mounted) {
              ScaffoldMessenger.of(
                this.context,
              ).showSnackBar(const SnackBar(content: Text('Ticket scanned.')));
            }
          },
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Point your camera at the booking QR code to verify boarding.',
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _uploadPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (image == null || user == null) return;
    final ref = FirebaseStorage.instance.ref('profilePhotos/${user.uid}.jpg');
    await ref.putData(
      await image.readAsBytes(),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    await user.updatePhotoURL(url);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundImage: user?.photoURL == null
                    ? null
                    : NetworkImage(user!.photoURL!),
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: IconButton.filled(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _uploadPhoto,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : 'SmartRide passenger',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _ProfileLinkTile(
          icon: Icons.bookmark,
          title: 'Saved places',
          subtitle: 'Manage your favorite stops',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SavedPlacesPage())),
        ),
        _ProfileLinkTile(
          icon: Icons.event_seat,
          title: 'Seat reservations',
          subtitle: 'See your reserved seats',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SeatReservationsPage()),
          ),
        ),
        _ProfileLinkTile(
          icon: Icons.payment,
          title: 'Payment method',
          subtitle: 'Update cards and wallet settings',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PaymentMethodPage())),
        ),
        _ProfileLinkTile(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'View recent alerts',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
        ),
        _ProfileLinkTile(
          icon: Icons.help_outline,
          title: 'Help & support',
          subtitle: 'Get assistance and FAQs',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HelpSupportPage())),
        ),
        _ProfileLinkTile(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'Switch theme and preferences',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _ProfileLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
