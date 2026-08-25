import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'auth/auth_pages.dart';
import 'customs/app_colors.dart';
import 'customs/constants_values.dart';
import 'firebase_options.dart';
import 'services/firestore_db.dart';
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
        // Sin esto el editor de plantillas revienta con
        // "FlutterQuillLocalizations instance is required" y la barra de
        // herramientas no se dibuja.
        FlutterQuillLocalizations.delegate,
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
        scaffoldBackgroundColor: AppColors.background,
        // Las superficies salen de AppColors.surface (hueso), no de blanco
        // puro, y sin contorno: la separacion la dan el fondo y la sombra.
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
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
          // Cinta de aviso cuando la app NO apunta a produccion. Sin esto no
          // hay forma de distinguir de un vistazo si lo que se esta viendo es
          // la base real o la copia, y las dos tienen los mismos datos.
          child: usandoBaseDePruebas
              ? Banner(
                  message: kFirestoreDatabaseId.toUpperCase(),
                  // Arriba a la derecha: la esquina superior izquierda la ocupa
                  // el logo del drawer.
                  location: BannerLocation.topEnd,
                  color: const Color(0xFFB3382B),
                  child: child!,
                )
              : child!,
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
