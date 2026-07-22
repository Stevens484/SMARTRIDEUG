import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';

class BusSimulationService {
  static final BusSimulationService _instance =
      BusSimulationService._internal();
  factory BusSimulationService() => _instance;
  BusSimulationService._internal();

  static final List<LatLng> _routePoints = const [
    LatLng(0.3136, 32.5811),
    LatLng(0.3180, 32.5780),
    LatLng(0.3220, 32.5760),
    LatLng(0.3292, 32.5711),
    LatLng(0.3340, 32.5675),
    LatLng(0.3300, 32.5650),
    LatLng(0.3260, 32.5680),
  ];

  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;

  Stream<BusModel> simulateBusMovement(String busId, String routeName) {
    return Stream.periodic(const Duration(seconds: 2), (_) {
      _progress += 0.05;
      if (_progress >= 1.0) {
        _progress = 0.0;
        _currentIndex = (_currentIndex + 1) % (_routePoints.length - 1);
      }

      final start = _routePoints[_currentIndex];
      final end = _routePoints[(_currentIndex + 1) % _routePoints.length];

      final lat = start.latitude + (end.latitude - start.latitude) * _progress;
      final lng =
          start.longitude + (end.longitude - start.longitude) * _progress;

      final speed = 20.0 + (DateTime.now().millisecond % 20);
      final passengers = 15 + (DateTime.now().millisecond % 20);
      final totalSeats = 40;

      return BusModel(
        id: busId,
        routeName: routeName,
        position: LatLng(lat, lng),
        speed: speed,
        passengerCount: passengers,
        availableSeats: totalSeats - passengers,
        totalSeats: totalSeats,
        status: 'active',
        lastUpdated: DateTime.now(),
      );
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
