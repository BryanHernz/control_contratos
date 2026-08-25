// Prueba del renderizador de plantillas.
//
// Genera dos veces el mismo documento y los deja lado a lado:
//
//   A_codigo.dart.pdf     armado a mano con pw.TextSpan, como esta hoy
//   B_plantilla.pdf       armado desde un delta con PlantillaRenderer
//
// Si salen iguales, el formato -- negrita, subrayado, justificado, tamano --
// sobrevive al cambio de origen, que es lo unico que hay que demostrar antes
// de construir el editor.
//
//   C_plantilla_editada.pdf   la misma plantilla con una clausula agregada,
//                             para ver que el documento crece y fluye.
//
// Se corre con:  dart run tool/plantilla_pilot.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:myapp/services/plantilla_render.dart';

late final pw.Font calibri;
late final pw.Font calibriBold;
late final pw.Font cambria;

const double letterSize = 12;
const double baselina = 4;

/// Datos del trabajador y la empresa, tal como los pasaria la app.
const datos = <String, String>{
  'empresa.nombre': 'AGRICOLA SANTA FILOMENA LTDA.',
  'empresa.rut': '76.123.456-7',
  'contrato.anio': '2026',
  'contrato.fecha': '25 DE AGOSTO DE 2026',
  'trabajador.nombre': 'JUAN PEREZ GONZALEZ',
  'trabajador.rut': '12.345.678-9',
  'trabajador.labor': 'MANEJO DE MAQUINARIA AGRICOLA',
};

Future<void> main() async {
  cambria = pw.Font.ttf(await _cargar('lib/images/Cambria.ttf'));
  calibri = pw.Font.ttf(await _cargar('lib/images/Calibri Regular.ttf'));
  calibriBold = pw.Font.ttf(await _cargar('lib/images/Calibri Bold.ttf'));

  final salida = Directory('build/plantilla_pilot');
  if (!salida.existsSync()) salida.createSync(recursive: true);

  await _guardar('${salida.path}/A_codigo.pdf', _cuerpoEnCodigo());
  await _guardar('${salida.path}/B_plantilla.pdf', _cuerpoDesdePlantilla(4));
  await _guardar(
      '${salida.path}/C_plantilla_editada.pdf', _cuerpoDesdePlantilla(14));

  stdout.writeln('\nArchivos en ${salida.path}');
}

Future<ByteData> _cargar(String ruta) async =>
    ByteData.view((await File(ruta).readAsBytes()).buffer);

Future<void> _guardar(String ruta, List<pw.Widget> cuerpo) async {
  final pdf = pw.Document()
    ..addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        build: (context) => cuerpo,
      ),
    );
  final bytes = await pdf.save();
  await File(ruta).writeAsBytes(bytes);

  final paginas = RegExp(r'/Type\s*/Page[^s]')
      .allMatches(String.fromCharCodes(bytes))
      .length;
  stdout.writeln('${ruta.split(RegExp(r"[/\\]")).last.padRight(26)} '
      '$paginas pagina(s)  ${bytes.length} bytes');
}

// ---------------------------------------------------------------- cabecera

/// La carátula y el bloque de firmas NO son parte de la plantilla: siguen en
/// codigo, igual en las dos versiones. La plantilla aporta el cuerpo.
List<pw.Widget> _cabecera() => [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(datos['empresa.nombre']!,
              style: pw.TextStyle(
                  font: cambria, fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.Text('AÑO ${datos['contrato.anio']}',
              style: pw.TextStyle(
                  font: cambria, fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ],
      ),
    ];

List<pw.Widget> _firmas() => [
      pw.SizedBox(height: 40),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _firma(datos['empresa.nombre']!, 'EMPLEADOR'),
          _firma(datos['trabajador.nombre']!, 'TRABAJADOR'),
        ],
      ),
    ];

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

// -------------------------------------------------- version A: en codigo

List<pw.Widget> _cuerpoEnCodigo() {
  pw.TextSpan n(String t) => pw.TextSpan(
      baseline: baselina,
      text: t,
      style: pw.TextStyle(font: calibri, fontSize: letterSize));
  pw.TextSpan b(String t) => pw.TextSpan(
      baseline: baselina,
      text: t,
      style: pw.TextStyle(font: calibriBold, fontSize: letterSize));

  return [
    ..._cabecera(),
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.RichText(
        textAlign: pw.TextAlign.center,
        text: pw.TextSpan(
          baseline: baselina,
          text: 'OBLIGACION DE INFORMAR - DERECHO A SABER',
          style: pw.TextStyle(
            font: calibriBold,
            fontSize: letterSize,
            decoration: pw.TextDecoration.underline,
          ),
        ),
      ),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.RichText(
        textAlign: pw.TextAlign.justify,
        text: pw.TextSpan(
          baseline: baselina,
          text: 'En Paine, a ',
          style: pw.TextStyle(font: calibri, fontSize: letterSize),
          children: [
            b(datos['contrato.fecha']!),
            n(', el empleador informa al trabajador '),
            b(datos['trabajador.nombre']!),
            n(', RUT '),
            b(datos['trabajador.rut']!),
            n(', de los riesgos laborales asociados a sus funciones, segun lo '
                'dispuesto en el articulo 21 del Decreto Supremo N 40 de 1969 '
                'del Ministerio del Trabajo y Prevision Social.'),
          ],
        ),
      ),
    ),
    for (var i = 1; i <= 4; i++)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: '$i.- ',
            style: pw.TextStyle(font: calibriBold, fontSize: letterSize),
            children: [
              n('El trabajador declara haber sido informado sobre los riesgos '
                  'de '),
              b(datos['trabajador.labor']!),
              n(', las medidas preventivas correspondientes y los metodos de '
                  'trabajo correctos, incluyendo el uso obligatorio de los '
                  'elementos de proteccion personal entregados por el '
                  'empleador.'),
            ],
          ),
        ),
      ),
    ..._firmas(),
  ];
}

// ------------------------------------------ version B: desde la plantilla

/// El delta que guardaria Firestore. Esto es lo que produce el editor.
Map<String, dynamic> _delta(int clausulas) {
  final ops = <Map<String, dynamic>>[
    {
      'insert': 'OBLIGACION DE INFORMAR - DERECHO A SABER',
      'attributes': {'bold': true, 'underline': true}
    },
    {
      'insert': '\n',
      'attributes': <String, dynamic>{'align': 'center'}
    },
    {'insert': 'En Paine, a '},
    {
      'insert': '{{contrato.fecha}}',
      'attributes': {'bold': true}
    },
    {'insert': ', el empleador informa al trabajador '},
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true}
    },
    {'insert': ', RUT '},
    {
      'insert': '{{trabajador.rut}}',
      'attributes': {'bold': true}
    },
    {
      'insert': ', de los riesgos laborales asociados a sus funciones, segun '
          'lo dispuesto en el articulo 21 del Decreto Supremo N 40 de 1969 '
          'del Ministerio del Trabajo y Prevision Social.'
    },
    {
      'insert': '\n',
      'attributes': <String, dynamic>{'align': 'justify'}
    },
  ];

  for (var i = 1; i <= clausulas; i++) {
    ops.addAll([
      {
        'insert': '$i.- ',
        'attributes': {'bold': true}
      },
      {
        'insert': 'El trabajador declara haber sido informado sobre los '
            'riesgos de '
      },
      {
        'insert': '{{trabajador.labor}}',
        'attributes': {'bold': true}
      },
      {
        'insert': ', las medidas preventivas correspondientes y los metodos '
            'de trabajo correctos, incluyendo el uso obligatorio de los '
            'elementos de proteccion personal entregados por el empleador.'
      },
      {
        'insert': '\n',
        'attributes': <String, dynamic>{'align': 'justify'}
      },
    ]);
  }

  return {'ops': ops};
}

List<pw.Widget> _cuerpoDesdePlantilla(int clausulas) {
  final renderer = PlantillaRenderer(
    fuenteNormal: calibri,
    fuenteNegrita: calibriBold,
    datos: datos,
    tamanoBase: letterSize,
    baseline: baselina,
    espacioAntesDelPrimero: true,
  );

  final cuerpo = renderer.construir(_delta(clausulas));

  if (renderer.marcadoresSinValor.isNotEmpty) {
    stdout.writeln('  AVISO marcadores sin valor: '
        '${renderer.marcadoresSinValor.join(", ")}');
  }

  // El titulo subrayado va como atributo en el delta; aqui lo dejamos igual
  // que en la version A envolviendo el primer parrafo.
  return [..._cabecera(), ...cuerpo, ..._firmas()];
}
