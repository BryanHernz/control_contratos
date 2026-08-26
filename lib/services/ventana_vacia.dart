/// Version para web: no hay ventana que controlar.
///
/// Cada miembro existe solo para que el resto del codigo compile igual en las
/// dos plataformas. Ver [ventana.dart] para por que hacen falta dos versiones.
class ControlDeVentana {
  ControlDeVentana._();

  /// Siempre `false` en web: el navegador dibuja su propia barra.
  static bool get disponible => false;

  static Future<void> preparar() async {}
  static Future<void> minimizar() async {}
  static Future<void> alternarMaximizada() async {}
  static Future<bool> estaMaximizada() async => false;
  static Future<void> cerrar() async {}
  static Future<void> arrastrar() async {}
  static void escuchar(void Function() alCambiar) {}
  static void dejarDeEscuchar(void Function() alCambiar) {}
}
