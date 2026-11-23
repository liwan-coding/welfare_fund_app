import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'design/app_theme.dart';
import 'constants/app_constants.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/donation_success_screen.dart';
import 'screens/payment_failed_screen.dart';
import 'screens/payment_loading_screen.dart';
import 'screens/fund_news_screen.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/setting_page_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  debugPrint('Background message received: ${message.messageId}');
}

void main() {
  // Raw print() is synchronous I/O and can leak data in release builds, so it
  // is silenced there. Debug and profile builds are unchanged.
  runZonedGuarded(
    _bootstrap,
    (error, stack) => debugPrint('Uncaught error: $error\n$stack'),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (!kReleaseMode) parent.print(zone, line);
      },
    ),
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error');
    return true;
  };

  // Decoded-image cache sized for a phone: enough for feed scrolling without
  // holding the default 100MB of bitmaps.
  PaintingBinding.instance.imageCache
    ..maximumSize = 150
    ..maximumSizeBytes = 80 << 20;

  // Independent start-up work runs in parallel instead of one await after
  // another, which shortens time-to-first-frame.
  await Future.wait<void>([
    () async {
      if (kIsWeb) return; // needs firebase_options.dart
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }(),
    EasyLocalization.ensureInitialized(),
    () async {
      try {
        await ApiClient().initialize();
        await AuthService().initialize();
      } catch (e) {
        debugPrint('Error during initialization: $e');
      }
    }(),
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      saveLocale: true,
      child: const StudentWelfareFundApp(),
    ),
  );
}

class StudentWelfareFundApp extends StatelessWidget {
  const StudentWelfareFundApp({super.key});

  // تحديد الـ route الأولي بناءً على URL الحالي
  String _getInitialRoute() {
    try {
      // للويب، تحقق من URL الحالي
      String? currentPath;
      if (kIsWeb) {
        try {
          // Use Uri.base which works on web to get pathname
          final uri = Uri.base;
          currentPath = uri.path;
          print('Current URL path: $currentPath');
          print('Current URL full: ${uri.toString()}');
          print('Current query params: ${uri.queryParameters}');
        } catch (e) {
          print('Error reading URL: $e');
          currentPath = '/';
        }
      } else {
        currentPath = '/';
      }

      // إذا كان URL يحتوي على payment/success أو payment/cancel
      // ابدأ من payment loading screen لمعالجة المعاملات بشكل صحيح
      if (currentPath.contains('/payment/success') ||
          currentPath.contains('/payment/cancel')) {
        print(
            'Payment redirect detected, starting from payment loading screen');
        return '/payment/loading';
      }

      // إذا كان URL يحتوي على /home
      if (currentPath.contains('/home')) {
        print('Redirecting to home screen');
        return AppConstants.homeRoute;
      }
    } catch (e) {
      print('Error checking URL: $e');
    }

    // افتراضي: ابدأ من splash screen
    return AppConstants.splashRoute;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => SettingPageProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Localization configuration
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,

            // Theme configuration (Apple HIG). Dark theme is enabled once screens
            // stop hard-coding light colors.
            theme: AppTheme.light(),

            // Initial route - check URL first
            initialRoute: _getInitialRoute(),

            // Route configuration
            routes: {
              AppConstants.splashRoute: (context) => const SplashScreen(),
              AppConstants.homeRoute: (context) => const MainShell(),
              AppConstants.paymentSuccessRoute: (context) =>
                  const DonationSuccessScreen(),
              AppConstants.paymentCancelRoute: (context) =>
                  const PaymentFailedScreen(),
              '/payment/loading': (context) => const PaymentLoadingScreen(),
              AppConstants.fundNewsRoute: (context) => const FundNewsScreen(),
            },
          );
        },
      ),
    );
  }
}
