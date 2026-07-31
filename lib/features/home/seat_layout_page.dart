import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/confirm_seat_page.dart';

class SeatLayoutPage extends StatefulWidget {
  final String busId;
  final String routeId;
  final String busNumber;

  const SeatLayoutPage({
    super.key,
    required this.busId,
    required this.routeId,
    required this.busNumber,
  });

  @override
  State<SeatLayoutPage> createState() => _SeatLayoutPageState();
}

class _SeatLayoutPageState extends State<SeatLayoutPage> {
  final Set<String> selectedSeats = {};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Seat selection')),
    body: SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('buses')
            .doc(widget.busId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final busData = snapshot.data!.data();
          final totalSeats = (busData?['totalSeats'] as num?)?.toInt() ?? 32;
          final reservedSeats = List<String>.from(
            busData?['reservedSeats'] as List<dynamic>? ?? const [],
          );
          final pendingSeats = List<String>.from(
            busData?['pendingSeats'] as List<dynamic>? ?? const [],
          );
          final farePerSeat =
              (busData?['farePerSeat'] as num?)?.toInt() ?? 3000;
          final seats = List.generate(
            totalSeats,
            (i) => (i + 1).toString().padLeft(2, '0'),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: _SeatHeader(busNumber: widget.busNumber),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.grey100),
                  ),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.08,
                        ),
                    itemCount: seats.length,
                    itemBuilder: (context, index) {
                      final seat = seats[index];
                      final isSelected = selectedSeats.contains(seat);
                      final isReserved = reservedSeats.contains(seat);
                      final isPending = pendingSeats.contains(seat);
                      final isAvailable = !isReserved && !isPending;
                      final fill = isSelected
                          ? AppTheme.primary
                          : isAvailable
                          ? AppTheme.white
                          : isPending
                          ? AppTheme.grey100
                          : AppTheme.grey300;
                      final textColor = isSelected
                          ? Colors.white
                          : isAvailable
                          ? AppTheme.navy
                          : AppTheme.grey500;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isAvailable
                              ? () => setState(() {
                                  isSelected
                                      ? selectedSeats.remove(seat)
                                      : selectedSeats.add(seat);
                                })
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : isAvailable
                                    ? AppTheme.grey300
                                    : Colors.transparent,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                seat,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (selectedSeats.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  decoration: const BoxDecoration(color: AppTheme.white),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConfirmSeatPage(
                              busId: widget.busId,
                              routeId: widget.routeId,
                              busNumber: widget.busNumber,
                              farePerSeat: farePerSeat,
                              seats: selectedSeats.toList(),
                            ),
                          ),
                        ),
                        child: Text(
                          'Continue — ${selectedSeats.length} ${selectedSeats.length == 1 ? 'seat' : 'seats'}',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _SeatHeader extends StatelessWidget {
  const _SeatHeader({required this.busNumber});
  final String busNumber;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your seat',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bus $busNumber  •  Driver at the front',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _SeatLegend(label: 'Available', color: AppTheme.white),
              _SeatLegend(label: 'Selected', color: AppTheme.primary),
              _SeatLegend(label: 'Reserved', color: AppTheme.grey100),
              _SeatLegend(label: 'Occupied', color: AppTheme.grey300),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: color == AppTheme.white
                ? AppTheme.grey300
                : Colors.transparent,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          color: AppTheme.grey700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
