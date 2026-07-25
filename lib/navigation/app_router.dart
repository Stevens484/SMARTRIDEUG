import 'package:flutter/material.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/authentication/splash_page.dart';
import 'package:smartrideug/features/home/home_page.dart';
import 'package:smartrideug/features/home/destination_page.dart';
import 'package:smartrideug/features/home/step_by_step_navigation_page.dart';
import 'package:smartrideug/features/home/confirm_seat_page.dart'; // 🔥 ADD THIS
import 'package:smartrideug/features/home/booking_status_page.dart'; // 🔥 ADD THIS
import 'package:smartrideug/features/home/seat_reservations_page.dart'; // 🔥 ADD THIS
import 'package:smartrideug/features/map/live_map_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case SplashPage.routeName:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case HomePage.routeName:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case DestinationPage.routeName:
        return MaterialPageRoute(builder: (_) => const DestinationPage());

      case StepByStepNavigationPage.routeName:
        return MaterialPageRoute(
          builder: (_) => const StepByStepNavigationPage(
            busNumber: '302',
            currentStop: 'Current Stop',
            nextStop: 'Next Stop',
            arrivalTime: '00:00',
          ),
        );

      // 🔥 MAP ROUTE
      case '/live-map':
        return MaterialPageRoute(builder: (_) => const LiveMapScreen());

      // 🔥 CONFIRM SEAT ROUTE
      case '/confirm-seat':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ConfirmSeatPage(
            busId: args?['busId'] ?? 'BUS-001',
            routeId: args?['routeId'] ?? 'route_001',
            busNumber: args?['busNumber'] ?? '001',
            farePerSeat: args?['farePerSeat'] ?? 3000,
            seats: args?['seats'] ?? ['1A'],
          ),
        );

      // 🔥 BOOKING STATUS ROUTE
      case '/booking-status':
        final args = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => BookingStatusPage(bookingId: args ?? ''),
        );

      case AuthenticationPage.routeName:
      default:
        return MaterialPageRoute(builder: (_) => const AuthenticationPage());
    }
  }
}
