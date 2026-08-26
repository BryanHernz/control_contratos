import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
import 'customs/widgets/banda_barra_estado.dart';
import 'customs/widgets/barra_de_titulo.dart';
import 'customs/constants_values.dart';
import 'firebase_options.dart';
import 'services/firestore_db.dart';
import 'services/update_service.dart';
import 'services/ventana.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Localización de fechas en español
  await initializeDateFormatting('es');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Oculta la barra de titulo del sistema en escritorio. Va antes de `runApp`
  // para que la ventana no llegue a mostrarse con la barra nativa puesta: si
  // se hace despues, se ve un parpadeo al arrancar.
  await ControlDeVentana.preparar();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  StreamSubscription<User?>? _sesion;

  @override
  void initState() {
    super.initState();

    // La comprobacion de actualizaciones necesita sesion iniciada: `updates/`
    // en Storage exige `request.auth != null`.
    //
    // Antes corria en el primer frame y se adelantaba a que Firebase
    // restaurara la sesion guardada, asi que fallaba con
    // `firebase_storage/unauthorized` **en silencio**. El efecto era que al
    // abrir la app nunca aparecia el aviso: habia que entrar, cerrarla y
    // volver a abrirla para que apareciera.
    //
    // Escuchar el estado de sesion cubre los dos casos con un solo camino: la
    // sesion restaurada al arrancar y el login recien hecho.
    _sesion = FirebaseAuth.instance.authStateChanges().listen((usuario) {
      if (usuario != null) UpdateService.checkForUpdate();
    });
  }

  @override
  void dispose() {
    _sesion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Barra de estado y de navegacion.
    //
    // `statusBarColor` y `systemNavigationBarColor` **ya no hacen nada** en
    // Android 15 o superior: con `targetSdk = 36` el sistema fuerza
    // edge-to-edge y descarta ambos colores. La app dibuja debajo de las
    // barras y lo que se ve detras es el fondo del Scaffold -- casi blanco --
    // con los iconos claros encima, o sea invisibles.
    //
    // Se dejan igual porque siguen valiendo en Android 14 y anteriores, que es
    // buena parte de los telefonos en uso. El color de verdad lo pinta el
    // `builder` de mas abajo, que es lo unico que funciona en ambos casos.
    //
    // El BRILLO de los iconos si se respeta en todas las versiones, y por eso
    // va en claro: la banda que pintamos detras es `primario`, que es oscuro.
    final overlay = SystemUiOverlayStyle(
      statusBarColor: primario,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark, // texto blanco en iOS
      systemNavigationBarColor: primario,
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
        // Cinta de aviso cuando la app NO apunta a produccion. Sin esto no hay
        // forma de distinguir de un vistazo si lo que se esta viendo es la
        // base real o la copia, y las dos tienen los mismos datos.
        final contenido = usandoBaseDePruebas
            ? Banner(
                message: kFirestoreDatabaseId.toUpperCase(),
                // Arriba a la derecha: la esquina superior izquierda la ocupa
                // el logo del drawer.
                location: BannerLocation.topEnd,
                color: const Color(0xFFB3382B),
                child: child!,
              )
            : child!;

        // El orden importa. `BandaBarraDeEstado` va DENTRO de este MediaQuery,
        // no fuera: necesita leer el inset real para saber cuanto mide la
        // franja, y sobre todo necesita ser lo ultimo que toca el padding. Al
        // reves, este MediaQuery volveria a instalar el padding de arriba y
        // los `SafeArea` de las vistas dejarian el hueco blanco de nuevo.
        return MediaQuery(
          // Fija el escalado de texto a 1.0 para consistencia visual.
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: BandaBarraDeEstado(
            color: primario,
            // En escritorio la barra de titulo es nuestra; en web y en
            // Android `BarraDeTitulo` mide cero y esta Column no cambia nada.
            child: Column(
              children: [
                const BarraDeTitulo(titulo: 'Control de Contratos'),
                Expanded(child: contenido),
              ],
            ),
          ),
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
