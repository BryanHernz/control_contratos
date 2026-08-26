import 'dart:io';

import 'package:flutter/widgets.dart' show Size;

import 'package:window_manager/window_manager.dart';

/// Control de la ventana en escritorio.
///
/// Solo Windows: es la unica plataforma de escritorio que se entrega. En
/// Android este archivo tambien se compila -- `dart.library.io` es cierto
/// alli -- pero `disponible` da `false` y no se llama a nada, que es lo que
/// evita el `MissingPluginException`.
class ControlDeVentana {
  ControlDeVentana._();

  static bool get disponible => Platform.isWindows;

  /// Oculta la barra de titulo del sistema y muestra la ventana.
  ///
  /// Se llama antes de `runApp`. `waitUntilReadyToShow` existe para no mostrar
  /// la ventana hasta tenerla configurada: sin eso aparece un instante con la
  /// barra nativa puesta y despues salta al tamano final, que se ve como un
  /// parpadeo.
  ///
  /// `TitleBarStyle.hidden` quita la barra pero **deja el marco**, asi que se
  /// conservan el redimensionado desde los bordes y los diseños de anclaje de
  /// Windows. `setAsFrameless` los perderia.
  static Future<void> preparar() async {
    if (!disponible) return;
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1280, 820),
        minimumSize: Size(940, 620),
        center: true,
        title: 'Control de Contratos',
        titleBarStyle: TitleBarStyle.hidden,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  static Future<void> minimizar() => windowManager.minimize();

  static Future<void> alternarMaximizada() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  static Future<bool> estaMaximizada() => windowManager.isMaximized();

  static Future<void> cerrar() => windowManager.close();

  /// Mueve la ventana siguiendo al puntero.
  ///
  /// Lo hace el sistema, no Flutter: por eso basta con avisarle al empezar el
  /// arrastre y no hay que seguir el movimiento a mano.
  static Future<void> arrastrar() => windowManager.startDragging();

  /// Puentes vivos, para poder quitar el listener exacto al soltar el widget.
  static final Map<void Function(), _Puente> _puentes = {};

  static void escuchar(void Function() alCambiar) {
    if (!disponible) return;
    final puente = _Puente(alCambiar);
    _puentes[alCambiar] = puente;
    windowManager.addListener(puente);
  }

  static void dejarDeEscuchar(void Function() alCambiar) {
    final puente = _puentes.remove(alCambiar);
    if (puente != null) windowManager.removeListener(puente);
  }
}

/// Traduce los eventos de `window_manager` a una simple llamada.
///
/// Existe para que la barra de titulo no tenga que mezclar `WindowListener`
/// -- y con eso importar el paquete -- solo para saber si esta maximizada.
class _Puente with WindowListener {
  _Puente(this.alCambiar);

  final void Function() alCambiar;

  @override
  void onWindowMaximize() => alCambiar();

  @override
  void onWindowUnmaximize() => alCambiar();
}
