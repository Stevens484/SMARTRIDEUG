import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/report_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin dashboard')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('busLocations').snapshots(),
      builder: (context, snapshot) => ListView(
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
                '${snapshot.data?.size ?? 0}',
                'Live buses',
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
                    .collection('drivers')
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
                  ),
                ),
              ),
            ),
        ],
      ),
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
