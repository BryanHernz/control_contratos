import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  // Utils fecha
  static String dateKeyFrom(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return DateFormat('yyyy-MM-dd').format(x);
  }

  // Refs
  static DocumentReference<Map<String, dynamic>> _typesRef() =>
      FirebaseFirestore.instance.collection('Otros').doc('listas-asistencia');

  static DocumentReference<Map<String, dynamic>> _dayRef(DateTime day) {
    final key = dateKeyFrom(DateTime(day.year, day.month, day.day));
    return FirebaseFirestore.instance.collection('Asistencias').doc(key);
  }

  // Tipos globales
  static Stream<List<String>> listenAllListTypes() {
    return _typesRef().snapshots().map((snap) {
      final raw =
          (snap.data()?['tipos'] as List?)?.cast<dynamic>() ?? <dynamic>[];
      final tipos = raw
          .map((e) => e.toString().trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      tipos.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return tipos;
    });
  }

  static Future<void> addListType(String rawName) async {
    final name = rawName.trim().toUpperCase();
    if (name.isEmpty) return;
    final ref = _typesRef();
    await ref.set({
      'nombre': 'listas_asistencia',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final snap = await ref.get();
    final current = (snap.data()?['tipos'] as List?)?.cast<dynamic>() ?? [];
    final normalized =
        current.map((e) => e.toString().trim().toUpperCase()).toList();
    if (!normalized.contains(name)) {
      await ref.set({
        'tipos': FieldValue.arrayUnion([name]),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Día
  static Future<void> _ensureDayDoc(DateTime day) async {
    final ref = _dayRef(day);
    await ref.set({
      'fecha': Timestamp.fromDate(DateTime(day.year, day.month, day.day)),
      'dateKey': dateKeyFrom(day),
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Listas activas del día (mapa)
  static Stream<List<String>> listenDayActiveLists(DateTime day) {
    return _dayRef(day).snapshots().map((snap) {
      final data = snap.data();
      final listas = (data?['listas'] as Map?)?.cast<String, dynamic>() ?? {};
      final names = listas.keys
          .map((k) => k.toString().trim().toUpperCase())
          .where((k) => k.isNotEmpty)
          .toList();
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return names;
    });
  }

  static Future<void> addActiveList(DateTime day, String rawName) async {
    final name = rawName.trim().toUpperCase();
    if (name.isEmpty) return;
    final ref = _dayRef(day);
    await _ensureDayDoc(day);
    await ref.set({
      'listas': {
        name: {
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        }
      },
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Presentes
  static Future<void> addOrMovePresent(
    DateTime day, {
    required String workerId,
    required String name,
    required String rut,
    required String list,
    required String addedBy,
  }) async {
    final ref = _dayRef(day);
    await _ensureDayDoc(day);
    await addActiveList(day, list.toUpperCase());

    await ref.set({
      'presentes': {
        workerId: {
          'workerId': workerId,
          'name': name,
          'rut': rut,
          'list': list.toString().toUpperCase(),
          'addedBy': addedBy,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      },
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removePresent(DateTime day, String workerId) async {
    final ref = _dayRef(day);
    await ref.update({
      'presentes.$workerId': FieldValue.delete(),
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> listenPresents(
      DateTime day, String group) {
    return _dayRef(day).snapshots().map((snap) {
      final data = snap.data();
      final presentes =
          (data?['presentes'] as Map?)?.cast<String, dynamic>() ?? {};
      final list = presentes.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => group == 'GENERAL'
              ? true
              : (e['list'] ?? '').toString().toUpperCase() ==
                  group.toUpperCase())
          .toList();
      list.sort((a, b) => (a['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['name'] ?? '').toString().toLowerCase()));
      for (var e in list) {
        if ((e['list'] ?? '') is String) {
          e['list'] = (e['list'] ?? '').toString().toUpperCase();
        }
      }
      return list;
    });
  }
}
