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
    final geo = data['location'] as GeoPoint;
    return BusModel(
      id: docId,
      routeName: data['routeName'] ?? 'Unknown Route',
      position: LatLng(geo.latitude, geo.longitude),
      speed: (data['speed'] ?? 0.0).toDouble(),
      passengerCount: data['passengerCount'] ?? 0,
      availableSeats: data['availableSeats'] ?? data['totalSeats'] ?? 0,
      totalSeats: data['totalSeats'] ?? 40,
      status: data['status'] ?? 'active',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
