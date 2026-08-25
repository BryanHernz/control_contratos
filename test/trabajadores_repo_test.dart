import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/trabajadores_repo.dart';

/// Logica pura del repositorio de trabajadores: la que decide que se consulta
/// y con que texto se busca. No toca Firestore.
void main() {
  group('textoDeBusqueda', () {
    test('junta nombre, apellido y rut en minusculas', () {
      expect(
        TrabajadoresRepo.textoDeBusqueda(
          nombres: 'María Fernanda',
          apellidos: 'González Aravena',
          rut: '18.765.432-1',
        ),
        'maria fernanda gonzalez aravena 18.765.432-1',
      );
    });

    test('quita las tildes, que es lo que hace buscable a "Curico"', () {
      expect(
        TrabajadoresRepo.textoDeBusqueda(nombres: 'José', apellidos: 'Muñoz'),
        'jose munoz',
      );
    });

    test('no deja espacios de sobra cuando falta un dato', () {
      expect(
        TrabajadoresRepo.textoDeBusqueda(nombres: 'Ana', rut: '11.111.111-1'),
        'ana 11.111.111-1',
      );
      expect(TrabajadoresRepo.textoDeBusqueda(), '');
    });
  });

  group('prefijosDeBusqueda', () {
    // El caso que fallaba: guardando una sola cadena concatenada, buscar por
    // apellido no encontraba a nadie, porque "bryan hernandez ..." no empieza
    // con "hernan".
    final bryan = TrabajadoresRepo.prefijosDeBusqueda(
      nombres: 'Bryan',
      apellidos: 'Hernández',
      rut: '12.345.678-9',
    );

    test('encuentra por el apellido, no solo por el nombre', () {
      expect(bryan, contains('hernan'));
      expect(bryan, contains('hernandez'));
      expect(bryan, contains('br'));
      expect(bryan, contains('bryan'));
    });

    test('el apellido entra sin tilde', () {
      // Se teclea "hernandez", no "hernández".
      expect(bryan, contains('hernande'));
      expect(bryan.any((p) => p.contains('á')), isFalse);
    });

    test('el RUT se encuentra con puntos y sin ellos', () {
      expect(bryan, contains('12.345.678-9'.substring(0, 12)));
      expect(bryan, contains('123456789'));
      expect(bryan, contains('1234'));
    });

    test('no indexa prefijos de una sola letra', () {
      // Con una letra el array de cualquiera coincidiria con media planilla.
      expect(bryan.every((p) => p.length >= 2), isTrue);
    });

    test('el array se mantiene acotado', () {
      final largo = TrabajadoresRepo.prefijosDeBusqueda(
        nombres: 'Maria Fernanda Alejandra',
        apellidos: 'Gonzalez Aravena Fuentealba',
        rut: '18.765.432-1',
      );
      // Cada palabra aporta a lo mas `maximoPrefijo - 1` entradas.
      expect(largo.length, lessThan(120));
      expect(largo.every((p) => p.length <= TrabajadoresRepo.maximoPrefijo),
          isTrue);
    });

    test('sin datos no genera nada', () {
      expect(TrabajadoresRepo.prefijosDeBusqueda(), isEmpty);
      // Una inicial suelta tampoco: no llega al minimo.
      expect(TrabajadoresRepo.prefijosDeBusqueda(nombres: 'A'), isEmpty);
    });

    test('varios nombres aportan cada uno los suyos', () {
      final p = TrabajadoresRepo.prefijosDeBusqueda(
        nombres: 'Juan Carlos',
        apellidos: 'Perez Soto',
      );
      expect(p, containsAll(['ju', 'juan', 'ca', 'carlos', 'pe', 'so']));
    });
  });

  group('FiltrosTrabajadores', () {
    test('sin nada seleccionado esta vacio', () {
      const f = FiltrosTrabajadores();
      expect(f.vacio, isTrue);
      expect(f.hayFiltroDeCampo, isFalse);
      expect(f.hayBusqueda, isFalse);
      expect(f.camposActivos, isEmpty);
    });

    test('una busqueda de solo espacios no cuenta', () {
      const f = FiltrosTrabajadores(busqueda: '   ');
      expect(f.hayBusqueda, isFalse);
      expect(f.vacio, isTrue);
    });

    test('el establecimiento se consulta como `lugar`', () {
      // El modelo lo llama `place` y la vista "empresa", pero en Firestore el
      // campo es `lugar`. Si esto se rompe, el filtro no devuelve nada.
      const f = FiltrosTrabajadores(empresa: 'fundo santa filomena');
      expect(f.camposActivos.first.$1, 'lugar');
      expect(f.camposActivos.first.$2, 'fundo santa filomena');
    });

    test('los filtros salen en orden y solo los activos', () {
      const f = FiltrosTrabajadores(labor: 'poda', afp: 'habitat');
      expect(f.camposActivos.map((c) => c.$1).toList(), ['labor', 'afp']);
    });

    test('con varios filtros, el primero es el que va al servidor', () {
      // Firestore necesita un indice compuesto por cada combinacion de
      // igualdades mas el orden. Solo se declara uno por campo, asi que el
      // resto se afina en memoria sobre un conjunto ya reducido.
      //
      // El orden es el DECLARADO en `camposActivos`, no el orden en que se
      // pasan los argumentos: `labor` va antes que `comuna` aunque aqui se
      // escriba despues. Eso decide cual consulta necesita indice.
      const f = FiltrosTrabajadores(
        comuna: 'paine',
        labor: 'poda',
        prevision: 'fonasa',
      );
      expect(f.camposActivos.length, 3);
      expect(f.camposActivos.map((c) => c.$1).toList(),
          ['labor', 'comuna', 'prevision']);
      expect(f.camposActivos.first.$1, 'labor');
    });
  });
}
