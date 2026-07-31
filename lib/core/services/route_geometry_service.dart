import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/services/osrm_routing_service.dart';

/// Resolves the actual road geometry for a configured transit route.
///
/// Route stop coordinates are preferred because they are maintained by the
/// administrator. If stops have not been configured yet, the route's saved
/// endpoint coordinates are used; as a last resort the endpoint names are
/// geocoded in Uganda. No map screen uses fixed sample coordinates.
class RouteGeometryService {
  RouteGeometryService({
    FirebaseFirestore? firestore,
    OsrmRoutingService? routing,
    http.Client? client,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _routing = routing ?? OsrmRoutingService(),
       _client = client ?? http.Client();

  final FirebaseFirestore _firestore;
  final OsrmRoutingService _routing;
  final http.Client _client;

  final Map<String, Future<RouteGeometry>> _cache = {};
  final Map<String, Future<LatLng>> _placeCache = {};

  Future<RouteGeometry> resolve({
    required String routeId,
    required Map<String, dynamic> route,
  }) => _cache.putIfAbsent(
    routeId,
    () => _resolve(routeId: routeId, route: route),
  );

  void invalidate(String routeId) => _cache.remove(routeId);

  /// Finds a real Ugandan map location for an administrator-entered stop name.
  ///
  /// This is public so the stop editor can store coordinates once, rather than
  /// making every passenger device geocode the same stop later.
  Future<LatLng> resolvePlace(String place) {
    final query = place.trim();
    if (query.isEmpty) {
      throw ArgumentError.value(place, 'place', 'A stop name is required.');
    }
    return _placeCache.putIfAbsent(query, () => _geocode(query));
  }

  Future<RouteGeometry> _resolve({
    required String routeId,
    required Map<String, dynamic> route,
  }) async {
    final stopPoints = await _stopsFor(routeId);
    final endpoints = stopPoints.length >= 2
        ? stopPoints
        : [
            await _endpoint(route, 'origin'),
            await _endpoint(route, 'destination'),
          ];

    try {
      final roadRoute = await _routing.routeThrough(endpoints);
      return RouteGeometry(
        origin: endpoints.first,
        destination: endpoints.last,
        points: roadRoute.points,
        duration: roadRoute.duration,
      );
    } catch (_) {
      // The endpoints are still the genuine configured locations. The UI can
      // render this as a temporary direct connection while routing recovers.
      return RouteGeometry(
        origin: endpoints.first,
        destination: endpoints.last,
        points: endpoints,
      );
    }
  }

  Future<List<LatLng>> _stopsFor(String routeId) async {
    final snapshot = await _firestore
        .collection('routes')
        .doc(routeId)
        .collection('stops')
        .get();
    final stops = snapshot.docs.toList()
      ..sort(
        (left, right) => ((left.data()['order'] as num?)?.toInt() ?? 999999)
            .compareTo((right.data()['order'] as num?)?.toInt() ?? 999999),
      );
    return stops
        .map((document) => _pointFrom(document.data(), ''))
        .whereType<LatLng>()
        .toList();
  }

  Future<LatLng> _endpoint(Map<String, dynamic> route, String field) async {
    final saved = _pointFrom(route, field);
    if (saved != null) return saved;
    final place = route[field]?.toString().trim() ?? '';
    if (place.isEmpty) {
      throw StateError('This route does not have a $field location.');
    }
    return resolvePlace(place);
  }

  LatLng? _pointFrom(Map<String, dynamic> data, String prefix) {
    final latitudeKey = prefix.isEmpty ? 'latitude' : '${prefix}Lat';
    final longitudeKey = prefix.isEmpty ? 'longitude' : '${prefix}Lng';
    final latitude = data[latitudeKey];
    final longitude = data[longitudeKey];
    if (latitude is num && longitude is num) {
      final lat = latitude.toDouble();
      final lng = longitude.toDouble();
      if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  Future<LatLng> _geocode(String place) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$place, Kampala, Uganda',
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'ug',
    });
    final response = await _client
        .get(
          uri,
          headers: const {
            'User-Agent': 'SmartRideUg/1.0 (route planning)',
            'Accept-Language': 'en',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Could not find $place.');
    }
    final results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) throw StateError('Could not find $place.');
    final result = results.first as Map<String, dynamic>;
    final latitude = double.tryParse(result['lat']?.toString() ?? '');
    final longitude = double.tryParse(result['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) {
      throw StateError('Could not find $place.');
    }
    return LatLng(latitude, longitude);
  }
}

class RouteGeometry {
  const RouteGeometry({
    required this.origin,
    required this.destination,
    required this.points,
    this.duration,
  });

  final LatLng origin;
  final LatLng destination;
  final List<LatLng> points;
  final Duration? duration;
}
