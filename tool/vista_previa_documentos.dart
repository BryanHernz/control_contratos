// Genera un PDF de cada plantilla, para revisarlas todas de una pasada.
//
//   dart run tool/vista_previa_documentos.dart
//
// Usa los datos de ejemplo, la misma pagina que el documento real (carta,
// margenes 40x60, MultiPage con cabecera y pie repetidos) y las firmas que
// declara cada tipo. Sirve para comparar contra un PDF emitido por la app
// antes de dar por buena una transcripcion.

import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:myapp/services/plantilla_campos.dart';
import 'package:myapp/services/plantilla_render.dart';
import 'package:myapp/services/plantilla_tipos.dart';
import 'package:myapp/services/plantillas_iniciales.dart';

late final pw.Font cambria;
late final pw.Font calibri;
late final pw.Font calibriBold;

Future<void> main() async {
  ByteData cargar(List<int> b) => ByteData.view(Uint8List.fromList(b).buffer);
  cambria =
      pw.Font.ttf(cargar(await File('lib/images/Cambria.ttf').readAsBytes()));
  calibri = pw.Font.ttf(
      cargar(await File('lib/images/Calibri Regular.ttf').readAsBytes()));
  calibriBold = pw.Font.ttf(
      cargar(await File('lib/images/Calibri Bold.ttf').readAsBytes()));

  final salida = Directory('build/documentos');
  if (!salida.existsSync()) salida.createSync(recursive: true);

  final datos = datosDeEjemplo;
  var problemas = 0;

  for (final tipo in TipoPlantilla.todos) {
    final delta = plantillasIniciales[tipo.clave];
    if (delta == null) {
      stdout.writeln('${tipo.clave.padRight(18)} sin plantilla');
      continue;
    }

    final renderer = PlantillaRenderer(
      fuenteNormal: calibri,
      fuenteNegrita: calibriBold,
      datos: datos,
      espacioAntesDelPrimero: true,
      encabezadosTabla: tipo.tabla,
      filasTabla: filasIniciales[tipo.clave] ?? const [],
    );
    final cuerpo = renderer.construir(delta);

    final pdf = pw.Document()
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          header: (_) => _cabecera(datos),
          footer: (_) => _pie(datos),
          build: (_) => [...cuerpo, ..._firmas(datos, tipo.firmas)],
        ),
      );

    final bytes = await pdf.save();
    final archivo = '${salida.path}/${tipo.clave}.pdf';
    await File(archivo).writeAsBytes(bytes);

    final paginas = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(bytes))
        .length;

    final aviso = renderer.marcadoresSinValor.isEmpty
        ? ''
        : '  !! sin valor: ${renderer.marcadoresSinValor.join(", ")}';
    if (renderer.marcadoresSinValor.isNotEmpty) problemas++;

    stdout.writeln('${tipo.clave.padRight(18)} $paginas pag  '
        '${bytes.length.toString().padLeft(6)} bytes$aviso');
  }

  stdout.writeln('\nArchivos en ${salida.path}');
  if (problemas > 0) {
    stdout.writeln('$problemas documento(s) con marcadores sin resolver.');
    exitCode = 1;
  }
}

pw.Widget _cabecera(Map<String, String> d) {
  final estilo =
      pw.TextStyle(font: cambria, fontWeight: pw.FontWeight.bold, fontSize: 12);
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(d['empresa.nombre'] ?? '', style: estilo),
        pw.Text('AÑO ${d['contrato.anio'] ?? ''}', style: estilo),
      ],
    ),
  );
}

pw.Widget _pie(Map<String, String> d) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Center(
        child: pw.Text(
          d['empresa.domicilio'] ?? '',
          style: pw.TextStyle(
            font: calibriBold,
            fontSize: 10,
            color: const PdfColor.fromInt(0xFF9B9B9B),
          ),
        ),
      ),
    );

List<pw.Widget> _firmas(Map<String, String> d, List<LineaDeFirma> lineas) {
  if (lineas.isEmpty) return const [];
  final estilo = pw.TextStyle(
      font: calibriBold, fontWeight: pw.FontWeight.bold, fontSize: 12);

  pw.Widget firma(LineaDeFirma f) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('_______________________________', style: estilo),
          pw.SizedBox(height: 8),
          pw.Text(d[f.claveNombre] ?? '', style: estilo),
          if (f.claveRut != null)
            pw.Text('RUT N°: ${d[f.claveRut] ?? ''}', style: estilo),
          pw.Text(f.rol, style: estilo),
          if (f.nota != null)
            pw.SizedBox(
              width: 200,
              child: pw.Text(
                f.nota!,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: calibriBold, fontSize: 10),
              ),
            ),
        ],
      );

  return [
    pw.SizedBox(height: 44),
    pw.Row(
      mainAxisAlignment: lineas.length == 1
          ? pw.MainAxisAlignment.center
          : pw.MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [for (final f in lineas) firma(f)],
    ),
  ];
}
