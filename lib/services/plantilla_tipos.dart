library;

/// Descripcion de cada documento que la app emite.
///
/// Datos puros, sin Firestore: asi los pueden usar tanto la app como las
/// herramientas de `tool/`, que corren en la VM de Dart y no pueden importar
/// Flutter ni Firebase.

/// Una linea de firma al pie de un documento.
///
/// Va como dato y no escrita en cada documento porque el PDF y la vista previa
/// tienen que dibujar exactamente la misma: la vista previa no las mostraba
/// justamente porque cada generador las armaba por su cuenta.
class LineaDeFirma {
  const LineaDeFirma({
    required this.rol,
    required this.claveNombre,
    this.claveRut,
    this.nota,
  });

  /// `EMPLEADOR`, `TRABAJADOR`, `RELATOR`, `FIRMA TRABAJADOR`...
  final String rol;

  /// Campo de plantilla con el nombre de quien firma.
  final String claveNombre;

  /// Campo con su RUT, si el documento lo imprime.
  final String? claveRut;

  /// Texto chico bajo la firma. Lo usa `Derecho a saber`, que lleva la
  /// declaracion de haber recibido la induccion debajo de quien firma.
  final String? nota;

  static const empleador = LineaDeFirma(
    rol: 'EMPLEADOR',
    claveNombre: 'empresa.nombre',
    claveRut: 'empresa.rut',
  );
  static const trabajador = LineaDeFirma(
    rol: 'TRABAJADOR',
    claveNombre: 'trabajador.nombre',
    claveRut: 'trabajador.rut',
  );
  static const firmaTrabajador = LineaDeFirma(
    rol: 'FIRMA TRABAJADOR',
    claveNombre: 'trabajador.nombre',
    claveRut: 'trabajador.rut',
  );
  static const relator = LineaDeFirma(
    rol: 'RELATOR',
    claveNombre: 'empresa.representante',
  );
  static const trabajadorConDeclaracion = LineaDeFirma(
    rol: 'TRABAJADOR',
    claveNombre: 'trabajador.nombre',
    nota: 'Declaro haber recibido la introducción de seguridad laboral y '
        'entender a los riesgos a los que me expongo.',
  );
}

/// Los documentos que la app sabe generar.
///
/// La clave es el id del documento en `Plantillas`; no se renombra nunca,
/// porque los documentos ya emitidos apuntan a ella.
class TipoPlantilla {
  const TipoPlantilla(
    this.clave,
    this.nombre,
    this.descripcion, {
    this.firmas = const [],
    this.tabla,
  });

  final String clave;
  final String nombre;
  final String descripcion;

  /// Quienes firman al pie. Vacio si el documento no lleva firmas.
  final List<LineaDeFirma> firmas;

  /// Encabezados de la tabla del documento, si lleva una.
  ///
  /// `Derecho a saber` y `EPP` no son prosa pura: llevan una tabla de riesgos y
  /// otra de implementos. Eso es una lista de registros, no texto, y se edita
  /// como lista -- meterlo en el editor de texto seria pelear con el.
  final List<String>? tabla;

  bool get llevaTabla => tabla != null;

  static const contrato = TipoPlantilla(
    'contrato',
    'Contrato de trabajo',
    'Contrato para faena determinada.',
    firmas: [LineaDeFirma.empleador, LineaDeFirma.trabajador],
  );
  static const derechoASaber = TipoPlantilla(
    'derecho-a-saber',
    'Derecho a saber',
    'Obligacion de informar los riesgos laborales.',
    firmas: [
      LineaDeFirma.relator,
      LineaDeFirma.trabajadorConDeclaracion,
    ],
    tabla: ['RIESGOS', 'MEDIDAS DE PREVENCION'],
  );
  static const epp = TipoPlantilla(
    'epp',
    'Entrega de EPP',
    'Elementos de proteccion personal entregados.',
    firmas: [LineaDeFirma.firmaTrabajador],
    tabla: ['DETALLE IMPLEMENTOS', 'FECHA DE ENTREGA', 'FECHA DEVOLUCION'],
  );
  static const registro = TipoPlantilla(
    'registro',
    'Registro',
    'Registro de entrega y capacitacion.',
    firmas: [LineaDeFirma.firmaTrabajador],
  );
  static const finiquito = TipoPlantilla(
    'finiquito',
    'Finiquito',
    'Termino de la relacion laboral.',
    firmas: [LineaDeFirma.empleador, LineaDeFirma.trabajador],
  );

  /// Los tipos que se editan.
  ///
  /// «EPP + Registro» NO esta: no es un documento distinto sino los dos
  /// anteriores impresos en la misma hoja, porque cada uno ocupa media pagina
  /// y asi se ahorra papel. Tener una plantilla propia significaba mantener el
  /// mismo texto por duplicado, y que editar EPP no cambiara nada en la
  /// version combinada.
  static const List<TipoPlantilla> todos = [
    contrato,
    derechoASaber,
    epp,
    registro,
    finiquito,
  ];

  static TipoPlantilla? porClave(String clave) {
    for (final t in todos) {
      if (t.clave == clave) return t;
    }
    return null;
  }
}
