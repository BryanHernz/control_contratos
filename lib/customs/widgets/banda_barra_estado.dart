import 'package:flutter/material.dart';

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
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Container(height: alto, color: color),
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
