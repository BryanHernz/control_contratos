import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firestore_db.dart';

/// Registro de acciones sobre datos que importan.
///
/// La coleccion `Auditoria` tenia **cero documentos** pese a existir desde el
/// principio. El unico punto que escribia lo hacia sin `await` y dentro de un
/// `catch` vacio, asi que cualquier fallo desaparecia sin dejar rastro -- y el
/// panel "Actividad reciente" del dashboard nunca mostro nada.
///
/// Las reglas de Firestore permiten crear pero no editar ni borrar: un
/// registro que el cliente puede modificar no sirve como registro.
///
/// Sigue siendo el cliente quien decide registrar. Lo correcto es un trigger
/// en el servidor, para que no dependa de que la app se porte bien; mientras
/// tanto, al menos ya no se pierde en silencio.
class Auditoria {
  static const crearTrabajador = 'CREAR_TRABAJADOR';
  static const editarTrabajador = 'EDITAR_TRABAJADOR';
  static const eliminarTrabajador = 'ELIMINAR_TRABAJADOR';
  static const generarContrato = 'GENERAR_CONTRATO';
  static const generarFiniquito = 'GENERAR_FINIQUITO';
  static const publicarPlantilla = 'PUBLICAR_PLANTILLA';

  /// Deja constancia de una accion.
  ///
  /// **No relanza.** Que la auditoria falle no puede impedir que se cree un
  /// trabajador; pero tampoco se traga el error: queda en la consola para que
  /// se pueda diagnosticar.
  static Future<void> registrar(
    String accion, {
    String? entidadId,
    Map<String, dynamic> detalle = const {},
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await db.collection('Auditoria').add({
        'accion': accion,
        'usuario': user?.email ?? user?.uid ?? 'desconocido',
        if (entidadId != null) 'entidadId': entidadId,
        ...detalle,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Un `catch` vacio era justamente el problema. Aqui se registra.
      debugPrint('No se pudo escribir en Auditoria ($accion): $e');
    }
  }
}
