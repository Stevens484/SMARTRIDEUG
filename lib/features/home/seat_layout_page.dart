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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seat Layout')),
      body: SafeArea(
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
            final farePerSeat =
                (busData?['farePerSeat'] as num?)?.toInt() ?? 3000;
            final seats = List.generate(
              totalSeats,
              (i) => (i + 1).toString().padLeft(2, '0'),
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Select a seat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text('Front'),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.2,
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
                            ),
                          ),
                          child: Center(
                            child: Text(
                              seat,
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (selectedSeats.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConfirmSeatPage(
                                busId: widget.busId,
                                routeId: widget.routeId,
                                busNumber: widget.busNumber,
                                farePerSeat: farePerSeat,
                                seats: selectedSeats.toList(),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Continue â€” ${selectedSeats.length} ${selectedSeats.length == 1 ? 'seat' : 'seats'}',
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
}
