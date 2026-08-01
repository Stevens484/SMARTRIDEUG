import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:smartrideug/core/services/authentication_service.dart';
=======
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
import 'package:smartrideug/core/services/report_service.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/core/theme/theme_notifier.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/admin/management_page.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthenticationPage.routeName, (_) => false);
    }
  }

  Future<void> _report(
    BuildContext context,
    String type,
    Duration duration,
  ) async {
    final end = DateTime.now();
    try {
      await ReportService().createReport(
        type: type,
        start: end.subtract(duration),
        end: end,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$type report created.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not create report: $e')));
      }
    }
  }

  void _openAddStaffSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddStaffSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin dashboard'),
      actions: [
        IconButton(
<<<<<<< HEAD
          icon: const Icon(Icons.person_add_alt_1),
          tooltip: 'Add Staff',
          onPressed: () => _openAddStaffSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            }
          },
=======
          tooltip: Theme.of(context).brightness == Brightness.dark
              ? 'Use light mode'
              : 'Use dark mode',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => themeNotifier.toggleTheme(
            Theme.of(context).brightness != Brightness.dark,
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('busLocations').snapshots(),
      builder: (context, snapshot) {
        const liveStatuses = {'active', 'online', 'moving', 'approaching_stop'};
        final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
        final liveBuses = (snapshot.data?.docs ?? const []).where((bus) {
          final data = bus.data();
          final updatedAt = data['updatedAt'];
          final isFresh =
              updatedAt is Timestamp && updatedAt.toDate().isAfter(cutoff);
          final hasPosition =
              (data['currentLatitude'] ?? data['latitude']) is num &&
              (data['currentLongitude'] ?? data['longitude']) is num;
          return liveStatuses.contains(
                data['status']?.toString().trim().toLowerCase(),
              ) &&
              hasPosition &&
              isFresh;
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Operations overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metric(
                  context,
                  Icons.directions_bus,
                  '${liveBuses.length}',
                  'Live buses',
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('buses')
                      .snapshots(),
                  builder: (_, s) => _metric(
                    context,
                    Icons.directions_bus_outlined,
                    '${s.data?.size ?? 0}',
                    'Buses',
                  ),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .snapshots(),
                  builder: (_, s) => _metric(
                    context,
                    Icons.confirmation_num,
                    '${s.data?.size ?? 0}',
                    'Bookings',
                  ),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'driver')
                      .snapshots(),
                  builder: (_, s) => _metric(
                    context,
                    Icons.badge,
                    '${s.data?.size ?? 0}',
                    'Drivers',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _RouteBusMonitoring(buses: liveBuses),
            const SizedBox(height: 24),
            Text('Reports', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _reportTile(
              context,
              Icons.today,
              'Daily report',
              () => _report(context, 'daily', const Duration(days: 1)),
            ),
            _reportTile(
              context,
              Icons.date_range,
              'Weekly report',
              () => _report(context, 'weekly', const Duration(days: 7)),
            ),
            _reportTile(
              context,
              Icons.calendar_month,
              'Monthly report',
              () => _report(context, 'monthly', const Duration(days: 30)),
            ),
            _reportTile(context, Icons.tune, 'Custom report', () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
<<<<<<< HEAD
            }
          }),
          const SizedBox(height: 20),
          Text(
            'Manage platform',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text('Add Staff'),
            subtitle: const Text('Create driver or admin accounts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openAddStaffSheet(context),
          ),
          for (final item in const [
            (Icons.people, 'Drivers'),
            (Icons.directions_bus, 'Buses'),
            (Icons.route, 'Routes'),
            (Icons.place, 'Pickup stations'),
            (Icons.event_seat, 'Seat layouts'),
            (Icons.payments, 'Fares'),
          ])
            ListTile(
              leading: Icon(item.$1),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _CollectionEditor(
                    title: item.$2,
                    collection: item.$2.toLowerCase().replaceAll(' ', ''),
=======
              if (range != null) {
                await ReportService().createReport(
                  type: 'custom',
                  start: range.start,
                  end: range.end.add(const Duration(days: 1)),
                );
              }
            }),
            const SizedBox(height: 20),
            Text(
              'Manage platform',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final item in const [
              (Icons.directions_bus, 'Buses', ManagementKind.buses),
              (Icons.route, 'Routes', ManagementKind.routes),
              (Icons.place, 'Stops & pickups', ManagementKind.stops),
              (Icons.badge, 'Drivers', ManagementKind.drivers),
              (
                Icons.admin_panel_settings,
                'Administrators',
                ManagementKind.admins,
              ),
              (
                Icons.campaign_outlined,
                'Announcements',
                ManagementKind.notifications,
              ),
              (
                Icons.help_outline,
                'Help & support',
                ManagementKind.helpSupport,
              ),
            ])
              ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManagementPage(title: item.$2, kind: item.$3),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
  Widget _metric(BuildContext c, IconData icon, String value, String label) =>
      SizedBox(
        width: 150,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(height: 8),
                Text(value, style: Theme.of(c).textTheme.headlineSmall),
                Text(label),
              ],
            ),
          ),
        ),
      );
  Widget _reportTile(
    BuildContext c,
    IconData icon,
    String text,
    VoidCallback action,
  ) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: const Icon(Icons.arrow_forward),
      onTap: action,
    ),
  );
}

<<<<<<< HEAD
class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet();

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  String _role = 'driver';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _employeeId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _employeeId.text.trim().isEmpty ||
        _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fill in name, email, employee ID, and a password of at '
            'least 6 characters.',
          ),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthenticationService().createStaffAccount(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        employeeId: _employeeId.text,
        role: _role,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Staff account created for ${_name.text}.')),
        );
        _name.clear();
        _email.clear();
        _employeeId.clear();
        _password.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not create account: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 24,
      right: 24,
      top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Staff', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Create a driver or admin account.'),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _employeeId,
            decoration: const InputDecoration(labelText: 'Employee ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Temporary password'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: 'driver', child: Text('Driver')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Creating...' : 'Create account'),
          ),
        ],
      ),
    ),
  );
}

=======
class _RouteBusMonitoring extends StatefulWidget {
  const _RouteBusMonitoring({required this.buses});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> buses;

  @override
  State<_RouteBusMonitoring> createState() => _RouteBusMonitoringState();
}

class _RouteBusMonitoringState extends State<_RouteBusMonitoring> {
  String? _routeId;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          final routes = snapshot.data?.docs ?? const [];
          final selected = routes.any((route) => route.id == _routeId)
              ? _routeId
              : null;
          final selectedRoute = selected == null
              ? null
              : routes.firstWhere((route) => route.id == selected);
          final buses = selected == null
              ? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]
              : widget.buses.where((bus) {
                  final data = bus.data();
                  return (data['routeId'] ?? data['currentRoute'])
                          ?.toString() ==
                      selected;
                }).toList();
          final located = buses.where((bus) {
            final data = bus.data();
            return (data['currentLatitude'] ?? data['latitude']) is num &&
                (data['currentLongitude'] ?? data['longitude']) is num;
          }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live bus monitoring',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selected,
                decoration: const InputDecoration(
                  labelText: 'Select an active route',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
                items: routes
                    .map(
                      (route) => DropdownMenuItem(
                        value: route.id,
                        child: Text(
                          route.data()['name']?.toString() ?? route.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _routeId = value),
              ),
              const SizedBox(height: 12),
              if (selected == null)
                const _MapMessage('Select a route to see its live buses.')
              else
                _AdminBusMap(
                  routeId: selected,
                  route: selectedRoute!.data(),
                  buses: located,
                ),
            ],
          );
        },
      );
}

class _MapMessage extends StatelessWidget {
  const _MapMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(message, textAlign: TextAlign.center),
  );
}

class _AdminBusMap extends StatelessWidget {
  const _AdminBusMap({
    required this.routeId,
    required this.route,
    required this.buses,
  });
  final String routeId;
  final Map<String, dynamic> route;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> buses;

  @override
  Widget build(BuildContext context) {
    if (route.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 280,
          child: RouteMapPanel(routeId: routeId, route: route, buses: buses),
        ),
      );
    }
    final located = buses.where((bus) {
      final data = bus.data();
      return (data['currentLatitude'] ?? data['latitude']) is num &&
          (data['currentLongitude'] ?? data['longitude']) is num;
    }).toList();
    final first = located.first.data();
    final centerLatitude = first['currentLatitude'] ?? first['latitude'];
    final centerLongitude = first['currentLongitude'] ?? first['longitude'];
    final center = LatLng(
      (centerLatitude as num).toDouble(),
      (centerLongitude as num).toDouble(),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.smartrideug.app',
            ),
            MarkerLayer(
              markers: located.map((bus) {
                final data = bus.data();
                final rawLatitude = data['currentLatitude'] ?? data['latitude'];
                final rawLongitude =
                    data['currentLongitude'] ?? data['longitude'];
                final latitude = (rawLatitude as num).toDouble();
                final longitude = (rawLongitude as num).toDouble();
                return Marker(
                  point: LatLng(latitude, longitude),
                  width: 46,
                  height: 46,
                  child: Tooltip(
                    message:
                        data['plateNumber']?.toString() ??
                        data['plate']?.toString() ??
                        data['busNumber']?.toString() ??
                        bus.id,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
class _CollectionEditor extends StatelessWidget {
  const _CollectionEditor({required this.title, required this.collection});
  final String title, collection;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No live records yet.'));
        }
        return ListView(
          children: snapshot.data!.docs
              .map(
                (d) => ListTile(
                  title: Text(d.data()['name']?.toString() ?? d.id),
                  subtitle: Text(
                    d
                        .data()
                        .entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' · '),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}
