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

  /// **La tarjeta es MAS OSCURA que el fondo, no al reves.**
  ///
  /// El fondo del cuerpo es blanco, el mismo del drawer lateral, para que la
  /// pantalla se lea como una sola superficie continua. La tarjeta se despega
  /// bajando un par de grados desde ese blanco: sigue siendo un tono de blanco,
  /// nunca celeste.
  ///
  /// Intentos anteriores hicieron lo contrario -- fondo azul-gris (#CBD8E2,
  /// #B3C4D2) con la tarjeta mas clara -- y el resultado era el "celeste" que
  /// habia que sacar. Si hace falta mas separacion, se baja [surface] otro par
  /// de grados; [background] se queda en blanco.
  /// #ECEDEF (19 puntos bajo el blanco) resulto imperceptible. Este baja 33.
  static const Color surface = Color(0xFFDEE2E6);
  static const Color background = Colors.white;

  /// Zonas que hacen de "pagina" dentro de un modal y que a su vez contienen
  /// tarjetas ([surface]). Mismo blanco que [background], por el mismo motivo:
  /// la tarjeta es la que baja, no la pagina.
  static const Color surfaceSunken = Colors.white;

  /// Texto sobre superficies oscuras (headers con gradiente).
  static const Color onDarkStrong = Colors.white;

  /// Blanco al 80%. Sobre el header (#263238) da 8.19:1.
  static const Color onDarkMuted = Color(0xCCFFFFFF);
}

/// Decoracion estandar de una tarjeta.
///
/// Existe porque cada tipo de tarjeta (metrica, grafico, listado, ficha de
/// trabajador) traia su propio `Border.all(color: Colors.black.withOpacity(
/// 0.05))`. Sobre un fondo claro ese borde no se ve, asi que ninguna de las
/// tarjetas se leia como superficie separada: el dashboard quedaba "todo
/// parejo". Una sola definicion para todas.
///
/// **Plana: sin borde y SIN sombra.** La unica separacion es el salto de color
/// entre [AppColors.surface] y [AppColors.background].
///
/// Cualquier sombra, por chica que sea, se difumina sobre un fondo azul-gris y
/// se lee como un halo celeste rodeando la tarjeta. Se probo ancha (blur 16) y
/// minima (blur 5) y las dos se veian igual de celestes. Si alguien quiere
/// volver a "elevar" las tarjetas, el camino NO es una sombra: es separar mas
/// los dos tonos.
BoxDecoration appCardDecoration({double radius = 16}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
    );
