import 'package:flutter/material.dart';
import 'package:smartrideug/features/authentication/authentication_page.dart';
import 'package:smartrideug/features/authentication/splash_page.dart';
import 'package:smartrideug/features/home/home_page.dart';
import 'package:smartrideug/features/home/destination_page.dart';
import 'package:smartrideug/features/home/step_by_step_navigation_page.dart';

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
      case AuthenticationPage.routeName:
      default:
        return MaterialPageRoute(builder: (_) => const AuthenticationPage());
    }
  }
}
