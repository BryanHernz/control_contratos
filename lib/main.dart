import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'auth/auth_pages.dart';
import 'customs/constants_values.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );
  initializeDateFormatting();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
    ));

    return Builder(
      builder: (BuildContext context) {
        // Obtiene los datos de MediaQuery actuales
        final mediaQueryData = MediaQuery.of(context);
        // Define tu factor de escala deseado (ajusta este valor)
        const double scaleFactor = 0.9; // Reducir la escala al 80%

        // Aplica el factor de escala a los datos de MediaQuery
        final newMediaQueryData = mediaQueryData.copyWith(
          textScaler: TextScaler.linear(mediaQueryData.textScaleFactor * scaleFactor),
          // Puedes intentar escalar otras propiedades si tu diseño las usa
          // size: mediaQueryData.size * scaleFactor, // Esto podría tener efectos complejos
          // padding: mediaQueryData.padding * scaleFactor,
        );

        // Envuelve la aplicación con el nuevo MediaQuery
        return MediaQuery(
          data: newMediaQueryData,
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            useInheritedMediaQuery: true, // Importante: usa el MediaQuery heredado
            title: 'CONTROL DE CONTRATOS',
            theme: ThemeData(
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              colorScheme: ColorScheme(
                  surfaceTint: Colors.white,
                  brightness: Brightness.light,
                  primary: primario,
                  onPrimary: Colors.white,
                  secondary: Colors.white,
                  onSecondary: Colors.black,
                  error: Colors.black,
                  onError: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black),
              scaffoldBackgroundColor: Colors.white,
              fontFamily: GoogleFonts.rajdhani().fontFamily,
              textTheme: GoogleFonts.rajdhaniTextTheme(Theme.of(context).textTheme),
            ),
            home: const MainPage(),
          ),
        );
      },
    );
  }
}