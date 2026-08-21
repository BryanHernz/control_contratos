import 'package:flutter/material.dart';

/// Tokens de color de texto sobre fondo claro.
///
/// Los tonos que se venian usando para texto secundario quedan bajo el minimo
/// de 4.5:1 que pide WCAG AA sobre blanco (medido, no estimado):
///
///   blueGrey.shade400  #78909C   3.35:1   BAJO AA
///   blueGrey.shade500  #607D8B   4.37:1   BAJO AA
///   grey.shade400      #BDBDBD   1.88:1   BAJO AA
///   grey.shade500      #9E9E9E   2.68:1   BAJO AA
///
/// (`blueGrey.shade600` #546E7A da 5.40:1 y si pasa; no hace falta tocarlo.)
///
/// Reemplazos, todos verificados contra blanco:
///
///   textStrong    #1B2A32   14.75:1
///   textBody      #2E3E47   11.07:1
///   textMuted     #4A5C66    6.97:1   <- reemplaza blueGrey.shade500
///   textFaint     #5C6E78    5.31:1   <- el mas claro admisible para texto
///   iconMuted     #55666F    5.97:1   <- reemplaza blueGrey.shade400
///
/// Regla: no usar shades 300/400/500 de grey/blueGrey para texto sobre blanco.
class AppColors {
  const AppColors._();

  /// Titulos y valores. Maximo contraste sin llegar al negro puro.
  static const Color textStrong = Color(0xFF1B2A32);

  /// Texto corrido.
  static const Color textBody = Color(0xFF2E3E47);

  /// Labels, subtitulos, metadatos. Legible a 12-13px.
  static const Color textMuted = Color(0xFF4A5C66);

  /// El tono mas claro admisible para texto. No bajar de aca.
  static const Color textFaint = Color(0xFF5C6E78);

  /// Iconos acompanando texto secundario.
  static const Color iconMuted = Color(0xFF55666F);

  /// Separadores y bordes sutiles.
  static const Color divider = Color(0xFFE3E9ED);
  static const Color border = Color(0xFFC4D0DA);

  /// Tarjeta blanca sobre fondo gris muy claro: es el esquema **original** del
  /// proyecto (`Colors.white` sobre `0xFFF0F2F5`), recuperado despues de que
  /// una tanda de intentos lo invirtiera (fondo azul-gris con tarjeta clara),
  /// que es de donde salia el "celeste" que hubo que perseguir.
  ///
  /// Lo unico que cambia respecto del original es que ya no estan repetidos a
  /// mano en cinco vistas y en el tema.
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF0F2F5);

  /// Zonas que hacen de "pagina" dentro de un modal y que a su vez contienen
  /// tarjetas ([surface]). Mismo gris que el fondo, para que la tarjeta de
  /// adentro se despegue igual que en la pantalla.
  static const Color surfaceSunken = Color(0xFFF0F2F5);

  /// Texto sobre superficies oscuras (headers con gradiente).
  static const Color onDarkStrong = Colors.white;

  /// Blanco al 80%. Sobre el header (#263238) da 8.19:1.
  static const Color onDarkMuted = Color(0xCCFFFFFF);
}

/// Decoracion estandar de una tarjeta: blanca, con el borde negro al 5% que
/// tenia el proyecto originalmente.
///
/// Existe porque cada tipo de tarjeta (metrica, grafico, listado, ficha de
/// trabajador) repetia esta misma decoracion por su cuenta. Unificarlas es lo
/// unico que cambia respecto del original.
///
/// **Sin sombra.** Cualquier sombra difuminada toma el color del fondo y se
/// lee como un halo alrededor de la tarjeta; se probo con blur 16 y con blur 5
/// y las dos se veian mal.
BoxDecoration appCardDecoration({double radius = 16}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withOpacity(0.05)),
    );
