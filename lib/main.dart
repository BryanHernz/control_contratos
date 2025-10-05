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

        // Envuelve la aplicación con el nuevo MediaQuery
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery:
              true, // Importante: usa el MediaQuery heredado
          title: 'CONTROL DE CONTRATOS',
          theme: ThemeData(
            useMaterial3: true,
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
            textTheme:
                GoogleFonts.rajdhaniTextTheme(Theme.of(context).textTheme),
          ),
          builder: (context, child) {
            // Obtenemos los datos del MediaQuery actual
            final mediaQueryData = MediaQuery.of(context);

            // Retornamos un nuevo MediaQuery con el textScaleFactor fijo
            return MediaQuery(
              data: mediaQueryData.copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          home: const MainPage(),
        );
      },
    );
  }
}
