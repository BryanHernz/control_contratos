// Repara texto doble-codificado (mojibake) en archivos fuente.
//
// El sintoma: `electrónico` guardado como `electrÃ³nico`, `N°` como `NÂ°`,
// `AÑO` como `AÃƒÆ'â€˜O`. Pasa cuando un archivo UTF-8 se lee como Latin-1 o
// Windows-1252 y se vuelve a guardar como UTF-8, a veces varias veces seguidas.
// Como estos literales se imprimen en los PDF de contrato y finiquito, la
// basura sale en documentos que la gente firma.
//
// La reparacion es la inversa exacta del dano: tomar la cadena, codificarla
// como Windows-1252 y decodificarla como UTF-8. Si el resultado es UTF-8
// valido y distinto, era mojibake; se repite hasta que deje de cambiar.
//
//   dart run tool/fix_mojibake.dart <archivo>...            (solo informa)
//   dart run tool/fix_mojibake.dart --apply <archivo>...    (reescribe)

import 'dart:convert';
import 'dart:io';

/// Los bytes 0x80-0x9F de Windows-1252, que Latin-1 deja sin asignar. Son los
/// que producen los sospechosos habituales: â‚¬ â€™ â€œ Å“ Ëœ â„¢.
const Map<int, int> _cp1252 = {
  0x20AC: 0x80,
  0x201A: 0x82,
  0x0192: 0x83,
  0x201E: 0x84,
  0x2026: 0x85,
  0x2020: 0x86,
  0x2021: 0x87,
  0x02C6: 0x88,
  0x2030: 0x89,
  0x0160: 0x8A,
  0x2039: 0x8B,
  0x0152: 0x8C,
  0x017D: 0x8E,
  0x2018: 0x91,
  0x2019: 0x92,
  0x201C: 0x93,
  0x201D: 0x94,
  0x2022: 0x95,
  0x2013: 0x96,
  0x2014: 0x97,
  0x02DC: 0x98,
  0x2122: 0x99,
  0x0161: 0x9A,
  0x203A: 0x9B,
  0x0153: 0x9C,
  0x017E: 0x9E,
  0x0178: 0x9F,
};

/// Un paso de reparacion. Devuelve null si la cadena no es mojibake.
String? _unaVuelta(String texto) {
  final bytes = <int>[];
  for (final r in texto.runes) {
    if (r < 0x100) {
      bytes.add(r);
    } else if (_cp1252.containsKey(r)) {
      bytes.add(_cp1252[r]!);
    } else {
      // Hay un caracter que no cabe en un byte: no vino de este dano.
      return null;
    }
  }
  try {
    final decodificado = utf8.decode(bytes, allowMalformed: false);
    return decodificado == texto ? null : decodificado;
  } on FormatException {
    return null;
  }
}

/// Repara hasta que deje de cambiar. El dano puede estar aplicado varias veces
/// -- `AÑO` en este proyecto venia con tres capas encima.
({String texto, int vueltas}) reparar(String texto) {
  var actual = texto;
  var vueltas = 0;
  while (vueltas < 6) {
    final siguiente = _unaVuelta(actual);
    if (siguiente == null) break;
    actual = siguiente;
    vueltas++;
  }
  return (texto: actual, vueltas: vueltas);
}

void main(List<String> args) {
  final aplicar = args.contains('--apply');
  final archivos = args.where((a) => !a.startsWith('--')).toList();

  if (archivos.isEmpty) {
    stderr
        .writeln('Uso: dart run tool/fix_mojibake.dart [--apply] <archivo>...');
    exitCode = 64;
    return;
  }

  var totalLineas = 0;

  for (final ruta in archivos) {
    final file = File(ruta);
    if (!file.existsSync()) {
      stderr.writeln('No existe: $ruta');
      continue;
    }

    final lineas = file.readAsStringSync(encoding: utf8).split('\n');
    final salida = <String>[];
    var tocadas = 0;

    for (var i = 0; i < lineas.length; i++) {
      final r = reparar(lineas[i]);
      salida.add(r.texto);
      if (r.vueltas > 0) {
        tocadas++;
        totalLineas++;
        if (tocadas <= 8) {
          stdout.writeln('  L${i + 1} (${r.vueltas} capa'
              '${r.vueltas == 1 ? "" : "s"})');
          stdout.writeln('    antes:   ${_recorte(lineas[i])}');
          stdout.writeln('    despues: ${_recorte(r.texto)}');
        }
      }
    }

    stdout.writeln('$ruta: $tocadas linea(s) con mojibake'
        '${tocadas > 8 ? " (se muestran las primeras 8)" : ""}');

    if (aplicar && tocadas > 0) {
      file.writeAsStringSync(salida.join('\n'), encoding: utf8);
      stdout.writeln('  -> reescrito');
    }
  }

  stdout.writeln('\nTotal: $totalLineas linea(s)'
      '${aplicar ? " reparadas" : " por reparar (usa --apply)"}');
}

String _recorte(String s) {
  final t = s.trim();
  return t.length <= 96 ? t : '${t.substring(0, 96)}...';
}
