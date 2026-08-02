import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/features/home/destination_page.dart';
import 'package:smartrideug/features/home/bus_details_page.dart';
import 'package:smartrideug/features/home/saved_places_page.dart';
import 'package:smartrideug/features/home/seat_reservations_page.dart';

/// The passenger landing page.  It intentionally keeps the map preview light
/// weight; the interactive, location-aware map remains available on tap.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.guestMode,
    required this.onGuestAction,
  });

  final bool guestMode;
  final void Function(String feature) onGuestAction;

  void _openDestination(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DestinationPage()));
  }

  void _openBookings(BuildContext context) {
    if (guestMode) {
      onGuestAction('bookings');
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SeatReservationsPage()));
  }

  void _openSavedPlaces(BuildContext context) {
    if (guestMode) {
      onGuestAction('saved places');
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SavedPlacesPage()));
  }

  void _openMap(BuildContext context) =>
      Navigator.of(context).pushNamed('/live-map');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final name = guestMode
        ? 'there'
        : user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim().split(' ').first
        : user?.email?.split('@').first ?? 'Rider';

    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good afternoon, $name 👋',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Where are you going?',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 27,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DestinationSearch(onTap: () => _openDestination(context)),
                  const SizedBox(height: 20),
                  _CurrentLocationCard(onMapTap: () => _openMap(context)),
                  const SizedBox(height: 20),
                  _MapPreviewCard(onTap: () => _openMap(context)),
                  const SizedBox(height: 20),
                  const _NearbyBusesCard(),
                  const SizedBox(height: 20),
                  _NextTripCard(
                    guestMode: guestMode,
                    onGuestAction: onGuestAction,
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeading('Quick actions'),
                  const SizedBox(height: 12),
                  _QuickActions(
                    onBook: () => _openBookings(context),
                    onScan: () => _showComingSoon(context, 'Scan boarding QR'),
                    onTrips: () => _openBookings(context),
                    onSaved: () => _openSavedPlaces(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String action) {
    if (guestMode) {
      onGuestAction(action.toLowerCase());
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action is available from the Scan tab.')),
    );
  }
}

class _DestinationSearch extends StatelessWidget {
  const _DestinationSearch({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: _cardDecoration(context, radius: 17),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 31,
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  'Search destination or route',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 17,
                  ),
                ),
              ),
              Container(
                width: 53,
                height: 57,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: .22),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({required this.onMapTap});
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 390;
      final colors = Theme.of(context).colorScheme;
      return Container(
        padding: EdgeInsets.all(isNarrow ? 12 : 16),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            Container(
              width: isNarrow ? 58 : 68,
              height: isNarrow ? 58 : 68,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: colors.primary,
                size: 37,
              ),
            ),
            SizedBox(width: isNarrow ? 10 : 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current location',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Makerere Main Gate',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.gps_fixed_rounded,
                        color: colors.onSurfaceVariant,
                        size: 15,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Accuracy ±8 m',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            isNarrow
                ? IconButton.outlined(
                    tooltip: 'Update location',
                    onPressed: onMapTap,
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                    style: IconButton.styleFrom(
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onMapTap,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Update'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      side: BorderSide(color: colors.outlineVariant),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ],
        ),
      );
    },
  );
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 15, 17, 13),
            child: Row(
              children: [
                Text(
                  'Live map',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.circle, size: 8, color: AppTheme.primary),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.map_outlined, size: 20),
                  label: const Text('View full map'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 262,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    // Use real OpenStreetMap tiles here; the full screen map
                    // remains the interactive experience after tapping.
                    child: IgnorePointer(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('buses')
                            .where(
                              'status',
                              whereIn: const [
                                'active',
                                'online',
                                'moving',
                                'approaching_stop',
                                'stopped',
                              ],
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          final buses = (snapshot.data?.docs ?? const []).where(
                            (bus) {
                              final data = bus.data();
                              final hasCoordinates =
                                  (data['latitude'] is num &&
                                      data['longitude'] is num) ||
                                  data['location'] is GeoPoint;
                              return hasCoordinates && data['disabled'] != true;
                            },
                          ).toList();
                          return FlutterMap(
                            options: const MapOptions(
                              initialCenter: LatLng(0.3238, 32.5736),
                              initialZoom: 13.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.smartrideug',
                              ),
                              MarkerLayer(
                                markers: buses.map((bus) {
                                  final data = bus.data();
                                  final location = data['location'];
                                  final point = location is GeoPoint
                                      ? LatLng(
                                          location.latitude,
                                          location.longitude,
                                        )
                                      : LatLng(
                                          (data['latitude'] as num).toDouble(),
                                          (data['longitude'] as num).toDouble(),
                                        );
                                  return Marker(
                                    point: point,
                                    width: 46,
                                    height: 46,
                                    child: const _BusPin(),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: .82),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        child: Text(
                          '© OpenStreetMap',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyNearbyBusesCard extends StatefulWidget {
  const _LegacyNearbyBusesCard();

  @override
  State<_LegacyNearbyBusesCard> createState() => _LegacyNearbyBusesCardState();
}

class _LegacyNearbyBusesCardState extends State<_LegacyNearbyBusesCard> {
  bool _isExpanded = false;

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Material(
            color: colors.surface,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby buses',
                            style: TextStyle(
                              fontSize: 18,
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '3 buses available nearby',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _isExpanded ? 'Hide list' : 'View list',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      turns: _isExpanded ? .5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, color: colors.outlineVariant),
                const _BusRow(
                  number: 'Bus 14',
                  route: 'Ntinda  •  via Wandegeya',
                  seats: '18 seats',
                  time: '2 min',
                  distance: '250 m away',
                ),
                _BusRow(
                  number: 'Bus 21',
                  route: 'Mukono  •  via Kireka',
                  seats: '12 seats',
                  time: '5 min',
                  distance: '1.2 km away',
                ),
                _BusRow(
                  number: 'Bus 8',
                  route: 'Nakawa  •  via Naalya',
                  seats: '20 seats',
                  time: '7 min',
                  distance: '1.8 km away',
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyBusesCard extends StatefulWidget {
  const _NearbyBusesCard();

  @override
  State<_NearbyBusesCard> createState() => _NearbyBusesCardState();
}

class _NearbyBusesCardState extends State<_NearbyBusesCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('buses')
          .where(
            'status',
            whereIn: const [
              'active',
              'online',
              'moving',
              'approaching_stop',
              'stopped',
            ],
          )
          .snapshots(),
      builder: (context, snapshot) {
        final buses =
            (snapshot.data?.docs ?? const [])
                .where(
                  (bus) =>
                      bus.data()['disabled'] != true &&
                      _hasFreshDriverPosition(bus.data()),
                )
                .toList()
              ..sort(
                (left, right) => _lastGpsUpdate(
                  right.data(),
                ).compareTo(_lastGpsUpdate(left.data())),
              );
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              Material(
                color: colors.surface,
                child: InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nearby buses',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? 'Checking live buses…'
                                    : '${buses.length} active ${buses.length == 1 ? 'bus' : 'buses'}',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _isExpanded ? 'Hide list' : 'View list',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isExpanded ? .5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Column(
                  children: [
                    Divider(height: 1, color: colors.outlineVariant),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      )
                    else if (buses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No buses with live driver tracking are available right now.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    else
                      ...List.generate(
                        buses.length,
                        (index) => _BusRow.fromBus(
                          buses[index].data(),
                          last: index == buses.length - 1,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static bool _hasFreshDriverPosition(Map<String, dynamic> bus) {
    final latitude = bus['latitude'];
    final longitude = bus['longitude'];
    if (latitude is! num || longitude is! num) return false;
    final updatedAt = bus['updatedAt'];
    if (updatedAt is! Timestamp) return false;
    return DateTime.now().difference(updatedAt.toDate()).abs() <=
        const Duration(minutes: 3);
  }

  static DateTime _lastGpsUpdate(Map<String, dynamic> bus) {
    final updatedAt = bus['updatedAt'];
    return updatedAt is Timestamp
        ? updatedAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _BusRow extends StatelessWidget {
  const _BusRow({
    required this.number,
    required this.route,
    required this.seats,
    required this.time,
    required this.distance,
    this.last = false,
  });
  final String number;
  final String route;
  final String seats;
  final String time;
  final String distance;
  final bool last;

  factory _BusRow.fromBus(Map<String, dynamic> bus, {required bool last}) {
    final seats = bus['availableSeats'] ?? bus['totalSeats'];
    final status = (bus['status'] ?? 'active').toString().toLowerCase();
    return _BusRow(
      number: (bus['registrationNumber'] ?? bus['busNumber'] ?? 'Bus')
          .toString(),
      route: (bus['routeName'] ?? bus['routeId'] ?? 'Route pending').toString(),
      seats: seats == null ? 'Seats N/A' : '$seats seats',
      time: switch (status) {
        'moving' => 'Moving',
        'online' || 'active' => 'Online',
        'approaching_stop' => 'Approaching',
        'stopped' => 'Stopped',
        _ => status,
      },
      distance: 'GPS live',
      last: last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  route,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              seats,
              style: TextStyle(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                distance,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 3),
          Icon(Icons.chevron_right_rounded, color: colors.outline),
        ],
      ),
    );
  }
}

class LegacyNextTripCard extends StatelessWidget {
  const LegacyNextTripCard({
    super.key,
    required this.guestMode,
    required this.onTap,
  });
  final bool guestMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: colors.primary.withValues(alpha: .25)),
          ),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guestMode ? 'Plan your next trip' : 'Your next trip',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guestMode
                          ? 'Sign in to reserve a seat'
                          : 'Bus 14 to Ntinda',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      guestMode
                          ? 'Book, track and travel easily'
                          : 'Today  •  4:30 PM',
                      style: TextStyle(
                        color: colors.onPrimaryContainer.withValues(alpha: .75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onTap,
                child: Text(guestMode ? 'Explore' : 'View trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextTripCard extends StatefulWidget {
  const _NextTripCard({required this.guestMode, required this.onGuestAction});

  final bool guestMode;
  final void Function(String feature) onGuestAction;

  @override
  State<_NextTripCard> createState() => _NextTripCardState();
}

class _NextTripCardState extends State<_NextTripCard> {
  String? _selectedDepartureId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = _DailyDeparture.dayKey(DateTime.now());

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('buses')
          .where('serviceDate', isEqualTo: today)
          .snapshots(),
      builder: (context, snapshot) {
        final departures =
            snapshot.data?.docs
                      .map(_DailyDeparture.fromDocument)
                      .where((departure) => departure.isAvailableToday(today))
                      .toList() ??
                  []
              ..sort(
                (first, second) => first.minutes.compareTo(second.minutes),
              );
        final selected = departures.firstWhere(
          (departure) => departure.id == _selectedDepartureId,
          orElse: () =>
              departures.isEmpty ? _DailyDeparture.empty : departures.first,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: colors.primary.withValues(alpha: .25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: colors.onPrimary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s departures',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          'Choose a time that works for you',
                          style: TextStyle(
                            color: colors.onPrimaryContainer.withValues(
                              alpha: .75,
                            ),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Text(
                  'Unable to load today\'s departures. Please try again.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                )
              else if (departures.isEmpty)
                Text(
                  'No departures have been published for today yet.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: departures.map((departure) {
                    final isSelected = departure.id == selected.id;
                    return ChoiceChip(
                      label: Text('${departure.time} · ${departure.number}'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedDepartureId = departure.id),
                      selectedColor: colors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colors.onPrimary
                            : colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.routeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${selected.availableSeats} seats available · Bus ${selected.number}',
                            style: TextStyle(
                              color: colors.onPrimaryContainer.withValues(
                                alpha: .75,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => _book(context, selected),
                      child: Text(widget.guestMode ? 'Sign in' : 'Select'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _book(BuildContext context, _DailyDeparture departure) {
    if (widget.guestMode) {
      widget.onGuestAction('booking a scheduled trip');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusDetailsPage(
          busId: departure.id,
          routeId: departure.routeId,
          number: departure.number,
        ),
      ),
    );
  }
}

class _DailyDeparture {
  const _DailyDeparture({
    required this.id,
    required this.number,
    required this.routeId,
    required this.routeName,
    required this.time,
    required this.serviceDate,
    required this.availableSeats,
    required this.status,
    required this.disabled,
  });

  static const empty = _DailyDeparture(
    id: '',
    number: '',
    routeId: '',
    routeName: '',
    time: '',
    serviceDate: '',
    availableSeats: 0,
    status: '',
    disabled: true,
  );

  final String id;
  final String number;
  final String routeId;
  final String routeName;
  final String time;
  final String serviceDate;
  final int availableSeats;
  final String status;
  final bool disabled;

  int get minutes {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time);
    if (match == null) return 24 * 60;
    return (int.parse(match.group(1)!) * 60) + int.parse(match.group(2)!);
  }

  bool isAvailableToday(String today) {
    const validStatuses = {
      'active',
      'online',
      'scheduled',
      'ready',
      'moving',
      'approaching_stop',
      'stopped',
    };
    return !disabled &&
        validStatuses.contains(status.toLowerCase()) &&
        time.isNotEmpty &&
        (serviceDate.isEmpty || serviceDate == today) &&
        availableSeats > 0;
  }

  factory _DailyDeparture.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final reserved = data['reservedSeats'] is List
        ? data['reservedSeats'] as List
        : const [];
    final pending = data['pendingSeats'] is List
        ? data['pendingSeats'] as List
        : const [];
    final totalSeats = (data['totalSeats'] as num?)?.toInt() ?? 0;
    return _DailyDeparture(
      id: document.id,
      number: (data['busNumber'] ?? data['registrationNumber'] ?? document.id)
          .toString(),
      routeId: data['routeId']?.toString() ?? '',
      routeName:
          (data['routeName'] ?? data['routeId'] ?? 'Route details pending')
              .toString(),
      time: (data['departureTime'] ?? '').toString().trim(),
      serviceDate: (data['serviceDate'] ?? '').toString().trim(),
      availableSeats:
          (data['availableSeats'] as num?)?.toInt() ??
          (totalSeats - reserved.length - pending.length).clamp(0, totalSeats),
      status: data['status']?.toString() ?? 'scheduled',
      disabled: data['disabled'] == true,
    );
  }

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBook,
    required this.onScan,
    required this.onTrips,
    required this.onSaved,
  });
  final VoidCallback onBook;
  final VoidCallback onScan;
  final VoidCallback onTrips;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ActionTile(
          icon: Icons.directions_bus_rounded,
          label: 'Book Seat',
          caption: 'Reserve now',
          color: AppTheme.primary,
          onTap: onBook,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionTile(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan QR',
          caption: 'Board quickly',
          color: const Color(0xFF2878E8),
          onTap: onScan,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionTile(
          icon: Icons.receipt_long_rounded,
          label: 'My Trips',
          caption: 'View bookings',
          color: const Color(0xFF7246CE),
          onTap: onTrips,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionTile(
          icon: Icons.star_outline_rounded,
          label: 'Saved',
          caption: 'Your places',
          color: const Color(0xFFF5A524),
          onTap: onSaved,
        ),
      ),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: _cardDecoration(context, radius: 14),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _BusPin extends StatelessWidget {
  const _BusPin();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppTheme.primary,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x42007344),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: const Icon(
      Icons.directions_bus_rounded,
      size: 21,
      color: Colors.white,
    ),
  );
}

BoxDecoration _cardDecoration(BuildContext context, {double radius = 17}) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: colors.outlineVariant.withValues(alpha: .7)),
    boxShadow: [
      BoxShadow(
        color: colors.shadow.withValues(alpha: .16),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
