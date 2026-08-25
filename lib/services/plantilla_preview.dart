import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'plantilla_campos.dart';
import 'plantilla_render.dart';
import 'plantilla_service.dart';

/// Resultado de previsualizar una plantilla.
class VistaPreviaPlantilla {
  const VistaPreviaPlantilla({
    required this.bytes,
    required this.paginas,
    required this.marcadoresSinValor,
    required this.parrafos,
  });

  final Uint8List bytes;

  /// Los parrafos ya interpretados, para dibujarlos en pantalla sin rasterizar
  /// el PDF. Salen del mismo analisis que alimenta al documento.
  final List<ParrafoPlantilla> parrafos;

  /// Cuantas hojas ocupa. Es el dato que hay que tener a la vista mientras se
  /// escribe: los documentos usaban `pw.Page`, que no fluye, y una clausula de
  /// mas hacia que el final se dibujara fuera de la hoja sin avisar. Ahora
  /// fluyen, pero un contrato que pasa de una a dos paginas sigue siendo una
  /// decision de quien lo edita, no una sorpresa al imprimirlo.
  final int paginas;

  /// Marcadores escritos en la plantilla que no existen en los datos.
  final Set<String> marcadoresSinValor;
}

/// Genera el PDF de una plantilla para verlo mientras se edita.
class PlantillaPreview {
  static pw.Font? _calibri;
  static pw.Font? _calibriBold;
  static pw.Font? _cambria;

  /// Las fuentes se cargan una vez: son ~1 MB cada una y la vista previa se
  /// regenera con cada pausa al escribir.
  static Future<void> _cargarFuentes() async {
    if (_calibri != null) return;
    _cambria = pw.Font.ttf(await rootBundle.load('lib/images/Cambria.ttf'));
    _calibri =
        pw.Font.ttf(await rootBundle.load('lib/images/Calibri Regular.ttf'));
    _calibriBold =
        pw.Font.ttf(await rootBundle.load('lib/images/Calibri Bold.ttf'));
  }

  /// Datos de muestra, derivados de [camposDePlantilla].
  ///
  /// No se escriben aqui: si esta lista y la del selector se mantienen por
  /// separado, terminan discrepando y la vista previa marca en rojo campos
  /// que el documento real resuelve bien.
  static Map<String, String> get datosDeMuestra => datosDeEjemplo;

  /// Construye el PDF de un delta.
  ///
  /// Reproduce la misma pagina que usa el documento real: carta, margenes de
  /// 40x60 y `MultiPage`, para que el numero de hojas que muestra la vista
  /// previa sea el que va a salir impreso.
  static Future<VistaPreviaPlantilla> generar(
    Map<String, dynamic> delta, {
    Map<String, String>? datos,
    TipoPlantilla? tipo,
    List<List<String>> filas = const [],
  }) async {
    await _cargarFuentes();

    final renderer = PlantillaRenderer(
      fuenteNormal: _calibri!,
      fuenteNegrita: _calibriBold!,
      datos: datos ?? datosDeMuestra,
      espacioAntesDelPrimero: true,
      encabezadosTabla: tipo?.tabla,
      filasTabla: filas,
    );

    final cuerpo = renderer.construir(delta);
    final valores = datos ?? datosDeMuestra;

    final pdf = pw.Document()
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          // `header` y `footer` de MultiPage se dibujan pegados al borde de
          // CADA hoja y se repiten. Antes la caratula era el primer widget del
          // flujo y el domicilio el ultimo, asi que en un documento de dos
          // paginas la caratula solo salia en la primera y el domicilio
          // quedaba flotando donde terminara el texto, no al pie.
          header: (context) => _cabecera(valores),
          footer: (context) => _pie(valores),
          build: (context) => [
            ...cuerpo,
            if (tipo != null && tipo.firmas.isNotEmpty)
              ..._firmas(valores, tipo.firmas),
          ],
        ),
      );

    final bytes = await pdf.save();

    return VistaPreviaPlantilla(
      bytes: bytes,
      paginas: contarPaginas(bytes),
      marcadoresSinValor: renderer.marcadoresSinValor,
      parrafos: AnalizadorPlantilla(datos: valores).analizar(delta).parrafos,
    );
  }

  /// Cuenta los objetos de pagina del PDF ya generado.
  ///
  /// Se hace sobre los bytes y no sobre el `Document` porque el reparto en
  /// hojas lo decide `MultiPage` al maquetar, no antes.
  static int contarPaginas(List<int> bytes) {
    return RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(bytes))
        .length;
  }

  // La caratula y el bloque de firmas no son parte de la plantilla: van en
  // codigo, iguales para todos los documentos. La plantilla aporta el cuerpo.

  static pw.Widget _cabecera(Map<String, String> d) {
    final estilo = pw.TextStyle(
      font: _cambria,
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
    );
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

  /// Domicilio de la empresa, al pie de cada hoja.
  static pw.Widget _pie(Map<String, String> d) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Center(
        child: pw.Text(
          d['empresa.domicilio'] ?? '',
          style: pw.TextStyle(
            font: _calibriBold,
            fontSize: 10,
            color: const PdfColor.fromInt(0xFF9B9B9B),
          ),
        ),
      ),
    );
  }

  static List<pw.Widget> _firmas(
    Map<String, String> d,
    List<LineaDeFirma> lineas,
  ) {
    final estilo = pw.TextStyle(
      font: _calibriBold,
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
    );

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
                  style: pw.TextStyle(font: _calibriBold, fontSize: 10),
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
}
