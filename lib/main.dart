import 'package:flutter/material.dart';
import 'package:smartrideug/core/theme/app_theme.dart';
import 'package:smartrideug/core/theme/theme_notifier.dart';
import 'package:smartrideug/firebase/firebase_initializer.dart';
import 'package:smartrideug/firebase/firebase_options.dart';
import 'package:smartrideug/features/authentication/splash_page.dart';
import 'package:smartrideug/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartRideApp());
}

class SmartRideApp extends StatelessWidget {
  const SmartRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'SmartRide UG',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          initialRoute: SplashPage.routeName,
          onGenerateRoute: AppRouter.generate,
        );
      },
    );
  }
}
