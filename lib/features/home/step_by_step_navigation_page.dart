import 'package:flutter/material.dart';

class StepByStepNavigationPage extends StatefulWidget {
  final String busNumber;
  final String currentStop;
  final String nextStop;
  final String arrivalTime;
  final int passengerCount;
  final double distanceRemaining; // in km

  const StepByStepNavigationPage({
    super.key,
    required this.busNumber,
    required this.currentStop,
    required this.nextStop,
    required this.arrivalTime,
    this.passengerCount = 12,
    this.distanceRemaining = 2.5,
  });

  static const routeName = '/step-by-step-navigation';

  @override
  State<StepByStepNavigationPage> createState() =>
      _StepByStepNavigationPageState();
}

class _StepByStepNavigationPageState extends State<StepByStepNavigationPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Navigation'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: [
          _MapView(
            busNumber: widget.busNumber,
            currentStop: widget.currentStop,
            nextStop: widget.nextStop,
            arrivalTime: widget.arrivalTime,
            passengerCount: widget.passengerCount,
          ),
          _StopDetailsView(
            busNumber: widget.busNumber,
            currentStop: widget.currentStop,
            nextStop: widget.nextStop,
            arrivalTime: widget.arrivalTime,
            distanceRemaining: widget.distanceRemaining,
            passengerCount: widget.passengerCount,
          ),
        ],
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final String busNumber;
  final String currentStop;
  final String nextStop;
  final String arrivalTime;
  final int passengerCount;

  const _MapView({
    required this.busNumber,
    required this.currentStop,
    required this.nextStop,
    required this.arrivalTime,
    required this.passengerCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Map placeholder
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Live Map View',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Route visualization from $currentStop to $nextStop',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          // Bus info header
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(204),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              busNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ARRIVE AT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                arrivalTime,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.people,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              passengerCount.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Next stop footer
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next stop',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextStop,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: Colors.white.withAlpha(179),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '2 minutes',
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopDetailsView extends StatelessWidget {
  final String busNumber;
  final String currentStop;
  final String nextStop;
  final String arrivalTime;
  final double distanceRemaining;
  final int passengerCount;

  const _StopDetailsView({
    required this.busNumber,
    required this.currentStop,
    required this.nextStop,
    required this.arrivalTime,
    required this.distanceRemaining,
    required this.passengerCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.directions_bus,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BUS $busNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'On the way',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ETA',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              arrivalTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Route info
            Text('Your Journey', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Stop progression
            _StopProgression(currentStop: currentStop, nextStop: nextStop),
            const SizedBox(height: 24),
            // Trip details
            Text('Trip Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _TripDetailRow(
              icon: Icons.location_on,
              label: 'Current Location',
              value: currentStop,
            ),
            const SizedBox(height: 12),
            _TripDetailRow(
              icon: Icons.flag,
              label: 'Destination',
              value: nextStop,
            ),
            const SizedBox(height: 12),
            _TripDetailRow(
              icon: Icons.straighten,
              label: 'Distance Remaining',
              value: '${distanceRemaining.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 12),
            _TripDetailRow(
              icon: Icons.people,
              label: 'Passengers',
              value: passengerCount.toString(),
            ),
            const SizedBox(height: 24),
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text('Contact Driver'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling driver...')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share Journey'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing journey...')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopProgression extends StatelessWidget {
  final String currentStop;
  final String nextStop;

  const _StopProgression({required this.currentStop, required this.nextStop});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current stop
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentStop,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Current location',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Line connector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            height: 24,
            child: VerticalDivider(
              color: Theme.of(context).colorScheme.primary.withAlpha(102),
              thickness: 2,
            ),
          ),
        ),
        // Next stop
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextStop,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Your stop',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TripDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
