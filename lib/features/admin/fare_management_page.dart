import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lets administrators set a fixed fare per seat for an ordered pickup-to-stop
/// pair. Passenger fare quotes read these records live.
class FareManagementPage extends StatelessWidget {
  const FareManagementPage({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pickup-to-stop fares')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openEditor(context),
      icon: const Icon(Icons.add),
      label: const Text('Set fare'),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('fares').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load road-route fares.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final fares = snapshot.data!.docs.toList()
          ..sort((a, b) => _updatedAt(b).compareTo(_updatedAt(a)));
        if (fares.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Set a rate for each pickup and later stop that passengers can select.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: fares.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final document = fares[index];
            final data = document.data();
            final rate = data['farePerSeat'] as int?;
            return ListTile(
              leading: const Icon(Icons.route_outlined),
              title: Text(
                '${data['pickupStopName'] ?? 'Pickup'} → ${data['destinationStopName'] ?? 'Stop'}',
              ),
              subtitle: Text(
                '${data['routeName'] ?? data['routeId'] ?? 'Route'} · UGX ${rate?.toInt() ?? 0} per seat',
              ),
              trailing: PopupMenuButton<_FareAction>(
                onSelected: (action) {
                  if (action == _FareAction.edit) {
                    _openEditor(context, document: document);
                  } else {
                    _delete(context, document);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _FareAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _FareAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );

  Future<void> _openEditor(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final draft = await showModalBottomSheet<_FareDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FareEditor(initial: document?.data()),
    );
    if (draft == null) return;
    try {
      final newId = _id(
        draft.routeId,
        draft.pickupStopId,
        draft.destinationStopId,
      );
      final batch = _db.batch();
      batch.set(_db.collection('fares').doc(newId), {
        ...draft.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (document != null && document.id != newId) {
        batch.delete(document.reference);
      }
      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Road-route fare saved.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save fare: $error')));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this fare?'),
        content: const Text(
          'Passengers will use a legacy fare only if one exists.',
        ),
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

  static DateTime _updatedAt(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()['updatedAt'];
    return value is Timestamp ? value.toDate() : DateTime(1970);
  }

  static String _id(String routeId, String pickupId, String stopId) =>
      '${routeId}_${pickupId}_$stopId';
}

enum _FareAction { edit, delete }

class _FareDraft {
  const _FareDraft({
    required this.routeId,
    required this.routeName,
    required this.pickupStopId,
    required this.pickupStopName,
    required this.destinationStopId,
    required this.destinationStopName,
    required this.farePerSeat,
  });

  final String routeId;
  final String routeName;
  final String pickupStopId;
  final String pickupStopName;
  final String destinationStopId;
  final String destinationStopName;
  final int farePerSeat;

  Map<String, dynamic> toFirestore() => {
    'routeId': routeId,
    'routeName': routeName,
    'pickupStopId': pickupStopId,
    'pickupStopName': pickupStopName,
    'destinationStopId': destinationStopId,
    'destinationStopName': destinationStopName,
    'farePerSeat': farePerSeat,
  };
}

class _FareEditor extends StatefulWidget {
  const _FareEditor({this.initial});
  final Map<String, dynamic>? initial;

  @override
  State<_FareEditor> createState() => _FareEditorState();
}

class _FareEditorState extends State<_FareEditor> {
  String? _routeId;
  String? _pickupId;
  String? _destinationId;
  late final TextEditingController _rate = TextEditingController(
    text: widget.initial?['farePerSeat']?.toString() ?? '',
  );

  @override
  void initState() {
    super.initState();
    _routeId = widget.initial?['routeId']?.toString();
    _pickupId = widget.initial?['pickupStopId']?.toString();
    _destinationId = widget.initial?['destinationStopId']?.toString();
  }

  @override
  void dispose() {
    _rate.dispose();
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
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('routes').snapshots(),
      builder: (context, routeSnapshot) {
        final routes = routeSnapshot.data?.docs ?? const [];
        final selectedRoute = routes
            .where((route) => route.id == _routeId)
            .firstOrNull;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set pickup-to-stop fare',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'The stop must be after the selected pickup in route order.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRoute == null ? null : _routeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Route'),
                items: routes
                    .map(
                      (route) => DropdownMenuItem(
                        value: route.id,
                        child: Text(
                          route.data()['name']?.toString() ?? route.id,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _routeId = value;
                  _pickupId = null;
                  _destinationId = null;
                }),
              ),
              const SizedBox(height: 12),
              if (_routeId == null)
                const Text('Select a route to choose its pickup and stop.')
              else
                _RoutePointSelectors(
                  routeId: _routeId!,
                  pickupId: _pickupId,
                  destinationId: _destinationId,
                  onPickupChanged: (value) => setState(() {
                    _pickupId = value;
                    _destinationId = null;
                  }),
                  onDestinationChanged: (value) =>
                      setState(() => _destinationId = value),
                  onReady: (pickup, destination) =>
                      _save(selectedRoute, pickup, destination),
                  rate: _rate,
                ),
            ],
          ),
        );
      },
    ),
  );

  void _save(
    QueryDocumentSnapshot<Map<String, dynamic>>? route,
    QueryDocumentSnapshot<Map<String, dynamic>> pickup,
    QueryDocumentSnapshot<Map<String, dynamic>> destination,
  ) {
    final rate = int.tryParse(_rate.text.trim());
    if (route == null || rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive fare per seat.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _FareDraft(
        routeId: route.id,
        routeName: route.data()['name']?.toString() ?? route.id,
        pickupStopId: pickup.id,
        pickupStopName: pickup.data()['name']?.toString() ?? 'Pickup',
        destinationStopId: destination.id,
        destinationStopName: destination.data()['name']?.toString() ?? 'Stop',
        farePerSeat: rate,
      ),
    );
  }
}

class _RoutePointSelectors extends StatelessWidget {
  const _RoutePointSelectors({
    required this.routeId,
    required this.pickupId,
    required this.destinationId,
    required this.onPickupChanged,
    required this.onDestinationChanged,
    required this.onReady,
    required this.rate,
  });

  final String routeId;
  final String? pickupId;
  final String? destinationId;
  final ValueChanged<String?> onPickupChanged;
  final ValueChanged<String?> onDestinationChanged;
  final void Function(
    QueryDocumentSnapshot<Map<String, dynamic>> pickup,
    QueryDocumentSnapshot<Map<String, dynamic>> destination,
  )
  onReady;
  final TextEditingController rate;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('routes')
        .doc(routeId)
        .collection('stops')
        .snapshots(),
    builder: (context, snapshot) {
      final points = snapshot.data?.docs.toList() ?? []
        ..sort(
          (a, b) => ((a.data()['order'] as num?)?.toInt() ?? 99999).compareTo(
            (b.data()['order'] as num?)?.toInt() ?? 99999,
          ),
        );
      final pickups = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (var index = 0; index < points.length - 1; index += 1) {
        if (_isRoutePoint(points[index].data()['type']?.toString())) {
          pickups.add(points[index]);
        }
      }
      final pickupIndex = points.indexWhere((point) => point.id == pickupId);
      final destinations = <QueryDocumentSnapshot<Map<String, dynamic>>>[
        if (pickupIndex >= 0)
          for (var index = pickupIndex + 1; index < points.length; index += 1)
            if (_isRoutePoint(points[index].data()['type']?.toString()))
              points[index],
      ];
      final pickup = pickups.where((point) => point.id == pickupId).firstOrNull;
      final destination = destinations
          .where((point) => point.id == destinationId)
          .firstOrNull;
      return Column(
        children: [
          DropdownButtonFormField<String>(
            value: pickup?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pickup point'),
            items: pickups
                .map(
                  (point) => DropdownMenuItem(
                    value: point.id,
                    child: Text(point.data()['name']?.toString() ?? point.id),
                  ),
                )
                .toList(),
            onChanged: onPickupChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('fare-stop-$pickupId'),
            value: destination?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Later stop'),
            items: destinations
                .map(
                  (point) => DropdownMenuItem(
                    value: point.id,
                    child: Text(point.data()['name']?.toString() ?? point.id),
                  ),
                )
                .toList(),
            onChanged: pickup == null ? null : onDestinationChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: rate,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Fare per seat (UGX)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: pickup == null || destination == null
                ? null
                : () => onReady(pickup, destination),
            child: const Text('Save fare'),
          ),
        ],
      );
    },
  );
}

bool _isRoutePoint(String? type) {
  final value = type?.trim().toLowerCase();
  return value == 'pickup' ||
      value == 'pickup_point' ||
      value == 'pickup point' ||
      value == 'stop' ||
      value == 'destination' ||
      value == 'both';
}
