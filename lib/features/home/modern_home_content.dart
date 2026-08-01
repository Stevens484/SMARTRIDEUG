import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/destination_page.dart';
import 'package:smartrideug/features/home/saved_places_page.dart';
import 'package:smartrideug/features/map/live_map_screen.dart';

class ModernHomeContent extends StatefulWidget {
  const ModernHomeContent({super.key});

  @override
  State<ModernHomeContent> createState() => _ModernHomeContentState();
}

class _ModernHomeContentState extends State<ModernHomeContent> {
  Position? _position;
  String? _locationName;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) setState(() => _position = position);
      final locationName = await _reverseGeocode(position);
      if (mounted) setState(() => _locationName = locationName);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<String> _reverseGeocode(Position position) async {
    try {
      final response = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'format': 'jsonv2',
              'lat': position.latitude.toString(),
              'lon': position.longitude.toString(),
              'zoom': '16',
            }),
            headers: const {'User-Agent': 'SmartRideUG/1.0'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return 'Current location';

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final rawAddress = result['address'];
      if (rawAddress is! Map) return _displayName(result);
      final address = Map<String, dynamic>.from(rawAddress);

      // Nominatim's address fields differ by location. In Kampala, for
      // example, a GPS result may have a road and suburb but no "city".
      // Keep the most useful nearby place name instead of falling back to the
      // generic "Current location" in that case.
      final street = _addressPart(address, const [
        'road',
        'pedestrian',
        'footway',
        'residential',
      ]);
      final area = _addressPart(address, const [
        'neighbourhood',
        'suburb',
        'quarter',
        'city_district',
        'ward',
        'village',
        'hamlet',
      ]);
      final city = _addressPart(address, const [
        'city',
        'town',
        'municipality',
        'county',
        'state_district',
      ]);
      final parts = <String>[];
      for (final part in [street, area, city]) {
        if (part != null && !parts.contains(part)) parts.add(part);
      }
      return parts.isEmpty ? _displayName(result) : parts.join(', ');
    } catch (_) {
      return 'Current location';
    }
  }

  String? _addressPart(Map<String, dynamic> address, List<String> fields) {
    for (final field in fields) {
      final value = address[field]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String _displayName(Map<String, dynamic> result) {
    final displayName = result['display_name']?.toString().trim();
    if (displayName == null || displayName.isEmpty) return 'Current location';
    return displayName.split(',').take(2).join(',').trim();
  }

  void _openDestination() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const DestinationPage()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim().split(' ').first
        : null;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme),
      ),
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _HeaderAndSearch(
              greeting: greeting,
              name: name,
              onSearch: _openDestination,
              from:
                  _locationName ??
                  (_locating
                      ? 'Finding your location...'
                      : _position == null
                      ? 'Current location unavailable'
                      : 'Current location'),
              userId: user?.uid,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _LiveMap(position: _position),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _ActiveRide(onFindBus: _openDestination),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: _QuickActions(
                onScan: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open the Scan tab to scan a ticket.'),
                  ),
                ),
                onFavorites: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedPlacesPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAndSearch extends StatelessWidget {
  const _HeaderAndSearch({
    required this.greeting,
    required this.name,
    required this.onSearch,
    required this.from,
    required this.userId,
  });

  final String greeting;
  final String? name;
  final VoidCallback onSearch;
  final String from;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final isNarrow = constraints.maxWidth < 350;
        final horizontalPadding = isNarrow ? 12.0 : 16.0;
        return Column(
          children: [
            Container(
              height: isLandscape ? 102 : 126,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                isLandscape ? 12 : 18,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0F2345),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    ClipRect(
                      child: SizedBox(
                        height: 0,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: null,
                              icon: const Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 31,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    children: [
                                      TextSpan(text: 'Smart'),
                                      TextSpan(
                                        text: 'Ride',
                                        style: TextStyle(
                                          color: AppTheme.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: null,
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                Positioned(
                                  right: 5,
                                  top: 2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        height: .8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 4 : 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$greeting${name == null ? '' : ', $name'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLandscape ? 16 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 2 : 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Wherever you're going, we'll get you there.",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFE5E7EB),
                          fontSize: isLandscape ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isLandscape ? 10 : 14,
                horizontalPadding,
                0,
              ),
              child: _RouteSearchCard(
                from: from,
                userId: userId,
                onSearch: onSearch,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RouteSearchCard extends StatefulWidget {
  const _RouteSearchCard({
    required this.from,
    required this.userId,
    required this.onSearch,
  });
  final String from;
  final String? userId;
  final VoidCallback onSearch;

  @override
  State<_RouteSearchCard> createState() => _RouteSearchCardState();
}

class _RouteSearchCardState extends State<_RouteSearchCard> {
  bool _swapped = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final stackFields = constraints.maxWidth < 350;
        final compact = isLandscape || constraints.maxWidth < 390;
        final fieldHeight = compact ? 56.0 : 62.0;
        final swapSize = compact ? 42.0 : 48.0;
        final colorScheme = Theme.of(context).colorScheme;
        final firstField = _LocationField(
          label: _swapped ? 'Where to?' : 'From',
          value: _swapped ? 'Choose a starting point' : widget.from,
          isDestination: _swapped,
          height: fieldHeight,
          onTap: widget.onSearch,
        );
        final secondField = _LocationField(
          label: _swapped ? 'From' : 'Where to?',
          value: _swapped ? widget.from : 'Search destination or route',
          isDestination: !_swapped,
          height: fieldHeight,
          onTap: widget.onSearch,
        );
        final swapButton = IconButton(
          tooltip: 'Swap locations',
          onPressed: () => setState(() => _swapped = !_swapped),
          icon: Icon(
            stackFields ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
            size: compact ? 22 : 25,
          ),
          color: colorScheme.onSurface,
          style: IconButton.styleFrom(
            fixedSize: Size.square(swapSize),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        );

        return Container(
          padding: EdgeInsets.all(compact ? 12 : 18),
          decoration: _cardDecoration(context, radius: compact ? 20 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stackFields) ...[
                firstField,
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: swapButton,
                  ),
                ),
                secondField,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: firstField),
                    SizedBox(width: compact ? 6 : 10),
                    Padding(
                      padding: EdgeInsets.only(bottom: fieldHeight - swapSize),
                      child: swapButton,
                    ),
                    SizedBox(width: compact ? 6 : 10),
                    Expanded(child: secondField),
                  ],
                ),
              SizedBox(height: compact ? 12 : 18),
              Text(
                'Recent searches',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _RecentSearches(userId: widget.userId, onTap: widget.onSearch),
            ],
          ),
        );
      },
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.value,
    required this.isDestination,
    required this.height,
    required this.onTap,
  });
  final String label;
  final String value;
  final bool isDestination;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: height <= 56 ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: height <= 56 ? 5 : 7),
      Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isDestination
                        ? Icons.search_rounded
                        : Icons.location_on_rounded,
                    color: isDestination
                        ? const Color(0xFF9CA3AF)
                        : AppTheme.orange,
                    size: height <= 56 ? 20 : 23,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: height <= 56 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDestination
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: height <= 56 ? 12 : 13,
                        fontWeight: isDestination
                            ? FontWeight.w400
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.userId, required this.onTap});
  final String? userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Text(
        'Your recent destinations will appear here.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final raw = snapshot.data?.data()?['recentSearches'];
        final searches = raw is List
            ? raw
                  .map(
                    (item) => item is Map
                        ? (item['name'] ?? item['destination'])?.toString()
                        : item.toString(),
                  )
                  .whereType<String>()
                  .where((item) => item.trim().isNotEmpty)
                  .take(4)
                  .toList()
            : <String>[];
        if (searches.isEmpty) {
          return Text(
            'Your recent destinations will appear here.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches
              .map(
                (search) => ActionChip(
                  label: Text(search),
                  onPressed: onTap,
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _NearbyBuses extends StatelessWidget {
  const _NearbyBuses({required this.onBook});
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
    decoration: _cardDecoration(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Nearby Buses',
              style: TextStyle(
                color: Color(0xFF0F2345),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: onBook, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: MediaQuery.of(context).orientation == Orientation.landscape
              ? 210
              : 260,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('busLocations')
                .where(
                  'status',
                  whereIn: const [
                    'online',
                    'moving',
                    'approaching_stop',
                    'stopped',
                  ],
                )
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              final buses =
                  snapshot.data?.docs
                      .map(_Bus.fromDocument)
                      .whereType<_Bus>()
                      .toList() ??
                  const <_Bus>[];
              if (buses.isEmpty) return const _EmptyBuses();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: buses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) =>
                    _BusCard(bus: buses[index], onBook: onBook),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _EmptyBuses extends StatelessWidget {
  const _EmptyBuses();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_bus_outlined, color: Color(0xFF9CA3AF), size: 42),
        SizedBox(height: 8),
        Text(
          'No nearby buses are currently online.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    ),
  );
}

class _BusCard extends StatelessWidget {
  const _BusCard({required this.bus, required this.onBook});
  final _Bus bus;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final color = bus.seats == 0
        ? const Color(0xFFEF4444)
        : bus.seats <= 3
        ? const Color(0xFFF59E0B)
        : const Color(0xFF22C55E);
    final isFull = bus.seats == 0;
    return Container(
      width: 174,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 23,
              backgroundColor: color,
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            bus.number,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bus.route,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            bus.eta ?? 'Live location',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isFull ? 'Full' : '${bus.seats} seats available',
            style: TextStyle(
              color: isFull ? color : const Color(0xFF111827),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  bus.price ?? 'Fare unavailable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: isFull ? null : onBook,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    backgroundColor: isFull
                        ? const Color(0xFFFEE2E2)
                        : AppTheme.orange,
                    foregroundColor: isFull
                        ? const Color(0xFFEF4444)
                        : Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(isFull ? 'Full' : 'Book'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveMap extends StatelessWidget {
  const _LiveMap({required this.position});
  final Position? position;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: _cardDecoration(context),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
          child: Row(
            children: [
              const Text(
                'Live Map',
                style: TextStyle(
                  color: Color(0xFF0F2345),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveMapScreen()),
                ),
                child: const Text('View full map'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).orientation == Orientation.landscape
              ? 230
              : 350,
          child: _MapCanvas(position: position),
        ),
      ],
    ),
  );
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.position});
  final Position? position;
  @override
  Widget build(BuildContext context) {
    final here = position == null
        ? const LatLng(0.3476, 32.5825)
        : LatLng(position!.latitude, position!.longitude);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('busLocations')
          .where(
            'status',
            whereIn: const ['online', 'moving', 'approaching_stop'],
          )
          .snapshots(),
      builder: (_, snapshot) => FlutterMap(
        options: MapOptions(
          initialCenter: here,
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.smartrideug.app',
          ),
          MarkerLayer(
            markers: [
              if (position != null)
                Marker(
                  point: here,
                  width: 42,
                  height: 42,
                  child: const _MapPin(
                    icon: Icons.person_pin_circle,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ..._busMarkers(snapshot.data),
            ],
          ),
        ],
      ),
    );
  }

  List<Marker> _busMarkers(QuerySnapshot<Map<String, dynamic>>? snapshot) =>
      (snapshot?.docs ?? const [])
          .map((document) {
            final data = document.data();
            final latitude =
                (data['currentLatitude'] ?? data['latitude']) as num?;
            final longitude =
                (data['currentLongitude'] ?? data['longitude']) as num?;
            if (latitude == null || longitude == null) return null;
            return Marker(
              point: LatLng(latitude.toDouble(), longitude.toDouble()),
              width: 38,
              height: 38,
              child: const _MapPin(
                icon: Icons.directions_bus_rounded,
                color: AppTheme.orange,
              ),
            );
          })
          .whereType<Marker>()
          .toList();
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x220F2345),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 21),
  );
}

class _ActiveRide extends StatelessWidget {
  const _ActiveRide({required this.onFindBus});
  final VoidCallback onFindBus;
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return _NoActiveRide(onFindBus: onFindBus);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('passengerId', isEqualTo: userId)
          .limit(10)
          .snapshots(),
      builder: (_, snapshot) {
        final active = snapshot.data?.docs
            .map((doc) => doc.data())
            .where(
              (data) => const [
                'confirmed',
                'held',
                'active',
                'boarding',
              ].contains(data['status']?.toString().toLowerCase()),
            )
            .cast<Map<String, dynamic>>()
            .firstOrNull;
        return active == null
            ? _NoActiveRide(onFindBus: onFindBus)
            : _RideSummary(booking: active);
      },
    );
  }
}

class _NoActiveRide extends StatelessWidget {
  const _NoActiveRide({required this.onFindBus});
  final VoidCallback onFindBus;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(context),
    child: Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: AppTheme.orange,
            size: 37,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No active ride',
                style: TextStyle(
                  color: Color(0xFF0F2345),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Find a bus and reserve your seat.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onFindBus,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: const Text('Find a Bus'),
        ),
      ],
    ),
  );
}

class _RideSummary extends StatelessWidget {
  const _RideSummary({required this.booking});
  final Map<String, dynamic> booking;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(context),
    child: Row(
      children: [
        const Icon(
          Icons.directions_bus_rounded,
          color: AppTheme.orange,
          size: 42,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active ride',
                style: TextStyle(
                  color: Color(0xFF0F2345),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                (booking['destination'] ??
                        booking['routeName'] ??
                        'Your booked journey')
                    .toString(),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7280)),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onScan, required this.onFavorites});
  final VoidCallback onScan;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = constraints.maxWidth >= 560
          ? 220.0
          : (constraints.maxWidth - 12) / 2;
      return Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _Action(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan Ticket',
                color: const Color(0xFF22C55E),
                onTap: onScan,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _Action(
                icon: Icons.star_border_rounded,
                label: 'Favorite',
                color: const Color(0xFFEF4444),
                onTap: onFavorites,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: MediaQuery.of(context).orientation == Orientation.landscape
            ? 96
            : 118,
        padding: EdgeInsets.symmetric(
          horizontal: 5,
          vertical: MediaQuery.of(context).orientation == Orientation.landscape
              ? 10
              : 15,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: MediaQuery.of(context).orientation == Orientation.landscape
                  ? 25
                  : 29,
            ),
            SizedBox(
              height:
                  MediaQuery.of(context).orientation == Orientation.landscape
                  ? 7
                  : 12,
            ),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F2345),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Bus {
  const _Bus({
    required this.number,
    required this.route,
    required this.seats,
    this.eta,
    this.price,
  });
  final String number;
  final String route;
  final int seats;
  final String? eta;
  final String? price;
  static _Bus? fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return null;
    final number = data['busNumber']?.toString();
    if (number == null || number.isEmpty) return null;
    final seats = (data['availableSeats'] as num?)?.toInt() ?? 0;
    return _Bus(
      number: 'Bus $number',
      route:
          (data['routeName'] ?? data['routeId'] ?? 'Route details unavailable')
              .toString(),
      seats: seats,
      eta: data['eta']?.toString(),
      price: data['fare']?.toString(),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context, {double radius = 20}) =>
    BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .24 : .07,
          ),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
