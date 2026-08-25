// Piloto: comprobar si `pw.MultiPage` conserva el formato de `pw.Page`.
//
// Los seis documentos de la app usan `pw.Page`, que es UNA hoja y no fluye: si
// el contenido no cabe, se corta. Eso hoy no se nota porque el texto esta
// congelado en el codigo y alguien lo ajusto hasta que cupiera. En cuanto un
// usuario pueda editar la plantilla, deja de caber.
//
// Este script genera cuatro PDF con el mismo vocabulario de estilo que usa el
// contrato -- calibri / calibriBold / cambria, 12pt, justificado, negrita,
// subrayado -- para responder dos preguntas con archivos en la mano:
//
//   1_page_corto.pdf       vs  2_multipage_corto.pdf
//        Con contenido que SI cabe: deben salir identicos.
//
//   3_page_largo.pdf       vs  4_multipage_largo.pdf
//        Con contenido que NO cabe: `Page` pierde el final, `MultiPage` fluye.
//
// Se corre con:  dart run tool/pdf_pilot.dart
// No forma parte de la app.

import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const double letterSize = 12;
const double baselina = 4;

late final pw.Font cambria;
late final pw.Font calibri;
late final pw.Font calibriBold;

Future<void> main() async {
  cambria = pw.Font.ttf(await _cargar('lib/images/Cambria.ttf'));
  calibri = pw.Font.ttf(await _cargar('lib/images/Calibri Regular.ttf'));
  calibriBold = pw.Font.ttf(await _cargar('lib/images/Calibri Bold.ttf'));

  final salida = Directory('build/pdf_pilot');
  if (!salida.existsSync()) salida.createSync(recursive: true);

  await _generar('${salida.path}/1_page_corto.pdf', multi: false, clausulas: 4);
  await _generar('${salida.path}/2_multipage_corto.pdf',
      multi: true, clausulas: 4);
  await _generar('${salida.path}/3_page_largo.pdf',
      multi: false, clausulas: 16);
  await _generar('${salida.path}/4_multipage_largo.pdf',
      multi: true, clausulas: 16);

  stdout.writeln('\nArchivos en ${salida.path}:');
  for (final f in salida.listSync()..sort((a, b) => a.path.compareTo(b.path))) {
    final kb = (File(f.path).lengthSync() / 1024).toStringAsFixed(1);
    stdout.writeln('  ${f.path.split(RegExp(r"[/\\]")).last}  ($kb KB)');
  }
}

Future<ByteData> _cargar(String ruta) async {
  final bytes = await File(ruta).readAsBytes();
  return ByteData.view(bytes.buffer);
}

Future<void> _generar(
  String ruta, {
  required bool multi,
  required int clausulas,
}) async {
  final pdf = pw.Document();
  final cuerpo = _cuerpo(clausulas);

  if (multi) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
        // `Page` lo llevaba en la Column que envolvia todo; en `MultiPage` es
        // un parametro de la pagina, porque ya no hay Column envolvente.
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        build: (context) => cuerpo,
      ),
    );
  } else {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: cuerpo,
        ),
      ),
    );
  }

  final bytes = await pdf.save();
  await File(ruta).writeAsBytes(bytes);

  final paginas = _contarPaginas(bytes);
  stdout.writeln(
    '${multi ? "MultiPage" : "Page     "}  ${clausulas.toString().padLeft(2)} clausulas  '
    '-> $paginas pagina(s)  ${ruta.split(RegExp(r"[/\\]")).last}',
  );
}

/// Cuenta los objetos `/Type /Page` del PDF generado.
int _contarPaginas(List<int> bytes) {
  final texto = String.fromCharCodes(bytes);
  return RegExp(r'/Type\s*/Page[^s]').allMatches(texto).length;
}

/// Mismo vocabulario que el contrato real: cabecera con nombre de empresa y
/// anio, titulo centrado subrayado, parrafos justificados con trozos en
/// negrita, y bloque de firmas en dos columnas.
List<pw.Widget> _cuerpo(int clausulas) {
  return [
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('AGRICOLA SANTA FILOMENA LTDA.',
            style: pw.TextStyle(
                font: cambria, fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Text('AÑO ${DateTime.now().year}',
            style: pw.TextStyle(
                font: cambria, fontWeight: pw.FontWeight.bold, fontSize: 12)),
      ],
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Center(
        child: pw.Text(
          'OBLIGACION DE INFORMAR - DERECHO A SABER',
          style: pw.TextStyle(
            decoration: pw.TextDecoration.underline,
            font: calibriBold,
            fontSize: letterSize,
          ),
        ),
      ),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.RichText(
        textAlign: pw.TextAlign.justify,
        text: pw.TextSpan(
          baseline: baselina,
          text: 'En Paine, a ',
          style: pw.TextStyle(font: calibri, fontSize: letterSize),
          children: [
            pw.TextSpan(
              baseline: baselina,
              text: '25 DE AGOSTO DE 2026',
              style: pw.TextStyle(font: calibriBold, fontSize: letterSize),
            ),
            pw.TextSpan(
              baseline: baselina,
              text: ', el empleador informa al trabajador ',
              style: pw.TextStyle(font: calibri, fontSize: letterSize),
            ),
            pw.TextSpan(
              baseline: baselina,
              text: 'JUAN PEREZ GONZALEZ',
              style: pw.TextStyle(font: calibriBold, fontSize: letterSize),
            ),
            pw.TextSpan(
              baseline: baselina,
              text: ' de los riesgos laborales asociados a sus funciones, '
                  'segun lo dispuesto en el articulo 21 del Decreto Supremo '
                  'N 40 de 1969 del Ministerio del Trabajo y Prevision Social.',
              style: pw.TextStyle(font: calibri, fontSize: letterSize),
            ),
          ],
        ),
      ),
    ),
    for (var i = 1; i <= clausulas; i++)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: '$i.- ',
            style: pw.TextStyle(font: calibriBold, fontSize: letterSize),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: 'El trabajador declara haber sido informado sobre '
                    'los riesgos de ',
                style: pw.TextStyle(font: calibri, fontSize: letterSize),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'MANEJO DE MAQUINARIA AGRICOLA',
                style: pw.TextStyle(font: calibriBold, fontSize: letterSize),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', las medidas preventivas correspondientes y los '
                    'metodos de trabajo correctos, incluyendo el uso '
                    'obligatorio de los elementos de proteccion personal '
                    'entregados por el empleador y registrados en el '
                    'documento respectivo.',
                style: pw.TextStyle(font: calibri, fontSize: letterSize),
              ),
            ],
          ),
        ),
      ),
    pw.SizedBox(height: 40),
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _firma('AGRICOLA SANTA FILOMENA LTDA.', 'EMPLEADOR'),
        _firma('JUAN PEREZ GONZALEZ', 'TRABAJADOR'),
      ],
    ),
  ];
}

pw.Widget _firma(String nombre, String rol) {
  final estilo = pw.TextStyle(
      font: calibriBold, fontWeight: pw.FontWeight.bold, fontSize: 12);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text('_______________________________', style: estilo),
      pw.SizedBox(height: 8),
      pw.Text(nombre, style: estilo),
      pw.Text(rol, style: estilo),
    ],
  );
}
