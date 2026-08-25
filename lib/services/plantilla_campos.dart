/// Los campos que una plantilla puede usar, en un solo lugar.
///
/// Antes esta lista existia por triplicado y sin hablarse: el selector del
/// editor, los datos de muestra de la vista previa y el mapa que arma el
/// generador. Bastaba agregar un campo en uno para que la vista previa lo
/// declarara inexistente y lo marcara en rojo aunque el documento real lo
/// resolviera bien -- que es exactamente lo que pasaba con
/// `trabajador.nacimiento` y `contrato.horas_semanales`.
///
/// Ahora la fuente de verdad es [camposDePlantilla]: de ahi salen el selector,
/// el ejemplo y la validacion. Agregar un campo es agregar una entrada aqui y
/// devolver su valor en `_datosDePlantilla`.
class CampoPlantilla {
  const CampoPlantilla({
    required this.clave,
    required this.etiqueta,
    required this.ejemplo,
  });

  /// Lo que se escribe en la plantilla, sin las llaves.
  final String clave;

  /// Como se llama en el selector del editor.
  final String etiqueta;

  /// Valor con que se dibuja la vista previa.
  ///
  /// Deliberadamente largos: si un documento cabe con "Juan Perez" pero no con
  /// un nombre real de cuatro apellidos, tiene que verse antes de publicar.
  final String ejemplo;

  String get token => '{{$clave}}';
}

/// Campos agrupados como se muestran en el editor.
const Map<String, List<CampoPlantilla>> camposDePlantilla = {
  'Trabajador': [
    CampoPlantilla(
      clave: 'trabajador.nombre',
      etiqueta: 'Nombre completo',
      ejemplo: 'MARIA FERNANDA GONZALEZ ARAVENA',
    ),
    CampoPlantilla(
      clave: 'trabajador.rut',
      etiqueta: 'RUT',
      ejemplo: '18.765.432-1',
    ),
    CampoPlantilla(
      clave: 'trabajador.labor',
      etiqueta: 'Labor o cargo',
      ejemplo: 'OPERADORA DE MAQUINARIA AGRICOLA',
    ),
    CampoPlantilla(
      clave: 'trabajador.nacionalidad',
      etiqueta: 'Nacionalidad',
      ejemplo: 'CHILENA',
    ),
    CampoPlantilla(
      clave: 'trabajador.estado_civil',
      etiqueta: 'Estado civil',
      ejemplo: 'SOLTERA',
    ),
    CampoPlantilla(
      clave: 'trabajador.nacimiento',
      etiqueta: 'Fecha de nacimiento',
      ejemplo: '14/03/1994',
    ),
    CampoPlantilla(
      clave: 'trabajador.domicilio',
      etiqueta: 'Domicilio',
      ejemplo: 'AVENIDA LOS AROMOS 1245, VILLA EL ESFUERZO',
    ),
    CampoPlantilla(
      clave: 'trabajador.comuna',
      etiqueta: 'Comuna',
      ejemplo: 'PAINE',
    ),
    CampoPlantilla(
      clave: 'trabajador.correo',
      etiqueta: 'Correo',
      ejemplo: 'MF.GONZALEZ@CORREO.CL',
    ),
    CampoPlantilla(
      clave: 'trabajador.afp',
      etiqueta: 'AFP',
      ejemplo: 'HABITAT',
    ),
    CampoPlantilla(
      clave: 'trabajador.prevision',
      etiqueta: 'Prevision',
      ejemplo: 'FONASA',
    ),
  ],
  'Empresa': [
    CampoPlantilla(
      clave: 'empresa.nombre',
      etiqueta: 'Razon social',
      ejemplo: 'AGRICOLA SANTA FILOMENA LIMITADA',
    ),
    CampoPlantilla(
      clave: 'empresa.rut',
      etiqueta: 'RUT',
      ejemplo: '76.543.210-K',
    ),
    CampoPlantilla(
      clave: 'empresa.representante',
      etiqueta: 'Representante legal',
      ejemplo: 'OCTAVIO ORLANDO NUNEZ MENARES',
    ),
    // Estaba escrito a mano en el PDF, igual que el nombre del representante.
    // Vive en `Otros/empresadata`; si el campo no esta cargado ahi, la vista
    // previa lo va a marcar -- y con razon.
    CampoPlantilla(
      clave: 'empresa.representante_rut',
      etiqueta: 'RUT del representante',
      ejemplo: '11.171.021-K',
    ),
    CampoPlantilla(
      clave: 'empresa.domicilio',
      etiqueta: 'Domicilio',
      ejemplo: "O’Higgins Pelay Lt 2 H Pc N° 2 A, "
          "Comuna San Francisco De Mostazal",
    ),
    CampoPlantilla(
      clave: 'empresa.correo',
      etiqueta: 'Correo',
      ejemplo: 'MRL.ANDREA@LIVE.COM',
    ),
  ],
  'Contrato': [
    CampoPlantilla(
      clave: 'contrato.fecha',
      etiqueta: 'Fecha del documento',
      ejemplo: '25/08/2026',
    ),
    CampoPlantilla(
      clave: 'contrato.anio',
      etiqueta: 'Anio',
      ejemplo: '2026',
    ),
    CampoPlantilla(
      clave: 'contrato.fecha_ingreso',
      etiqueta: 'Fecha de ingreso',
      ejemplo: '01 DE SEPTIEMBRE DE 2026',
    ),
    CampoPlantilla(
      clave: 'contrato.sueldo',
      etiqueta: 'Sueldo',
      ejemplo: '\$25.000 (VEINTICINCO MIL PESOS)',
    ),
    CampoPlantilla(
      clave: 'contrato.horas_semanales',
      etiqueta: 'Horas semanales',
      ejemplo: '44',
    ),
    CampoPlantilla(
      clave: 'contrato.faena',
      etiqueta: 'Faena',
      ejemplo: 'COSECHA DE TEMPORADA 2026-2027',
    ),
    CampoPlantilla(
      clave: 'contrato.establecimiento',
      etiqueta: 'Establecimiento',
      ejemplo: 'FUNDO SANTA FILOMENA, PAINE',
    ),
    CampoPlantilla(
      clave: 'contrato.horario',
      etiqueta: 'Horario',
      ejemplo: 'Lunes a Jueves de 8:00 a 18:00 hrs, '
          'Viernes de 8:00 a 17:00 hrs',
    ),
    CampoPlantilla(
      clave: 'contrato.colacion',
      etiqueta: 'Colacion',
      ejemplo: 'una hora',
    ),
  ],
  // Solo tienen valor al emitir un finiquito: los escribe quien lo genera en
  // el formulario, no salen de la ficha del trabajador.
  'Finiquito': [
    CampoPlantilla(
      clave: 'finiquito.fecha_egreso',
      etiqueta: 'Fecha de egreso',
      ejemplo: '31 DE MARZO DE 2027',
    ),
    CampoPlantilla(
      clave: 'finiquito.vacaciones',
      etiqueta: 'Vacaciones proporcionales',
      ejemplo: '\$180.000',
    ),
    CampoPlantilla(
      clave: 'finiquito.total',
      etiqueta: 'Total a pagar',
      ejemplo: '\$640.000',
    ),
  ],
};

/// Todas las claves validas, en plano.
Set<String> get clavesDePlantilla => {
      for (final grupo in camposDePlantilla.values)
        for (final campo in grupo) campo.clave,
    };

/// Datos de ejemplo para la vista previa, derivados de la misma lista.
Map<String, String> get datosDeEjemplo => {
      for (final grupo in camposDePlantilla.values)
        for (final campo in grupo) campo.clave: campo.ejemplo,
    };
