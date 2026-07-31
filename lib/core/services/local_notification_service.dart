import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ArrivalNotificationAction {
  const ArrivalNotificationAction({
    required this.bookingId,
    required this.actionId,
  });

  final String bookingId;
  final String actionId;
}

/// Local notifications used while the passenger app has an active live-bus
/// listener. Actions are surfaced to the booking screen on Android and iOS.
class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<ArrivalNotificationAction> _actions =
      StreamController<ArrivalNotificationAction>.broadcast();
  bool _initialized = false;

  Stream<ArrivalNotificationAction> get actions => _actions.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'bus_arrival',
          actions: [
            DarwinNotificationAction.plain(
              'confirm',
              'Confirm',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'cancel',
              'Cancel',
              options: {
                DarwinNotificationActionOption.destructive,
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showBusArrival(String bookingId) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'bus_arrivals',
        'Bus arrivals',
        channelDescription: 'Alerts when a booked bus reaches the pickup stop.',
        importance: Importance.max,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(
            'confirm',
            'Confirm',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'cancel',
            'Cancel',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: 'bus_arrival'),
    );
    await _plugin.show(
      id: bookingId.hashCode & 0x7fffffff,
      title: 'Your bus has arrived',
      body: 'Are you ready to board?',
      notificationDetails: details,
      payload: bookingId,
    );
  }

  Future<void> showWelcome() async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'welcome_messages',
        'Welcome messages',
        channelDescription: 'A one-time introduction to SmartRide UG.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: 1,
      title: 'Welcome to SmartRide UG!',
      body:
          'Find routes to your destination, track active buses, reserve seats, and get an alert when your bus arrives.',
      notificationDetails: details,
    );
  }

  void _handleResponse(NotificationResponse response) {
    final bookingId = response.payload;
    final actionId = response.actionId;
    if (bookingId == null || actionId == null) return;
    if (actionId == 'confirm' || actionId == 'cancel') {
      _actions.add(
        ArrivalNotificationAction(bookingId: bookingId, actionId: actionId),
      );
    }
  }
}
