import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firestore_db.dart';

/// Borrar la ficha de un trabajador, decidiendo si sus fotos de carnet se van
/// con ella.
///
/// Las fotos viven en Storage con la ruta armada a partir del RUT:
///
///     WorkersIdImages/{rut}_front
///     WorkersIdImages/{rut}_back
///
/// O sea que **no pertenecen a la ficha sino al RUT**. Dos fichas repetidas
/// apuntan al mismo archivo, y hay 16 RUT repetidos en el padron.
///
/// De ahi salen los dos errores posibles, y los dos existian:
///
/// - borrar siempre las imagenes deja sin carnet a la ficha que se conserva,
///   que es lo que hacia el detalle del trabajador;
/// - no borrarlas nunca deja archivos huerfanos en Storage para siempre, sin
///   ninguna ficha que los referencie.
///
/// La regla correcta es mirar si queda alguien mas usando esa MISMA ruta.
class EliminarTrabajador {
  EliminarTrabajador._();

  static const _carpeta = 'WorkersIdImages';

  /// Cuantas otras fichas usarian las mismas fotos.
  ///
  /// La comparacion es por igualdad exacta del texto del RUT y no
  /// normalizada, y eso es a proposito: la ruta del archivo se arma con el RUT
  /// **tal como esta escrito**, asi que `12.345.678-9` y `12345678-9` apuntan
  /// a archivos distintos aunque sean la misma persona.
  static Future<int> otrasFichasConElMismoRut({
    required String id,
    required String rut,
  }) async {
    if (rut.trim().isEmpty) return 0;
    final snap =
        await db.collection('Trabajadores').where('rut', isEqualTo: rut).get();
    return snap.docs.where((d) => d.id != id).length;
  }

  /// Borra la ficha y, solo si nadie mas comparte su RUT, tambien sus fotos.
  ///
  /// Devuelve `true` si las fotos se borraron.
  static Future<bool> eliminar({
    required String id,
    required String rut,
  }) async {
    final quedanOtras = await otrasFichasConElMismoRut(id: id, rut: rut);

    await db.collection('Trabajadores').doc(id).delete();

    if (quedanOtras > 0) {
      debugPrint('[EliminarTrabajador] $rut lo usan $quedanOtras fichas mas: '
          'las fotos se conservan.');
      return false;
    }

    for (final sufijo in const ['front', 'back']) {
      try {
        await FirebaseStorage.instance
            .ref(_carpeta)
            .child('${rut}_$sufijo')
            .delete();
      } catch (e) {
        // Que no exista es lo normal: 1 de cada 4 fichas no tiene foto. No es
        // un error que deba detener el borrado de la ficha, que ya ocurrio.
        debugPrint('[EliminarTrabajador] ${rut}_$sufijo: $e');
      }
    }
    return true;
  }
}
