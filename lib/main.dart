import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/config/secure_firebase_options.dart';
import 'core/localization/app_localizations.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/home/providers/store_provider.dart';
import 'features/items/providers/item_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/exchange/providers/exchange_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/trust/providers/trust_score_provider.dart';
import 'features/location/providers/new_location_provider.dart'
    as location_provider;
import 'features/location/services/location_notification_service.dart';
import 'features/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with secure configuration
  await Firebase.initializeApp(
    options: await SecureFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize location notification service
  await LocationNotificationService.initialize();

  // Configure Open Food Facts API user agent globally
  try {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'Nalliq',
      version: '1.0.0',
      system: 'Flutter',
      url: 'https://github.com/nalliq/nalliq-app',
      comment: 'Community Food Barter App',
    );
    print('Open Food Facts user agent configured globally');
  } catch (e) {
    print('Error configuring Open Food Facts user agent: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ExchangeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => TrustScoreProvider()),
        ChangeNotifierProvider(
          create:
              (_) => location_provider.LocationProvider()..initializeLocation(),
        ),
        ChangeNotifierProxyProvider<
          location_provider.LocationProvider,
          HomeProvider
        >(
          create: (_) => HomeProvider(),
          update:
              (_, location, home) => home!..updateLocationProvider(location),
        ),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settingsProvider, authProvider, child) {
          // Set the auth provider in the router
          AppRouter.setAuthProvider(authProvider);
          // Apply accessibility settings to our custom themes
          final safeFontSizeFactor =
              (settingsProvider.textScaleFactor > 0.0 &&
                      settingsProvider.textScaleFactor <= 3.0)
                  ? settingsProvider.textScaleFactor
                  : 1.0;

          // Create high contrast themes when needed
          ThemeData lightTheme;
          ThemeData darkTheme;

          if (settingsProvider.highContrastEnabled) {
            // High contrast light theme
            lightTheme = AppTheme.lightTheme.copyWith(
              colorScheme: const ColorScheme.highContrastLight(),
              // Override custom colors for high contrast
              scaffoldBackgroundColor: Colors.white,
              cardColor: Colors.white,
              appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              textTheme: AppTheme.lightTheme.textTheme.apply(
                displayColor: Colors.black,
                bodyColor: Colors.black,
              ),
            );
            // High contrast dark theme
            darkTheme = AppTheme.darkTheme.copyWith(
              colorScheme: const ColorScheme.highContrastDark(),
              // Override custom colors for high contrast
              scaffoldBackgroundColor: Colors.black,
              cardColor: Colors.black,
              appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              textTheme: AppTheme.darkTheme.textTheme.apply(
                displayColor: Colors.white,
                bodyColor: Colors.white,
              ),
            );
          } else {
            lightTheme = AppTheme.lightTheme;
            darkTheme = AppTheme.darkTheme;
          }

          return MaterialApp.router(
            title: AppStrings.appName,
            theme: lightTheme.copyWith(
              textTheme: lightTheme.textTheme.apply(
                fontSizeFactor: safeFontSizeFactor,
              ),
            ),
            darkTheme: darkTheme.copyWith(
              textTheme: darkTheme.textTheme.apply(
                fontSizeFactor: safeFontSizeFactor,
              ),
            ),
            themeMode:
                settingsProvider.darkTheme ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: settingsProvider.locale,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
