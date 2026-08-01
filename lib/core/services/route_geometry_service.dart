import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resolves a route using the ordered, administrator-managed stops first and
/// OSRM road geometry second. Results are cached per route revision.
class RouteGeometryService {
  RouteGeometryService({FirebaseFirestore? firestore, http.Client? client})
    : _db = firestore ?? FirebaseFirestore.instance,
      _client = client ?? http.Client();

  final FirebaseFirestore _db;
  final http.Client _client;
  final Map<String, Future<RouteGeometry>> _cache = {};

  Future<RouteGeometry> resolve({
    required String routeId,
    required Map<String, dynamic> route,
  }) {
    final cacheKey =
        '$routeId:${route['updatedAt'] ?? route['polyline'] ?? ''}';
    return _cache.putIfAbsent(
      cacheKey,
      () => _resolve(routeId: routeId, route: route),
    );
  }

  void invalidate(String routeId) =>
      _cache.removeWhere((key, _) => key.startsWith('$routeId:'));

  Future<RouteGeometry> _resolve({
    required String routeId,
    required Map<String, dynamic> route,
  }) async {
    final stops = await _stops(routeId, route);
    final origin =
        _coordinate(route, 'origin') ??
        (stops.isNotEmpty ? stops.first.position : null) ??
        await _geocode(route['origin']?.toString());
    final destination =
        _coordinate(route, 'destination') ??
        (stops.isNotEmpty ? stops.last.position : null) ??
        await _geocode(route['destination']?.toString());
    if (origin == null || destination == null) {
      throw StateError('This route needs origin and destination coordinates.');
    }

    final waypoints =
        <LatLng>[
          origin,
          ...stops.map((stop) => stop.position),
          destination,
        ].fold<List<LatLng>>([], (result, point) {
          if (result.isEmpty || result.last != point) result.add(point);
          return result;
        });
    final cached = route['polyline']?.toString();
    if (cached != null && cached.isNotEmpty) {
      final points = decodePolyline(cached, precision: 6);
      if (points.length >= 2) {
        return RouteGeometry(
          origin: origin,
          destination: destination,
          stops: stops,
          points: points,
        );
      }
    }

    try {
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline6',
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw StateError('OSRM route unavailable.');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>? ?? const [];
      final geometry = routes.isEmpty
          ? null
          : routes.first['geometry']?.toString();
      final points = geometry == null
          ? const <LatLng>[]
          : decodePolyline(geometry, precision: 6);
      if (points.length >= 2) {
        return RouteGeometry(
          origin: origin,
          destination: destination,
          stops: stops,
          points: points,
        );
      }
    } catch (_) {
      // The configured stop sequence remains a valid visual fallback while
      // OSRM is temporarily unavailable.
    }
    return RouteGeometry(
      origin: origin,
      destination: destination,
      stops: stops,
      points: waypoints,
    );
  }

  Future<List<RouteStop>> _stops(
    String routeId,
    Map<String, dynamic> route,
  ) async {
    final snapshot = await _db
        .collection('routes')
        .doc(routeId)
        .collection('stops')
        .get();
    final documents = snapshot.docs.toList()
      ..sort(
        (a, b) => ((a.data()['order'] as num?)?.toInt() ?? 99999).compareTo(
          (b.data()['order'] as num?)?.toInt() ?? 99999,
        ),
      );
    final configured = documents
        .map((document) => _stop(document.id, document.data()))
        .whereType<RouteStop>()
        .toList();
    if (configured.isNotEmpty) return configured;
    final embedded = route['stops'] as List<dynamic>? ?? const [];
    return embedded
        .whereType<Map>()
        .map(
          (data) => _stop(
            data['id']?.toString() ?? data['name']?.toString() ?? '',
            Map<String, dynamic>.from(data),
          ),
        )
        .whereType<RouteStop>()
        .toList();
  }

  RouteStop? _stop(String id, Map<String, dynamic> data) {
    final point = _point(
      data['latitude'] ?? data['lat'],
      data['longitude'] ?? data['lng'],
    );
    if (point == null) return null;
    return RouteStop(
      id: id,
      name: data['name']?.toString() ?? 'Stop',
      position: point,
    );
  }

  LatLng? _coordinate(Map<String, dynamic> data, String prefix) => _point(
    data['${prefix}Lat'] ??
        data['${prefix}Latitude'] ??
        (data[prefix] is Map ? (data[prefix] as Map)['latitude'] : null) ??
        (data[prefix] is GeoPoint ? (data[prefix] as GeoPoint).latitude : null),
    data['${prefix}Lng'] ??
        data['${prefix}Longitude'] ??
        (data[prefix] is Map ? (data[prefix] as Map)['longitude'] : null) ??
        (data[prefix] is GeoPoint
            ? (data[prefix] as GeoPoint).longitude
            : null),
  );

  LatLng? _point(dynamic latitude, dynamic longitude) {
    if (latitude is GeoPoint) {
      return LatLng(latitude.latitude, latitude.longitude);
    }
    if (latitude is! num || longitude is! num) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }

  /// Older routes were saved with place names but no coordinates. Resolve
  /// those names through OpenStreetMap's Nominatim service so their route map
  /// can still be drawn; administrator-provided coordinates always win.
  Future<LatLng?> _geocode(String? place) async {
    if (place == null || place.trim().isEmpty) return null;
    try {
      final response = await _client
          .get(
            Uri.https('nominatim.openstreetmap.org', '/search', {
              'q': '$place, Uganda',
              'format': 'jsonv2',
              'limit': '1',
            }),
            headers: {'User-Agent': 'SmartRideUG/1.0'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty || results.first is! Map) return null;
      final result = results.first as Map<String, dynamic>;
      return LatLng(
        double.parse(result['lat'].toString()),
        double.parse(result['lon'].toString()),
      );
    } catch (_) {
      return null;
    }
  }

  static List<LatLng> decodePolyline(String encoded, {int precision = 5}) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    while (index < encoded.length) {
      int decodeValue() {
        var shift = 0;
        var result = 0;
        int byte;
        do {
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20 && index < encoded.length);
        return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      }

      latitude += decodeValue();
      longitude += decodeValue();
      final factor = precision == 6 ? 1000000.0 : 100000.0;
      points.add(LatLng(latitude / factor, longitude / factor));
    }
    return points;
  }
}

class RouteGeometry {
  const RouteGeometry({
    required this.origin,
    required this.destination,
    required this.stops,
    required this.points,
  });
  final LatLng origin;
  final LatLng destination;
  final List<RouteStop> stops;
  final List<LatLng> points;
}

class RouteStop {
  const RouteStop({
    required this.id,
    required this.name,
    required this.position,
  });
  final String id;
  final String name;
  final LatLng position;
}
