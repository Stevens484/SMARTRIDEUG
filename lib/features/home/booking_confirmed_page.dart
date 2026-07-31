import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your digital ticket')),
    body: SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final booking = snapshot.data!.data();
          if (booking == null)
            return const Center(child: Text('This ticket is unavailable.'));
          final ticket = booking['ticketToken']?.toString();
          if (booking['status'] != 'confirmed' || ticket == null) {
            return const Center(
              child: Text('Payment is still being confirmed.'),
            );
          }
          final seats = (booking['seats'] as List<dynamic>? ?? const []).join(
            ', ',
          );
          final qrData = 'SMARTRIDE|$bookingId|$ticket';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              const _TicketHero(),
              const SizedBox(height: 18),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F5ED),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CONFIRMED',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            booking['routeName']?.toString() ??
                                'Your SmartRide journey',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Board with this secure travel pass',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.grey100),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 205,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            ticket,
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _TicketNotchDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        children: [
                          _line(
                            Icons.directions_bus_outlined,
                            'Bus',
                            booking['busNumber']?.toString() ?? 'N/A',
                          ),
                          _line(
                            Icons.location_on_outlined,
                            'Boarding',
                            booking['pickupStopName']?.toString() ?? 'N/A',
                          ),
                          _line(
                            Icons.event_seat_outlined,
                            'Seat${seats.contains(',') ? 's' : ''}',
                            seats,
                          ),
                          _line(
                            Icons.account_balance_wallet_outlined,
                            'Total paid',
                            'UGX ${booking['fare'] ?? 0}',
                            emphasized: true,
                          ),
                          _line(
                            Icons.receipt_long_outlined,
                            'Reference',
                            booking['paymentReference']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
          );
        },
      ),
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
