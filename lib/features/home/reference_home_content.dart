import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/destination_page.dart';
import 'package:smartrideug/features/home/settings_page.dart';
import 'package:smartrideug/features/map/live_map_screen.dart';

/// Passenger landing view driven by the device location and live bus records.
class ReferenceHomeContent extends StatefulWidget {
  const ReferenceHomeContent({super.key});

  @override
  State<ReferenceHomeContent> createState() => _ReferenceHomeContentState();
}

class _ReferenceHomeContentState extends State<ReferenceHomeContent> {
  Position? _position;
  String? _locationError;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationException(
          'Turn on location services to see your position.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _LocationException('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _position = position);
    } on _LocationException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Unable to get your current location.');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _openDestination() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DestinationPage()));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.grey50,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        children: [
          const Text(
            'Good afternoon, there',
            style: TextStyle(
              color: AppTheme.grey500,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Where are you\\ngoing?',
            style: TextStyle(
              color: AppTheme.grey900,
              fontSize: 42,
              height: .98,
              letterSpacing: -1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          _SearchCard(
            onSearchTap: _openDestination,
            onSettingsTap: _openSettings,
          ),
          const SizedBox(height: 26),
          _LocationCard(
            position: _position,
            isLocating: _isLocating,
            errorMessage: _locationError,
            onRefresh: _isLocating ? null : _loadLocation,
          ),
          const SizedBox(height: 26),
          _MapPreview(
            position: _position,
            isLocating: _isLocating,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LiveMapScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.onSearchTap, required this.onSettingsTap});

  final VoidCallback onSearchTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 8,
      shadowColor: AppTheme.navy.withValues(alpha: .15),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.search,
                          color: AppTheme.orange,
                          size: 34,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search destination\\nor route',
                          style: TextStyle(
                            color: AppTheme.grey500,
                            fontSize: 26,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Settings',
              child: InkWell(
                onTap: onSettingsTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.position,
    required this.isLocating,
    required this.errorMessage,
    required this.onRefresh,
  });

  final Position? position;
  final bool isLocating;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final details = switch ((position, isLocating, errorMessage)) {
      (_, true, _) => const (
        'Finding your location',
        'Please wait...',
        Icons.my_location,
      ),
      (final position?, _, _) => (
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        'Accuracy \\u00B1${position.accuracy.round()} m',
        Icons.gps_fixed,
      ),
      (_, _, final error?) => (
        'Location unavailable',
        error,
        Icons.location_off,
      ),
      _ => const (
        'Location unavailable',
        'Tap refresh to try again.',
        Icons.location_off,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppTheme.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: AppTheme.orange,
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current location',
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.$1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.grey900,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(details.$3, color: AppTheme.grey500, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        details.$2,
                        style: const TextStyle(
                          color: AppTheme.grey500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh location',
            onPressed: onRefresh,
            icon: isLocating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppTheme.grey500, size: 30),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.position,
    required this.isLocating,
    required this.onTap,
  });

  final Position? position;
  final bool isLocating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = position == null
        ? null
        : LatLng(position!.latitude, position!.longitude);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 16, 18),
              child: Row(
                children: [
                  Text(
                    'Live map',
                    style: TextStyle(
                      color: AppTheme.grey900,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.circle, color: AppTheme.orange, size: 12),
                  ),
                  Spacer(),
                  Icon(Icons.map_outlined, color: AppTheme.orange, size: 28),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'View full map',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.orange,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 230,
            child: location == null
                ? _MapUnavailable(isLocating: isLocating)
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('busLocations')
                        .where(
                          'status',
                          whereIn: const [
                            'online',
                            'moving',
                            'approaching_stop',
                          ],
                        )
                        .snapshots(),
                    builder: (context, snapshot) => FlutterMap(
                      options: MapOptions(
                        initialCenter: location,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.mhl.smartrideug',
                        ),
                        MarkerLayer(markers: _markers(location, snapshot.data)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Marker> _markers(
    LatLng userLocation,
    QuerySnapshot<Map<String, dynamic>>? buses,
  ) {
    final markers = <Marker>[
      Marker(
        point: userLocation,
        width: 58,
        height: 58,
        child: const _UserMarker(),
      ),
    ];
    for (final bus in buses?.docs ?? const []) {
      final data = bus.data();
      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) continue;
      markers.add(
        Marker(
          point: LatLng(latitude, longitude),
          width: 48,
          height: 48,
          child: const _BusMarker(),
        ),
      );
    }
    return markers;
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable({required this.isLocating});
  final bool isLocating;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTheme.grey100,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLocating)
            const CircularProgressIndicator(color: AppTheme.orange)
          else
            const Icon(Icons.location_off, color: AppTheme.grey500, size: 34),
          const SizedBox(height: 10),
          Text(
            isLocating
                ? 'Loading your map...'
                : 'Enable location to preview the map.',
            style: const TextStyle(color: AppTheme.grey500),
          ),
        ],
      ),
    ),
  );
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.navy,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
    ),
    child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 30),
  );
}

class _BusMarker extends StatelessWidget {
  const _BusMarker();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.orange,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: [
        BoxShadow(
          color: AppTheme.navy.withValues(alpha: .22),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: const Icon(Icons.directions_bus, color: Colors.white, size: 26),
  );
}

class _LocationException implements Exception {
  const _LocationException(this.message);
  final String message;
}
