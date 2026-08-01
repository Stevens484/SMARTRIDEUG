import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
<<<<<<< HEAD
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
=======
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:smartrideug/core/theme/app_theme.dart';
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/home/destination_page.dart';
import 'package:smartrideug/features/home/help_support_page.dart';
import 'package:smartrideug/features/home/payment_method_page.dart';
import 'package:smartrideug/features/home/saved_places_page.dart';
import 'package:smartrideug/features/home/booking_status_page.dart';
import 'package:smartrideug/features/home/seat_reservations_page.dart';
import 'package:smartrideug/features/home/settings_page.dart';
import 'package:smartrideug/features/home/modern_home_content.dart';
import 'package:smartrideug/features/map/live_map_screen.dart';
import 'package:smartrideug/features/notifications/notifications_page.dart';
<<<<<<< HEAD
import 'package:smartrideug/core/theme/app_theme.dart';
=======
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

class HomePage extends StatefulWidget {
  final bool guestMode;
  const HomePage({super.key, this.guestMode = false});

  static const routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

<<<<<<< HEAD
  final List<String> _pageTitles = [
    'Smart Ride',
    'My Bookings',
    'Scan',
    'Profile',
  ];
=======
  static const _pageTitles = ['Smart Ride', 'Routes', 'Scan', 'Profile'];
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)

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
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: _selectedIndex == 0
            ? RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(text: 'Smart'),
                    TextSpan(
                      text: 'Ride',
                      style: TextStyle(color: AppTheme.orange),
                    ),
                  ],
                ),
              )
            : Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
<<<<<<< HEAD
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              if (widget.guestMode) {
                _handleGuestAction('notifications');
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
=======
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.navy),
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
<<<<<<< HEAD
                child: widget.guestMode
                    ? const Icon(Icons.person_outline, size: 36)
                    : const Icon(Icons.person, size: 36),
=======
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
<<<<<<< HEAD
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Scan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
=======
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const ModernHomeContent(),
          const LiveMapScreen(),
          const _ScanTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: _ResponsiveBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _ResponsiveBottomNavigation extends StatelessWidget {
  const _ResponsiveBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    (
      label: 'Routes',
      icon: Icons.directions_bus_outlined,
      selectedIcon: Icons.directions_bus_rounded,
    ),
    (
      label: 'Scan',
      icon: Icons.qr_code_scanner,
      selectedIcon: Icons.qr_code_scanner,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final height = isLandscape ? 58.0 : 68.0;

    return SafeArea(
      top: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SizedBox(
          height: height,
          child: Row(
            children: List.generate(
              _items.length,
              (index) => _ResponsiveNavigationItem(
                label: _items[index].label,
                icon: _items[index].icon,
                selectedIcon: _items[index].selectedIcon,
                selected: index == selectedIndex,
                compact: isLandscape,
                onTap: () => onSelected(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveNavigationItem extends StatelessWidget {
  const _ResponsiveNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.orange : AppTheme.navy;
    final iconSize = compact ? 22.0 : 24.0;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 3 : 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: compact ? 36 : 42,
                  height: compact ? 28 : 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFEDD5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    color: color,
                    size: iconSize,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: compact ? 10 : 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          ),
        ),
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
<<<<<<< HEAD
=======
  final bool _hasActiveRide = false;

  List<osm.Marker> _markersFrom(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) {
            final data = doc.data();
            final lat = (data['latitude'] as num?)?.toDouble();
            final lng = (data['longitude'] as num?)?.toDouble();
            if (lat == null || lng == null) return null;
            return osm.Marker(
              point: latlng.LatLng(lat, lng),
              width: 38,
              height: 38,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            );
          })
          .whereType<osm.Marker>()
          .toList();

>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
<<<<<<< HEAD
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
=======
      color: AppTheme.grey50,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header Section with Gradient Background
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting and Bell Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Good afternoon, ',
                          style: TextStyle(
                            color: AppTheme.grey500,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: userName,
                              style: TextStyle(
                                color: AppTheme.grey500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' 👋'),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: AppTheme.orange,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Where are you going today?',
                  style: TextStyle(
                    color: AppTheme.grey900,
                    fontSize: 32,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                // Search Bar with Filter
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
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22,
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
                                  ),
                                  border: InputBorder.none,
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
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.tune, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Current Location Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                border: Border.all(color: AppTheme.grey100),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.orangeSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppTheme.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: TextStyle(
                            color: AppTheme.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userLocation,
                          style: TextStyle(
                            color: AppTheme.navy,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View on Map',
                      style: TextStyle(
                        color: AppTheme.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Nearby Buses Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby Buses',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '5 buses near you',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.25),
                ),
              ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
            // Nearby Buses — now backed by a real live count, tappable
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/live-map'),
              child: Container(
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
                        'assets/images/logo.png',
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
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('busLocations')
                                .where(
                                  'status',
                                  whereIn: [
                                    'online',
                                    'moving',
                                    'approaching_stop',
                                  ],
                                )
                                .snapshots(),
                            builder: (context, snap) {
                              final count = snap.data?.docs.length ?? 0;
                              return Text(
                                count == 1
                                    ? '1 bus online now'
                                    : '$count buses online now',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              );
                            },
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
            ),
            const SizedBox(height: 8),
            // Live Map — one real map preview, backed by real Firestore data
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
<<<<<<< HEAD
                    height: 160,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/live-map'),
                      child: AbsorbPointer(child: _HomeMiniMap()),
=======
                    height: 260,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('busLocations')
                          .where(
                            'status',
                            whereIn: [
                              'online',
                              'moving',
                              'approaching_stop',
                              'stopped',
                            ],
                          )
                          .snapshots(),
                      builder: (context, snapshot) => osm.FlutterMap(
                        options: const osm.MapOptions(
                          initialCenter: latlng.LatLng(0.3476, 32.5825),
                          initialZoom: 13,
                        ),
                        children: [
                          osm.TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.mhl.smartrideug',
                          ),
                          osm.MarkerLayer(
                            markers: snapshot.hasData
                                ? _markersFrom(snapshot.data!)
                                : const [],
                          ),
                        ],
                      ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('busLocations')
                      .where(
                        'status',
                        whereIn: ['online', 'moving', 'approaching_stop'],
                      )
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return Row(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          count == 1 ? '1 bus nearby' : '$count buses nearby',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Upcoming Trips — real data, most recent real booking
            if (!widget.guestMode && user != null)
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
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SeatReservationsPage(),
                          ),
                        ),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('passengerId', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'No upcoming trips yet — search a destination to book one.',
                            style: TextStyle(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.85,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      final booking = docs.first.data();
                      final bookingId = docs.first.id;
                      final routeId = booking['routeId']?.toString();
                      final status = booking['status']?.toString() ?? 'pending';
                      final seats = List<String>.from(
                        booking['seats'] as List? ?? const [],
                      );
                      final fare = booking['fare'];

                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingStatusPage(bookingId: bookingId),
                          ),
                        ),
                        child:
                            FutureBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              future: routeId == null
                                  ? null
                                  : FirebaseFirestore.instance
                                        .collection('routes')
                                        .doc(routeId)
                                        .get(),
                              builder: (context, routeSnap) {
                                final route = routeSnap.data?.data();
                                final origin =
                                    route?['origin']?.toString() ?? '—';
                                final destination =
                                    route?['destination']?.toString() ?? '—';

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.2),
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_bus,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    origin,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.onPrimary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: colorScheme.primary,
                                                  size: 11,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    destination,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.onPrimary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  seats.isEmpty
                                                      ? ''
                                                      : 'Seat ${seats.join(", ")}',
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme.onPrimary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (fare != null) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'UGX $fare',
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.primary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
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
                                          color: colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      );
                    },
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
<<<<<<< HEAD
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
=======
                        subtitle: 'View all your\nbookings',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SeatReservationsPage(),
                          ),
                        ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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

/// Small, real, live preview map shown on the Home tab. Read-only —
/// tapping anywhere navigates to the full LiveMapScreen instead of
/// interacting with this map directly.
class _HomeMiniMap extends StatelessWidget {
  const _HomeMiniMap();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('busLocations')
          .where('status', whereIn: ['online', 'moving', 'approaching_stop'])
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final points = docs
            .map((d) {
              final lat = (d.data()['latitude'] as num?)?.toDouble();
              final lng = (d.data()['longitude'] as num?)?.toDouble();
              return (lat != null && lng != null) ? LatLng(lat, lng) : null;
            })
            .whereType<LatLng>()
            .toList();

        if (points.isEmpty) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 36, color: Colors.grey),
                  SizedBox(height: 6),
                  Text(
                    'No buses online right now',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final center = points.first;
        return FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.mhl.smart_ride_ug',
            ),
            MarkerLayer(
              markers: points
                  .map(
                    (p) => Marker(
                      point: p,
                      width: 26,
                      height: 26,
                      child: const Icon(
                        Icons.directions_bus,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Sign in to view your bookings.'));
    }

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
<<<<<<< HEAD
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('passengerId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Text('No bookings yet — go book a seat!');
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final status = data['status']?.toString() ?? 'pending';
                final seats = List<String>.from(
                  data['seats'] as List? ?? const [],
                );
                IconData icon;
                switch (status) {
                  case 'confirmed':
                    icon = Icons.check_circle;
                    break;
                  case 'cancelled':
                    icon = Icons.cancel;
                    break;
                  default:
                    icon = Icons.hourglass_top;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StatusCard(
                    title: status[0].toUpperCase() + status.substring(1),
                    subtitle: seats.isEmpty
                        ? 'Booking ${doc.id.substring(0, 6)}'
                        : 'Seats: ${seats.join(", ")}',
                    status: status == 'pending'
                        ? 'Waiting for confirmation'
                        : status,
                    icon: icon,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingStatusPage(bookingId: doc.id),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
=======
        _StatusCard(
          title: 'Pending ride',
          subtitle: 'BUS 101 • Makerere → Ntinda',
          status: 'Waiting for confirmation',
          icon: Icons.hourglass_top,
        ),
        const SizedBox(height: 16),
        _StatusCard(
          title: 'Confirmed ride',
          subtitle: 'BUS 215 • City Centre → Entebbe',
          status: 'Reserved seat 16',
          icon: Icons.event_seat,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SeatReservationsPage()),
          ),
          child: const Text('Open booking details'),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Text(status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
