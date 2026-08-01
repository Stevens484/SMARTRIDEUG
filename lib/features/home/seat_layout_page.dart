import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/confirm_seat_page.dart';

class SeatLayoutPage extends StatefulWidget {
  final String busId;
<<<<<<< HEAD
  final String routeId;
  final String busNumber;

  const SeatLayoutPage({
    super.key,
    required this.busId,
    required this.routeId,
    required this.busNumber,
=======
  final String busNumber;
  final String routeId;
  final int totalSeats;
  const SeatLayoutPage({
    super.key,
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.totalSeats,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  });

  @override
  State<SeatLayoutPage> createState() => _SeatLayoutPageState();
}

class _SeatLayoutPageState extends State<SeatLayoutPage> {
  final Set<String> selectedSeats = {};

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) {
=======
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('buses')
            .doc(widget.busId)
            .snapshots(),
        builder: (context, snapshot) {
          final bus = snapshot.data?.data();
          final totalSeats =
              (bus?['totalSeats'] as num?)?.toInt() ?? widget.totalSeats;
          final reservedSeats =
              (bus?['reservedSeats'] as List<dynamic>? ?? const [])
                  .map((seat) => seat.toString())
                  .toSet();
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('seatHolds')
                .where('busId', isEqualTo: widget.busId)
                .snapshots(),
            builder: (context, holdsSnapshot) {
              final heldSeats = (holdsSnapshot.data?.docs ?? const [])
                  .where((hold) {
                    final status = hold.data()['status']?.toString();
                    return status == 'held' || status == 'confirmed';
                  })
                  .map((hold) => hold.data()['seat']?.toString())
                  .whereType<String>()
                  .toSet();
              return _layout(context, totalSeats, {
                ...reservedSeats,
                ...heldSeats,
              });
            },
          );
        },
      );

  Widget _layout(
    BuildContext context,
    int totalSeats,
    Set<String> reservedSeats,
  ) {
    final seats = List.generate(
      totalSeats.clamp(1, 120),
      (index) => (index + 1).toString().padLeft(2, '0'),
    );
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
    return Scaffold(
      appBar: AppBar(title: const Text('Seat selection')),
      body: SafeArea(
<<<<<<< HEAD
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .doc(widget.busId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

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
                      final isAvailable = !reservedSeats.contains(seat);
                      return GestureDetector(
                        onTap: isAvailable
                            ? () => setState(() {
                                if (isSelected) {
                                  selectedSeats.remove(seat);
                                } else {
                                  selectedSeats.add(seat);
                                }
                              })
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? (isSelected
                                      ? AppTheme.primaryGreen
                                      : AppTheme.primaryGreen.withAlpha(40))
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : Colors.transparent,
                              width: 2,
=======
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.orangeSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: AppTheme.orange,
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
                                const SizedBox(height: 3),
                                Text(
                                  'Bus ${widget.busNumber}  •  Driver at the front',
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
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          _SeatLegend(
                            label: 'Available',
                            color: AppTheme.white,
                          ),
                          _SeatLegend(
                            label: 'Selected',
                            color: AppTheme.orange,
                          ),
                          _SeatLegend(
                            label: 'Reserved',
                            color: AppTheme.grey100,
                          ),
                          _SeatLegend(label: 'Driver', color: AppTheme.grey300),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.08,
                  ),
                  itemCount: seats.length,
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    final isSelected = selectedSeats.contains(seat);
                    final isDriverSeat = index == 0;
                    final isReserved = reservedSeats.contains(seat);
                    final isAvailable = !isDriverSeat && !isReserved;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isAvailable
                            ? () => setState(
                                () => isSelected
                                    ? selectedSeats.remove(seat)
                                    : selectedSeats.add(seat),
                              )
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.orange
                                : isAvailable
                                ? AppTheme.white
                                : isReserved
                                ? AppTheme.grey100
                                : AppTheme.grey300,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.orange
                                  : isAvailable
                                  ? AppTheme.grey300
                                  : Colors.transparent,
                              width: isSelected ? 2 : 1,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
                            ),
                          ),
                          child: Center(
                            child: Text(
                              seat,
                              style: TextStyle(
<<<<<<< HEAD
                                color: isAvailable
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
=======
                                color: isSelected
                                    ? Colors.white
                                    : isAvailable
                                    ? AppTheme.navy
                                    : AppTheme.grey500,
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
                color: AppTheme.white,
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
                            seats: selectedSeats.toList(),
                          ),
                        ),
                      ),
                      child: Text(
                        'Continue — ${selectedSeats.length} ${selectedSeats.length == 1 ? 'seat' : 'seats'}',
                      ),
                    ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
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
