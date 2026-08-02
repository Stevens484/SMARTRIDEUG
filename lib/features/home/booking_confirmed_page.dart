import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/features/map/route_map_panel.dart';

class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          final booking = snapshot.data?.data();
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (booking == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Your digital ticket')),
              body: const Center(child: Text('This ticket is unavailable.')),
            );
          }
          return _ticket(context, booking);
        },
      );

  Widget _ticket(BuildContext context, Map<String, dynamic> booking) {
    final scheme = Theme.of(context).colorScheme;
    final isConfirmed =
        booking['status']?.toString().toLowerCase() == 'confirmed';
    final routeLabel =
        '${booking['origin'] ?? ''} → ${booking['destination'] ?? ''}';
    final bus = booking['plateNumber']?.toString().isNotEmpty == true
        ? booking['plateNumber'].toString()
        : booking['busNumber']?.toString() ?? 'Unavailable';
    final fare = booking['fare'];
    return Scaffold(
      appBar: AppBar(title: const Text('Your digital ticket')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.secondary,
                    child: Icon(
                      Icons.airplane_ticket_outlined,
                      color: scheme.onSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConfirmed
                              ? 'Your trip is confirmed'
                              : 'Seat hold pending',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          routeLabel,
                          style: TextStyle(
                            color: scheme.onPrimary.withValues(alpha: .78),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Chip(
                      label: Text(isConfirmed ? 'CONFIRMED' : 'HELD'),
                      backgroundColor: scheme.secondaryContainer,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      routeLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 170,
                      height: 110,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        color: scheme.onSurface,
                        size: 82,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      bookingId,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Divider(height: 34),
                    _line(context, 'Bus', bus),
                    _line(
                      context,
                      'Boarding',
                      booking['pickupStopName']?.toString() ?? 'Unavailable',
                    ),
                    _line(
                      context,
                      'Seat',
                      (booking['seats'] as Iterable?)?.join(', ') ??
                          'Unavailable',
                    ),
                    _line(
                      context,
                      'Total',
                      fare is num ? 'UGX ${fare.toInt()}' : 'Fare unavailable',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _map(booking),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _map(Map<String, dynamic> booking) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('routes')
            .doc(booking['routeId'])
            .snapshots(),
        builder: (context, snapshot) {
          final route = snapshot.data?.data();
          if (route == null) return const SizedBox.shrink();
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 190,
              child: RouteMapPanel(
                routeId: booking['routeId'].toString(),
                route: route,
              ),
            ),
          );
        },
      );

  Widget _line(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );

  static Widget _line(
    IconData icon,
    String label,
    String value, {
    bool emphasized = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.grey500),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppTheme.grey500, fontSize: 13),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: emphasized ? AppTheme.primary : AppTheme.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TicketHero extends StatelessWidget {
  const _TicketHero();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.navy, AppTheme.navyLight],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.airplane_ticket_outlined, color: Colors.white),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your trip is confirmed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Have a safe and comfortable journey.',
                style: TextStyle(color: Color(0xFFD5E0F0), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TicketNotchDivider extends StatelessWidget {
  const _TicketNotchDivider();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SizedBox(
        width: 12,
        height: 24,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
          ),
        ),
      ),
      Expanded(child: DashedLine()),
      SizedBox(
        width: 12,
        height: 24,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
          ),
        ),
      ),
    ],
  );
}

class DashedLine extends StatelessWidget {
  const DashedLine({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        (constraints.maxWidth / 8).floor(),
        (_) =>
            const SizedBox(width: 4, child: Divider(color: AppTheme.grey300)),
      ),
    ),
  );
}
