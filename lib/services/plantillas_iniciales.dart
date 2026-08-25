/// Version 1 de cada plantilla: el texto que hoy esta escrito en el generador,
/// transcrito a delta.
///
/// Es una transcripcion, no una reescritura. Cualquier diferencia respecto del
/// PDF que emite el codigo es un error de transcripcion, y se comprueba con
/// `dart run tool/plantilla_pilot.dart` comparando ambos archivos.
///
/// Lo que NO entra en la plantilla:
///
///  - La caratula (empresa + anio) y el bloque de firmas, que son identicos en
///    todos los documentos y viven en codigo.
///  - Las tablas. `Derecho a saber`, `EPP` y `EPP + Registro` llevan una tabla
///    de riesgos o de elementos entregados: eso es una lista de registros, no
///    prosa, y se edita mejor como lista que dentro de un editor de texto.
///    Esos tres documentos necesitan su propio editor de filas.
library;

/// Registro de entrega del reglamento interno.
///
/// Prosa pura, sin tablas ni calculos: es el documento mas corto de los seis,
/// por eso es el primero que se migra.
const Map<String, dynamic> deltaRegistro = {
  'ops': [
    {
      'insert': 'REGISTRO DE ENTREGA DE REGLAMENTO DE HIGIENE Y SEGURIDAD',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'center'},
    },
    {
      'insert': '(LEY 16.744 CODIGO DEL TRABAJO)',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'center'},
    },
    {'insert': 'Yo: '},
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ', RUT: N° '},
    {
      'insert': '{{trabajador.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', Cargo: '},
    {
      'insert': '{{trabajador.labor}}',
      'attributes': {'bold': true},
    },
    {'insert': ', con fecha: '},
    {
      'insert': '{{contrato.fecha}}',
      'attributes': {'bold': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Bajo mi firma declaro haber recibido un ejemplar del '
          'reglamento interno de orden higiene y seguridad de la empresa ',
    },
    {
      'insert': '{{empresa.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', Representada por Don '},
    {
      'insert': '{{empresa.representante}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.representante_rut}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', del cual me comprometo a tomar conocimiento en su totalidad '
          'no pudiendo alegar desconocimiento de su texto a su entrega, '
          'reconociendo además en forma expresa que este reglamento interno es '
          'parte integrante del contrato de trabajo que mantengo vigente con '
          'la empresa.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
  ],
};

/// Contrato de trabajo para faena determinada.
///
/// Prosa pura: diez parrafos justificados, ocho de ellos con su ordinal en
/// negrita. Es el documento que mas se edita y por eso el que mas gana con
/// esto -- hoy cambiar una clausula significa tocar el codigo y publicar una
/// version de la app.
///
/// El titulo va aparte del cuerpo porque lleva subrayado y centrado, igual que
/// en el codigo original.
const Map<String, dynamic> deltaContrato = {
  'ops': [
    {
      'insert': 'CONTRATO DE TRABAJO PARA FAENA DETERMINADA',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'center'},
    },

    // --- comparecencia ---
    {'insert': 'En Paine, a '},
    {
      'insert': '{{contrato.fecha_ingreso}}',
      'attributes': {'bold': true},
    },
    {'insert': ', entre '},
    {
      'insert': '{{empresa.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', Representada por Don '},
    {
      'insert': '{{empresa.representante}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.representante_rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ' correo electrónico '},
    {
      'insert': '{{empresa.correo}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', ambos con domicilio en '
          '{{empresa.domicilio}}, en lo sucesivo ',
    },
    {
      'insert': 'El “Empleador”',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': ' y Don(a): ',
      'attributes': {'bold': true},
    },
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ', RUT N° '},
    {
      'insert': '{{trabajador.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', correo electrónico '},
    {
      'insert': '{{trabajador.correo}}',
      'attributes': {'bold': true},
    },
    {'insert': ', de nacionalidad '},
    {
      'insert': '{{trabajador.nacionalidad}}',
      'attributes': {'bold': true},
    },
    {'insert': ', estado civil '},
    {
      'insert': '{{trabajador.estado_civil}}',
      'attributes': {'bold': true},
    },
    {'insert': ', fecha de nacimiento '},
    {
      'insert': '{{trabajador.nacimiento}}',
      'attributes': {'bold': true},
    },
    {'insert': ', con domicilio en '},
    {
      'insert': '{{trabajador.domicilio}}',
      'attributes': {'bold': true},
    },
    {'insert': ', comuna de '},
    {
      'insert': '{{trabajador.comuna}}',
      'attributes': {'bold': true},
    },
    {'insert': ', en adelante el '},
    {
      'insert': '“trabajador”',
      'attributes': {'bold': true, 'underline': true},
    },
    {'insert': ' se suscribe el siguiente contrato de trabajo:'},
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    // --- clausulas ---
    {
      'insert': 'Primero: ',
      'attributes': {'bold': true},
    },
    {'insert': 'El Empleador contrata al trabajador para ejecutar '},
    {
      'insert': '{{trabajador.labor}}',
      'attributes': {'bold': true},
    },
    {'insert': ' en el establecimiento de '},
    {
      'insert': '{{contrato.establecimiento}}',
      'attributes': {'bold': true},
    },
    {'insert': '.'},
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'Segundo: ',
      'attributes': {'bold': true},
    },
    {
      'insert': 'El empleador se compromete a remunerar al trabajador la suma '
          'de ',
    },
    {
      'insert': '{{contrato.sueldo}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', diarios, del monto señalado el empleador efectuara los '
          'descuentos correspondientes a las leyes sociales.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'Tercero: ',
      'attributes': {'bold': true},
    },
    {
      'insert': 'El trabajador se obliga a cumplir la siguiente jornada de '
          'trabajo de ',
    },
    {
      'insert': '{{contrato.horas_semanales}} horas semanales.',
      'attributes': {'bold': true},
    },
    {'insert': ' {{contrato.horario}} con {{contrato.colacion}} de colación.'},
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'Cuarto: ',
      'attributes': {'bold': true},
    },
    {
      'insert': 'Queda estrictamente prohibido al trabajador realizar '
          'cualquier labor o trabajo, ya sea por cuenta propia o ajena que '
          'valla en desmedro de las obligaciones que asume, en especial en '
          'aquellas referidas al cumplimiento a las jornadas de trabajo.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'Quinto: ',
      'attributes': {'bold': true},
    },
    {
      'insert': 'El presente contrato durará la faena determinada descrita '
          'anteriormente pudiendo cualquiera de las partes ponerle termino a '
          'las condiciones, las cuales establece el código del trabajo.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'Sexto: ',
      'attributes': {'bold': true},
    },
    {
      'insert': 'Se hace entrega del reglamento interno de la empresa, el '
          'trabajador toma conocimiento y se compromete a cumplir las '
          'obligaciones y prohibiciones que en él se mencionan del derecho de '
          'saber.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'Séptimo: ',
      'attributes': {'bold': true},
    },
    {'insert': 'El trabajador se encuentra afiliado a la AFP '},
    {
      'insert': '{{trabajador.afp}}',
      'attributes': {'bold': true},
    },
    {'insert': '. Asimismo, se encuentra afiliado a la Previsión de Salud '},
    {
      'insert': '{{trabajador.prevision}}.',
      'attributes': {'bold': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'Octavo: ',
      'attributes': {'bold': true},
    },
    {'insert': 'Se deja constancia que el trabajador ingresó el día '},
    {
      'insert': '{{contrato.fecha_ingreso}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ' y expira conjuntamente con las labores que le dieron origen, '
          'para lo cual el trabajador se da por notificado de desahucio al '
          'momento de suscribir este contrato.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },

    {
      'insert': 'El presente contrato se firma en dos ejemplares, quedando uno '
          'de ellos en poder del empleador y el otro en poder del trabajador, '
          'quien declara recibirlo a su entera satisfacción.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
  ],
};

/// Derecho a saber: obligacion de informar los riesgos laborales.
///
/// El cuerpo es prosa, pero el corazon del documento es la tabla de riesgos y
/// medidas. Va aparte del texto -- ver [filasDerechoASaber] -- y se coloca en
/// el cuerpo con el marcador `{{tabla}}`.
const Map<String, dynamic> deltaDerechoASaber = {
  'ops': [
    {
      'insert': 'DERECHO A SABER',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'center'},
    },
    {'insert': 'Nombre: '},
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ', Fecha: '},
    {
      'insert': '{{contrato.fecha}}',
      'attributes': {'bold': true},
    },
    {'insert': ', RUT: N° '},
    {
      'insert': '{{trabajador.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', Área de trabajo: '},
    {
      'insert': '{{contrato.establecimiento}}',
      'attributes': {'bold': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {'insert': 'A través de la presente, la empresa '},
    {
      'insert': '{{empresa.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', Representada por Don '},
    {
      'insert': '{{empresa.representante}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.representante_rut}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', declara haberme informado de los riesgos que entrañan las '
          'labores que desarrollaré en mi trabajo, así como las medidas '
          'preventivas que debo tomar para hacer de esto un método seguro de '
          'trabajo.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {'insert': '{{tabla}}'},
    {'insert': '\n'},
    {
      'insert': 'Declaro haber recibido la introducción de seguridad laboral y '
          'entender a los riesgos a los que me expongo.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
  ],
};

/// Riesgos y medidas, tal como estaban escritos en el generador.
const List<List<String>> filasDerechoASaber = [
  [
    'ATROPELLAMIENTO',
    '- Evite correr, transite por calles y recorridos autorizados.\n'
        '- En caminos marcados transite enfrentando al conductor.',
  ],
  [
    'LESIONES OCULARES',
    '- Utilice elementos oculares en todo momento para evitar golpes con ramas '
        'al transitar entre las matas o al acercarse a retirar frutas.',
  ],
  [
    'CAIDAS A NIVEL Y DISTINTO NIVEL',
    '- Utilice pisos y escaleras bien anclados y con responsabilidad.\n'
        '- Tener atención a las superficies de trabajo.\n'
        '- Mantener su entorno de trabajo libre de obstáculos.\n'
        '- No utilice el celular mientras camina.\n'
        '- Cuando transite entre hileras mantenga cuidado con mangueras y '
        'ramas de podas pasadas.',
  ],
  [
    'EXPOSICION A MANEJO MANUAL DE CARGA',
    '- Aplicar método correcto de levantamiento de carga y de posturas '
        'correctas de trabajo, el peso máximo a mover es de 25 kg para '
        'hombres y 20 kg para mujeres, solicite ayuda si es necesario.\n'
        '- No trasladar mas de una escalera o banquillo por persona.',
  ],
  [
    'EXPOSICION A PRODUCTOS FITOSANITARIOS',
    '- Actuar conforme a los procedimientos de aplicación y resguardo de '
        'almacenamiento e higiene que existen para cada tipo.\n'
        '- Después de cada aplicación deberá ducharse y usar ropa distinta.\n'
        '- Respetar los plazos de resguardo a los cuarteles.',
  ],
  [
    'EXPOSICION A RADIACION UV SOLAR',
    '- La exposición y/o acumulación de radiación ultravioleta de fuentes '
        'naturales o artificiales deben llevar el resguardo necesario.\n'
        '- Usar los artículos necesarios para evitar la exposición (lentes con '
        'protección uv, gorros legionarios, uso y aplicación de protector '
        'solar cada 2 horas si es necesario).',
  ],
];

/// Entrega de elementos de proteccion personal.
const Map<String, dynamic> deltaEpp = {
  'ops': [
    {
      'insert': 'FICHA DE ENTREGA DE ELEMENTOS DE PROTECCION',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'center'},
    },
    {
      'insert': 'Según lo establecido en el articulo 53 del decreto supremo '
          '594, el empleador deberá proporcionar a sus trabajadores, libre de '
          'costo, los elementos de protección personal adecuados al riesgo a '
          'cubrir y el adiestramiento necesario para su correcto empleo, '
          'debiendo, además, mantenerlo en perfecto estado de funcionamiento. '
          'Por su parte, el trabajador deberá usarlos en forma permanente '
          'mientras se encuentre expuesto al riesgo.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Asimismo, se recuerda lo establecido en el articulo 68 de la '
          'Ley N° 16.744 donde se indica que “las empresas deberán '
          'proporcionar a sus trabajadores los equipos e implementos de '
          'protección necesarios, no pudiendo en caso alguno cobrarles su '
          'valor”.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {'insert': '{{tabla}}'},
    {'insert': '\n'},
  ],
};

/// Implementos entregados. Las dos columnas de fecha se completan a mano sobre
/// el papel, por eso van vacias.
const List<List<String>> filasEpp = [
  ['GORRO LEGENDARIO', '', ''],
  ['ANTIPARRAS', '', ''],
  ['GUANTES', '', ''],
  ['BLOQUEADOR', '', ''],
];

/// Finiquito: termino de la relacion laboral.
///
/// Prosa pura. Los montos no salen de la ficha del trabajador sino del
/// formulario que se llena al emitirlo, de ahi `{{finiquito.vacaciones}}` y
/// `{{finiquito.total}}`.
const Map<String, dynamic> deltaFiniquito = {
  'ops': [
    {
      'insert': 'FINIQUITO DEL TRABAJADOR',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'center'},
    },
    {'insert': 'En Paine, a '},
    {
      'insert': '{{finiquito.fecha_egreso}}',
      'attributes': {'bold': true},
    },
    {'insert': ', entre '},
    {
      'insert': '{{empresa.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', Representada por Don '},
    {
      'insert': '{{empresa.representante}}',
      'attributes': {'bold': true},
    },
    {'insert': ' RUT N° '},
    {
      'insert': '{{empresa.representante_rut}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', ambos con domicilio en {{empresa.domicilio}}, en lo '
          'sucesivo ',
    },
    {
      'insert': 'El “Empleador”',
      'attributes': {'bold': true, 'underline': true},
    },
    {
      'insert': ' y Don(a): ',
      'attributes': {'bold': true},
    },
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ', RUT N° '},
    {
      'insert': '{{trabajador.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', se acuerda el siguiente finiquito:'},
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Primero: ',
      'attributes': {'bold': true},
    },
    {'insert': 'Don(a) '},
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': ', RUT N° '},
    {
      'insert': '{{trabajador.rut}}',
      'attributes': {'bold': true},
    },
    {'insert': ', prestó servicios a “'},
    {
      'insert': '{{empresa.nombre}}',
      'attributes': {'bold': true},
    },
    {'insert': '”, ejecutando '},
    {
      'insert': '{{trabajador.labor}}',
      'attributes': {'bold': true},
    },
    {'insert': ', desde el día '},
    {
      'insert': '{{contrato.fecha_ingreso}}',
      'attributes': {'bold': true},
    },
    {'insert': ' hasta el día '},
    {
      'insert': '{{finiquito.fecha_egreso}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', fecha esta última de terminación de los servicios por la '
          'causa del Art. 159 Inciso N° 5, “CONCLUSION DEL TRABAJO O SERVICIO '
          'QUE DIÓ ORIGEN AL CONTRATO”.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Segundo: ',
      'attributes': {'bold': true},
    },
    {'insert': 'Don(a) '},
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', declara recibir en este acto a su entera satisfacción, de '
          'parte de {{empresa.nombre}}, las sumas que a continuación se '
          'indican:',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Vacaciones proporcionales: {{finiquito.vacaciones}}',
      'attributes': {'bold': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Total: {{finiquito.total}}',
      'attributes': {'bold': true},
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Tercero: ',
      'attributes': {'bold': true},
    },
    {'insert': 'Don(a) '},
    {
      'insert': '{{trabajador.nombre}}',
      'attributes': {'bold': true},
    },
    {
      'insert': ', deja constancia que durante el tiempo que prestó servicios '
          'a “{{empresa.nombre}}”; recibió oportunamente el total de las '
          'remuneraciones, beneficios y demás prestaciones convenidas de '
          'acuerdo a su contrato de trabajo, clase de trabajo ejecutado y '
          'disposiciones legales pertinentes, y que en tal virtud el empleador '
          'nada le adeuda por tales conceptos, ni por horas extraordinarias, '
          'asignación familiar, feriado, indemnización por años de servicios, '
          'imposiciones previsionales, así como por ningún otro concepto, ya '
          'sea legal o contractual, derivado de la prestación de sus '
          'servicios, de su contrato de trabajo o de la terminación del '
          'mismo. En consecuencia, declara que no tiene reclamo alguno que '
          'formular en contra de “{{empresa.nombre}}”.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Cuarto: ',
      'attributes': {'bold': true},
    },
    {
      'insert': 'Se deja constancia de acuerdo a la ley N.º 21329 el '
          'trabajador no está afecto a la retención por pensión alimenticia.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
    {
      'insert': 'Para constancia firman las partes el presente FINIQUITO en '
          'dos ejemplares, quedando uno de ellos en poder del empleador y el '
          'otro en poder del trabajador.',
    },
    {
      'insert': '\n',
      'attributes': {'align': 'justify'},
    },
  ],
};

/// Plantillas listas para sembrar, por clave de tipo.
const Map<String, Map<String, dynamic>> plantillasIniciales = {
  'registro': deltaRegistro,
  'contrato': deltaContrato,
  'derecho-a-saber': deltaDerechoASaber,
  'epp': deltaEpp,
  'finiquito': deltaFiniquito,
};

/// Filas iniciales de los documentos que llevan tabla.
const Map<String, List<List<String>>> filasIniciales = {
  'derecho-a-saber': filasDerechoASaber,
  'epp': filasEpp,
};
