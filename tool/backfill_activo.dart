// Deja definido el campo `activo` en los trabajadores que no lo tienen.
//
//   dart run tool/backfill_activo.dart pruebas             (solo informa)
//   dart run tool/backfill_activo.dart pruebas --aplicar
//
// La base va como argumento y sin valor por defecto: `(default)` es produccion
// y eso se escribe entero a mano.
//
// Necesita un token en GOOGLE_ACCESS_TOKEN (`gcloud auth print-access-token`).
//
// POR QUE
//
// El campo lo escribe la app sola: imprimir un contrato marca `activo: true` y
// un finiquito `activo: false`. Pero 675 de los 676 trabajadores se crearon
// antes de que eso existiera, asi que no tienen el campo -- y en Firestore un
// campo ausente no lo encuentra ninguna consulta. El dashboard contaba 1
// trabajador de 676.
//
// Se escribe `false` y no `true` a proposito: el padron es un registro
// historico de todos los que han pasado desde 2023, no una lista de quien
// trabaja hoy. Marcarlos activos seria inventar un dato. Quedan en falso y se
// activan al emitirles un contrato, o a mano desde la ficha.
//
// OJO ANTES DE CORRER ESTO: cualquier trigger `onDocumentWritten` sobre
// `Trabajadores` se disparara una vez por documento. `resumenTrabajadores`
// recorria la coleccion entera en cada invocacion -- 675 escrituras habrian
// costado unas 456.000 lecturas -- y por eso se elimino antes.

import 'dart:convert';
import 'dart:io';

const proyecto = 'contratos-control';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/backfill_activo.dart '
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
      throw Exception('HTTP ${res.statusCode}: $texto');
    }
    return jsonDecode(texto) as Map<String, dynamic>;
  }

  final raiz = 'https://firestore.googleapis.com/v1/projects/$proyecto'
      '/databases/$baseUrl/documents';

  var revisados = 0;
  var sinCampo = 0;
  var escritos = 0;
  var yaActivos = 0;
  String? pageToken;

  do {
    final url = StringBuffer('$raiz/Trabajadores?pageSize=300');
    if (pageToken != null) url.write('&pageToken=$pageToken');
    final pagina = await pedir('GET', url.toString());

    for (final doc in (pagina['documents'] as List? ?? const [])) {
      revisados++;
      final campos = (doc['fields'] as Map?) ?? const {};
      final nombre = doc['name'].toString().split('/').last;

      if (campos.containsKey('activo')) {
        if ((campos['activo'] as Map?)?['booleanValue'] == true) yaActivos++;
        continue;
      }
      sinCampo++;

      if (!aplicar) {
        if (sinCampo <= 5) stderr.writeln('  $nombre -> activo: false');
        continue;
      }

      // `updateMask` con un solo campo: no se toca nada mas del documento.
      await pedir(
        'PATCH',
        '$raiz/Trabajadores/$nombre?updateMask.fieldPaths=activo',
        {
          'fields': {
            'activo': {'booleanValue': false}
          }
        },
      );
      escritos++;
      if (escritos % 50 == 0) stdout.writeln('  $escritos escritos...');
    }

    pageToken = pagina['nextPageToken'] as String?;
  } while (pageToken != null);

  cliente.close();

  stdout.writeln('');
  stdout.writeln('Revisados: $revisados');
  stdout.writeln('Ya tenian el campo: ${revisados - sinCampo}'
      '  (de esos, $yaActivos activos)');
  stdout.writeln('Sin el campo: $sinCampo');
  if (aplicar) {
    stdout.writeln('Escritos: $escritos');
  } else {
    stdout.writeln('(solo informe; usa --aplicar para escribir)');
  }
}
