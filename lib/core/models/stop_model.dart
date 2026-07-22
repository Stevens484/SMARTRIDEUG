import 'package:latlong2/latlong.dart';

class StopModel {
  final String id;
  final String name;
  final LatLng position;
  final List<String> routes;

  StopModel({
    required this.id,
    required this.name,
    required this.position,
    this.routes = const [],
  });
}
