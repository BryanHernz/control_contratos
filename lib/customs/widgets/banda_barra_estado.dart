import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Pinta una franja solida detras de la barra de estado del sistema.
///
/// Desde Android 15 (`targetSdk` 35 o mas) el sistema fuerza edge-to-edge y
/// **descarta** `SystemUiOverlayStyle.statusBarColor`. La app pasa a dibujar
/// debajo de la barra, y lo que se ve detras es el fondo del Scaffold: en esta
/// app `AppColors.background` (#F0F2F5), que se lee como blanco. Con los
/// iconos en claro encima, quedan invisibles.
///
/// La unica forma que funciona en todas las versiones es pintar esa franja
/// nosotros. Va envolviendo la app entera y no pantalla por pantalla porque
/// cada vista arma su propio `Scaffold`: repetirlo serian doce copias, y la
/// que se olvide queda con la barra blanca.
///
/// Al reservar aqui ese alto hay que **quitar el padding superior** del
/// `MediaQuery` que ve el hijo, o los `SafeArea` de las vistas volverian a
/// insertarlo y dejarian un hueco del alto de la barra.
///
/// En web y escritorio el inset es 0: no dibuja nada y no estorba.
class BandaBarraDeEstado extends StatelessWidget {
  const BandaBarraDeEstado({
    super.key,
    required this.child,
    this.colores = AppColors.chromeOscuro,
  });

  /// Los tonos del degradado. Por defecto el del chrome de la app.
  ///
  /// Antes era un color plano y se le pasaba `primario`, que es el tono
  /// **final** del degradado: la banda quedaba mas clara que la superficie de
  /// abajo, que empieza en el inicial, y el corte se veia.
  final List<Color> colores;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Container(
          height: alto,
          decoration: BoxDecoration(
            // El mismo degradado y el mismo sentido que las cabeceras: la
            // banda toca ese borde y cualquier diferencia se ve como una
            // costura.
            gradient: LinearGradient(
              colors: colores,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
