import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // 🔥 ADD THIS IMPORT
import 'package:latlong2/latlong.dart';

class BusModel {
  final String id;
  final String routeName;
  final LatLng position;
  final double speed;
  final int passengerCount;
  final int availableSeats;
  final int totalSeats;
  final String status;
  final DateTime lastUpdated;

  BusModel({
    required this.id,
    required this.routeName,
    required this.position,
    required this.speed,
    required this.passengerCount,
    required this.availableSeats,
    required this.totalSeats,
    required this.status,
    required this.lastUpdated,
  });

  Color get seatColor {
    if (availableSeats >= 15) return Colors.green;
    if (availableSeats >= 5) return Colors.orange;
    return Colors.red;
  }

  String get seatStatus {
    if (availableSeats >= 15) return 'Available';
    if (availableSeats >= 5) return 'Limited';
    return 'Full';
  }

  factory BusModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final location = data['location'];
    final latitude = location is GeoPoint
        ? location.latitude
        : (data['latitude'] as num?)?.toDouble() ?? 0;
    final longitude = location is GeoPoint
        ? location.longitude
        : (data['longitude'] as num?)?.toDouble() ?? 0;
    final updatedAt = data['updatedAt'] ?? data['lastUpdated'];
    return BusModel(
      id: docId,
      routeName: data['routeName'] ?? 'Unknown Route',
      position: LatLng(latitude, longitude),
      speed: (data['speed'] ?? 0.0).toDouble(),
      passengerCount: data['passengerCount'] ?? 0,
      availableSeats: data['availableSeats'] ?? data['totalSeats'] ?? 0,
      totalSeats: data['totalSeats'] ?? 40,
      status: data['status'] ?? 'active',
      lastUpdated: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
    );
  }
}
