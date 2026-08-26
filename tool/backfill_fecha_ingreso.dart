// Agrega `fechaIngreso` (fecha real) a partir de `ingreso` (texto).
//
//   dart run tool/backfill_fecha_ingreso.dart pruebas             (informa)
//   dart run tool/backfill_fecha_ingreso.dart pruebas --aplicar
//
// La base va como argumento y sin valor por defecto: `(default)` es produccion
// y eso se escribe entero a mano.
//
// Necesita un token en GOOGLE_ACCESS_TOKEN (`gcloud auth print-access-token`).
//
// POR QUE
//
// `ingreso` se guarda como texto en espanol -- "4 de noviembre de 2025" --
// porque es lo que escribe el selector de fecha del formulario. Firestore no
// puede ordenar ni filtrar por eso: no es una fecha, es una frase. Sin un
// campo de fecha real no hay forma de preguntar "quien entro este mes" ni
// "que contratos vencen en 30 dias".
//
// SE AGREGA, NO SE REEMPLAZA. `ingreso` queda intacto porque es lo que imprime
// el contrato (`contrato.fecha_ingreso` sale de ahi, en mayusculas). Tocarlo
// significaria arriesgar el documento legal para ahorrar un campo.
//
// La hora es MEDIODIA UTC y no medianoche, a proposito: Chile va en UTC-3 o
// UTC-4, asi que un timestamp a las 00:00Z se lee como el dia ANTERIOR en hora
// local y todas las fechas se correrian un dia.

import 'dart:convert';
import 'dart:io';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const proyecto = 'contratos-control';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/backfill_fecha_ingreso.dart '
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

  // El MISMO formato con que el formulario escribe el texto. Usar otro seria
  // adivinar como se guardo.
  await initializeDateFormatting('es');
  final formato = DateFormat.yMMMMd('es');

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
  var yaTenian = 0;
  var convertidos = 0;
  var escritos = 0;
  final ilegibles = <String>[];
  String? pageToken;

  do {
    final url = StringBuffer('$raiz/Trabajadores?pageSize=300');
    if (pageToken != null) url.write('&pageToken=$pageToken');
    final pagina = await pedir('GET', url.toString());

    for (final doc in (pagina['documents'] as List? ?? const [])) {
      revisados++;
      final campos = (doc['fields'] as Map?) ?? const {};
      final nombre = doc['name'].toString().split('/').last;

      if (campos.containsKey('fechaIngreso')) {
        yaTenian++;
        continue;
      }

      final texto =
          ((campos['ingreso'] as Map?)?['stringValue'] ?? '').toString().trim();
      if (texto.isEmpty) {
        ilegibles.add('$nombre (vacio)');
        continue;
      }

      DateTime fecha;
      try {
        fecha = formato.parseLoose(texto.toLowerCase());
      } catch (_) {
        ilegibles.add('$nombre -> "$texto"');
        continue;
      }
      convertidos++;

      final iso = DateTime.utc(fecha.year, fecha.month, fecha.day, 12)
          .toIso8601String();

      if (!aplicar) {
        if (convertidos <= 5) stderr.writeln('  "$texto"  ->  $iso');
        continue;
      }

      await pedir(
        'PATCH',
        '$raiz/Trabajadores/$nombre?updateMask.fieldPaths=fechaIngreso',
        {
          'fields': {
            'fechaIngreso': {'timestampValue': iso}
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
  stdout.writeln('Ya tenian fechaIngreso: $yaTenian');
  stdout.writeln('Convertibles: $convertidos');
  stdout.writeln('Ilegibles: ${ilegibles.length}');
  for (final s in ilegibles.take(10)) {
    stdout.writeln('   $s');
  }
  if (aplicar) {
    stdout.writeln('Escritos: $escritos');
  } else {
    stdout.writeln('(solo informe; usa --aplicar para escribir)');
  }
}
