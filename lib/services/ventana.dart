/// Control de la ventana del sistema.
///
/// `window_manager` importa `dart:io`, asi que importarlo desde codigo
/// compartido rompe la compilacion web -- y la web es donde mas gente entra.
/// Esta importacion condicional deja el paquete fuera de ese build: la web se
/// lleva la version vacia, que no hace nada.
///
/// Android tambien pasa por la version de `dart:io`, pero el paquete no
/// declara Android, asi que ahi `disponible` es `false` y no se llama nunca.
export 'ventana_vacia.dart' if (dart.library.io) 'ventana_escritorio.dart';
