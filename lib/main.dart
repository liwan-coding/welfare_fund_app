import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart' show kIsWeb;
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
  print('🔔 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (only for non-web platforms or when options are available)
  if (!kIsWeb) {
    await Firebase.initializeApp();
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } else {
    print(
        '⚠️ Firebase not initialized on web - firebase_options.dart is required');
    print('Run: dart pub global activate flutterfire_cli');
    print('Then: flutterfire configure');
  }

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Register web implementation for webview_flutter when running on web
  if (kIsWeb) {
    // Only register web platform when actually running on web
    // This will be handled by conditional imports if needed
  }

  try {
    // Initialize API Client
    await ApiClient().initialize();
    print('API Client initialized successfully');

    // Initialize Auth Service
    await AuthService().initialize();
    print('Auth Service initialized successfully');
  } catch (e) {
    print('Error during initialization: $e');
  }

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
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Localization configuration
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,

            // RTL for Arabic, LTR for English
            builder: (context, child) {
              final isRtl = context.locale.languageCode == 'ar';
              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },

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
