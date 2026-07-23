import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';

class BusSimulationService {
  static final BusSimulationService _instance =
      BusSimulationService._internal();
  factory BusSimulationService() => _instance;
  BusSimulationService._internal();

  // 🔥 MULTIPLE ROUTES FOR DIFFERENT BUSES
  static final List<List<LatLng>> _allRoutes = [
    // Route 4A - Kampala Loop (BUS-001)
    [
      LatLng(0.3136, 32.5811),
      LatLng(0.3180, 32.5780),
      LatLng(0.3220, 32.5760),
      LatLng(0.3292, 32.5711),
      LatLng(0.3340, 32.5675),
      LatLng(0.3300, 32.5650),
      LatLng(0.3260, 32.5680),
    ],
    // Route 14 - Wandegeya to City Square (BUS-002)
    [
      LatLng(0.3220, 32.5760),
      LatLng(0.3180, 32.5780),
      LatLng(0.3136, 32.5811),
      LatLng(0.3100, 32.5840),
      LatLng(0.3080, 32.5860),
    ],
    // Route 22 - Kyambogo to City Center (BUS-003)
    [
      LatLng(0.3400, 32.5600),
      LatLng(0.3350, 32.5630),
      LatLng(0.3292, 32.5711),
      LatLng(0.3220, 32.5760),
      LatLng(0.3136, 32.5811),
    ],
    // Route 5 - Nakasero to Mulago (BUS-004)
    [
      LatLng(0.3260, 32.5680),
      LatLng(0.3292, 32.5711),
      LatLng(0.3320, 32.5690),
      LatLng(0.3300, 32.5650),
      LatLng(0.3280, 32.5630),
    ],
  ];

  static const List<String> _busIds = ['BUS-001', 'BUS-002', 'BUS-003', 'BUS-004'];
  static const List<String> _routeNames = [
    'Route 4A - Kampala Loop',
    'Route 14 - Wandegeya → City Square',
    'Route 22 - Kyambogo → City Center',
    'Route 5 - Nakasero → Mulago',
  ];

  // Track state for each bus
  final List<int> _currentIndices = List.filled(_busIds.length, 0);
  final List<double> _progresses = List.filled(_busIds.length, 0.0);
  final Random _random = Random();

  // 🔥 Generate stream for MULTIPLE buses
  Stream<List<BusModel>> simulateMultipleBuses() {
    return Stream.periodic(const Duration(seconds: 2), (_) {
      final List<BusModel> buses = [];

      for (int i = 0; i < _busIds.length; i++) {
        final route = _allRoutes[i % _allRoutes.length];
        _progresses[i] += 0.04 + (_random.nextDouble() * 0.04);

        if (_progresses[i] >= 1.0) {
          _progresses[i] = 0.0;
          _currentIndices[i] = (_currentIndices[i] + 1) % (route.length - 1);
        }

        final start = route[_currentIndices[i]];
        final end = route[(_currentIndices[i] + 1) % route.length];

        final lat = start.latitude + (end.latitude - start.latitude) * _progresses[i];
        final lng = start.longitude + (end.longitude - start.longitude) * _progresses[i];

        // Randomize speed, passengers, and seats per bus
        final speed = 15.0 + (_random.nextDouble() * 25);
        final totalSeats = 40;
        final passengerCount = 8 + _random.nextInt(28);
        final availableSeats = totalSeats - passengerCount;

        buses.add(BusModel(
          id: _busIds[i],
          routeName: _routeNames[i % _routeNames.length],
          position: LatLng(lat, lng),
          speed: speed,
          passengerCount: passengerCount,
          availableSeats: availableSeats.clamp(0, totalSeats),
          totalSeats: totalSeats,
          status: 'active',
          lastUpdated: DateTime.now(),
        ));
      }

      return buses;
    });
  }

  // Keep old method for backward compatibility
  Stream<BusModel> simulateBusMovement(String busId, String routeName) {
    return simulateMultipleBuses().map((buses) {
      return buses.firstWhere((b) => b.id == busId, orElse: () => buses.first);
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  Timer? _timer;
}