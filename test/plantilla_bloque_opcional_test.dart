import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/services/plantilla_render.dart';

/// El contrato en codigo omitia entero el trozo ", correo electronico ..."
/// cuando el trabajador no tenia correo. Al migrarlo a plantilla eso se
/// perdio: una plantilla es texto y no sabe decir "esto solo si hay dato", asi
/// que 640 de 676 contratos salian con la frase colgando y nada detras.
///
/// Estas pruebas fijan el bloque `{{si ...}} ... {{fin}}` que lo devuelve.
void main() {
  /// El fragmento real de la plantilla de contrato: la frase va en un `insert`
  /// y el marcador en otro, porque el valor va en negrita. El bloque tiene que
  /// funcionar cruzando esa frontera.
  Map<String, dynamic> delta() => {
        'ops': [
          {'insert': 'don '},
          {
            'insert': '{{trabajador.nombres}}',
            'attributes': {'bold': true}
          },
          {'insert': '{{si trabajador.correo}}, correo electrónico '},
          {
            'insert': '{{trabajador.correo}}',
            'attributes': {'bold': true}
          },
          {'insert': '{{fin}}'},
          {'insert': ', de nacionalidad chilena.\n'},
        ]
      };

  String render(Map<String, String> datos) {
    final a = AnalizadorPlantilla(datos: datos).analizar(delta());
    return a.parrafos
        .map((p) => p.trozos.map((t) => t.texto).join())
        .join('\n');
  }

  test('con correo, imprime la frase y el valor', () {
    final texto = render({
      'trabajador.nombres': 'JUAN PEREZ',
      'trabajador.correo': 'JUAN@EJEMPLO.CL',
    });
    expect(texto, 'don JUAN PEREZ, correo electrónico JUAN@EJEMPLO.CL, '
        'de nacionalidad chilena.');
  });

  test('SIN correo, no queda la frase colgando', () {
    final texto = render({
      'trabajador.nombres': 'JUAN PEREZ',
      'trabajador.correo': '',
    });
    expect(texto, 'don JUAN PEREZ, de nacionalidad chilena.');
    expect(texto, isNot(contains('correo electrónico')));
  });

  test('la clave ausente se comporta igual que la vacia', () {
    final texto = render({'trabajador.nombres': 'JUAN PEREZ'});
    expect(texto, isNot(contains('correo electrónico')));
  });

  test('un bloque opcional vacio no se reporta como marcador sin resolver', () {
    // Si se reportara, el editor avisaria "falta este campo" por algo que es
    // opcional por diseño, y el aviso dejaria de significar nada.
    final a = AnalizadorPlantilla(datos: {
      'trabajador.nombres': 'JUAN PEREZ',
      'trabajador.correo': '',
    }).analizar(delta());
    expect(a.marcadoresSinValor, isNot(contains('trabajador.correo')));
    expect(a.marcadoresSinValor, isNot(contains('fin')));
  });

  test('un marcador FUERA de un bloque sigue avisando si no tiene valor', () {
    final a = AnalizadorPlantilla(datos: const {}).analizar(delta());
    expect(a.marcadoresSinValor, contains('trabajador.nombres'));
  });
}
