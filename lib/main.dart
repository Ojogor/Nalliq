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
import 'features/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with secure configuration
  await Firebase.initializeApp(
    options: await SecureFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

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
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ExchangeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => TrustScoreProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
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
              textTheme: AppTheme.lightTheme.textTheme.apply(
                fontSizeFactor: safeFontSizeFactor,
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
            );

            // High contrast dark theme
            darkTheme = AppTheme.darkTheme.copyWith(
              colorScheme: const ColorScheme.highContrastDark(),
              // Override custom colors for high contrast
              scaffoldBackgroundColor: Colors.black,
              cardColor: const Color(0xFF121212),
              textTheme: AppTheme.darkTheme.textTheme.apply(
                fontSizeFactor: safeFontSizeFactor,
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
            );
          } else {
            // Normal themes with font scaling
            lightTheme = AppTheme.lightTheme.copyWith(
              textTheme:
                  safeFontSizeFactor != 1.0
                      ? AppTheme.lightTheme.textTheme.apply(
                        fontSizeFactor: safeFontSizeFactor,
                      )
                      : AppTheme.lightTheme.textTheme,
            );

            darkTheme = AppTheme.darkTheme.copyWith(
              textTheme:
                  safeFontSizeFactor != 1.0
                      ? AppTheme.darkTheme.textTheme.apply(
                        fontSizeFactor: safeFontSizeFactor,
                      )
                      : AppTheme.darkTheme.textTheme,
            );
          }

          return MaterialApp.router(
            title: AppStrings.appName,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode:
                settingsProvider.darkModeEnabled
                    ? ThemeMode.dark
                    : ThemeMode.light,
            locale: settingsProvider.selectedLocale,
            supportedLocales: const [Locale('en', ''), Locale('fr', '')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
