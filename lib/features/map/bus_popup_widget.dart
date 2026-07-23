import 'package:flutter/material.dart';
import 'package:smartrideug/core/models/bus_model.dart';
import 'package:smartrideug/core/theme/app_theme.dart';

class BusPopupWidget extends StatelessWidget {
  final BusModel bus;

  const BusPopupWidget({super.key, required this.bus});

  @override
  Widget build(BuildContext context) {
    final color = bus.seatColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.directions_bus, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bus.id,
                          style: const TextStyle(
                            color: AppTheme.grey900,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bus.seatStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      bus.routeName,
                      style: TextStyle(color: AppTheme.grey500, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildStatItem('Speed', '${bus.speed.toStringAsFixed(0)} km/h'),
              _buildStatItem('Passengers', '${bus.passengerCount}'),
              _buildStatItem('Seats Left', '${bus.availableSeats}'),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Estimated arrival: ~5 min',
                  style: TextStyle(color: AppTheme.grey700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🔥 FIXED: Book Seat button uses Navigator.push with proper route
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // 🔥 FIX: Use direct Navigation with MaterialPageRoute
                Navigator.pushNamed(
                  context,
                  '/confirm-seat',
                  arguments: {
                    'busId': bus.id,
                    'routeName': bus.routeName,
                    'availableSeats': bus.availableSeats,
                  },
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.airplane_ticket, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Book Seat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.grey900,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
