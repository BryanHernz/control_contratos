import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/customs/widgets/banda_barra_estado.dart';

/// La barra de estado se veia blanca en Android 15 porque el sistema descarta
/// `statusBarColor` y la app dibuja debajo de la barra. Estas pruebas fijan las
/// dos mitades del arreglo: que la franja se pinte, y que no se cuente dos
/// veces.
void main() {
  const azul = Color(0xFF455A64);

  /// Monta el widget simulando el inset que reporta el sistema.
  Future<void> montar(WidgetTester tester, double insetSuperior,
      {required Widget hijo}) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: insetSuperior)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: BandaBarraDeEstado(color: azul, child: hijo),
        ),
      ),
    );
  }

  testWidgets('pinta una franja del alto de la barra y con el color pedido',
      (tester) async {
    await montar(tester, 48, hijo: const SizedBox.expand());

    final franja = tester.widget<Container>(find.byType(Container).first);
    expect(tester.getSize(find.byType(Container).first).height, 48);
    expect((franja.color ?? (franja.decoration as BoxDecoration?)?.color), azul);
  });

  testWidgets('el hijo ya no ve el padding superior, para que un SafeArea '
      'no lo sume de nuevo', (tester) async {
    late EdgeInsets vistoPorElHijo;

    await montar(
      tester,
      48,
      hijo: Builder(
        builder: (context) {
          vistoPorElHijo = MediaQuery.paddingOf(context);
          return const SizedBox.expand();
        },
      ),
    );

    // Si esto fuera 48, un `SafeArea` dentro de la vista dejaria un hueco
    // blanco del alto de la barra debajo de la franja que ya pintamos.
    expect(vistoPorElHijo.top, 0);
  });

  testWidgets('sin inset -- web y escritorio -- no dibuja nada',
      (tester) async {
    await montar(tester, 0, hijo: const SizedBox.expand());

    expect(tester.getSize(find.byType(Container).first).height, 0);
  });

  testWidgets('el contenido arranca justo debajo de la franja', (tester) async {
    final llave = GlobalKey();

    await montar(
      tester,
      48,
      hijo: SizedBox.expand(key: llave),
    );

    expect(tester.getTopLeft(find.byKey(llave)).dy, 48);
  });

  testWidgets(
      'anidada como en main.dart, un SafeArea de una vista NO suma otro hueco',
      (tester) async {
    final llave = GlobalKey();

    // Este es el orden real: MediaQuery (escalado de texto) por fuera, la
    // franja por dentro, y la vista con su SafeArea al final. Si se invierte,
    // el MediaQuery de afuera reinstala el padding, el SafeArea lo aplica y
    // aparece un segundo hueco del alto de la barra -- que es exactamente el
    // borde blanco que se estaba arreglando.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 48)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: BandaBarraDeEstado(
                color: azul,
                child: SafeArea(child: SizedBox.expand(key: llave)),
              ),
            ),
          ),
        ),
      ),
    );

    // 48 = solo la franja. 96 seria la franja mas el SafeArea contando de
    // nuevo el mismo inset.
    expect(tester.getTopLeft(find.byKey(llave)).dy, 48);
  });
}
