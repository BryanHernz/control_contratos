import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:myapp/services/trabajadores_repo.dart';

/// `ingreso` se guarda como texto en espanol. Estas pruebas fijan la
/// conversion a fecha real, que es lo que permite ordenar y filtrar.
void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  test('interpreta el formato que escribe el formulario', () {
    final d = fechaDeIngreso('4 de noviembre de 2025');
    expect(d, isNotNull);
    expect(d!.year, 2025);
    expect(d.month, 11);
    expect(d.day, 4);
  });

  test('guarda a mediodia UTC, no a medianoche', () {
    // Chile va en UTC-3 o UTC-4: con 00:00Z la fecha se lee como el dia
    // ANTERIOR en hora local y todo el padron se correria un dia.
    final d = fechaDeIngreso('1 de diciembre de 2025')!;
    expect(d.isUtc, isTrue);
    expect(d.hour, 12);
    expect(d.toLocal().day, 1);
  });

  test('devuelve null en vez de inventar una fecha', () {
    expect(fechaDeIngreso(''), isNull);
    expect(fechaDeIngreso(null), isNull);
    expect(fechaDeIngreso('cuando empezo la cosecha'), isNull);
  });
}
