import 'package:flutter/material.dart';

import '../../services/plantilla_render.dart';
import '../../services/plantilla_service.dart';

/// Vista previa de una plantilla, dibujada con widgets de Flutter.
///
/// No es un PDF rasterizado a proposito. `PdfPreview` del paquete `printing`
/// necesita pdf.js cargado en `web/index.html`, que esta app no incluye -- es
/// el unico punto que rasterizaria, porque todo lo demas usa `layoutPdf`, que
/// delega en el navegador. Sin ese script el widget se queda en blanco y
/// bloquea la pestaña.
///
/// Lo importante es que esto **no** es una segunda interpretacion de la
/// plantilla: los parrafos salen del mismo [AnalizadorPlantilla] que alimenta
/// al PDF, y las firmas y la tabla, de la misma [TipoPlantilla]. Cambiar como
/// se lee un delta cambia las dos vistas a la vez.
///
/// El numero de paginas sigue saliendo del PDF de verdad, que se genera igual
/// -- contar objetos de pagina no necesita rasterizar nada.
class HojaPrevia extends StatelessWidget {
  const HojaPrevia({
    super.key,
    required this.parrafos,
    required this.cabecera,
    required this.pie,
    required this.firmas,
    required this.datos,
    this.encabezadosTabla,
    this.filasTabla = const [],
  });

  final List<ParrafoPlantilla> parrafos;

  /// Razon social y anio, como en el encabezado del documento.
  final (String, String) cabecera;

  /// Domicilio de la empresa, al pie.
  final String pie;

  /// Quienes firman. Se dibujan igual que en el PDF.
  final List<LineaDeFirma> firmas;

  /// Valores de los campos, para resolver los nombres de quienes firman.
  final Map<String, String> datos;

  final List<String>? encabezadosTabla;
  final List<List<String>> filasTabla;

  /// Proporcion de una hoja carta.
  static const double _proporcionCarta = 279.4 / 215.9;

  @override
  Widget build(BuildContext context) {
    // El documento usa Calibri a 12pt sobre carta con margenes de 60pt. Aqui
    // se dibuja a escala, asi que el tamano va en proporcion al ancho.
    return LayoutBuilder(
      builder: (context, c) {
        final anchoHoja = c.maxWidth;
        final escala = anchoHoja / 612; // 612pt = ancho de una carta
        final margen = 60 * escala;
        final base = 12 * escala;

        return SingleChildScrollView(
          child: Container(
            width: anchoHoja,
            constraints: BoxConstraints(
              minHeight: anchoHoja * _proporcionCarta,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: margen,
              vertical: 40 * escala,
            ),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _cabecera(base),
                SizedBox(height: 12 * escala),
                for (final p in parrafos)
                  if (p.esTabla)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12 * escala),
                      child: _tabla(base),
                    )
                  else if (p.vacio)
                    SizedBox(height: 12 * escala)
                  else
                    Padding(
                      padding: EdgeInsets.only(bottom: 12 * escala),
                      child: _parrafo(p, base),
                    ),
                if (firmas.isNotEmpty) ...[
                  SizedBox(height: 44 * escala),
                  _firmas(base),
                ],
                SizedBox(height: 24 * escala),
                _pie(base),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cabecera(double base) {
    final estilo = TextStyle(
      fontFamily: 'Cambria',
      fontWeight: FontWeight.bold,
      fontSize: base,
      color: Colors.black,
      height: 1.25,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(cabecera.$1, style: estilo)),
        Text('AÑO ${cabecera.$2}', style: estilo),
      ],
    );
  }

  Widget _firmas(double base) {
    final estilo = TextStyle(
      fontFamily: 'Calibri Bold',
      fontWeight: FontWeight.bold,
      fontSize: base,
      color: Colors.black,
      height: 1.3,
    );

    return Row(
      mainAxisAlignment: firmas.length == 1
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in firmas)
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('_______________________________', style: estilo),
                SizedBox(height: 6 * base / 12),
                Text(
                  datos[f.claveNombre] ?? '',
                  textAlign: TextAlign.center,
                  style: estilo,
                ),
                if (f.claveRut != null)
                  Text('RUT N°: ${datos[f.claveRut] ?? ''}', style: estilo),
                Text(f.rol, style: estilo),
                if (f.nota != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4 * base / 12),
                    child: Text(
                      f.nota!,
                      textAlign: TextAlign.center,
                      style: estilo.copyWith(fontSize: base * 10 / 12),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _pie(double base) {
    return Center(
      child: Text(
        pie,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Calibri Bold',
          fontSize: base * 10 / 12,
          color: const Color(0xFF9B9B9B),
        ),
      ),
    );
  }

  Widget _tabla(double base) {
    final cabeceras = encabezadosTabla ?? const <String>[];
    if (cabeceras.isEmpty) return const SizedBox.shrink();

    TableCell celda(String texto, {bool cabecera = false}) => TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * base / 12,
              vertical: 5 * base / 12,
            ),
            child: Text(
              texto,
              textAlign: cabecera ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontFamily: cabecera ? 'Calibri Bold' : 'Calibri',
                fontSize: base - (base / 12),
                color: Colors.black,
                height: 1.25,
              ),
            ),
          ),
        );

    return Table(
      border: TableBorder.all(width: 0.5, color: Colors.black),
      columnWidths: {
        for (var i = 0; i < cabeceras.length; i++)
          i: FlexColumnWidth(i == 0 ? 1 : 2),
      },
      children: [
        TableRow(
          children: [for (final c in cabeceras) celda(c, cabecera: true)],
        ),
        for (final fila in filasTabla)
          TableRow(
            children: [
              for (var i = 0; i < cabeceras.length; i++)
                celda(i < fila.length ? fila[i] : ''),
            ],
          ),
      ],
    );
  }

  Widget _parrafo(ParrafoPlantilla p, double base) {
    return Text.rich(
      TextSpan(
        children: [
          for (final t in p.trozos)
            TextSpan(
              text: t.texto,
              style: TextStyle(
                fontFamily: t.negrita ? 'Calibri Bold' : 'Calibri',
                fontSize: t.tamano == null ? base : t.tamano! * base / 12,
                fontStyle: t.cursiva ? FontStyle.italic : FontStyle.normal,
                decoration: t.subrayado
                    ? TextDecoration.underline
                    : TextDecoration.none,
                color: Colors.black,
                height: 1.25,
              ),
            ),
        ],
      ),
      textAlign: _alineacion(p.alineacion),
    );
  }

  TextAlign _alineacion(String valor) {
    switch (valor) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }
}
