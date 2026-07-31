import 'package:latlong2/latlong.dart';

/// A lightweight, read-only ETA estimator for a bus's ordered pickup stops.
/// It deliberately uses the live bus coordinate already published by the
/// operator; no booking, capacity, or reservation state is changed.
class BusEtaService {
  const BusEtaService();

  static const _fallbackSpeedKph = 24.0;
  static const _roadDistanceFactor = 1.22;
  static const _arrivingDistanceMetres = 180.0;

  List<StopEta> estimate({
    required LatLng? busLocation,
    required List<EtaStop> stops,
    num? speedKph,
    DateTime? now,
  }) {
    final requestedAt = now ?? DateTime.now();
    if (busLocation == null) {
      return stops
          .map((stop) => StopEta(stop: stop, state: StopEtaState.unavailable))
          .toList();
    }

    final distance = const Distance();
    final locatedStops = stops
        .asMap()
        .entries
        .where((entry) => entry.value.location != null)
        .toList();
    if (locatedStops.isEmpty) {
      return stops
          .map((stop) => StopEta(stop: stop, state: StopEtaState.unavailable))
          .toList();
    }

    final nearest = locatedStops.reduce(
      (left, right) =>
          distance
                  .as(LengthUnit.Meter, busLocation, left.value.location!)
                  .compareTo(
                    distance.as(
                      LengthUnit.Meter,
                      busLocation,
                      right.value.location!,
                    ),
                  ) <=
              0
          ? left
          : right,
    );
    final nearestDistance = distance.as(
      LengthUnit.Meter,
      busLocation,
      nearest.value.location!,
    );
    final effectiveSpeed = ((speedKph?.toDouble() ?? _fallbackSpeedKph).clamp(
      10.0,
      55.0,
    )).toDouble();
    var metresRemaining = nearestDistance * _roadDistanceFactor;
    final results = <StopEta>[];

    for (var index = 0; index < stops.length; index++) {
      final stop = stops[index];
      if (stop.location == null) {
        results.add(StopEta(stop: stop, state: StopEtaState.unavailable));
        continue;
      }
      if (index < nearest.key) {
        results.add(StopEta(stop: stop, state: StopEtaState.passed));
        continue;
      }
      if (index > nearest.key) {
        final previous = stops[index - 1].location;
        if (previous != null) {
          metresRemaining +=
              distance.as(LengthUnit.Meter, previous, stop.location!) *
              _roadDistanceFactor;
        }
      }
      final minutes = (metresRemaining / (effectiveSpeed * 1000 / 60)).ceil();
      final cappedMinutes = minutes.clamp(0, 24 * 60).toInt();
      results.add(
        StopEta(
          stop: stop,
          state:
              nearestDistance <= _arrivingDistanceMetres && index == nearest.key
              ? StopEtaState.arriving
              : StopEtaState.upcoming,
          minutes: cappedMinutes,
          arrivalTime: requestedAt.add(Duration(minutes: cappedMinutes)),
        ),
      );
    }
    return results;
  }
}

class EtaStop {
  const EtaStop({required this.id, required this.name, this.location});
  final String id;
  final String name;
  final LatLng? location;
}

class StopEta {
  const StopEta({
    required this.stop,
    required this.state,
    this.minutes,
    this.arrivalTime,
  });
  final EtaStop stop;
  final StopEtaState state;
  final int? minutes;
  final DateTime? arrivalTime;
}

enum StopEtaState { arriving, upcoming, passed, unavailable }
