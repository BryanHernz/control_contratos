// Rellena el campo `busqueda` de los trabajadores que no lo tienen.
//
// Firestore no sabe buscar dentro de un texto: solo por prefijo y sobre un
// campo indexado. Por eso cada trabajador guarda una version normalizada de
// "nombres apellidos rut" -- sin tildes y en minusculas -- contra la que se
// consulta. Los documentos creados desde ahora lo escriben solos; los 674 que
// ya existen necesitan esta pasada.
//
//   dart run tool/backfill_busqueda.dart pruebas            (solo informa)
//   dart run tool/backfill_busqueda.dart pruebas --aplicar
//
// La base va como argumento y sin valor por defecto: `(default)` es
// produccion y eso se escribe entero a mano.
//
// Necesita un token: se lo pasa por la variable GOOGLE_ACCESS_TOKEN, o se
// obtiene con `gcloud auth print-access-token`.

import 'dart:convert';
import 'dart:io';

const proyecto = 'contratos-control';

const minimoPrefijo = 2;
const maximoPrefijo = 12;

/// Igual que `TrabajadoresRepo.prefijosDeBusqueda`, replicado aqui porque esta
/// herramienta corre en la VM de Dart y no puede importar Firestore.
List<String> prefijos(String nombres, String apellidos, String rut) {
  final rutLimpio = rut.replaceAll(RegExp(r'[.\-]'), '');
  final palabras = <String>{
    ...normalizar(nombres).split(RegExp(r'\s+')),
    ...normalizar(apellidos).split(RegExp(r'\s+')),
    ...normalizar(rut).split(RegExp(r'\s+')),
    normalizar(rutLimpio),
  }.where((w) => w.length >= minimoPrefijo).toSet();

  final salida = <String>{};
  for (final palabra in palabras) {
    final hasta =
        palabra.length < maximoPrefijo ? palabra.length : maximoPrefijo;
    for (var i = minimoPrefijo; i <= hasta; i++) {
      salida.add(palabra.substring(0, i));
    }
  }
  return salida.toList()..sort();
}

String normalizar(String s) => s
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u')
    .replaceAll('ñ', 'n');

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/backfill_busqueda.dart '
        '<pruebas|(default)> [--aplicar]');
    exitCode = 64;
    return;
  }

  final base = args.first;
  final aplicar = args.contains('--aplicar');
  final token = Platform.environment['GOOGLE_ACCESS_TOKEN'] ?? '';
  if (token.isEmpty) {
    stderr.writeln('Falta GOOGLE_ACCESS_TOKEN.');
    exitCode = 78;
    return;
  }

  final baseUrl = Uri.encodeComponent(base);
  final cliente = HttpClient();

  Future<Map<String, dynamic>> pedir(
    String metodo,
    String url, [
    Object? cuerpo,
  ]) async {
    final req = await cliente.openUrl(metodo, Uri.parse(url));
    req.headers.set('Authorization', 'Bearer $token');
    if (cuerpo != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(cuerpo));
    }
    final res = await req.close();
    final texto = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}: ${texto.substring(0, 200)}');
    }
    return jsonDecode(texto) as Map<String, dynamic>;
  }

  final raiz = 'https://firestore.googleapis.com/v1/projects/$proyecto'
      '/databases/$baseUrl/documents';

  var revisados = 0;
  var pendientes = 0;
  var escritos = 0;
  String? pageToken;

  do {
    final url = StringBuffer('$raiz/Trabajadores?pageSize=300');
    if (pageToken != null) url.write('&pageToken=$pageToken');
    final pagina = await pedir('GET', url.toString());

    for (final doc in (pagina['documents'] as List? ?? const [])) {
      revisados++;
      final campos = (doc['fields'] as Map?) ?? const {};
      final nombre = doc['name'].toString().split('/').last;

      String texto(String k) =>
          ((campos[k] as Map?)?['stringValue'] ?? '').toString().trim();

      final esperado = normalizar(
        [texto('nombres'), texto('apellidos'), texto('rut')]
            .where((s) => s.isNotEmpty)
            .join(' '),
      );
      final esperadosPrefijos =
          prefijos(texto('nombres'), texto('apellidos'), texto('rut'));

      final actual = texto('busqueda');
      final actualPrefijos = (((campos['busquedaPrefijos']
                  as Map?)?['arrayValue'] as Map?)?['values'] as List? ??
              const [])
          .map((v) => (v as Map)['stringValue'].toString())
          .toList();

      final igual = actual == esperado &&
          actualPrefijos.length == esperadosPrefijos.length;
      if (igual || esperado.isEmpty) continue;
      pendientes++;

      if (!aplicar) {
        if (pendientes <= 5) {
          stdout.writeln('  $nombre -> "$esperado" '
              '(${esperadosPrefijos.length} prefijos)');
        }
        continue;
      }

      await pedir(
        'PATCH',
        '$raiz/Trabajadores/$nombre'
            '?updateMask.fieldPaths=busqueda'
            '&updateMask.fieldPaths=busquedaPrefijos',
        {
          'fields': {
            'busqueda': {'stringValue': esperado},
            'busquedaPrefijos': {
              'arrayValue': {
                'values': [
                  for (final p in esperadosPrefijos) {'stringValue': p}
                ]
              }
            },
          }
        },
      );
      escritos++;
      if (escritos % 50 == 0) stdout.writeln('  $escritos escritos...');
    }

    pageToken = pagina['nextPageToken'] as String?;
  } while (pageToken != null);

  cliente.close();

  stdout.writeln('\nRevisados: $revisados');
  stdout.writeln('Sin campo o desactualizados: $pendientes');
  if (aplicar) {
    stdout.writeln('Escritos: $escritos');
  } else {
    stdout.writeln('(solo informe; usa --aplicar para escribir)');
  }
}
