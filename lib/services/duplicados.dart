import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/worker_model.dart';
import 'firestore_db.dart';

/// Una ficha que comparte RUT con otra.
class FichaRepetida {
  const FichaRepetida({required this.id, required this.datos});

  final String id;
  final Map<String, dynamic> datos;

  String texto(String clave) => (datos[clave] ?? '').toString().trim();

  /// La ficha como modelo, para abrir el formulario de edicion con ella.
  WorkerModel get modelo => WorkerModel(
        id: id,
        name: texto('nombres'),
        lastName: texto('apellidos'),
        rut: texto('rut'),
        email: texto('correo'),
        nacionality: texto('nacionalidad'),
        civilState: texto('estadoCivil'),
        birth: texto('fechaNacimiento'),
        adress: texto('direccion'),
        commune: texto('comuna'),
        labor: texto('labor'),
        place: texto('lugar'),
        afp: texto('afp'),
        prevision: texto('prevision'),
        ingress: texto('ingreso'),
        imageFront: texto('imagenFront'),
        imageBack: texto('imagenBack'),
        activo: datos['activo'] == true,
      );

  String get nombreCompleto =>
      '${texto('nombres')} ${texto('apellidos')}'.trim();

  DateTime? get ingreso {
    final t = datos['fechaIngreso'];
    return t is Timestamp ? t.toDate() : null;
  }
}

/// Un RUT que aparece en mas de una ficha.
///
/// **No** se llama "duplicado" a proposito. Medido sobre las 676 fichas: de 16
/// RUT repetidos, la fecha de nacimiento difiere en 9 -- y en al menos un caso
/// los nombres son de dos personas distintas (`rodrigo gutierrez hurtado` y
/// `camila hurtado gutierrez` con el mismo RUT). Ahi el duplicado no existe:
/// lo que hay es un RUT mal escrito, y fusionarlas borraria a un trabajador
/// real.
class GrupoRepetido {
  const GrupoRepetido({required this.rut, required this.fichas});

  /// El RUT normalizado: sin puntos, sin guion, en mayusculas.
  final String rut;
  final List<FichaRepetida> fichas;

  /// Campos en los que las fichas no coinciden.
  ///
  /// Es lo que hay que mirar para decidir: si difieren el nombre y la fecha de
  /// nacimiento, casi seguro son dos personas.
  List<String> get camposEnConflicto {
    const revisar = [
      'nombres',
      'apellidos',
      'fechaNacimiento',
      'nacionalidad',
      'estadoCivil',
      'direccion',
      'comuna',
      'labor',
      'lugar',
      'afp',
      'prevision',
      'correo',
    ];
    return [
      for (final c in revisar)
        if (fichas.map((f) => f.texto(c)).where((v) => v.isNotEmpty).toSet()
                .length >
            1)
          c,
    ];
  }

  /// `true` cuando lo mas probable es que sean personas distintas.
  ///
  /// La senal fuerte es la fecha de nacimiento: dos fichas de la misma persona
  /// pueden traer el nombre escrito distinto -- "jhenny" y "jenny" -- pero no
  /// deberian discrepar en cuando nacio. Es una sospecha, no un veredicto:
  /// quien decide es quien tiene la cedula a la vista.
  bool get pareceOtraPersona =>
      camposEnConflicto.contains('fechaNacimiento') &&
      (camposEnConflicto.contains('apellidos') ||
          camposEnConflicto.contains('nombres'));
}

/// Encuentra las fichas que comparten RUT.
class Duplicados {
  Duplicados._();

  /// Normaliza un RUT para compararlo: `12.345.678-9` y `123456789` son el
  /// mismo.
  static String normalizar(String rut) =>
      rut.replaceAll(RegExp(r'[.\-\s]'), '').toUpperCase();

  /// Recorre el padron completo y agrupa por RUT.
  ///
  /// Es una lectura de toda la coleccion, y por eso vive en una pantalla que
  /// se abre a proposito y no en el arranque de la app. Firestore no sabe
  /// hacer "agrupar por campo": hay que traer y agrupar aca.
  static Future<List<GrupoRepetido>> buscar() async {
    final snap = await db.collection('Trabajadores').get();

    final porRut = <String, List<FichaRepetida>>{};
    for (final doc in snap.docs) {
      final datos = doc.data();
      final rut = normalizar((datos['rut'] ?? '').toString());
      if (rut.isEmpty) continue;
      porRut
          .putIfAbsent(rut, () => <FichaRepetida>[])
          .add(FichaRepetida(id: doc.id, datos: datos));
    }

    final grupos = [
      for (final e in porRut.entries)
        if (e.value.length > 1) GrupoRepetido(rut: e.key, fichas: e.value),
    ];

    // Primero los que parecen personas distintas: son los que hay que mirar,
    // porque ahi hay un RUT mal escrito y alguien puede quedar sin ficha.
    grupos.sort((a, b) {
      if (a.pareceOtraPersona != b.pareceOtraPersona) {
        return a.pareceOtraPersona ? -1 : 1;
      }
      return a.rut.compareTo(b.rut);
    });
    return grupos;
  }

  /// Funde [descartada] dentro de [conservada] y borra la primera.
  ///
  /// Solo rellena lo que en la ficha que queda esta vacio: nunca pisa un dato
  /// existente. Si las dos traen algo distinto, gana la que se conserva --
  /// que es la que eligio quien esta mirando las dos.
  ///
  /// La fecha de ingreso es la excepcion: se queda **la mas reciente** de las
  /// dos. Que a alguien se le cargue una ficha nueva significa que volvio a
  /// entrar, asi que el ultimo ingreso es el que describe su situacion actual.
  static Future<void> fusionar({
    required FichaRepetida conservada,
    required FichaRepetida descartada,
  }) async {
    final cambios = <String, dynamic>{};

    for (final clave in descartada.datos.keys) {
      // `busqueda` y `busquedaPrefijos` se derivan del nombre y el RUT: si se
      // copiaran de la otra ficha, buscar encontraria al trabajador por
      // datos que ya no son los suyos.
      if (clave == 'busqueda' ||
          clave == 'busquedaPrefijos' ||
          clave == 'fechaIngreso' ||
          clave == 'ingreso') {
        continue;
      }
      final actual = conservada.datos[clave];
      final vacio = actual == null || actual.toString().trim().isEmpty;
      final entrante = descartada.datos[clave];
      final entranteVacio =
          entrante == null || entrante.toString().trim().isEmpty;
      if (vacio && !entranteVacio) cambios[clave] = entrante;
    }

    final iA = conservada.ingreso;
    final iB = descartada.ingreso;
    if (iB != null && (iA == null || iB.isAfter(iA))) {
      cambios['fechaIngreso'] = Timestamp.fromDate(iB);
      cambios['ingreso'] = descartada.texto('ingreso');
    }

    final lote = db.batch();
    if (cambios.isNotEmpty) {
      lote.update(
        db.collection('Trabajadores').doc(conservada.id),
        cambios,
      );
    }
    lote.delete(db.collection('Trabajadores').doc(descartada.id));
    await lote.commit();
  }

  /// Borra una ficha repetida.
  ///
  /// **No toca las imagenes de carnet.** Viven en Storage bajo
  /// `WorkersIdImages/{rut}_front`, o sea indexadas por RUT: dos fichas que
  /// comparten RUT comparten tambien las fotos, y borrarlas al eliminar una
  /// dejaria sin carnet a la que se conserva.
  static Future<void> eliminar(FichaRepetida ficha) {
    return db.collection('Trabajadores').doc(ficha.id).delete();
  }
}
