import 'package:flutter/material.dart';

/// Acceso al menu lateral desde cualquier vista.
///
/// Cada pantalla arma su propio `Scaffold`, asi que `Scaffold.of(context)`
/// encuentra el de la vista -- que no tiene drawer -- y no el de `HomePage`,
/// que si lo tiene. Guardar aqui la llave del Scaffold de arriba es lo que
/// permite que el boton del menu viva dentro de la cabecera de cada pagina en
/// vez de en una barra aparte.
class MenuLateral {
  MenuLateral._();

  static GlobalKey<ScaffoldState>? _llave;

  /// La registra `HomePage` al construirse.
  static void registrar(GlobalKey<ScaffoldState> llave) => _llave = llave;

  /// `true` si hay un menu que abrir. En escritorio el menu esta siempre a la
  /// vista y no hay drawer, asi que el boton no debe dibujarse.
  static bool get disponible => _llave?.currentState?.hasDrawer ?? false;

  static void abrir() => _llave?.currentState?.openDrawer();
}
