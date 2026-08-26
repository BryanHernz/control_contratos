import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/services/duplicados.dart';

/// El detector no decide: propone. Estas pruebas fijan que la senal de
/// "probablemente no son la misma persona" se levante donde corresponde,
/// porque de eso depende que nadie fusione y borre a un trabajador real.
void main() {
  FichaRepetida ficha(Map<String, dynamic> datos, [String id = 'x']) =>
      FichaRepetida(id: id, datos: datos);

  group('normalizar', () {
    test('el mismo RUT escrito de varias formas es uno solo', () {
      expect(Duplicados.normalizar('12.345.678-9'), '123456789');
      expect(Duplicados.normalizar('12345678-9'), '123456789');
      expect(Duplicados.normalizar(' 12345678 9 '), '123456789');
      expect(Duplicados.normalizar('11.171.021-k'), '11171021K');
    });
  });

  group('pareceOtraPersona', () {
    test('nombre distinto Y fecha de nacimiento distinta -> sospechoso', () {
      // El caso real que aparecio en produccion: dos personas con el mismo
      // RUT escrito. Fusionarlas habria borrado a una.
      final g = GrupoRepetido(rut: '33669311K', fichas: [
        ficha({
          'nombres': 'rodrigo',
          'apellidos': 'gutierrez hurtado',
          'fechaNacimiento': '1 de noviembre de 2005',
        }),
        ficha({
          'nombres': 'camila',
          'apellidos': 'hurtado gutierrez',
          'fechaNacimiento': '6 de febrero de 2004',
        }),
      ]);
      expect(g.pareceOtraPersona, isTrue);
    });

    test('mismo nombre con tipeo y misma fecha -> no sospechoso', () {
      final g = GrupoRepetido(rut: '445306592', fichas: [
        ficha({
          'nombres': 'jhenny',
          'apellidos': 'coca muriel',
          'fechaNacimiento': '3 de mayo de 1995',
        }),
        ficha({
          'nombres': 'jenny',
          'apellidos': 'coca muriel',
          'fechaNacimiento': '3 de mayo de 1995',
        }),
      ]);
      expect(g.pareceOtraPersona, isFalse);
    });

    test('solo la fecha distinta, mismo nombre -> no sospechoso', () {
      // Un tipeo en la fecha es corriente; que ademas cambie el nombre no.
      final g = GrupoRepetido(rut: '335895487', fichas: [
        ficha({
          'nombres': 'jasmany',
          'apellidos': 'quiroz',
          'fechaNacimiento': '8 de agosto de 1990',
        }),
        ficha({
          'nombres': 'jasmany',
          'apellidos': 'quiroz',
          'fechaNacimiento': '25 de agosto de 1990',
        }),
      ]);
      expect(g.pareceOtraPersona, isFalse);
    });
  });

  group('camposEnConflicto', () {
    test('un campo vacio en una ficha no es un conflicto', () {
      // Que a una ficha le falte el correo y la otra lo traiga no es una
      // discrepancia: es justamente lo que la fusion viene a resolver.
      final g = GrupoRepetido(rut: '1', fichas: [
        ficha({'nombres': 'ana', 'correo': ''}),
        ficha({'nombres': 'ana', 'correo': 'ana@ejemplo.cl'}),
      ]);
      expect(g.camposEnConflicto, isEmpty);
    });

    test('dos valores distintos si lo son', () {
      final g = GrupoRepetido(rut: '1', fichas: [
        ficha({'labor': 'cosecha de cereza'}),
        ficha({'labor': 'cosecha de ciruelas'}),
      ]);
      expect(g.camposEnConflicto, contains('labor'));
    });
  });
}
