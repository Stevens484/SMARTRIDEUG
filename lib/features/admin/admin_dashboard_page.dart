import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/authentication_service.dart';
import 'package:smartrideug/core/services/report_service.dart';
import 'package:smartrideug/core/services/route_geometry_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin dashboard')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Operations', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Metric(
              collection: 'buses',
              label: 'Buses',
              icon: Icons.directions_bus,
            ),
            _Metric(collection: 'routes', label: 'Routes', icon: Icons.route),
            _Metric(
              collection: 'users',
              label: 'Drivers',
              icon: Icons.badge,
              driverOnly: true,
            ),
            _Metric(
              collection: 'bookings',
              label: 'Bookings',
              icon: Icons.confirmation_num,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Manage platform', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const _ActionTile(
          'Routes',
          Icons.route,
          _AdminListPage(kind: _Kind.routes),
        ),
        const _ActionTile(
          'Buses & assignments',
          Icons.directions_bus,
          _AdminListPage(kind: _Kind.buses),
        ),
        const _ActionTile(
          'Schedule daily buses',
          Icons.schedule,
          _BusSchedulePage(),
        ),
        const _ActionTile('Stops', Icons.place, _StopsPage()),
        const _ActionTile(
          'Drivers',
          Icons.badge,
          _AdminListPage(kind: _Kind.drivers),
        ),
        const _ActionTile(
          'All bookings',
          Icons.receipt_long,
          _AdminListPage(kind: _Kind.bookings),
        ),
        ListTile(
          leading: const Icon(Icons.assessment),
          title: const Text('Create daily report'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final now = DateTime.now();
            await ReportService().createReport(
              type: 'daily',
              start: now.subtract(const Duration(days: 1)),
              end: now,
            );
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Daily report created.')),
              );
          },
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.collection,
    required this.label,
    required this.icon,
    this.driverOnly = false,
  });
  final String collection, label;
  final IconData icon;
  final bool driverOnly;
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: driverOnly
            ? FirebaseFirestore.instance
                  .collection(collection)
                  .where('role', isEqualTo: 'driver')
                  .snapshots()
            : FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (_, snap) => SizedBox(
          width: 150,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon),
                  const SizedBox(height: 8),
                  Text(
                    '${snap.data?.size ?? 0}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.title, this.icon, this.page);
  final String title;
  final IconData icon;
  final Widget page;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  );
}

class _BusSchedulePage extends StatefulWidget {
  const _BusSchedulePage();

  @override
  State<_BusSchedulePage> createState() => _BusSchedulePageState();
}

class _BusSchedulePageState extends State<_BusSchedulePage> {
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  String get _dateKey => _dayKey(_selectedDate);

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _editSchedule(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> buses, {
    QueryDocumentSnapshot<Map<String, dynamic>>? scheduledBus,
  }) async {
    String? busId = scheduledBus?.id;
    var serviceDate = _selectedDate;
    var time = _timeFrom(scheduledBus?.data()['departureTime']);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            scheduledBus == null ? 'Schedule a bus' : 'Reschedule bus',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: busId,
                  decoration: const InputDecoration(labelText: 'Bus'),
                  hint: const Text('Select a bus'),
                  items: buses
                      .where((bus) => bus.data()['disabled'] != true)
                      .map(
                        (bus) => DropdownMenuItem(
                          value: bus.id,
                          child: Text(
                            _busLabel(bus),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => busId = value),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Service date'),
                  subtitle: Text(_dayKey(serviceDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: serviceDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => serviceDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_outlined),
                  title: const Text('Departure time'),
                  subtitle: Text(_timeKey(time)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (picked != null) setDialogState(() => time = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busId == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Publish schedule'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || busId == null) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('buses').doc(busId).update({
        'serviceDate': _dayKey(serviceDate),
        'departureTime': _timeKey(time),
        'status': 'scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _selectedDate = serviceDate);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bus departure published.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish schedule: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeSchedule(
    QueryDocumentSnapshot<Map<String, dynamic>> bus,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove departure?'),
        content: Text('Remove ${_busLabel(bus)} from $_dateKey?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await bus.reference.update({
        'serviceDate': FieldValue.delete(),
        'departureTime': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Departure removed.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove departure: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Schedule daily buses')),
    floatingActionButton: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('buses').snapshots(),
      builder: (context, snapshot) => FloatingActionButton.extended(
        onPressed: _saving || !snapshot.hasData
            ? null
            : () => _editSchedule(snapshot.data!.docs),
        icon: const Icon(Icons.add),
        label: const Text('Schedule bus'),
      ),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('buses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final scheduled =
            snapshot.data!.docs.where((bus) {
              final data = bus.data();
              return data['serviceDate'] == _dateKey &&
                  data['departureTime']?.toString().isNotEmpty == true;
            }).toList()..sort(
              (a, b) => (a.data()['departureTime']?.toString() ?? '').compareTo(
                b.data()['departureTime']?.toString() ?? '',
              ),
            );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: _pickDay,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Schedule for $_dateKey'),
            ),
            const SizedBox(height: 18),
            Text(
              'Published departures',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (scheduled.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No buses are scheduled for this day yet.'),
                ),
              )
            else
              ...scheduled.map(
                (bus) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.directions_bus_outlined),
                    ),
                    title: Text(_busLabel(bus)),
                    subtitle: Text(
                      bus.data()['routeName']?.toString() ??
                          'Route ${bus.data()['routeId'] ?? 'not assigned'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bus.data()['departureTime']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) => action == 'edit'
                              ? _editSchedule(
                                  snapshot.data!.docs,
                                  scheduledBus: bus,
                                )
                              : _removeSchedule(bus),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Reschedule'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 88),
          ],
        );
      },
    ),
  );

  static String _busLabel(QueryDocumentSnapshot<Map<String, dynamic>> bus) {
    final data = bus.data();
    return (data['busNumber'] ?? data['registrationNumber'] ?? 'Bus ${bus.id}')
        .toString();
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _timeKey(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static TimeOfDay _timeFrom(dynamic value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})$',
    ).firstMatch(value?.toString() ?? '');
    return match == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: int.parse(match.group(1)!),
            minute: int.parse(match.group(2)!),
          );
  }
}

class _StopsPage extends StatefulWidget {
  const _StopsPage();

  @override
  State<_StopsPage> createState() => _StopsPageState();
}

class _StopsPageState extends State<_StopsPage> {
  String? _routeId;

  Future<void> _saveStop({
    String? stopId,
    String? currentName,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    final name = TextEditingController(text: currentName ?? '');
    final latitude = TextEditingController(
      text: currentLatitude?.toString() ?? '',
    );
    final longitude = TextEditingController(
      text: currentLongitude?.toString() ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(stopId == null ? 'Add Stop' : 'Edit Stop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Stop name'),
            ),
            TextField(
              controller: latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude (optional)',
                helperText: 'Leave both coordinates blank to find the stop.',
              ),
            ),
            TextField(
              controller: longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude (optional)',
                helperText: 'Uses OpenStreetMap data for the stop name.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    var parsedLatitude = double.tryParse(latitude.text.trim());
    var parsedLongitude = double.tryParse(longitude.text.trim());
    if (saved != true || name.text.trim().isEmpty || _routeId == null) {
      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a stop name and select a route.'),
          ),
        );
      }
      name.dispose();
      latitude.dispose();
      longitude.dispose();
      return;
    }
    try {
      if ((parsedLatitude == null) != (parsedLongitude == null)) {
        throw StateError(
          'Enter both coordinates, or leave both blank to locate the stop.',
        );
      }
      final coordinatesWereFound =
          parsedLatitude == null && parsedLongitude == null;
      if (coordinatesWereFound) {
        final location = await RouteGeometryService().resolvePlace(
          name.text.trim(),
        );
        parsedLatitude = location.latitude;
        parsedLongitude = location.longitude;
      }
      final stopLatitude = parsedLatitude;
      final stopLongitude = parsedLongitude;
      if (stopLatitude == null || stopLongitude == null) {
        throw StateError('Could not determine stop coordinates.');
      }
      if (stopLatitude < -90 ||
          stopLatitude > 90 ||
          stopLongitude < -180 ||
          stopLongitude > 180) {
        throw StateError('The stop coordinates are outside the map range.');
      }
      final ref = FirebaseFirestore.instance
          .collection('routes')
          .doc(_routeId)
          .collection('stops')
          .doc(stopId);
      if (stopId == null) {
        final existing = await FirebaseFirestore.instance
            .collection('routes')
            .doc(_routeId)
            .collection('stops')
            .get();
        await ref.set({
          'name': name.text.trim(),
          'latitude': stopLatitude,
          'longitude': stopLongitude,
          'order': existing.size,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({
          'name': name.text.trim(),
          'latitude': stopLatitude,
          'longitude': stopLongitude,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted && coordinatesWereFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stop coordinates found from the map.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save stop: $error')));
      }
    } finally {
      name.dispose();
      latitude.dispose();
      longitude.dispose();
    }
  }

  Future<void> _deleteStop(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('routes')
          .doc(_routeId)
          .collection('stops')
          .doc(id)
          .delete();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete stop: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Manage Stops'),
      actions: [
        IconButton(
          tooltip: 'Reorder Stops',
          onPressed: _routeId == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ReorderStopsPage(routeId: _routeId!),
                  ),
                ),
          icon: const Icon(Icons.reorder),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _routeId == null ? null : _saveStop,
      icon: const Icon(Icons.add),
      label: const Text('Add Stop'),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('routes').snapshots(),
      builder: (context, routeSnapshot) {
        if (!routeSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final routes = routeSnapshot.data!.docs;
        if (routes.isEmpty)
          return const Center(
            child: Text('Create a route before adding stops.'),
          );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: routes.any((route) => route.id == _routeId)
                    ? _routeId
                    : null,
                decoration: const InputDecoration(labelText: 'Select route'),
                items: routes
                    .map(
                      (route) => DropdownMenuItem(
                        value: route.id,
                        child: Text(
                          (route.data()['name'] ?? route.id).toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _routeId = value),
              ),
            ),
            Expanded(
              child: _routeId == null
                  ? const Center(
                      child: Text('Select a route, then press Add Stop.'),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('routes')
                          .doc(_routeId)
                          .collection('stops')
                          .snapshots(),
                      builder: (context, stopSnapshot) {
                        if (!stopSnapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        if (stopSnapshot.data!.docs.isEmpty)
                          return const Center(
                            child: Text('No stops on this route yet.'),
                          );
                        return ListView(
                          children: stopSnapshot.data!.docs
                              .map(
                                (stop) => ListTile(
                                  leading: const Icon(Icons.place),
                                  title: Text(
                                    (stop.data()['name'] ?? stop.id).toString(),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (action) => action == 'edit'
                                        ? _saveStop(
                                            stopId: stop.id,
                                            currentName: stop
                                                .data()['name']
                                                ?.toString(),
                                            currentLatitude:
                                                (stop.data()['latitude']
                                                        as num?)
                                                    ?.toDouble(),
                                            currentLongitude:
                                                (stop.data()['longitude']
                                                        as num?)
                                                    ?.toDouble(),
                                          )
                                        : _deleteStop(stop.id),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _ReorderStopsPage extends StatefulWidget {
  const _ReorderStopsPage({required this.routeId});
  final String routeId;

  @override
  State<_ReorderStopsPage> createState() => _ReorderStopsPageState();
}

class _ReorderStopsPageState extends State<_ReorderStopsPage> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _stops;
  bool _saving = false;

  Future<void> _save() async {
    if (_stops == null) return;
    setState(() => _saving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var index = 0; index < _stops!.length; index++) {
        batch.update(_stops![index].reference, {
          'order': index,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reorder stops: $error')),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reorder Stops'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.routeId)
          .collection('stops')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        _stops ??= List.of(snapshot.data!.docs);
        if (_stops!.isEmpty)
          return const Center(child: Text('There are no stops to reorder.'));
        return ReorderableListView.builder(
          itemCount: _stops!.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final stop = _stops!.removeAt(oldIndex);
              _stops!.insert(newIndex, stop);
            });
          },
          itemBuilder: (context, index) {
            final stop = _stops![index];
            return ListTile(
              key: ValueKey(stop.id),
              leading: Text('${index + 1}'),
              title: Text((stop.data()['name'] ?? stop.id).toString()),
              trailing: const Icon(Icons.drag_handle),
            );
          },
        );
      },
    ),
  );
}

enum _Kind { routes, buses, stops, drivers, bookings }

class _AdminListPage extends StatelessWidget {
  const _AdminListPage({required this.kind});
  final _Kind kind;
  String get title => switch (kind) {
    _Kind.routes => 'Routes',
    _Kind.buses => 'Buses',
    _Kind.stops => 'Stops',
    _Kind.drivers => 'Drivers',
    _Kind.bookings => 'Bookings',
  };
  String get collection => switch (kind) {
    _Kind.routes => 'routes',
    _Kind.buses => 'buses',
    _Kind.stops => 'stops',
    _Kind.drivers => 'users',
    _Kind.bookings => 'bookings',
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    floatingActionButton: kind == _Kind.bookings
        ? null
        : FloatingActionButton.extended(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: Text(
              'Add ${kind == _Kind.buses ? 'Bus' : title.substring(0, title.length - 1)}',
            ),
          ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: kind == _Kind.drivers
          ? FirebaseFirestore.instance
                .collection(collection)
                .where('role', isEqualTo: 'driver')
                .snapshots()
          : FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return const Center(child: Text('No records yet.'));
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            return Card(
              child: ListTile(
                title: Text(_name(data, doc.id)),
                isThreeLine: kind == _Kind.buses,
                subtitle: kind == _Kind.buses
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _details(data),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextButton.icon(
                            onPressed: () => _assignDriver(context, doc.id),
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Assign driver'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      )
                    : Text(_details(data)),
                trailing: kind == _Kind.bookings
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (value) => _action(context, value, doc),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          if (kind == _Kind.buses || kind == _Kind.drivers)
                            PopupMenuItem(
                              value: 'disable',
                              child: Text(
                                data['disabled'] == true ? 'Enable' : 'Disable',
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
  String _name(Map<String, dynamic> d, String id) =>
      (d['name'] ??
              d['routeName'] ??
              d['registrationNumber'] ??
              d['busNumber'] ??
              d['email'] ??
              'Record $id')
          .toString();
  String _details(Map<String, dynamic> d) => d.entries
      .where(
        (e) => !['name', 'createdAt', 'updatedAt', 'password'].contains(e.key),
      )
      .map((e) => '${e.key}: ${e.value}')
      .join(' • ');
  Future<void> _action(
    BuildContext context,
    String action,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (action == 'edit') return _edit(context, doc: doc);
    if (action == 'driver') return _assignDriver(context, doc.id);
    if (kind != _Kind.drivers) {
      try {
        if (action == 'delete') {
          await doc.reference.delete();
        } else {
          await doc.reference.update({
            'disabled': doc.data()['disabled'] != true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved.')));
        }
      } catch (e) {
        _error(context, e);
      }
      return;
    }
    try {
      if (action == 'delete') {
        // Auth accounts can only be permanently deleted by a trusted backend.
        // Removing the profile prevents this account from accessing staff UI.
        await doc.reference.delete();
      } else {
        final disabled = doc.data()['disabled'] != true;
        final batch = FirebaseFirestore.instance.batch();
        batch.update(doc.reference, {
          'disabled': disabled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (disabled) {
          final assignedBuses = await FirebaseFirestore.instance
              .collection('buses')
              .where('driverId', isEqualTo: doc.id)
              .get();
          for (final bus in assignedBuses.docs) {
            batch.update(bus.reference, {
              'driverId': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        await batch.commit();
      }
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved.')));
    } catch (e) {
      _error(context, e);
    }
  }

  Future<void> _assignDriver(BuildContext context, String busId) async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('users').where('role', isEqualTo: 'driver').get(),
      db.collection('routes').get(),
      db.collection('buses').doc(busId).get(),
    ]);
    final drivers = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs
        .where((driver) => driver.data()['disabled'] != true)
        .toList();
    final routes = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final availableRoutes = routes.docs
        .where(
          (route) =>
              route.data()['active'] != false &&
              route.data()['disabled'] != true,
        )
        .toList();
    final busSnapshot = results[2] as DocumentSnapshot<Map<String, dynamic>>;
    if (!context.mounted) return;
    if (!busSnapshot.exists || busSnapshot.data()?['disabled'] == true) {
      _error(context, StateError('The selected bus is unavailable.'));
      return;
    }
    if (drivers.isEmpty || availableRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            drivers.isEmpty
                ? 'No active driver is available to assign.'
                : 'No active route is available to assign.',
          ),
        ),
      );
      return;
    }
    String? driverId = busSnapshot.data()?['driverId']?.toString();
    String? routeId = busSnapshot.data()?['routeId']?.toString();
    final assignment = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign driver and route'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: drivers.any((driver) => driver.id == driverId)
                    ? driverId
                    : null,
                decoration: const InputDecoration(labelText: 'Driver'),
                items: drivers
                    .map(
                      (driver) => DropdownMenuItem(
                        value: driver.id,
                        child: Text(
                          _name(driver.data(), driver.id),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => driverId = value),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue:
                    availableRoutes.any((route) => route.id == routeId)
                    ? routeId
                    : null,
                decoration: const InputDecoration(labelText: 'Route'),
                items: availableRoutes
                    .map(
                      (route) => DropdownMenuItem(
                        value: route.id,
                        child: Text(
                          (route.data()['name'] ?? route.id).toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => routeId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: driverId == null || routeId == null
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      'driverId': driverId!,
                      'routeId': routeId!,
                    }),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    if (assignment == null) return;
    try {
      final id = assignment['driverId']!;
      final selectedRouteId = assignment['routeId']!;
      final selectedDriver = drivers.firstWhere((driver) => driver.id == id);
      final driverName = _name(selectedDriver.data(), selectedDriver.id);
      final selectedRoute = routes.docs.firstWhere(
        (route) => route.id == selectedRouteId,
      );
      final routeName = (selectedRoute.data()['name'] ?? selectedRoute.id)
          .toString();
      final currentAssignments = await db
          .collection('buses')
          .where('driverId', isEqualTo: id)
          .get();
      await db.runTransaction((transaction) async {
        final busRef = db.collection('buses').doc(busId);
        final driverRef = db.collection('users').doc(id);
        final bus = await transaction.get(busRef);
        final driver = await transaction.get(driverRef);
        if (!bus.exists || bus.data()?['disabled'] == true) {
          throw StateError('The selected bus is unavailable.');
        }
        if (!driver.exists ||
            driver.data()?['role'] != 'driver' ||
            driver.data()?['disabled'] == true) {
          throw StateError('The selected driver is unavailable.');
        }
        final previousDriverId = bus.data()?['driverId']?.toString();
        for (final assignedBus in currentAssignments.docs) {
          if (assignedBus.id != busId) {
            transaction.update(assignedBus.reference, {
              'driverId': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        transaction.update(busRef, {
          'driverId': id,
          'driverName': driverName,
          'routeId': selectedRouteId,
          'routeName': routeName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(driverRef, {
          'assignedBusId': busId,
          'assignedRouteId': selectedRouteId,
          'assignedRouteName': routeName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (previousDriverId != null && previousDriverId != id) {
          transaction.update(db.collection('users').doc(previousDriverId), {
            'assignedBusId': FieldValue.delete(),
            'assignedRouteId': FieldValue.delete(),
            'assignedRouteName': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver, bus and route assigned.')),
        );
    } catch (e) {
      _error(context, e);
    }
  }

  Future<void> _edit(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final fields = _fields(kind);
    final routes = kind == _Kind.buses
        ? await FirebaseFirestore.instance.collection('routes').get()
        : null;
    final drivers = kind == _Kind.buses
        ? await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'driver')
              .get()
        : null;
    final values = {
      for (final field in fields)
        field: TextEditingController(
          text:
              doc?.data()[field]?.toString() ??
              (kind == _Kind.buses && field == 'status' ? 'active' : ''),
        ),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${doc == null ? 'Add' : 'Edit'} ${title.substring(0, title.length - 1)}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields
                .map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: field == 'routeId' && routes != null
                        ? DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: values[field]!.text.isEmpty
                                ? null
                                : values[field]!.text,
                            decoration: const InputDecoration(
                              labelText: 'Route',
                            ),
                            items: routes.docs
                                .map(
                                  (route) => DropdownMenuItem(
                                    value: route.id,
                                    child: Text(
                                      (route.data()['name'] ?? route.id)
                                          .toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                values[field]!.text = value ?? '',
                          )
                        : field == 'driverId' && drivers != null
                        ? DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue:
                                drivers.docs
                                    .where(
                                      (driver) =>
                                          driver.data()['disabled'] != true,
                                    )
                                    .any(
                                      (driver) =>
                                          driver.id == values[field]!.text,
                                    )
                                ? values[field]!.text
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Assigned driver (optional)',
                            ),
                            hint: const Text('Assign a driver now or later'),
                            items: drivers.docs
                                .where(
                                  (driver) => driver.data()['disabled'] != true,
                                )
                                .map(
                                  (driver) => DropdownMenuItem(
                                    value: driver.id,
                                    child: Text(
                                      _name(driver.data(), driver.id),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                values[field]!.text = value ?? '',
                          )
                        : field == 'status' && kind == _Kind.buses
                        ? DropdownButtonFormField<String>(
                            value: values[field]!.text.isEmpty
                                ? 'active'
                                : values[field]!.text,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'scheduled',
                                child: Text('Scheduled'),
                              ),
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Text('Inactive'),
                              ),
                              DropdownMenuItem(
                                value: 'maintenance',
                                child: Text('Maintenance'),
                              ),
                            ],
                            onChanged: (value) =>
                                values[field]!.text = value ?? 'active',
                          )
                        : TextField(
                            controller: values[field],
                            obscureText: field == 'password',
                            keyboardType: field == 'totalSeats'
                                ? TextInputType.number
                                : null,
                            decoration: InputDecoration(
                              labelText: _label(field),
                            ),
                          ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final data = <String, dynamic>{
      for (final field in fields)
        if (values[field]!.text.trim().isNotEmpty)
          field: field == 'totalSeats'
              ? int.tryParse(values[field]!.text) ?? 0
              : values[field]!.text.trim(),
    };
    if (kind == _Kind.buses &&
        (data['registrationNumber'] == null ||
            data['totalSeats'] == null ||
            data['routeId'] == null ||
            data['status'] == null)) {
      for (final controller in values.values) {
        controller.dispose();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete every bus field.')),
        );
      }
      return;
    }
    if (kind == _Kind.routes &&
        (data['origin'] == null || data['destination'] == null)) {
      for (final controller in values.values) {
        controller.dispose();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter the route origin and destination.'),
          ),
        );
      }
      return;
    }
    if (kind == _Kind.drivers &&
        doc == null &&
        (data['name'] == null ||
            data['email'] == null ||
            data['password'] == null)) {
      for (final controller in values.values) {
        controller.dispose();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter the driver name, email, and password.'),
          ),
        );
      }
      return;
    }
    if (kind == _Kind.routes) {
      data['name'] = '${data['origin']} - ${data['destination']}';
    }
    if (kind == _Kind.buses && routes != null) {
      for (final route in routes.docs) {
        if (route.id == data['routeId']) {
          data['routeName'] = (route.data()['name'] ?? route.id).toString();
          break;
        }
      }
      if (data['driverId']?.toString().isNotEmpty == true && drivers != null) {
        for (final driver in drivers.docs) {
          if (driver.id == data['driverId']) {
            data['driverName'] = _name(driver.data(), driver.id);
            break;
          }
        }
      }
    }
    try {
      if (kind == _Kind.drivers) {
        if (doc == null) {
          await AuthenticationService().createStaffAccount(
            name: data['name']?.toString() ?? '',
            email: data['email']?.toString() ?? '',
            password: data['password']?.toString() ?? '',
            employeeId: data['employeeId']?.toString() ?? '',
            role: 'driver',
          );
        } else {
          data.remove('password');
          // Changing another user's Firebase sign-in email requires a trusted
          // backend. Profile details remain editable here without that risk.
          data.remove('email');
          await doc.reference.update({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        final records = FirebaseFirestore.instance.collection(collection);
        DocumentReference<Map<String, dynamic>>? savedBus;
        if (doc == null) {
          savedBus = await records.add({
            ...data,
            if (kind == _Kind.routes) 'active': true,
            'disabled': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await doc.reference.update({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          savedBus = doc.reference;
        }
        if (kind == _Kind.buses &&
            data['driverId']?.toString().isNotEmpty == true) {
          await _syncDriverAssignment(
            busId: savedBus.id,
            driverId: data['driverId'].toString(),
            routeId: data['routeId'].toString(),
            routeName:
                data['routeName']?.toString() ?? data['routeId'].toString(),
            previousDriverId: doc?.data()['driverId']?.toString(),
          );
        }
      }
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved.')));
    } catch (e) {
      if (context.mounted) _error(context, e);
    } finally {
      for (final controller in values.values) {
        controller.dispose();
      }
    }
  }

  Future<void> _syncDriverAssignment({
    required String busId,
    required String driverId,
    required String routeId,
    required String routeName,
    String? previousDriverId,
  }) async {
    final db = FirebaseFirestore.instance;
    final existingAssignments = await db
        .collection('buses')
        .where('driverId', isEqualTo: driverId)
        .get();
    final batch = db.batch();
    for (final assignedBus in existingAssignments.docs) {
      if (assignedBus.id != busId) {
        batch.update(assignedBus.reference, {
          'driverId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.set(db.collection('users').doc(driverId), {
      'assignedBusId': busId,
      'assignedRouteId': routeId,
      'assignedRouteName': routeName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (previousDriverId != null && previousDriverId != driverId) {
      batch.update(db.collection('users').doc(previousDriverId), {
        'assignedBusId': FieldValue.delete(),
        'assignedRouteId': FieldValue.delete(),
        'assignedRouteName': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  List<String> _fields(_Kind k) => switch (k) {
    _Kind.routes => ['code', 'origin', 'destination'],
    _Kind.buses => [
      'registrationNumber',
      'totalSeats',
      'routeId',
      'driverId',
      'status',
    ],
    _Kind.stops => ['name', 'routeId'],
    _Kind.drivers => ['name', 'email', 'employeeId', 'password'],
    _Kind.bookings => [],
  };
  String _label(String field) => switch (field) {
    'registrationNumber' => 'Plate Number',
    'totalSeats' => 'Number of Seats',
    _ => field,
  };
  void _error(BuildContext context, Object error) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
}
