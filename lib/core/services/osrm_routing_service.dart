import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRoute {
  const OsrmRoute({required this.points, required this.duration});

  final List<LatLng> points;
  final Duration duration;
}

/// Retrieves road-following route geometry and travel time from OSRM.
class OsrmRoutingService {
  OsrmRoutingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<OsrmRoute> route({
    required LatLng origin,
    required LatLng destination,
  }) => routeThrough([origin, destination]);

  /// Retrieves a road-following route through every supplied waypoint.
  /// This keeps an assigned bus route on real roads instead of connecting its
  /// stops with straight, hard-coded map lines.
  Future<OsrmRoute> routeThrough(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      throw ArgumentError.value(
        waypoints,
        'waypoints',
        'At least an origin and destination are required.',
      );
    }
    final waypointCoordinates = waypoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$waypointCoordinates',
      const {'overview': 'full', 'geometries': 'geojson'},
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Routing is temporarily unavailable.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = body['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty)
      throw StateError('No road route was found.');
    final route = routes.first as Map<String, dynamic>;
    final routeCoordinates =
        (route['geometry'] as Map<String, dynamic>)['coordinates']
            as List<dynamic>;
    return OsrmRoute(
      points: routeCoordinates.map((point) {
        final pair = point as List<dynamic>;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList(),
      duration: Duration(seconds: ((route['duration'] as num?) ?? 0).round()),
    );
  }
}
