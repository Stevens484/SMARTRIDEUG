import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/firebase/firebase_options.dart';

enum ManagementKind {
  buses,
  routes,
  stops,
  drivers,
  admins,
  notifications,
  helpSupport,
}

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key, required this.kind, required this.title});

  final ManagementKind kind;
  final String title;

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _collection => switch (widget.kind) {
    ManagementKind.buses => 'buses',
    ManagementKind.routes => 'routes',
    ManagementKind.stops => 'stops',
    ManagementKind.drivers => 'users',
    ManagementKind.admins => 'users',
    ManagementKind.notifications => 'notifications',
    ManagementKind.helpSupport => 'appSettings',
  };

  List<_Field> get _fields => switch (widget.kind) {
    ManagementKind.buses => const [
      _Field('busNumber', 'Bus number'),
      _Field('plateNumber', 'Plate number'),
      _Field('routeId', 'Route ID'),
      _Field('totalSeats', 'Total seats', numeric: true),
    ],
    ManagementKind.routes => const [
      _Field('name', 'Route name'),
      _Field('origin', 'Origin'),
      _Field('destination', 'Destination'),
    ],
    ManagementKind.stops => const [
      _Field('routeId', 'Route ID'),
      _Field('name', 'Stop / pickup name'),
      _Field('latitude', 'Latitude', numeric: true),
      _Field('longitude', 'Longitude', numeric: true),
      _Field('order', 'Stop order', numeric: true),
      _Field('farePerKilometre', 'Fare per kilometre (UGX)', numeric: true),
    ],
    ManagementKind.drivers => const [
      _Field('name', 'Driver full name'),
      _Field('employeeId', 'Driver employee ID'),
      _Field('email', 'Driver email'),
    ],
    ManagementKind.admins => const [
      _Field('name', 'Administrator full name'),
      _Field('employeeId', 'Admin employee ID'),
      _Field('email', 'Admin email'),
    ],
    ManagementKind.notifications => const [
      _Field('title', 'Title'),
      _Field('body', 'Message', multiline: true),
      _Field('audience', 'Audience (all, passengers, drivers)'),
    ],
    ManagementKind.helpSupport => const [
      _Field('email', 'Support email'),
      _Field('phone', 'Support phone'),
      _Field('faqs', 'FAQs (one per line)', multiline: true),
    ],
  };

  Future<void> _add() => _openForm();

  Future<void> _openForm({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final values = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EntryForm(
        title: widget.title,
        fields: _fields,
        initialValues: document?.data(),
      ),
    );
    if (values == null) return;
    try {
      await _save(values, documentId: document?.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${widget.title} saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
      }
    }
  }

  Future<void> _save(Map<String, String> values, {String? documentId}) async {
    for (final field in _fields) {
      final value = values[field.key]?.trim() ?? '';
      if (value.isEmpty) throw StateError('${field.label} is required.');
      if (field.numeric && num.tryParse(value) == null) {
        throw StateError('${field.label} must be a number.');
      }
    }
    final data = <String, dynamic>{
      for (final field in _fields)
        field.key: field.numeric
            ? num.tryParse(values[field.key]!.trim())
            : values[field.key]!.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    switch (widget.kind) {
      case ManagementKind.buses:
        if (documentId != null) {
          await _db.collection('buses').doc(documentId).update(data);
          return;
        }
        final totalSeats = data['totalSeats'] as num? ?? 0;
        data.addAll({
          'availableSeats': totalSeats,
          'status': 'offline',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _db.collection('buses').add(data);
        return;
      case ManagementKind.routes:
        if (documentId != null) {
          await _db.collection('routes').doc(documentId).update(data);
          return;
        }
        data.addAll({
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _db.collection('routes').add(data);
        return;
      case ManagementKind.stops:
        final routeId = data['routeId']?.toString() ?? '';
        if (routeId.isEmpty) {
          throw StateError('Choose a route before adding a stop.');
        }
        final rootStop = documentId == null
            ? _db.collection('stops').doc()
            : _db.collection('stops').doc(documentId);
        final batch = _db.batch();
        batch.set(rootStop, {
          ...data,
          'stopId': rootStop.id,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: documentId != null));
        batch.set(
          _db
              .collection('routes')
              .doc(routeId)
              .collection('stops')
              .doc(rootStop.id),
          {
            ...data,
            'stopId': rootStop.id,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: documentId != null),
        );
        await batch.commit();
        return;
      case ManagementKind.drivers:
      case ManagementKind.admins:
        final role = widget.kind == ManagementKind.drivers ? 'driver' : 'admin';
        final employeeId = data['employeeId']?.toString() ?? '';
        if (employeeId.length < 6) {
          throw StateError('Employee ID must be at least 6 characters.');
        }
        final secondaryAuth = FirebaseAuth.instanceFor(
          app: await _provisioningApp(),
        );
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: data['email']!.toString(),
          password: employeeId,
        );
        final uid = credential.user!.uid;
        await credential.user!.updateDisplayName(data['name']!.toString());
        try {
          final batch = _db.batch();
          batch.set(_db.collection('users').doc(uid), {
            'name': data['name'],
            'displayName': data['name'],
            'email': data['email'],
            'role': role,
            'employeeId': employeeId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (role == 'driver') {
            batch.set(_db.collection('drivers').doc(uid), {
              'userId': uid,
              'name': data['name'],
              'displayName': data['name'],
              'email': data['email'],
              'employeeId': employeeId,
              'status': 'offline',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        } finally {
          await secondaryAuth.signOut();
        }
        return;
      case ManagementKind.notifications:
        final audience = data['audience']?.toString();
        data.addAll({
          'audience': audience == null || audience.isEmpty ? 'all' : audience,
          'type': 'promotion',
          'publishedAt': FieldValue.serverTimestamp(),
        });
        await _db.collection('notifications').add(data);
        return;
      case ManagementKind.helpSupport:
        final faqs = values['faqs']!
            .split(RegExp(r'\r?\n'))
            .map((faq) => faq.trim())
            .where((faq) => faq.isNotEmpty)
            .toList();
        await _db.collection('appSettings').doc('support').set({
          'email': data['email'],
          'phone': data['phone'],
          'faqs': faqs,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
    }
  }

  Future<FirebaseApp> _provisioningApp() async {
    const name = 'admin-provisioning';
    try {
      return Firebase.app(name);
    } on FirebaseException {
      return Firebase.initializeApp(
        name: name,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete ${widget.title.substring(0, widget.title.length - 1)}?',
        ),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await document.reference.delete();
  }

  Future<void> _changeRouteStatus(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => document.reference.update({
    'active': document.data()?['active'] != true,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> _assignDriver(
    DocumentSnapshot<Map<String, dynamic>> driver, {
    _DriverAssignment? directAssignment,
  }) async {
    final driverProfile = await _db.collection('drivers').doc(driver.id).get();
    if (!mounted) return;
    final assignment =
        directAssignment ??
        await showModalBottomSheet<_DriverAssignment>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _DriverAssignmentForm(
            driverId: driver.id,
            initialBusId: driverProfile.data()?['assignedBusId']?.toString(),
            initialRouteId: driverProfile
                .data()?['assignedRouteId']
                ?.toString(),
          ),
        );
    if (assignment == null) return;

    final selectedBus = await _db
        .collection('buses')
        .doc(assignment.busId)
        .get();
    final selectedRoute = await _db
        .collection('routes')
        .doc(assignment.routeId)
        .get();
    if (!selectedBus.exists || !selectedRoute.exists) {
      throw StateError('The selected bus or route is no longer available.');
    }
    if (selectedRoute.data()?['active'] == false) {
      throw StateError('Choose an active route for this assignment.');
    }
    final selectedLocation = await _db
        .collection('busLocations')
        .doc(assignment.busId)
        .get();
    const activeStatuses = {'active', 'online', 'moving', 'approaching_stop'};
    if (activeStatuses.contains(
      selectedLocation.data()?['status']?.toString().toLowerCase(),
    )) {
      throw StateError(
        'End this bus’s active trip before changing its assignment.',
      );
    }

    final previousBusId = driverProfile.data()?['assignedBusId']?.toString();
    if (previousBusId != null &&
        previousBusId.isNotEmpty &&
        previousBusId != assignment.busId) {
      final previousLocation = await _db
          .collection('busLocations')
          .doc(previousBusId)
          .get();
      if (activeStatuses.contains(
        previousLocation.data()?['status']?.toString().toLowerCase(),
      )) {
        throw StateError(
          'End the driver’s current trip before reassigning them.',
        );
      }
    }

    final batch = _db.batch();
    final previouslyAssignedDriver =
        selectedBus.data()?['driverId']?.toString() ??
        selectedBus.data()?['assignedDriverId']?.toString();
    if (previouslyAssignedDriver != null &&
        previouslyAssignedDriver.isNotEmpty &&
        previouslyAssignedDriver != driver.id) {
      batch.set(
        _db.collection('drivers').doc(previouslyAssignedDriver),
        {
          'assignedBusId': FieldValue.delete(),
          'assignedRouteId': FieldValue.delete(),
          'status': 'offline',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    if (previousBusId != null &&
        previousBusId.isNotEmpty &&
        previousBusId != assignment.busId) {
      batch.set(_db.collection('buses').doc(previousBusId), {
        'driverId': FieldValue.delete(),
        'assignedDriverId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    batch.set(_db.collection('drivers').doc(driver.id), {
      'userId': driver.id,
      'email': driver.data()?['email'],
      'employeeId': driver.data()?['employeeId'],
      'assignedBusId': assignment.busId,
      'assignedRouteId': assignment.routeId,
      'status': 'offline',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('buses').doc(assignment.busId), {
      'driverId': driver.id,
      'assignedDriverId': driver.id,
      'routeId': assignment.routeId,
      'currentRoute': assignment.routeId,
      'assignmentStatus': 'assigned',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      _db.collection('busLocations').doc(assignment.busId),
      {
        'busId': assignment.busId,
        'busNumber':
            selectedBus.data()?['busNumber']?.toString() ?? assignment.busId,
        'availableSeats': selectedBus.data()?['availableSeats'],
        'totalSeats': selectedBus.data()?['totalSeats'],
        'driverId': driver.id,
        'routeId': assignment.routeId,
        'routeName':
            selectedRoute.data()?['name']?.toString() ?? assignment.routeId,
        'origin': selectedRoute.data()?['origin']?.toString(),
        'destination': selectedRoute.data()?['destination']?.toString(),
        'status': 'offline',
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(_db.collection('busStatus').doc(assignment.busId), {
      'driverId': driver.id,
      'routeId': assignment.routeId,
      'status': 'offline',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> _assignBus(DocumentSnapshot<Map<String, dynamic>> bus) async {
    final selection = await showModalBottomSheet<_BusAssignment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BusAssignmentForm(
        busLabel:
            bus.data()?['plateNumber']?.toString() ??
            bus.data()?['busNumber']?.toString() ??
            bus.id,
        initialDriverId: bus.data()?['driverId']?.toString(),
        initialRouteId: bus.data()?['routeId']?.toString(),
      ),
    );
    if (selection == null) return;
    final driver = await _db.collection('users').doc(selection.driverId).get();
    if (!driver.exists || driver.data()?['role'] != 'driver') {
      throw StateError('The selected driver is no longer available.');
    }
    await _assignDriver(
      driver,
      directAssignment: _DriverAssignment(
        busId: bus.id,
        routeId: selection.routeId,
      ),
    );
  }

  void _showAssignmentError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not assign driver: $error')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add),
      label: const Text('Add'),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection(_collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load ${widget.title.toLowerCase()}.'),
          );
        }
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var documents = snapshot.data!.docs;
        if (widget.kind == ManagementKind.admins ||
            widget.kind == ManagementKind.drivers) {
          final role = widget.kind == ManagementKind.admins
              ? 'admin'
              : 'driver';
          documents = documents
              .where((item) => item.data()['role'] == role)
              .toList();
        }
        if (documents.isEmpty) {
          final hint = switch (widget.kind) {
            ManagementKind.drivers =>
              'Add a driver invitation. The driver will register with the employee ID.',
            ManagementKind.admins =>
              'Add an administrator invitation. The administrator will register with the employee ID.',
            _ => 'No live records yet.',
          };
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(hint, textAlign: TextAlign.center),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: documents.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (_, index) {
            final document = documents[index];
            final data = document.data();
            return ListTile(
              leading: Icon(_icon),
              title: Text(_title(data, document.id)),
              subtitle: Text(_summary(data)),
              trailing: widget.kind == ManagementKind.drivers
                  ? IconButton(
                      tooltip: 'Assign bus and route',
                      icon: const Icon(Icons.assignment_ind_outlined),
                      onPressed: () async {
                        try {
                          await _assignDriver(document);
                        } catch (error) {
                          _showAssignmentError(error);
                        }
                      },
                    )
                  : widget.kind == ManagementKind.buses ||
                        widget.kind == ManagementKind.routes ||
                        widget.kind == ManagementKind.helpSupport
                  ? PopupMenuButton<_RecordAction>(
                      onSelected: (action) async {
                        if (action == _RecordAction.edit) {
                          await _openForm(document: document);
                        } else if (action == _RecordAction.delete) {
                          await _delete(document);
                        } else if (action == _RecordAction.assign) {
                          try {
                            await _assignBus(document);
                          } catch (error) {
                            _showAssignmentError(error);
                          }
                        } else {
                          await _changeRouteStatus(document);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: _RecordAction.edit,
                          child: Text('Edit'),
                        ),
                        if (widget.kind == ManagementKind.buses)
                          const PopupMenuItem(
                            value: _RecordAction.assign,
                            child: Text('Assign route and driver'),
                          ),
                        if (widget.kind == ManagementKind.routes)
                          PopupMenuItem(
                            value: _RecordAction.status,
                            child: Text(
                              data['active'] == true ? 'Disable' : 'Enable',
                            ),
                          ),
                        const PopupMenuItem(
                          value: _RecordAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    ),
  );

  IconData get _icon => switch (widget.kind) {
    ManagementKind.buses => Icons.directions_bus_outlined,
    ManagementKind.routes => Icons.route_outlined,
    ManagementKind.stops => Icons.place_outlined,
    ManagementKind.drivers => Icons.badge_outlined,
    ManagementKind.admins => Icons.admin_panel_settings_outlined,
    ManagementKind.notifications => Icons.campaign_outlined,
    ManagementKind.helpSupport => Icons.help_outline,
  };

  String _title(Map<String, dynamic> data, String id) {
    final preferred = widget.kind == ManagementKind.buses
        ? data['plateNumber'] ?? data['plate'] ?? data['busNumber']
        : data['name'] ?? data['busNumber'];
    return (preferred ??
            data['title'] ??
            data['email'] ??
            data['employeeId'] ??
            id)
        .toString();
  }

  String _summary(Map<String, dynamic> data) => data.entries
      .where(
        (entry) =>
            !{'updatedAt', 'createdAt', 'publishedAt'}.contains(entry.key),
      )
      .take(4)
      .map((entry) => '${entry.key}: ${entry.value}')
      .join(' • ');
}

enum _RecordAction { edit, assign, status, delete }

class _Field {
  const _Field(
    this.key,
    this.label, {
    this.numeric = false,
    this.multiline = false,
  });
  final String key;
  final String label;
  final bool numeric;
  final bool multiline;
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({
    required this.title,
    required this.fields,
    this.initialValues,
  });
  final String title;
  final List<_Field> fields;
  final Map<String, dynamic>? initialValues;
  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.fields)
      field.key: TextEditingController(
        text: widget.initialValues?[field.key]?.toString() ?? '',
      ),
  };
  @override
  void dispose() {
    for (final controller in _controllers.values) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add ${widget.title}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final field in widget.fields) ...[
            _input(field),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              for (final entry in _controllers.entries)
                entry.key: entry.value.text,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  Widget _input(_Field field) {
    if (field.key != 'routeId') {
      return TextField(
        controller: _controllers[field.key],
        keyboardType: field.numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: field.multiline ? 3 : 1,
        decoration: InputDecoration(labelText: field.label),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('routes')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final routes = snapshot.data?.docs ?? const [];
        final selected = _controllers[field.key]!.text;
        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: routes.any((route) => route.id == selected) ? selected : null,
          decoration: InputDecoration(labelText: 'Active route'),
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
          onChanged: (value) => _controllers[field.key]!.text = value ?? '',
        );
      },
    );
  }
}

class _BusAssignment {
  const _BusAssignment({required this.driverId, required this.routeId});
  final String driverId;
  final String routeId;
}

class _BusAssignmentForm extends StatefulWidget {
  const _BusAssignmentForm({
    required this.busLabel,
    this.initialDriverId,
    this.initialRouteId,
  });

  final String busLabel;
  final String? initialDriverId;
  final String? initialRouteId;

  @override
  State<_BusAssignmentForm> createState() => _BusAssignmentFormState();
}

class _BusAssignmentFormState extends State<_BusAssignmentForm> {
  String? _driverId;
  String? _routeId;

  @override
  void initState() {
    super.initState();
    _driverId = widget.initialDriverId;
    _routeId = widget.initialRouteId;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .snapshots(),
      builder: (context, driverSnapshot) =>
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('routes')
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (context, routeSnapshot) {
              final drivers = driverSnapshot.data?.docs ?? const [];
              final routes = routeSnapshot.data?.docs ?? const [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assign ${widget.busLabel}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: drivers.any((driver) => driver.id == _driverId)
                        ? _driverId
                        : null,
                    decoration: const InputDecoration(labelText: 'Driver'),
                    items: drivers
                        .map(
                          (driver) => DropdownMenuItem(
                            value: driver.id,
                            child: Text(
                              driver.data()['email']?.toString() ?? driver.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _driverId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: routes.any((route) => route.id == _routeId)
                        ? _routeId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Active route',
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _driverId == null || _routeId == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            _BusAssignment(
                              driverId: _driverId!,
                              routeId: _routeId!,
                            ),
                          ),
                    child: const Text('Save assignment'),
                  ),
                ],
              );
            },
          ),
    ),
  );
}

class _DriverAssignment {
  const _DriverAssignment({required this.busId, required this.routeId});
  final String busId;
  final String routeId;
}

class _DriverAssignmentForm extends StatefulWidget {
  const _DriverAssignmentForm({
    required this.driverId,
    this.initialBusId,
    this.initialRouteId,
  });
  final String driverId;
  final String? initialBusId;
  final String? initialRouteId;
  @override
  State<_DriverAssignmentForm> createState() => _DriverAssignmentFormState();
}

class _DriverAssignmentFormState extends State<_DriverAssignmentForm> {
  String? _busId;
  String? _routeId;

  @override
  void initState() {
    super.initState();
    _busId = widget.initialBusId;
    _routeId = widget.initialRouteId;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('buses').snapshots(),
      builder: (context, busSnapshot) =>
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('routes')
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (context, routeSnapshot) {
              // A bus is assigned to one driver at a time. The current driver
              // still sees their own bus so an administrator can change route.
              final buses = (busSnapshot.data?.docs ?? const []).where((bus) {
                final assignedDriverId =
                    bus.data()['driverId']?.toString() ??
                    bus.data()['assignedDriverId']?.toString();
                return assignedDriverId == null ||
                    assignedDriverId.isEmpty ||
                    assignedDriverId == widget.driverId;
              }).toList();
              final routes = routeSnapshot.data?.docs ?? const [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assign driver',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: buses.any((bus) => bus.id == _busId) ? _busId : null,
                    decoration: const InputDecoration(labelText: 'Bus'),
                    items: buses
                        .map(
                          (bus) => DropdownMenuItem(
                            value: bus.id,
                            child: Text(
                              '${bus.data()['plateNumber'] ?? bus.data()['plate'] ?? bus.id} — Bus ${bus.data()['busNumber'] ?? 'number unavailable'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _busId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: routes.any((route) => route.id == _routeId)
                        ? _routeId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Active route',
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _busId == null || _routeId == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            _DriverAssignment(
                              busId: _busId!,
                              routeId: _routeId!,
                            ),
                          ),
                    child: const Text('Save assignment'),
                  ),
                ],
              );
            },
          ),
    ),
  );
}
