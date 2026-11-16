import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final state = await AppState.load();
  runApp(AppScope(state: state, child: const RockBosgApp()));
}

class RockBosgApp extends StatelessWidget {
  const RockBosgApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      title: 'RockBosg',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: state.themeMode,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
        // Letra grande opcional (por defecto activa en modo geólogo).
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(state.largeText ? 1.15 : 1.0),
          ),
          child: child!,
        );
      },
      home: state.mode == null || state.userName == null
          ? const OnboardingScreen()
          : const Shell(),
    );
  }
}
