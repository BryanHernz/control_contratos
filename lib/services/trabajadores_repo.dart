import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/worker_model.dart';
import '../utils/normalize.dart';
import 'firestore_db.dart';

/// Filtros de la vista de trabajadores.
///
/// Todos son de igualdad, que es lo que Firestore sabe combinar con un
/// `orderBy` teniendo un indice compuesto por cada campo.
class FiltrosTrabajadores {
  const FiltrosTrabajadores({
    this.empresa,
    this.labor,
    this.comuna,
    this.nacionalidad,
    this.afp,
    this.prevision,
    this.busqueda = '',
  });

  final String? empresa;
  final String? labor;
  final String? comuna;
  final String? nacionalidad;
  final String? afp;
  final String? prevision;

  /// Texto libre. Se resuelve por prefijo contra el campo [WorkerModel.busqueda].
  final String busqueda;

  bool get hayFiltroDeCampo =>
      empresa != null ||
      labor != null ||
      comuna != null ||
      nacionalidad != null ||
      afp != null ||
      prevision != null;

  bool get hayBusqueda => busqueda.trim().isNotEmpty;

  bool get vacio => !hayFiltroDeCampo && !hayBusqueda;

  /// Los filtros de campo como pares, en el orden en que se aplican.
  List<(String, String)> get camposActivos => [
        // En Firestore el establecimiento se llama `lugar`.
        if (empresa != null) ('lugar', empresa!),
        if (labor != null) ('labor', labor!),
        if (comuna != null) ('comuna', comuna!),
        if (nacionalidad != null) ('nacionalidad', nacionalidad!),
        if (afp != null) ('afp', afp!),
        if (prevision != null) ('prevision', prevision!),
      ];
}

/// Una pagina de resultados.
class PaginaTrabajadores {
  const PaginaTrabajadores({
    required this.trabajadores,
    required this.ultimo,
    required this.hayMas,
  });

  final List<WorkerModel> trabajadores;

  /// Cursor para pedir la siguiente pagina.
  final DocumentSnapshot? ultimo;

  final bool hayMas;
}

/// Acceso paginado a `Trabajadores`.
///
/// La vista cargaba los 674 documentos de una sola vez y encima con
/// `.snapshots()`, o sea en vivo: cada visita eran 674 lecturas y cualquier
/// escritura reenviaba lo que cambiara. Todo eso solo para poder buscar y
/// filtrar en memoria.
///
/// Aqui se pide de a paginas. Buscar y filtrar pasan a ser consultas, no
/// recorridos de una lista completa.
class TrabajadoresRepo {
  static const int tamanoPagina = 50;

  static CollectionReference<Map<String, dynamic>> get _col =>
      db.collection('Trabajadores');

  /// Arma la consulta segun los filtros.
  ///
  /// **Solo el primer filtro de campo va al servidor.** Firestore necesita un
  /// indice compuesto por cada combinacion de igualdades mas el `orderBy`, y
  /// con seis filtros opcionales eso son 64 combinaciones -- mas de las que
  /// tiene sentido declarar. Con uno solo alcanzan seis indices, y el resto se
  /// afina sobre un conjunto ya reducido.
  static Query<Map<String, dynamic>> _consulta(FiltrosTrabajadores f) {
    Query<Map<String, dynamic>> q = _col;

    final campos = f.camposActivos;
    if (campos.isNotEmpty) {
      q = q.where(campos.first.$1, isEqualTo: campos.first.$2);
    }

    if (f.hayBusqueda) {
      // Pertenencia al array de prefijos, no prefijo de una cadena.
      //
      // Guardar "bryan hernandez 12.345.678-9" y consultar por prefijo solo
      // encontraba por el PRIMER nombre: buscar "hernan" pedia cadenas que
      // empiecen con "hernan", y esa empieza con "bryan". Ahora cada palabra
      // aporta sus propios prefijos y `array-contains` los busca en cualquier
      // posicion.
      final t = normalize(f.busqueda.trim());
      return q.where('busquedaPrefijos', arrayContains: t).orderBy('nombres');
    }

    return q.orderBy('nombres');
  }

  /// Trae una pagina.
  ///
  /// [desde] es el cursor de la pagina anterior: la nueva empieza DESPUES de
  /// ese documento. [desdeInclusivo] en cambio empieza EN el, que es lo que
  /// necesita el salto por letra -- si excluyera el primer documento de la
  /// letra, saltar a la "M" mostraria desde el segundo Manuel.
  static Future<PaginaTrabajadores> pagina(
    FiltrosTrabajadores filtros, {
    DocumentSnapshot? desde,
    DocumentSnapshot? desdeInclusivo,
    int limite = tamanoPagina,
  }) async {
    var q = _consulta(filtros).limit(limite + 1);
    if (desdeInclusivo != null) {
      q = q.startAtDocument(desdeInclusivo);
    } else if (desde != null) {
      q = q.startAfterDocument(desde);
    }

    final snap = await q.get();
    final docs = snap.docs;

    // Se pide uno de mas para saber si hay pagina siguiente sin una consulta
    // extra de conteo.
    final hayMas = docs.length > limite;
    final visibles = hayMas ? docs.sublist(0, limite) : docs;

    final trabajadores =
        visibles.map(WorkerModel.fromDocumentSnapshot).toList();

    // Los filtros que no fueron al servidor se aplican aqui, sobre un conjunto
    // ya acotado por el primero.
    final restantes = filtros.camposActivos.skip(1).toList();
    final filtrados = restantes.isEmpty
        ? trabajadores
        : trabajadores.where((w) {
            for (final (campo, valor) in restantes) {
              if (_valorDe(w, campo) != valor) return false;
            }
            return true;
          }).toList();

    return PaginaTrabajadores(
      trabajadores: filtrados,
      ultimo: visibles.isEmpty ? null : visibles.last,
      hayMas: hayMas,
    );
  }

  /// Cursor para saltar a una letra del abecedario.
  ///
  /// Es una consulta acotada, no un recorrido: antes la barra alfabetica
  /// buscaba la posicion dentro de la lista completa en memoria.
  static Future<DocumentSnapshot?> cursorDeLetra(String letra) async {
    final snap = await _col
        .orderBy('nombres')
        .where('nombres', isGreaterThanOrEqualTo: letra.toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first;
  }

  /// Cuantos trabajadores hay, sin descargarlos.
  static Future<int> total(FiltrosTrabajadores filtros) async {
    final snap = await _consulta(filtros).count().get();
    return snap.count ?? 0;
  }

  static String? _valorDe(WorkerModel w, String campo) {
    switch (campo) {
      case 'lugar':
        return w.place;
      case 'labor':
        return w.labor;
      case 'comuna':
        return w.commune;
      case 'nacionalidad':
        return w.nacionality;
      case 'afp':
        return w.afp;
      case 'prevision':
        return w.prevision;
      default:
        return null;
    }
  }

  /// Texto normalizado del trabajador, legible.
  ///
  /// Se guarda para poder leerlo de un vistazo en la consola de Firestore; la
  /// busqueda de verdad usa [prefijosDeBusqueda].
  static String textoDeBusqueda({
    String? nombres,
    String? apellidos,
    String? rut,
  }) {
    return normalize([
      (nombres ?? '').trim(),
      (apellidos ?? '').trim(),
      (rut ?? '').trim(),
    ].where((s) => s.isNotEmpty).join(' '));
  }

  /// Minimo de letras que se indexan. Con una sola, el array de un trabajador
  /// coincidiria con media planilla y no acotaria nada.
  static const int minimoPrefijo = 2;

  /// Tope de letras por palabra. Mas alla no aporta: quien escribio doce
  /// letras ya encontro a quien buscaba.
  static const int maximoPrefijo = 12;

  /// Todos los prefijos por los que se puede encontrar a un trabajador.
  ///
  /// Firestore no sabe buscar dentro de un texto. La forma de que "hernan"
  /// encuentre a "Bryan Hernandez" es guardar de antemano cada prefijo de cada
  /// palabra y consultar con `array-contains`.
  ///
  /// El RUT entra dos veces, con puntos y sin ellos, porque la gente lo teclea
  /// de las dos maneras.
  static List<String> prefijosDeBusqueda({
    String? nombres,
    String? apellidos,
    String? rut,
  }) {
    final rutLimpio = (rut ?? '').replaceAll(RegExp(r'[.\-]'), '');

    final palabras = <String>{
      ...normalize(nombres ?? '').split(RegExp(r'\s+')),
      ...normalize(apellidos ?? '').split(RegExp(r'\s+')),
      ...normalize(rut ?? '').split(RegExp(r'\s+')),
      normalize(rutLimpio),
    }.where((w) => w.length >= minimoPrefijo).toSet();

    final prefijos = <String>{};
    for (final palabra in palabras) {
      final hasta =
          palabra.length < maximoPrefijo ? palabra.length : maximoPrefijo;
      for (var i = minimoPrefijo; i <= hasta; i++) {
        prefijos.add(palabra.substring(0, i));
      }
    }
    return prefijos.toList()..sort();
  }
}
