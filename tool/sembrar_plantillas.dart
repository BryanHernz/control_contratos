// Escribe, en archivos JSON listos para la API REST de Firestore, la version 1
// de cada plantilla definida en `lib/services/plantillas_iniciales.dart`.
//
// No habla con Firestore: solo prepara los cuerpos. Publicarlos es un paso
// aparte y explicito, porque escribe en una base real.
//
//   dart run tool/sembrar_plantillas.dart
//   bash tool/sembrar_plantillas.sh pruebas
//
// Se separa asi para poder revisar que se va a escribir antes de escribirlo.

import 'dart:convert';
import 'dart:io';

import 'package:myapp/services/plantillas_iniciales.dart';

void main() {
  final dir = Directory('build/semillas');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  plantillasIniciales.forEach((tipo, delta) {
    final deltaJson = jsonEncode(delta);

    final filas = filasIniciales[tipo] ?? const <List<String>>[];

    final version = {
      'fields': {
        'numero': {'integerValue': '1'},
        'deltaJson': {'stringValue': deltaJson},
        'filasJson': {'stringValue': jsonEncode(filas)},
        'creadaPor': {'stringValue': 'semilla'},
        'nota': {
          'stringValue':
              'Transcripcion del texto que estaba escrito en el generador.'
        },
      }
    };

    final cabecera = {
      'fields': {
        'tipo': {'stringValue': tipo},
        'versionActual': {'stringValue': 'v1-inicial'},
        'ultimoNumero': {'integerValue': '1'},
      }
    };

    File('${dir.path}/$tipo.version.json')
        .writeAsStringSync(jsonEncode(version));
    File('${dir.path}/$tipo.cabecera.json')
        .writeAsStringSync(jsonEncode(cabecera));

    final ops = (delta['ops'] as List).length;
    stdout.writeln('${tipo.padRight(18)} $ops ops'
        '${filas.isEmpty ? "" : ", ${filas.length} filas"}'
        ', ${deltaJson.length} bytes');
  });

  stdout.writeln('\nArchivos en ${dir.path}');
}
