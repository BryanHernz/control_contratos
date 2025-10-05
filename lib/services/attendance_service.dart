import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static String dateKeyFrom(DateTime d) {
    final x = DateTime(d.year, d.month, d.day); // normalizado
    return DateFormat('yyyy-MM-dd').format(x);
  }

  static Future<void> ensureDayDoc(DateTime day) async {
    final x = DateTime(day.year, day.month, day.day); // normalizado
    final dateKey = dateKeyFrom(x);
    final doc =
        FirebaseFirestore.instance.collection('Asistencias').doc(dateKey);
    await doc.set({
      'fecha': Timestamp.fromDate(x),
      'dateKey': dateKey,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> addPresent(
    DateTime day, {
    required String workerId,
    required String name,
    required String rut,
    required String addedBy,
  }) async {
    final x = DateTime(day.year, day.month, day.day); // normalizado
    final dateKey = dateKeyFrom(x);
    final doc =
        FirebaseFirestore.instance.collection('Asistencias').doc(dateKey);
    await ensureDayDoc(x);
    await doc.set({
      'presentes': {
        workerId: {
          'workerId': workerId,
          'name': name, // NOMBRES APELLIDOS
          'rut': rut,
          'addedBy': addedBy,
          'createdAt': FieldValue.serverTimestamp(),
        }
      },
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removePresent(DateTime day, String workerId) async {
    final x = DateTime(day.year, day.month, day.day); // normalizado
    final dateKey = dateKeyFrom(x);
    final doc =
        FirebaseFirestore.instance.collection('Asistencias').doc(dateKey);
    await doc.update({
      'presentes.$workerId': FieldValue.delete(),
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Devuelve los presentes del día SIN ordenar.
  /// La ordenación la hace la UI/PDF con el mismo criterio para evitar desfaces.
  static Stream<List<Map<String, dynamic>>> listenPresents(DateTime day) {
    final x = DateTime(day.year, day.month, day.day); // normalizado
    final dateKey = dateKeyFrom(x);
    return FirebaseFirestore.instance
        .collection('Asistencias')
        .doc(dateKey)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      final map = (data?['presentes'] as Map<String, dynamic>? ?? {});
      final list =
          map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return list; // sin ordenar
    });
  }
}
