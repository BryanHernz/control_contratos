import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_db.dart';
import 'plantilla_tipos.dart';

export 'plantilla_tipos.dart';

/// Una version publicada de una plantilla.
///
/// Las versiones **no se modifican**. Publicar crea una nueva y mueve el
/// puntero `versionActual`; la anterior queda intacta.
///
/// La razon no es prolijidad: un contrato firmado en marzo tiene que poder
/// reimprimirse identico en diciembre. Cada documento emitido guarda el
/// [id] de la version con que se genero, y la reimpresion usa esa, no la
/// vigente. Si la reimpresion saliera con clausulas distintas a las que la
/// persona firmo, el documento deja de servir como respaldo.
class VersionPlantilla {
  const VersionPlantilla({
    required this.id,
    required this.numero,
    required this.delta,
    required this.creadaPor,
    required this.creadaEn,
    this.nota = '',
    this.filas = const [],
  });

  final String id;
  final int numero;

  /// El contenido, en formato delta de Quill.
  final Map<String, dynamic> delta;

  final String creadaPor;
  final DateTime? creadaEn;

  /// Filas de la tabla del documento, si lleva una.
  ///
  /// Cada fila es una lista de celdas, tantas como encabezados declare
  /// [TipoPlantilla.tabla]. Va aparte del delta porque es una lista de
  /// registros, no prosa.
  final List<List<String>> filas;

  /// Que cambio respecto de la version anterior, escrito por quien publica.
  final String nota;

  factory VersionPlantilla.desdeDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? const {};
    return VersionPlantilla(
      id: doc.id,
      numero: (d['numero'] as num?)?.toInt() ?? 0,
      // Se guarda como texto y no como mapa anidado: un delta lleva listas de
      // mapas con claves libres, y Firestore no indexa ni valida bien eso.
      // Ademas asi el contenido publicado queda byte a byte como se guardo.
      delta: _leerDelta(d['deltaJson']),
      creadaPor: (d['creadaPor'] ?? '').toString(),
      creadaEn: (d['creadaEn'] as Timestamp?)?.toDate(),
      nota: (d['nota'] ?? '').toString(),
      filas: _leerFilas(d['filasJson']),
    );
  }

  static List<List<String>> _leerFilas(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return const [];
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        return [
          for (final fila in d)
            if (fila is List) [for (final c in fila) c.toString()],
        ];
      }
    } on FormatException {
      // Igual que con el delta: una tabla corrupta no tumba la pantalla.
    }
    return const [];
  }

  static Map<String, dynamic> _leerDelta(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return const {'ops': []};
    try {
      final decodificado = jsonDecode(raw);
      if (decodificado is Map<String, dynamic>) return decodificado;
      // Quill tambien serializa el delta como lista de ops a secas.
      if (decodificado is List) return {'ops': decodificado};
    } on FormatException {
      // Un delta corrupto no puede tumbar la pantalla de plantillas.
    }
    return const {'ops': []};
  }
}

class PlantillaService {
  static CollectionReference<Map<String, dynamic>> get _col =>
      db.collection('Plantillas');

  static DocumentReference<Map<String, dynamic>> _ref(String tipo) =>
      _col.doc(tipo);

  static CollectionReference<Map<String, dynamic>> _versiones(String tipo) =>
      _ref(tipo).collection('versiones');

  /// La plantilla vigente de un tipo, de una sola lectura.
  ///
  /// **Es lo que hay que usar para generar un documento**, no
  /// `escucharVigente(...).first`.
  ///
  /// `snapshots()` emite primero lo que tenga en cache -- que en la primera
  /// carga puede ser un documento inexistente -- y solo despues lo del
  /// servidor. `.first` se queda con esa primera emision y devuelve null, asi
  /// que el generador creia que no habia plantilla y caia al texto en codigo:
  /// publicabas una version, la veias en el editor, y el PDF salia con el
  /// texto viejo.
  static Future<VersionPlantilla?> obtenerVigente(String tipo) async {
    final cabecera = await _ref(tipo).get();
    final id = (cabecera.data()?['versionActual'] ?? '').toString();
    if (id.isEmpty) return null;
    final doc = await _versiones(tipo).doc(id).get();
    if (!doc.exists) return null;
    return VersionPlantilla.desdeDoc(doc);
  }

  /// La plantilla vigente, en vivo. Para pantallas que deben reaccionar a que
  /// alguien publique una version nueva mientras estan abiertas.
  static Stream<VersionPlantilla?> escucharVigente(String tipo) {
    return _ref(tipo).snapshots().asyncMap((snap) async {
      final id = (snap.data()?['versionActual'] ?? '').toString();
      if (id.isEmpty) return null;
      final doc = await _versiones(tipo).doc(id).get();
      if (!doc.exists) return null;
      return VersionPlantilla.desdeDoc(doc);
    });
  }

  /// Una version concreta. Es lo que usa la reimpresion de un documento ya
  /// emitido, que guarda el id con que se genero.
  static Future<VersionPlantilla?> obtenerVersion(
    String tipo,
    String versionId,
  ) async {
    final doc = await _versiones(tipo).doc(versionId).get();
    if (!doc.exists) return null;
    return VersionPlantilla.desdeDoc(doc);
  }

  /// Historial, de la mas nueva a la mas vieja.
  static Stream<List<VersionPlantilla>> escucharHistorial(String tipo) {
    return _versiones(tipo)
        .orderBy('numero', descending: true)
        .snapshots()
        .map((s) => s.docs.map(VersionPlantilla.desdeDoc).toList());
  }

  /// Publica una version nueva y la deja como vigente.
  ///
  /// Nunca toca las anteriores. Devuelve el id de la version creada.
  static Future<String> publicar({
    required String tipo,
    required Map<String, dynamic> delta,
    String nota = '',
    List<List<String>> filas = const [],
  }) async {
    final usuario = FirebaseAuth.instance.currentUser;
    final autor = usuario?.email ?? usuario?.uid ?? 'desconocido';
    final nuevaRef = _versiones(tipo).doc();

    await db.runTransaction((tx) async {
      final cabecera = await tx.get(_ref(tipo));
      final ultimo = (cabecera.data()?['ultimoNumero'] as num?)?.toInt() ?? 0;
      final numero = ultimo + 1;

      tx.set(nuevaRef, {
        'numero': numero,
        'deltaJson': jsonEncode(delta),
        'filasJson': jsonEncode(filas),
        'creadaPor': autor,
        'creadaEn': FieldValue.serverTimestamp(),
        'nota': nota.trim(),
      });

      tx.set(
        _ref(tipo),
        {
          'tipo': tipo,
          'versionActual': nuevaRef.id,
          'ultimoNumero': numero,
          'actualizadaPor': autor,
          'actualizadaEn': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    return nuevaRef.id;
  }

  /// Vuelve a dejar vigente una version anterior.
  ///
  /// No la copia ni la reescribe: solo mueve el puntero, para que el historial
  /// siga contando lo que de verdad paso.
  static Future<void> restaurar({
    required String tipo,
    required String versionId,
  }) async {
    final usuario = FirebaseAuth.instance.currentUser;
    await _ref(tipo).set(
      {
        'versionActual': versionId,
        'actualizadaPor': usuario?.email ?? usuario?.uid ?? 'desconocido',
        'actualizadaEn': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
