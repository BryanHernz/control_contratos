import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static String dateKeyFrom(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return DateFormat('yyyy-MM-dd').format(x);
  }

  static Future<void> ensureDayDoc(DateTime day) async {
    final x = DateTime(day.year, day.month, day.day);
    final dateKey = dateKeyFrom(x);
    final doc =
        FirebaseFirestore.instance.collection('Asistencias').doc(dateKey);
    await doc.set({
      'fecha': Timestamp.fromDate(x),
      'dateKey': dateKey,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Detecta si el `presentes` es del esquema antiguo (mapa directo de workerId->entrada)
  static bool _isLegacyPresentes(Object? presentes) {
    if (presentes is! Map) return false;
    // Si alguno de los values parece entrada (tiene 'rut' o 'name') entonces es legacy
    return presentes.values.any((v) =>
        v is Map &&
        (v.containsKey('rut') ||
            v.containsKey('name') ||
            v.containsKey('workerId')));
  }

  /// Devuelve el mapa de presentes para una LISTA (grupo) dada, haciendo compatibilidad.
  static Map<String, dynamic> _extractGroupMap(
    Map<String, dynamic>? data,
    String group,
  ) {
    final presentes = data?['presentes'];
    if (presentes is Map<String, dynamic>) {
      // Compatibilidad: si es legacy, usar como GENERAL
      if (_isLegacyPresentes(presentes)) {
        return group == 'GENERAL'
            ? Map<String, dynamic>.from(presentes)
            : <String, dynamic>{};
      }
      // Esquema nuevo: presentes[group] es un mapa de workerId -> entrada
      final g = presentes[group];
      if (g is Map) return Map<String, dynamic>.from(g.cast<String, dynamic>());
    }
    return <String, dynamic>{};
  }

  /// Lista de grupos existentes en el día (si es legacy => ['GENERAL'])
  static Stream<List<String>> listenGroups(DateTime day) {
    final x = DateTime(day.year, day.month, day.day);
    final dateKey = dateKeyFrom(x);
    return FirebaseFirestore.instance
        .collection('Asistencias')
        .doc(dateKey)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      final presentes = data?['presentes'];
      if (presentes is Map<String, dynamic>) {
        if (_isLegacyPresentes(presentes)) {
          return const ['GENERAL'];
        }
        // esquema nuevo: claves = nombres de listas
        final keys = presentes.keys.map((e) => e.toString()).toList();
        keys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return keys.isEmpty ? <String>['GENERAL'] : keys;
      }
      return const ['GENERAL'];
    });
  }

  /// Crea la lista (grupo) si no existe. No toca lo demás.
  static Future<void> ensureGroup(DateTime day, String group) async {
    final x = DateTime(day.year, day.month, day.day);
    final dateKey = dateKeyFrom(x);
    final ref =
        FirebaseFirestore.instance.collection('Asistencias').doc(dateKey);

    await ensureDayDoc(x);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final presentes = data['presentes'];

      Map<String, dynamic> newPresentes;

      if (presentes is Map<String, dynamic>) {
        if (_isLegacyPresentes(presentes)) {
          // migrar legacy a formato nuevo bajo GENERAL
          newPresentes = {
            'GENERAL': Map<String, dynamic>.from(presentes),
          };
        } else {
          newPresentes = Map<String, dynamic>.from(presentes);
        }
      } else {
        newPresentes = {};
      }

      newPresentes.putIfAbsent(group, () => {});
      tx.set(
          ref,
          {
            'presentes': newPresentes,
            'lastUpdate': FieldValue.serverTimestamp(),
          },
          SetOptions(
              merge:
                  false)); // reescribe 'presentes' con la versión migrada/asegurada
    });
  }

  static Future<void> addPresent(
    DateTime day, {
    required String group, // NUEVO
    required String workerId,
    required String name,
    required String rut,
    required String addedBy,
  }) async {
    final x = DateTime(day.year, day.month, day.day);
    final dateKey = dateKeyFrom(x);
    final doc =
        FirebaseFirestore.instance.collection('Asistencias').doc(dateKey);

    await ensureDayDoc(x);
    await ensureGroup(x, group); // asegura el grupo y migra si hace falta

    await doc.set({
      'presentes': {
        group: {
          workerId: {
            'workerId': workerId,
            'name': name,
            'rut': rut,
            'addedBy': addedBy,
            'createdAt': FieldValue.serverTimestamp(),
          }
        }
      },
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removePresent(
      DateTime day, String group, String workerId) async {
    final x = DateTime(day.year, day.month, day.day);
    final dateKey = dateKeyFrom(x);
    final doc =
        FirebaseFirestore.instance.collection('Asistencias').doc(dateKey);

    await doc.update({
      'presentes.$group.$workerId': FieldValue.delete(),
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> listenPresents(
      DateTime day, String group) {
    final x = DateTime(day.year, day.month, day.day);
    final dateKey = dateKeyFrom(x);
    return FirebaseFirestore.instance
        .collection('Asistencias')
        .doc(dateKey)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      final map = _extractGroupMap(data, group);
      final list =
          map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      list.sort((a, b) => (a['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['name'] ?? '').toString().toLowerCase()));
      return list;
    });
  }
}
