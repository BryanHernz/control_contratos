import 'package:pdf/widgets.dart' as pw;

/// Un trozo de texto con su estilo, ya con los marcadores resueltos.
class TrozoPlantilla {
  const TrozoPlantilla({
    required this.texto,
    this.negrita = false,
    this.cursiva = false,
    this.subrayado = false,
    this.tamano,
  });

  final String texto;
  final bool negrita;
  final bool cursiva;
  final bool subrayado;
  final double? tamano;
}

/// Un parrafo: sus trozos y su alineacion.
class ParrafoPlantilla {
  const ParrafoPlantilla({
    required this.trozos,
    required this.alineacion,
    this.esTabla = false,
  });

  final List<TrozoPlantilla> trozos;

  /// `left`, `center`, `right` o `justify`.
  final String alineacion;

  /// El parrafo era solo `{{tabla}}`: aqui va la tabla del documento.
  ///
  /// Se marca en vez de expandirse aqui porque el analizador no sabe que
  /// filas tiene la plantilla -- eso lo pone quien dibuja, que ademas necesita
  /// pintarla distinto en el PDF y en pantalla.
  final bool esTabla;

  bool get vacio => trozos.isEmpty && !esTabla;
}

/// Marcador que el usuario escribe donde quiere la tabla del documento.
const String kMarcadorTabla = '{{tabla}}';

/// Resultado de interpretar una plantilla.
class PlantillaAnalizada {
  const PlantillaAnalizada({
    required this.parrafos,
    required this.marcadoresSinValor,
  });

  final List<ParrafoPlantilla> parrafos;
  final Set<String> marcadoresSinValor;
}

/// Interpreta el delta de una plantilla.
///
/// La plantilla se guarda como un *delta* de Quill: la misma estructura que
/// produce un editor de texto enriquecido, y practicamente la misma que ya
/// tenia el codigo a mano. Un parrafo del contrato era esto:
///
/// ```dart
/// pw.RichText(
///   textAlign: pw.TextAlign.justify,
///   text: pw.TextSpan(text: 'El trabajador prestara servicios como ', ...
///     children: [pw.TextSpan(text: worker.labor, style: negrita), ...]),
/// )
/// ```
///
/// y ahora es esto:
///
/// ```json
/// {"ops": [
///   {"insert": "El trabajador prestara servicios como "},
///   {"insert": "{{trabajador.labor}}", "attributes": {"bold": true}},
///   {"insert": "\n", "attributes": {"align": "justify"}}
/// ]}
/// ```
///
/// El cambio es de donde vienen los trozos, no de como se dibujan. Por eso la
/// negrita, el subrayado, el justificado y el tamano se conservan: no se estan
/// reinterpretando, se estan leyendo de la misma forma de siempre.
///
/// ## Como funciona un delta
///
/// Los atributos de caracter (negrita, subrayado) van en el propio `insert`.
/// Los de parrafo (alineacion) van en el `insert` del salto de linea que lo
/// cierra -- asi lo define Quill, y por eso hay que acumular trozos hasta ver
/// un `\n` para saber con que alineacion dibujarlos.
///
/// El resultado es neutro respecto del destino: de aqui salen tanto los
/// widgets del PDF como los de la vista previa en pantalla. Tenerlo separado
/// es lo que garantiza que lo que se ve al editar sea lo que se imprime.
class AnalizadorPlantilla {
  AnalizadorPlantilla({required this.datos});

  /// Valores para los marcadores `{{...}}`, en plano:
  /// `{'trabajador.nombres': 'JUAN', 'empresa.rut': '76.123.456-7'}`.
  final Map<String, String> datos;

  static final RegExp _marcador = RegExp(r'\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}');

  /// Bloque opcional: `{{si trabajador.correo}} ... {{fin}}`.
  ///
  /// Existe porque una plantilla es texto plano y no sabe decir "esto solo si
  /// hay dato". El contrato en codigo SI lo sabia: omitia entero el trozo
  /// `, correo electronico ...` cuando el trabajador no tenia correo. Al
  /// migrarlo a plantilla eso se perdio, y 640 de 676 contratos salian con la
  /// frase colgando y nada detras.
  static final RegExp _bloque =
      RegExp(r'\{\{\s*(si\s+[a-zA-Z0-9_.]+|fin)\s*\}\}');

  final Set<String> _sinValor = <String>{};

  /// `true` mientras se recorre un bloque opcional cuya clave no tiene valor.
  bool _omitiendo = false;

  PlantillaAnalizada analizar(Map<String, dynamic> delta) {
    final ops = (delta['ops'] as List?) ?? const [];
    final parrafos = <ParrafoPlantilla>[];
    var pendientes = <TrozoPlantilla>[];

    void cerrar(Map<String, dynamic> atributosBloque) {
      final soloTabla = pendientes.length == 1 &&
          pendientes.first.texto.trim() == kMarcadorTabla;
      parrafos.add(ParrafoPlantilla(
        trozos: soloTabla ? const [] : pendientes,
        alineacion: (atributosBloque['align'] as String?) ?? 'left',
        esTabla: soloTabla,
      ));
      pendientes = <TrozoPlantilla>[];
    }

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is! String) continue; // imagenes y demas: fuera de alcance
      final attrs = (op['attributes'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      // Un `insert` puede traer varios saltos de linea de una vez.
      final partes = insert.split('\n');
      for (var i = 0; i < partes.length; i++) {
        if (partes[i].isNotEmpty) {
          _agregarTrozos(partes[i], attrs, pendientes);
        }
        // Cada separador cierra un parrafo; el ultimo pedazo no lleva salto
        // detras, asi que no cierra nada.
        if (i < partes.length - 1) cerrar(attrs);
      }
    }

    // Texto sin `\n` final: Quill siempre termina con uno, pero una plantilla
    // escrita a mano puede no hacerlo.
    if (pendientes.isNotEmpty) cerrar(const {});

    return PlantillaAnalizada(
      parrafos: parrafos,
      marcadoresSinValor: _sinValor,
    );
  }

  /// Parte el texto en los bloques `{{si ...}}` / `{{fin}}` y emite solo lo
  /// que corresponde imprimir.
  ///
  /// El estado de omision vive en el analizador y no aqui adentro porque un
  /// bloque casi siempre abarca varios `insert`: la frase suele ir en uno y el
  /// marcador con el valor en otro, porque va en negrita.
  void _agregarTrozos(
    String texto,
    Map<String, dynamic> attrs,
    List<TrozoPlantilla> destino,
  ) {
    void emitir(String t) {
      if (_omitiendo || t.isEmpty) return;
      destino.add(TrozoPlantilla(
        texto: _sustituir(t),
        negrita: attrs['bold'] == true,
        cursiva: attrs['italic'] == true,
        subrayado: attrs['underline'] == true,
        tamano: (attrs['size'] as num?)?.toDouble(),
      ));
    }

    var desde = 0;
    for (final m in _bloque.allMatches(texto)) {
      emitir(texto.substring(desde, m.start));
      final token = m.group(1)!;
      if (token == 'fin') {
        _omitiendo = false;
      } else {
        final clave = token.substring(2).trim();
        final valor = datos[clave];
        // Un bloque opcional sin valor NO cuenta como marcador sin resolver:
        // que falte es exactamente para lo que existe el bloque.
        _omitiendo = valor == null || valor.trim().isEmpty;
      }
      desde = m.end;
    }
    emitir(texto.substring(desde));
  }

  String _sustituir(String texto) {
    return texto.replaceAllMapped(_marcador, (m) {
      final clave = m.group(1)!;
      if (clave == 'tabla') return m.group(0)!; // lo resuelve quien dibuja
      final valor = datos[clave];
      if (valor == null) {
        _sinValor.add(clave);
        // Se deja visible a proposito: un hueco vacio en un contrato pasa
        // desapercibido, un `{{...}}` sin resolver no.
        return m.group(0)!;
      }
      return valor;
    });
  }
}

/// Convierte una plantilla en los widgets del PDF.
class PlantillaRenderer {
  PlantillaRenderer({
    required this.fuenteNormal,
    required this.fuenteNegrita,
    required this.datos,
    this.tamanoBase = 12,
    this.baseline = 4,
    this.espacioEntreParrafos = 12,
    this.espacioAntesDelPrimero = false,
    this.encabezadosTabla,
    this.filasTabla = const [],
  });

  final pw.Font fuenteNormal;
  final pw.Font fuenteNegrita;
  final Map<String, String> datos;
  final double tamanoBase;
  final double baseline;
  final double espacioEntreParrafos;

  /// El cuerpo casi nunca empieza la pagina: encima va la carátula, que sigue
  /// siendo codigo. Con esto el primer parrafo se separa de ella igual que se
  /// separan entre si los demas.
  final bool espacioAntesDelPrimero;

  /// Encabezados y filas de la tabla, si el documento lleva una.
  final List<String>? encabezadosTabla;
  final List<List<String>> filasTabla;

  final Set<String> marcadoresSinValor = <String>{};

  List<pw.Widget> construir(Map<String, dynamic> delta) {
    final analisis = AnalizadorPlantilla(datos: datos).analizar(delta);
    marcadoresSinValor.addAll(analisis.marcadoresSinValor);

    final widgets = <pw.Widget>[];
    for (final p in analisis.parrafos) {
      final espacioArriba = widgets.isEmpty && !espacioAntesDelPrimero
          ? 0.0
          : espacioEntreParrafos;

      if (p.esTabla) {
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(top: espacioArriba),
          child: _tabla(),
        ));
        continue;
      }

      if (p.vacio) {
        // Un salto de linea sin texto es un parrafo en blanco: se respeta como
        // separacion, que es lo que el usuario quiso al pulsar Enter dos veces.
        widgets.add(pw.SizedBox(height: espacioEntreParrafos));
        continue;
      }

      final spans = [
        for (final t in p.trozos)
          pw.TextSpan(
            baseline: baseline,
            text: t.texto,
            style: pw.TextStyle(
              font: t.negrita ? fuenteNegrita : fuenteNormal,
              fontSize: t.tamano ?? tamanoBase,
              decoration: t.subrayado ? pw.TextDecoration.underline : null,
              fontStyle: t.cursiva ? pw.FontStyle.italic : null,
            ),
          ),
      ];

      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(top: espacioArriba),
          // El `SizedBox` de ancho infinito no es decorativo: sin el, un
          // `RichText` se ajusta al ancho de su texto y `textAlign` no tiene
          // nada dentro de lo que alinear. Medido en el PDF: un titulo con
          // `TextAlign.center` arrancaba en x=60 -- el margen izquierdo -- y
          // con el SizedBox arranca en x=198,7, que es el centro real.
          //
          // No se notaba en los parrafos largos porque al partirse en varias
          // lineas ya ocupan todo el ancho; solo fallaba en los titulos, que
          // caben en una linea.
          child: pw.SizedBox(
            width: double.infinity,
            child: pw.RichText(
              textAlign: _alineacion(p.alineacion),
              text: pw.TextSpan(
                baseline: spans.first.baseline,
                text: spans.first.text,
                style: spans.first.style,
                children: spans.skip(1).toList(),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// La tabla del documento: encabezado en negrita y una fila por registro.
  pw.Widget _tabla() {
    final cabeceras = encabezadosTabla ?? const <String>[];
    if (cabeceras.isEmpty) return pw.SizedBox();

    pw.Widget celda(String texto, {bool cabecera = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            texto,
            textAlign: cabecera ? pw.TextAlign.center : pw.TextAlign.left,
            style: pw.TextStyle(
              font: cabecera ? fuenteNegrita : fuenteNormal,
              fontSize: tamanoBase - 1,
            ),
          ),
        );

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      // La primera columna mas angosta que el resto: en la tabla de riesgos
      // lleva el nombre del riesgo y las otras el detalle, que es mas largo.
      columnWidths: {
        for (var i = 0; i < cabeceras.length; i++)
          i: pw.FlexColumnWidth(i == 0 ? 1 : 2),
      },
      children: [
        pw.TableRow(
          children: [for (final c in cabeceras) celda(c, cabecera: true)],
        ),
        for (final fila in filasTabla)
          pw.TableRow(
            children: [
              for (var i = 0; i < cabeceras.length; i++)
                celda(i < fila.length ? fila[i] : ''),
            ],
          ),
      ],
    );
  }

  pw.TextAlign _alineacion(String valor) {
    switch (valor) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      case 'justify':
        return pw.TextAlign.justify;
      default:
        return pw.TextAlign.left;
    }
  }
}
