import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'auth/auth_pages.dart';
import 'customs/constants_values.dart'; // aquí tienes `primario = Colors.blueGrey[700]!`
import 'firebase_options.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Localización de fechas en español
  await initializeDateFormatting('es');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Verificar actualizaciones en el primer frame disponible (solo Android)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colores de barra de estado / navegación (afecta Android/iOS nativo; en web es no-op)
    final overlay = SystemUiOverlayStyle(
      statusBarColor: primario, // fondo barra de estado
      statusBarIconBrightness:
          Brightness.light, // iconos/texto blancos (Android)
      statusBarBrightness: Brightness.dark, // texto blanco en iOS
      systemNavigationBarColor: primario, // barra navegación Android
      systemNavigationBarIconBrightness: Brightness.light,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);

    final textTheme = GoogleFonts.rajdhaniTextTheme();

    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
      ],
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      title: 'CONTROL DE CONTRATOS',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        // Alineamos todo con tu primario blueGrey[700] (#455A64)
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primario,
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.black,
          error: Colors.red.shade700,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceTint: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primario,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: overlay, // asegura contraste correcto bajo AppBar
        ),
        scaffoldBackgroundColor: const Color(0xFFEFF4F8),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.68),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.9)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white.withOpacity(0.78),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.white.withOpacity(0.92)),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withOpacity(0.62),
          side: BorderSide(color: Colors.white.withOpacity(0.9)),
          labelStyle: TextStyle(
            color: Colors.blueGrey.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: primario,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: textTheme,
        fontFamily: GoogleFonts.rajdhani().fontFamily,
      ),
      builder: (context, child) {
        // Fija el escalado de texto a 1.0 para consistencia visual
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      home: const MainPage(),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
